import 'package:memorylens/features/auth/domain/entities/interest.dart';

/// Contract for reading the catalog of interests and adding new ones to it.
abstract class InterestRepository {
  Future<List<Interest>> getInterests();
  Future<List<Interest>> createInterests(List<String> names);
}
