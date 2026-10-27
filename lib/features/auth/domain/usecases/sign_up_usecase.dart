import 'package:memorylens/features/auth/domain/entities/interest.dart';
import 'package:memorylens/features/auth/domain/entities/profile.dart';
import 'package:memorylens/features/auth/domain/repository/auth_repository.dart';
import 'package:memorylens/features/auth/domain/repository/interest_repository.dart';
import 'package:memorylens/features/auth/domain/repository/profile_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Creates the account, saves its profile with the same id and its interests,
/// adding to the catalog the interests the user typed that did not exist yet.
class SignUpUseCase {
  final AuthRepository _auth = sl();
  final ProfileRepository _profiles = sl();
  final InterestRepository _interests = sl();

  Future<Profile> call({
    required String fullName,
    required String email,
    required String password,
    required String city,
    required String profession,
    required List<Interest> interests,
    List<String> newInterestNames = const [],
  }) async {
    final user = await _auth.signUp(email: email, password: password);
    final created = newInterestNames.isEmpty
        ? <Interest>[]
        : await _interests.createInterests(newInterestNames);
    final allInterests = [...interests, ...created];
    final profile = Profile(
      id: user.id,
      fullName: fullName,
      email: user.email,
      city: city,
      profession: profession,
      interests: allInterests,
    );
    await _profiles.createProfile(profile);
    await _profiles.saveInterests(
      user.id,
      allInterests.map((i) => i.id).toSet().toList(),
    );
    return profile;
  }
}
