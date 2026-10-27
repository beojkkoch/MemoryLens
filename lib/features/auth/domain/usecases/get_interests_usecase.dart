import 'package:memorylens/features/auth/domain/entities/interest.dart';
import 'package:memorylens/features/auth/domain/repository/interest_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Brings the interests the user can pick during sign up.
class GetInterestsUseCase {
  final InterestRepository _interests = sl();

  Future<List<Interest>> call() {
    return _interests.getInterests();
  }
}
