/// Whether the device has a network. It starts online so the banner does not
/// flash while the first check runs.
class ConnectivityState {
  final bool online;

  const ConnectivityState({this.online = true});

  @override
  bool operator ==(Object other) {
    return other is ConnectivityState && other.online == online;
  }

  @override
  int get hashCode => online.hashCode;

  @override
  String toString() {
    return 'ConnectivityState(online: $online)';
  }
}
