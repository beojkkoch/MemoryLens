import 'package:memorylens/features/auth/domain/entities/interest.dart';
import 'package:memorylens/features/auth/domain/entities/profile.dart';
import 'package:memorylens/features/auth/domain/repository/auth_repository.dart';
import 'package:memorylens/features/auth/domain/repository/profile_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Creates the account, saves its profile with the same id and its interests.
class SignUpUseCase {
  final AuthRepository _auth = sl();
  final ProfileRepository _profiles = sl();

  Future<Profile> call({
    required String fullName,
    required String email,
    required String password,
    required String city,
    required String profession,
    required List<Interest> interests,
  }) async {
    final user = await _auth.signUp(email: email, password: password);
    final profile = Profile(
      id: user.id,
      fullName: fullName,
      email: user.email,
      city: city,
      profession: profession,
      interests: interests,
    );
    await _profiles.createProfile(profile);
    await _profiles.saveInterests(user.id, interests.map((i) => i.id).toList());
    return profile;
  }
}
