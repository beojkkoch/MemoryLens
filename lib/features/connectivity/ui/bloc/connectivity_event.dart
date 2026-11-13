abstract class ConnectivityEvent {}

/// The app opened: start following the connection.
class ConnectivityStarted extends ConnectivityEvent {
  @override
  String toString() {
    return 'ConnectivityStarted()';
  }
}
