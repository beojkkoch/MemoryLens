import 'package:memorylens/features/auth/data/source/supabase_interest_data_source.dart';
import 'package:memorylens/features/auth/domain/entities/interest.dart';
import 'package:memorylens/features/auth/domain/repository/interest_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Fulfils InterestRepository by delegating on the Supabase data source.
class InterestRepositoryImpl implements InterestRepository {
  final SupabaseInterestDataSource _dataSource = sl();

  @override
  Future<List<Interest>> getInterests() {
    return _dataSource.getInterests();
  }
}
