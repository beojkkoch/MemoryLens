import 'package:memorylens/features/auth/data/source/supabase_profile_data_source.dart';
import 'package:memorylens/features/auth/domain/entities/profile.dart';
import 'package:memorylens/features/auth/domain/repository/profile_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Fulfils ProfileRepository by delegating on the Supabase data source.
class ProfileRepositoryImpl implements ProfileRepository {
  final SupabaseProfileDataSource _dataSource = sl();

  @override
  Future<void> createProfile(Profile profile) {
    return _dataSource.createProfile(profile);
  }

  @override
  Future<void> saveInterests(String userId, List<int> interestIds) {
    return _dataSource.saveInterests(userId, interestIds);
  }
}
