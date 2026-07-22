import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstraction over connectivity_plus so repositories can check for a
/// live connection before hitting Firebase, and fail fast with a clear
/// NetworkFailure instead of a confusing Firebase timeout.
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;
  const NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    final List<ConnectivityResult> result = await connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}
