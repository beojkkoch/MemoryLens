import 'package:memorylens/features/error_handling/data/mapper/exception_mapper.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/analysis_busy_exception.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/photo_analysis_outcome.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The only file that talks to the analizar-fotos Edge Function and reads the
/// analysis state of the foto table. The AI key lives in the function, never
/// in the app.
class SupabasePhotoAnalysisDataSource {
  static const functionName = 'analizar-fotos';

  /// The most rows the server gives in one answer.
  static const pageSize = 1000;

  /// When the function asks to wait without saying how long.
  static const defaultRetryAfter = Duration(seconds: 30);

  final SupabaseClient _client = Supabase.instance.client;

  /// Newest photos first, so the latest memories get described first. The
  /// row level security only shows each person their own photos.
  Future<List<String>> pendingPhotoIds() async {
    try {
      final ids = <String>[];
      var from = 0;
      while (true) {
        final rows = await _client
            .from('foto')
            .select('id')
            .eq('estado_analisis', 'pendiente')
            .order('fecha_captura', ascending: false, nullsFirst: false)
            .order('id')
            .range(from, from + pageSize - 1);
        ids.addAll(rows.map((row) => row['id'] as String));
        if (rows.length < pageSize) return ids;
        from += pageSize;
      }
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  /// Photos in [state]: 'pendiente', 'listo' or 'error'.
  Future<int> countInState(String state) async {
    try {
      final response = await _client
          .from('foto')
          .select('id')
          .eq('estado_analisis', state)
          .count(CountOption.exact);
      return response.count;
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  Future<Map<String, PhotoAnalysisOutcome>> analyze(
    List<String> photoIds,
  ) async {
    try {
      final response = await _client.functions.invoke(
        functionName,
        body: {'foto_ids': photoIds},
      );
      return parseResults(response.data);
    } on FunctionsHttpException catch (e, stack) {
      // 429: free plan limit. 503: the model is overloaded. Both pass by
      // waiting, so they are not errors for the person.
      if (e.status == 429 || e.status == 503) {
        Error.throwWithStackTrace(
          AnalysisBusyException(retryAfterFrom(e.details)),
          stack,
        );
      }
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  /// Uses the same function the Edge Function uses for a photo that is gone,
  /// one call per photo, all at the same time.
  Future<void> markFailed(List<String> photoIds) async {
    try {
      await Future.wait(
        photoIds.map(
          (id) => _client.rpc(
            'marcar_error_analisis_foto',
            params: {'p_foto_id': id},
          ),
        ),
      );
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  /// Reads `{"resultados": [{"foto_id": "...", "estado": "listo"}]}`.
  static Map<String, PhotoAnalysisOutcome> parseResults(Object? data) {
    final results = <String, PhotoAnalysisOutcome>{};
    final rows = data is Map ? data['resultados'] : null;
    if (rows is! List) return results;
    for (final row in rows) {
      if (row is! Map) continue;
      final id = row['foto_id'];
      if (id is! String) continue;
      switch (row['estado']) {
        case 'listo':
          results[id] = PhotoAnalysisOutcome.analyzed;
        case 'reintentar':
          results[id] = PhotoAnalysisOutcome.retry;
        case 'error':
          results[id] = PhotoAnalysisOutcome.failed;
      }
    }
    return results;
  }

  /// Reads `{"reintentar_en": 30}`, in seconds.
  static Duration retryAfterFrom(Object? details) {
    final seconds = details is Map ? details['reintentar_en'] : null;
    if (seconds is num && seconds > 0) {
      return Duration(seconds: seconds.ceil());
    }
    return defaultRetryAfter;
  }
}
