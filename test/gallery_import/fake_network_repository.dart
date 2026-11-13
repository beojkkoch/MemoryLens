import 'dart:async';

import 'package:memorylens/features/connectivity/domain/repository/connectivity_repository.dart';

/// Lets the test turn the connection off and on. Like the real data source it
/// says the current state first, then every change.
class FakeNetworkRepository implements ConnectivityRepository {
  bool online = true;

  final _changes = StreamController<bool>.broadcast(sync: true);

  /// The subscription to the changes starts at the same moment as the
  /// listener, so no change can fall between the first value and the rest.
  @override
  Stream<bool> watch() {
    late final StreamController<bool> controller;
    StreamSubscription<bool>? changes;
    controller = StreamController<bool>(
      onListen: () {
        controller.add(online);
        changes = _changes.stream.listen(controller.add);
      },
      // Returns nothing on purpose: under FakeAsync the future of a cancel
      // never completes, and a stream waiting for it never ends.
      onCancel: () {
        changes?.cancel();
      },
    );
    return controller.stream;
  }

  void setOnline(bool value) {
    online = value;
    _changes.add(value);
  }
}
