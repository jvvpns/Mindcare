import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  final _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();

  Stream<bool> get onConnectivityChanged => _controller.stream;

  bool _isOnline = false;
  bool get isOnline => _isOnline;

  Future<void> init() async {
    // Check initial status
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);

    // Listen for changes
    _connectivity.onConnectivityChanged.listen((result) {
      final status = _isConnected(result);
      if (status != _isOnline) {
        _isOnline = status;
        _controller.add(_isOnline);
      }
    });
  }

  bool _isConnected(List<ConnectivityResult> result) {
    return result.any((r) =>
    r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
  }

  Future<bool> checkNow() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);
    return _isOnline;
  }

  void dispose() {
    _controller.close();
  }
}