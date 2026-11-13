import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns any raw failure into an AppException with a friendly Spanish message.
///
/// It lives in the data layer because it knows the types thrown by http and
/// Supabase. It avoids dart:io so it also works on web.
class ExceptionMapper {
  static const _networkMessage =
      'No pudimos conectarnos. Revisa tu conexión a internet e inténtalo '
      'de nuevo.';
  static const _timeoutMessage =
      'La conexión está tardando demasiado. Inténtalo de nuevo.';
  static const _serverMessage =
      'Tuvimos un problema de nuestro lado. Inténtalo de nuevo en unos '
      'minutos.';
  static const _notFoundMessage =
      'No encontramos la información. Inténtalo de nuevo.';

  /// PostgREST code for "the query returned no rows".
  static const _noRowsCode = 'PGRST116';

  static AppException map(Object error) {
    if (error is AppException) return error;
    // AuthRetryableFetchException is an AuthException, so it goes first.
    if (error is AuthRetryableFetchException || error is http.ClientException) {
      return AppException(
        _networkMessage,
        kind: AppErrorKind.network,
        cause: error,
      );
    }
    if (error is TimeoutException) {
      return AppException(
        _timeoutMessage,
        kind: AppErrorKind.timeout,
        cause: error,
      );
    }
    if (error is PostgrestException) {
      final noRows = error.code == _noRowsCode;
      return AppException(
        noRows ? _notFoundMessage : _serverMessage,
        kind: noRows ? AppErrorKind.notFound : AppErrorKind.server,
        cause: error,
      );
    }
    if (error is AuthException) {
      return AppException(
        _serverMessage,
        kind: AppErrorKind.server,
        cause: error,
      );
    }
    return AppException(
      AppException.genericMessage,
      kind: AppErrorKind.unknown,
      cause: error,
    );
  }
}
