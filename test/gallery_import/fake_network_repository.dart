import 'dart:async';

import 'package:memorylens/features/connectivity/domain/repository/connectivity_repository.dart';

/// Lets the test turn the connection off and on. Like the real data source it
/// says the current state first, then every change.
class FakeNetworkRepository implements ConnectivityRepository {
  bool online = true;

  final _changes = StreamController<bool>.broadcast();

  @override
  Stream<bool> watch() async* {
    yield online;
    yield* _changes.stream;
  }

  void setOnline(bool value) {
    online = value;
    _changes.add(value);
  }
}
