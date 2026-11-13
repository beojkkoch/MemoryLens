import 'package:memorylens/features/connectivity/domain/repository/connectivity_repository.dart';
import 'package:memorylens/injection_container.dart';

/// Follows whether the device has a network connection.
class WatchConnectivityUseCase {
  final ConnectivityRepository _connectivity = sl();

  Stream<bool> call() {
    return _connectivity.watch();
  }
}
