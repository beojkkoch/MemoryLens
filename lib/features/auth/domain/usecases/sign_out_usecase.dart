import 'package:memorylens/features/auth/domain/repository/auth_repository.dart';
import 'package:memorylens/injection_container.dart';

class SignOutUsecase {
  final AuthRepository _auth = sl();

  Future<void> call() {
    return _auth.signOut();
  }
}
