import 'package:memorylens/features/error_handling/data/mapper/exception_mapper.dart';
import 'package:memorylens/features/gallery_import/data/source/signed_in_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The only file that reads and writes the escaneo_galeria table.
class SupabaseImportScanDataSource {
  /// Postgres code for "this row breaks a unique index".
  static const _uniqueViolationCode = '23505';

  final SupabaseClient _client = Supabase.instance.client;

  /// A person can only have one open scan (a unique index guarantees it), so
  /// an import that was cut short is continued instead of starting another.
  Future<String> startOrResume({required int total}) async {
    try {
      final userId = signedInUserId(_client);
      final open = await _findOpenScanId(userId);
      if (open != null) return await _saveTotal(open, total);

      try {
        final row = await _client
            .from('escaneo_galeria')
            .insert({'usuario_id': userId, 'total_fotos': total})
            .select('id')
            .single();
        return row['id'] as String;
      } on PostgrestException catch (e) {
        if (e.code != _uniqueViolationCode) rethrow;
        // Another run opened a scan right after the look above: use that one.
        final raced = await _findOpenScanId(userId);
        if (raced == null) rethrow;
        return await _saveTotal(raced, total);
      }
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  Future<void> markImportFinished(String scanId) async {
    try {
      await _client
          .from('escaneo_galeria')
          .update({
            'importacion_finalizada_en': DateTime.now()
                .toUtc()
                .toIso8601String(),
          })
          .eq('id', scanId);
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  Future<bool> hasPendingImport() async {
    try {
      final rows = await _client
          .from('escaneo_galeria')
          .select('id')
          .eq('usuario_id', signedInUserId(_client))
          .isFilter('finalizado_en', null)
          .isFilter('importacion_finalizada_en', null)
          .limit(1);
      return rows.isNotEmpty;
    } catch (e, stack) {
      Error.throwWithStackTrace(ExceptionMapper.map(e), stack);
    }
  }

  Future<String?> _findOpenScanId(String userId) async {
    final row = await _client
        .from('escaneo_galeria')
        .select('id')
        .eq('usuario_id', userId)
        .isFilter('finalizado_en', null)
        .maybeSingle();
    return row?['id'] as String?;
  }

  /// Saves how many photos there are to process, and reopens the import in
  /// case it had been marked as over and new photos came in.
  Future<String> _saveTotal(String scanId, int total) async {
    await _client
        .from('escaneo_galeria')
        .update({'total_fotos': total, 'importacion_finalizada_en': null})
        .eq('id', scanId);
    return scanId;
  }
}
