import 'package:memorylens/features/auth/domain/entities/profile.dart';
import 'package:memorylens/features/auth/domain/repository/auth_repository.dart';
import 'package:memorylens/features/auth/domain/repository/profile_repository.dart';
import 'package:memorylens/injection_container.dart';

class SignInUsecase {
  final AuthRepository _auth = sl();
  final ProfileRepository _profile = sl();
  //ProfileRepository _profile;

  Future<Profile> call({
    required String email,
    required String password,
  }) async {
    final user = await _auth.signIn(email: email, password: password);
    return _profile.getProfile(user.id);
  }
}
