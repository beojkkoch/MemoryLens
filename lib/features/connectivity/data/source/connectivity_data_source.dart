import 'package:connectivity_plus/connectivity_plus.dart';

/// The only file that uses connectivity_plus.
///
/// It only knows if a network interface is up, not if the internet works
/// behind it; that case shows up as a network error on the screen itself.
class ConnectivityDataSource {
  final Connectivity _connectivity = Connectivity();

  Stream<bool> watch() async* {
    yield isOnline(await _connectivity.checkConnectivity());
    yield* _connectivity.onConnectivityChanged.map(isOnline);
  }

  static bool isOnline(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}
