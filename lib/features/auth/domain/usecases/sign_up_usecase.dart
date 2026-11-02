import 'package:memorylens/features/auth/domain/entities/interest.dart';
import 'package:memorylens/features/auth/domain/repository/auth_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Creates the account with the form data. The backend saves the profile and
/// its interests once the user confirms the email.
class SignUpUseCase {
  final AuthRepository _auth = sl();

  Future<void> call({
    required String fullName,
    required String email,
    required String password,
    required String city,
    required String profession,
    required List<Interest> interests,
    List<String> newInterestNames = const [],
  }) async {
    await _auth.signUp(
      email: email,
      password: password,
      fullName: fullName,
      city: city,
      profession: profession,
      interestIds: interests.map((i) => i.id).toSet().toList(),
      newInterestNames: newInterestNames,
    );
  }
}
