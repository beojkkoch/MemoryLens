import 'package:memorylens/features/auth/domain/entities/profile.dart';

/// Contract for reading the profile of an account and its chosen interests.
abstract class ProfileRepository {
  Future<Profile> getProfile(String userId);
}
