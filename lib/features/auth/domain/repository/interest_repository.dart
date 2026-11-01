import 'package:memorylens/features/auth/domain/entities/interest.dart';

/// Contract for reading the catalog of interests.
abstract class InterestRepository {
  Future<List<Interest>> getInterests();
}
