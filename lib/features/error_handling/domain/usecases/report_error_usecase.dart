import 'package:memorylens/features/error_handling/domain/entities/app_exception.dart';
import 'package:memorylens/features/error_handling/domain/entities/error_report.dart';
import 'package:memorylens/features/error_handling/domain/repository/error_log_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Sends a technical error to the team log. It never throws, so reporting
/// can not become a new failure.
class ReportErrorUseCase {
  /// Looked up on each call, inside the try: if Supabase failed to start the
  /// repository can not be built, and that must not break the app either.
  ErrorLogRepository get _log => sl();

  Future<void> call({
    required String screen,
    required String action,
    required Object error,
    StackTrace? stackTrace,
  }) async {
    // A wrong password is a normal outcome, not something the team fixes.
    if (error is AppException && !error.technical) return;
    final origin = error is AppException ? (error.cause ?? error) : error;
    try {
      await _log.log(
        ErrorReport(
          screen: screen,
          action: action,
          errorType: origin.runtimeType.toString(),
          message: origin.toString(),
          stackTrace: stackTrace?.toString(),
        ),
      );
    } catch (_) {
      // Usually there is no connection: the error stays out of the log.
    }
  }
}
