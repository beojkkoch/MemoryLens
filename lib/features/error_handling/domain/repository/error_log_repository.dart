import 'package:memorylens/features/error_handling/domain/entities/error_report.dart';

abstract class ErrorLogRepository {
  /// Saves the report for the team. May throw when there is no connection.
  Future<void> log(ErrorReport report);
}
