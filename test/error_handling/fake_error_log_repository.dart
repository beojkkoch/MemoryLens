import 'package:memorylens/features/error_handling/domain/entities/error_report.dart';
import 'package:memorylens/features/error_handling/domain/repository/error_log_repository.dart';

/// Keeps the reports in memory instead of writing them to Supabase.
class FakeErrorLogRepository implements ErrorLogRepository {
  final List<ErrorReport> reports = [];
  Object? error;

  @override
  Future<void> log(ErrorReport report) async {
    if (error != null) throw error!;
    reports.add(report);
  }
}
