import 'package:memorylens/features/auth/domain/entities/interest.dart';

/// Something the register screen asks the RegisterBloc to do.
abstract class RegisterEvent {}

/// The screen opened and needs the catalog of interests.
class RegisterInterestsRequested extends RegisterEvent {
  @override
  String toString() {
    return 'RegisterInterestsRequested()';
  }
}

/// The user submitted the sign up form.
class RegisterSubmitted extends RegisterEvent {
  final String fullName;
  final String email;
  final String password;
  final String city;
  final String profession;
  final List<Interest> interests;
  final List<String> newInterestNames;

  RegisterSubmitted({
    required this.fullName,
    required this.email,
    required this.password,
    required this.city,
    required this.profession,
    required this.interests,
    this.newInterestNames = const [],
  });

  @override
  String toString() {
    return 'RegisterSubmitted(email: $email, interests: ${interests.length}, '
        'new: ${newInterestNames.length})';
  }
}
