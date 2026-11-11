import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atrio/modelos/user_model.dart';

import 'analytics_provider.dart';
import 'firebase_analytics_provider.dart';

/// Fachada única de analítica de producto de ATRIO.
///
/// Responsabilidades:
/// 1. **Desacoplar** la UI de los SDKs (reenvía a N [AnalyticsProvider]).
/// 2. **Consentimiento**: respeta la preferencia del usuario (persistida en
///    `SharedPreferences`) y la expone como [ChangeNotifier] para la UI.
/// 3. **Higiene de datos**: valida nombres de eventos/parámetros según las
///    reglas de GA4 y recorta valores para no perder eventos en silencio.
/// 4. **Privacidad**: solo se envían identificadores seudónimos y atributos
///    de segmentación. **Nunca** textos de peticiones, nombres, emails,
///    teléfonos ni importes ligados a una persona.
///
/// Uso:
/// ```dart
/// context.read<AnalyticsService>().logEvent('radio_play', {'station_id': 12});
/// ```
class AnalyticsService extends ChangeNotifier {
  AnalyticsService._internal();
  static final AnalyticsService instance = AnalyticsService._internal();

  /// Preferencia de consentimiento persistida.
  static const String _prefKeyConsent = 'analytics_consent_enabled';

  /// Valor por defecto si el usuario nunca ha tocado el ajuste.
  /// Se puede desactivar en Configuración › Privacidad.
  static const bool _defaultConsent = true;

  // Límites oficiales de GA4.
  static const int _maxEventNameLength = 40;
  static const int _maxParamNameLength = 40;
  static const int _maxParamValueLength = 100;
  static const int _maxParamsPerEvent = 25;
  static const int _maxUserPropertyNameLength = 24;
  static const int _maxUserPropertyValueLength = 36;
  static final RegExp _validName = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');
  static const List<String> _reservedPrefixes = ['firebase_', 'google_', 'ga_'];

  final List<AnalyticsProvider> _providers = [];
  bool _initialized = false;
  bool _enabled = _defaultConsent;
  String? _lastUserSignature;

  /// `true` si el usuario permite la recolección de analítica.
  bool get isEnabled => _enabled;

