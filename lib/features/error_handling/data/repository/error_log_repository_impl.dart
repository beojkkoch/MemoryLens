import 'package:memorylens/features/error_handling/data/source/supabase_error_log_data_source.dart';
import 'package:memorylens/features/error_handling/domain/entities/error_report.dart';
import 'package:memorylens/features/error_handling/domain/repository/error_log_repository.dart';
import 'package:memorylens/injection_container.dart';

class ErrorLogRepositoryImpl implements ErrorLogRepository {
  final SupabaseErrorLogDataSource _dataSource = sl();

  @override
  Future<void> log(ErrorReport report) {
    return _dataSource.insert(report);
  }
}
