import 'package:memorylens/features/auth/domain/entities/interest.dart';

/// Row of the usuario table: same id as the account, plus onboarding data.
class Profile {
  final String id;
  final String fullName;
  final String email;
  final String city;
  final String profession;
  final List<Interest> interests;

  const Profile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.city,
    required this.profession,
    this.interests = const [],
  });
}
