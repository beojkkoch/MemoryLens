abstract class ConnectivityRepository {
  /// True while the device has a network; emits the current value first and
  /// then every change.
  Stream<bool> watch();
}
