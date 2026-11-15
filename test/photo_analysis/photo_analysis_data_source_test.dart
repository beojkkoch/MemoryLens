import 'package:flutter_test/flutter_test.dart';
import 'package:memorylens/features/error_handling/data/mapper/exception_mapper.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/photo_analysis/data/source/supabase_photo_analysis_data_source.dart';
import 'package:memorylens/features/photo_analysis/domain/entities/photo_analysis_outcome.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('the answer of analizar-fotos', () {
    test('reads the state of each photo', () {
      final results = SupabasePhotoAnalysisDataSource.parseResults({
        'resultados': [
          {'foto_id': 'a', 'estado': 'listo'},
          {'foto_id': 'b', 'estado': 'error'},
        ],
      });

      expect(results, {
        'a': PhotoAnalysisOutcome.analyzed,
        'b': PhotoAnalysisOutcome.failed,
      });
    });

    test('ignores rows it does not understand', () {
      final results = SupabasePhotoAnalysisDataSource.parseResults({
        'resultados': [
          {'foto_id': 'a', 'estado': 'raro'},
          {'estado': 'listo'},
          'texto',
        ],
      });

      expect(results, isEmpty);
      expect(SupabasePhotoAnalysisDataSource.parseResults('x'), isEmpty);
      expect(SupabasePhotoAnalysisDataSource.parseResults(null), isEmpty);
    });

    test('takes the wait the function asks for', () {
      expect(
        SupabasePhotoAnalysisDataSource.retryAfterFrom({'reintentar_en': 12}),
        const Duration(seconds: 12),
      );
      expect(
        SupabasePhotoAnalysisDataSource.retryAfterFrom({'error': 'ocupado'}),
        SupabasePhotoAnalysisDataSource.defaultRetryAfter,
      );
      expect(
        SupabasePhotoAnalysisDataSource.retryAfterFrom('Too Many Requests'),
        SupabasePhotoAnalysisDataSource.defaultRetryAfter,
      );
    });
  });

  group('errors of an Edge Function', () {
    test('one that could not be reached is a connection problem', () {
      final mapped = ExceptionMapper.map(
        const FunctionsFetchException(details: 'socket closed'),
      );

      expect(mapped.kind, AppErrorKind.network);
    });

    test('a gateway timeout is a timeout', () {
      final mapped = ExceptionMapper.map(
        const FunctionsHttpException(status: 504),
      );

      expect(mapped.kind, AppErrorKind.timeout);
    });

    test('any other failure is ours, with a friendly message', () {
      final mapped = ExceptionMapper.map(
        const FunctionsHttpException(status: 500, details: {'error': 'x'}),
      );

      expect(mapped.kind, AppErrorKind.server);
      expect(mapped.message, isNot(contains('500')));
    });
  });
}
