import 'package:memorylens/features/auth/data/source/supabase_auth_data_source.dart';
import 'package:memorylens/features/auth/domain/entities/app_user.dart';
import 'package:memorylens/features/auth/domain/repository/auth_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Fulfils AuthRepository by delegating on the Supabase data source.
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseAuthDataSource _dataSource = sl();

  //AuthRepositoryImpl(this._dataSource);

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
    required String city,
    required String profession,
    required List<int> interestIds,
    required List<String> newInterestNames,
  }) {
    return _dataSource.signUp(
      email: email,
      password: password,
      fullName: fullName,
      city: city,
      profession: profession,
      interestIds: interestIds,
      newInterestNames: newInterestNames,
    );
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) {
    return _dataSource.signIn(email: email, password: password);
  }

  @override
  Future<void> signOut() {
    return _dataSource.signOut();
  }

  @override
  AppUser? currentUser() {
    return _dataSource.currentUser();
  }
}
