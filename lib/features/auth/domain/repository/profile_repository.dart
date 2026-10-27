import 'package:memorylens/features/auth/domain/entities/profile.dart';

/// Contract for saving the profile of an account and its chosen interests.
abstract class ProfileRepository {
  Future<void> createProfile(Profile profile);
  Future<void> saveInterests(String userId, List<int> interestIds);
}
