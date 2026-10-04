import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Servicio singleton para verificar si el dispositivo tiene
/// INTERNET REAL (no solo una red WiFi/datos conectada sin salida a internet).
class ConnectivityService {
  ConnectivityService._internal();
  static final ConnectivityService instance = ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _statusController =
      StreamController<bool>.broadcast();

  /// Stream que emite `true`/`false` cada vez que cambia el estado real de internet.
  Stream<bool> get onStatusChange => _statusController.stream;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _lastKnownStatus = false;
  Timer? _debounce;

  /// Llama esto una vez, por ejemplo en el main()
  void startMonitoring({Duration checkInterval = const Duration(seconds: 15)}) {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 800), () async {
        final result = await hasRealInternet();
        if (result != _lastKnownStatus) {
          _lastKnownStatus = result;
          _statusController.add(result);
        }
      });
    });

    Timer.periodic(checkInterval, (_) async {
      final result = await hasRealInternet();
      if (result != _lastKnownStatus) {
        _lastKnownStatus = result;
        _statusController.add(result);
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
    _debounce?.cancel();
    _statusController.close();
  }

  Future<bool> hasRealInternet() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none) &&
        connectivityResult.length == 1) {
      return false;
    }
    return _checkActualInternetAccess();
  }

  Future<bool> _checkActualInternetAccess() async {
    final hosts = ['google.com', 'cloudflare.com', 'one.one.one.one'];
    for (final host in hosts) {
      try {
        final result = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 4));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } on SocketException {
        continue;
      } on TimeoutException {
        continue;
      } catch (_) {
        continue;
      }
    }
    return false;
  }
}
