import 'package:memorylens/features/auth/domain/entities/app_user.dart';

/// Contract for creating accounts and reading the open session.
abstract class AuthRepository {
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
    required String city,
    required String profession,
    required List<int> interestIds,
    required List<String> newInterestNames,
  });

  Future<AppUser> signIn({required String email, required String password});

  Future<void> signOut();

  AppUser? currentUser();
}
