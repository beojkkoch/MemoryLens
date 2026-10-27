import 'package:memorylens/features/auth/data/source/supabase_auth_data_source.dart';
import 'package:memorylens/features/auth/domain/entities/app_user.dart';
import 'package:memorylens/features/auth/domain/repository/auth_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Fulfils AuthRepository by delegating on the Supabase data source.
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseAuthDataSource _dataSource = sl();

  @override
  Future<AppUser> signUp({required String email, required String password}) {
    return _dataSource.signUp(email: email, password: password);
  }

  @override
  AppUser? currentUser() {
    return _dataSource.currentUser();
  }
}
