import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:memorylens/features/error_handling/data/mapper/exception_mapper.dart';
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  /// Words that must never reach the person using the app.
  const technicalWords = [
    'Exception',
    'Socket',
    'Postgrest',
    'PGRST',
    'null',
    'Type',
    'http',
  ];

  void expectFriendly(AppException error) {
    for (final word in technicalWords) {
      expect(error.message, isNot(contains(word)));
    }
    expect(error.message, isNotEmpty);
  }

  group('ExceptionMapper', () {
    test('an AppException passes through untouched', () {
      const original = AppException('Mensaje listo');

      expect(identical(ExceptionMapper.map(original), original), isTrue);
    });

    test(
      'a failed request is a network error asking to check the connection',
      () {
        final mapped = ExceptionMapper.map(
          http.ClientException('Failed host lookup: vhavapudcqyvwycqizun'),
        );

        expect(mapped.kind, AppErrorKind.network);
        expect(mapped.message, contains('conexión'));
        expect(mapped.technical, isTrue);
        expectFriendly(mapped);
      },
    );

    test('a retryable auth fetch error is a network error', () {
      final mapped = ExceptionMapper.map(AuthRetryableFetchException());

      expect(mapped.kind, AppErrorKind.network);
      expectFriendly(mapped);
    });

    test('a timeout is told apart from a missing connection', () {
      final mapped = ExceptionMapper.map(
        TimeoutException('Future not completed'),
      );

      expect(mapped.kind, AppErrorKind.timeout);
      expect(mapped.message, contains('tardando'));
      expectFriendly(mapped);
    });

    test('a row that does not exist is a not found error', () {
      final mapped = ExceptionMapper.map(
        const PostgrestException(
          message: 'JSON object requested, multiple (or no) rows returned',
          code: 'PGRST116',
        ),
      );

      expect(mapped.kind, AppErrorKind.notFound);
      expectFriendly(mapped);
    });

    test('any other database failure is a server error', () {
      final mapped = ExceptionMapper.map(
        const PostgrestException(
          message: 'relation does not exist',
          code: '42P01',
        ),
      );

      expect(mapped.kind, AppErrorKind.server);
      expect(mapped.message, isNot(contains('relation')));
      expectFriendly(mapped);
    });

    test('a storage error without a status is a connection problem', () {
      final mapped = ExceptionMapper.map(
        const StorageException('Failed to fetch'),
      );

      expect(mapped.kind, AppErrorKind.network);
      expect(mapped.message, contains('conexión'));
      expectFriendly(mapped);
    });

    test('a storage request that times out is a timeout', () {
      for (final status in ['408', '504']) {
        final mapped = ExceptionMapper.map(
          StorageException('Gateway timeout', statusCode: status),
        );

        expect(mapped.kind, AppErrorKind.timeout, reason: status);
        expectFriendly(mapped);
      }
    });

    test('a missing bucket or file is a not found error', () {
      final mapped = ExceptionMapper.map(
        const StorageException('Bucket not found', statusCode: '404'),
      );

      expect(mapped.kind, AppErrorKind.notFound);
      expect(mapped.message, isNot(contains('Bucket')));
      expectFriendly(mapped);
    });

    test('a refused upload is a server error without the backend text', () {
      final mapped = ExceptionMapper.map(
        const StorageException(
          'new row violates row-level security policy',
          statusCode: '403',
        ),
      );

      expect(mapped.kind, AppErrorKind.server);
      expect(mapped.message, isNot(contains('row-level')));
      expectFriendly(mapped);
    });

    test('an unknown auth failure does not leak the english backend text', () {
      final mapped = ExceptionMapper.map(
        const AuthException(
          'Database error saving new user',
          code: 'unexpected_failure',
        ),
      );

      expect(mapped.kind, AppErrorKind.server);
      expect(mapped.message, isNot(contains('Database')));
    });

    test('a programming error becomes the generic message', () {
      final mapped = ExceptionMapper.map(TypeError());

      expect(mapped.kind, AppErrorKind.unknown);
      expect(mapped.message, AppException.genericMessage);
      expect(mapped.technical, isTrue);
    });

    test('the original error is kept as the cause for the log', () {
      final cause = http.ClientException('boom');

      expect(ExceptionMapper.map(cause).cause, same(cause));
    });
  });

  group('AppException', () {
    test('messageFor returns the message of an AppException', () {
      expect(
        AppException.messageFor(
          const AppException('Correo o contraseña incorrectos'),
        ),
        'Correo o contraseña incorrectos',
      );
    });

    test('messageFor hides any other error behind the generic message', () {
      expect(
        AppException.messageFor(
          Exception('SocketException: Connection refused'),
        ),
        AppException.genericMessage,
      );
      expect(
        AppException.messageFor(StateError('x')),
        AppException.genericMessage,
      );
    });

    test(
      'an exception written by hand is expected, so it is not technical',
      () {
        expect(const AppException('Ya existe una cuenta').technical, isFalse);
      },
    );
  });
}
