import 'package:memorylens/features/auth/domain/entities/app_user.dart';

/// Contract for creating accounts and reading the open session.
abstract class AuthRepository {
  Future<AppUser> signUp({required String email, required String password});
  AppUser? currentUser();
}
