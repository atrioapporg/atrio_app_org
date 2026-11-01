import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
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
  Timer? _periodicTimer;

  /// Llama esto una vez, por ejemplo en el main()
  void startMonitoring({Duration checkInterval = const Duration(seconds: 15)}) {
    try {
      _subscription?.cancel();
      _periodicTimer?.cancel();
      _subscription = _connectivity.onConnectivityChanged.listen((_) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 800), () async {
          final result = await hasRealInternet();
          if (result != _lastKnownStatus) {
            _lastKnownStatus = result;
            if (!_statusController.isClosed) {
              _statusController.add(result);
            }
          }
        });
      });

      _periodicTimer = Timer.periodic(checkInterval, (_) async {
        final result = await hasRealInternet();
        if (result != _lastKnownStatus) {
          _lastKnownStatus = result;
          if (!_statusController.isClosed) {
            _statusController.add(result);
          }
        }
      });
    } catch (e) {
      debugPrint('ℹ️ [ConnectivityService] Monitoreo pasivo de red: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
    _debounce?.cancel();
    _periodicTimer?.cancel();
  }

  Future<bool> hasRealInternet() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none) &&
          connectivityResult.length == 1) {
        return false;
      }
      return await _checkActualInternetAccess();
    } catch (e) {
      return true;
    }
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
