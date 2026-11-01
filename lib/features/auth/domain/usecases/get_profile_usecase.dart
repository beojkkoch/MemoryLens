import 'package:memorylens/features/auth/domain/entities/profile.dart';
import 'package:memorylens/features/auth/domain/repository/auth_repository.dart';
import 'package:memorylens/features/auth/domain/repository/profile_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Brings the profile of the person who has the session open.
class GetProfileUseCase {
  final AuthRepository _auth = sl();
  final ProfileRepository _profiles = sl();

  Future<Profile> call() {
    final user = _auth.currentUser();
    if (user == null) {
      throw Exception('No hay una sesión abierta');
    }
    return _profiles.getProfile(user.id);
  }
}