  /// Inicializa los proveedores y aplica el consentimiento guardado.
  /// Debe llamarse en `main()` después de `Firebase.initializeApp()`.
  Future<void> initialize({List<AnalyticsProvider>? providers}) async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefKeyConsent) ?? _defaultConsent;

    for (final provider in providers ?? [FirebaseAnalyticsProvider()]) {
      try {
        await provider.initialize();
        await provider.setCollectionEnabled(_enabled);
        _providers.add(provider);
      } catch (e) {
        // Ej.: falta GoogleService-Info.plist en iOS. La app sigue funcionando.
        debugPrint(
          'ℹ️ [AnalyticsService] Proveedor "${provider.name}" no disponible: $e',
        );
      }
    }
    _initialized = true;
    debugPrint(
      '📊 [AnalyticsService] Inicializado (${_providers.map((p) => p.name).join(', ')}) · consentimiento=$_enabled',
    );
  }

  /// Cambia el consentimiento del usuario. Al revocarlo se borran el
  /// identificador y los datos locales de analítica.
  Future<void> setConsent(bool enabled) async {
    if (_enabled == enabled) return;
    _enabled = enabled;
    notifyListeners(); // Respuesta inmediata del interruptor en la UI.

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyConsent, enabled);

    await _forEachProvider((p) async {
      if (!enabled) await p.reset();
      await p.setCollectionEnabled(enabled);
    });
    // Fuerza reenviar ID y propiedades de usuario si se vuelve a activar
    // (los listeners llaman a syncUser al recibir la notificación).
    _lastUserSignature = null;
    notifyListeners();
  }

  /// Registra un evento personalizado (`objeto_accion` en snake_case).
  ///
  /// Los valores `bool` se convierten a `'true'`/`'false'` porque GA4 solo
  /// acepta `String` y `num`.
  Future<void> logEvent(String name, [Map<String, Object?>? parameters]) async {
    if (!_canSend) return;
    if (!_isValidName(name, _maxEventNameLength)) {
      debugPrint('⚠️ [AnalyticsService] Nombre de evento inválido: "$name"');
      return;
    }
    final params = _sanitizeParameters(parameters);
    if (kDebugMode) debugPrint('📊 [Analytics] $name ${params ?? ''}');
    await _forEachProvider((p) => p.logEvent(name, params));
  }

  /// Registra la visualización de una pantalla. GA4 calcula a partir de aquí
  /// las pantallas más vistas y el tiempo de interacción en cada una.
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    if (!_canSend || screenName.trim().isEmpty) return;
    final name = _truncate(screenName.trim(), _maxParamValueLength);
    if (kDebugMode) debugPrint('📊 [Analytics] screen_view → $name');
    await _forEachProvider(
      (p) => p.logScreenView(screenName: name, screenClass: screenClass),
    );
  }

  /// Sincroniza identidad seudónima y propiedades de segmentación con el
  /// usuario autenticado. Si [user] es `null` (logout) se limpia la identidad.
  ///
  /// Es idempotente: solo envía cambios reales, por lo que puede llamarse en
  /// cada `notifyListeners()` de `UserProvider`.
  Future<void> syncUser(UserModel? user) async {
    if (!_canSend) return;

    final String signature = user == null
        ? 'anonymous'
        : '${user.id}|${user.role.name}|${user.iglesiaId}|${user.membershipStatus}';
    if (signature == _lastUserSignature) return;
    final bool wasLoggedIn =
        _lastUserSignature != null && _lastUserSignature != 'anonymous';
    _lastUserSignature = signature;

    if (user == null || user.id <= 0) {
      if (wasLoggedIn) await _forEachProvider((p) => p.reset());
      await _setUserProperties(const {
        'user_role': 'anonymous',
        'church_id': null,
        'membership_status': null,
      });
      return;
    }

    // ID interno de Odoo: seudónimo, sin datos personales.
    await _forEachProvider((p) => p.setUserId(user.id.toString()));
    await _setUserProperties({
      'user_role': _roleToProperty(user.role),
      'church_id': user.iglesiaId?.toString(),
      'membership_status': user.membershipStatus,
    });
  }

  // ---------------------------------------------------------------------------
  // Internos
  // ---------------------------------------------------------------------------

  bool get _canSend => _initialized && _enabled && _providers.isNotEmpty;

  Future<void> _setUserProperties(Map<String, String?> properties) async {
    for (final entry in properties.entries) {
      if (!_isValidName(entry.key, _maxUserPropertyNameLength)) continue;
      final value = entry.value == null
          ? null
          : _truncate(entry.value!, _maxUserPropertyValueLength);
      await _forEachProvider((p) => p.setUserProperty(entry.key, value));
    }
  }

  String _roleToProperty(UserRole role) {
    switch (role) {
      case UserRole.platformAdmin:
        return 'platform_admin';
      case UserRole.churchAdmin:
        return 'church_admin';
      case UserRole.member:
        return 'member';
      case UserRole.user:
        return 'user';
    }
  }

  bool _isValidName(String name, int maxLength) {
    if (name.isEmpty || name.length > maxLength) return false;
    if (!_validName.hasMatch(name)) return false;
    final lower = name.toLowerCase();
    return !_reservedPrefixes.any(lower.startsWith);
  }

  Map<String, Object>? _sanitizeParameters(Map<String, Object?>? raw) {
    if (raw == null || raw.isEmpty) return null;
    final result = <String, Object>{};
    for (final entry in raw.entries) {
      if (result.length >= _maxParamsPerEvent) break;
      final value = entry.value;
      if (value == null) continue;
      if (!_isValidName(entry.key, _maxParamNameLength)) {
        debugPrint('⚠️ [AnalyticsService] Parámetro inválido: "${entry.key}"');
        continue;
      }
      if (value is num) {
        result[entry.key] = value;
      } else if (value is bool) {
        result[entry.key] = value.toString();
      } else {
        result[entry.key] = _truncate(value.toString(), _maxParamValueLength);
      }
    }
    return result.isEmpty ? null : result;
  }

  String _truncate(String value, int max) =>
      value.length <= max ? value : value.substring(0, max);

  Future<void> _forEachProvider(
    Future<void> Function(AnalyticsProvider provider) action,
  ) async {
    for (final provider in _providers) {
      try {
        await action(provider);
      } catch (e) {
        debugPrint('⚠️ [AnalyticsService] Error en "${provider.name}": $e');
      }
    }
  }
}
