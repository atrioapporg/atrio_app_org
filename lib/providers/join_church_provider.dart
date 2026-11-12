import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:atrio/atrio_api.dart';
import 'package:atrio/modelos/join_church_models.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/servicios/join_church_service.dart';
import 'package:atrio/servicios/token_storage_service.dart';
import 'package:atrio/utils/qr_token_parser.dart';

/// Estados discretos del ciclo de vida de vinculación por QR.
enum JoinChurchStep {
  idle,
  resolvingToken,
  previewReady,
  submitting,
  success,
  alreadyMember,
  requiresLogin,
  error,
}

/// Provider central que gestiona la lógica de negocio para la vinculación
/// de un feligrés a una iglesia mediante QR o Deep Link.
class JoinChurchProvider extends ChangeNotifier {
  final JoinChurchService _service;
  final TokenStorageService _tokenStorage;
  final FlutterSecureStorage _secureStorage;

  static const String keyPendingJoinToken = 'pending_join_token';

  JoinChurchStep _step = JoinChurchStep.idle;
  JoinChurchPreview? _currentPreview;
  String? _lastResolvedToken;
  String? _errorMessage;
  String? _errorCode;
  bool _isScannerActive = true;

  JoinChurchProvider({
    JoinChurchService? service,
    TokenStorageService? tokenStorage,
    FlutterSecureStorage? secureStorage,
  })  : _service = service ?? JoinChurchService(),
        _tokenStorage = tokenStorage ?? TokenStorageService(),
        _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(resetOnError: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  // Getters públicos
  JoinChurchStep get step => _step;
  JoinChurchPreview? get currentPreview => _currentPreview;
  String? get lastResolvedToken => _lastResolvedToken;
  String? get errorMessage => _errorMessage;
  String? get errorCode => _errorCode;
  bool get isScannerActive => _isScannerActive;

  bool get isLoading =>
      _step == JoinChurchStep.resolvingToken || _step == JoinChurchStep.submitting;

  /// Pausa o reanuda la captura en el widget del escáner.
  void setScannerActive(bool active) {
    if (_isScannerActive != active) {
      _isScannerActive = active;
      notifyListeners();
    }
  }

  /// Punto de entrada unificado y agnóstico al canal de captura.
  /// Puede invocarse desde:
  /// 1. El callback onDetect del `MobileScanner`.
  /// 2. El stream de AppLinks / Universal Links.
  /// 3. El ciclo posterior a un login diferido.
  Future<bool> handleJoinToken({
    required String rawInput,
    required UserProvider userProvider,
  }) async {
    // Evitar ejecuciones simultáneas mientras se resuelve un proceso previo
    if (_step == JoinChurchStep.resolvingToken || _step == JoinChurchStep.submitting) {
      return false;
    }

    if (isOutdatedOrFalseQr(rawInput)) {
      _setError(
        'outdated_qr',
        'El código QR escaneado está desactualizado. Por favor, regenera o vuelve a abrir el código en la pantalla de la iglesia.',
      );
      return false;
    }

    final token = joinTokenFromUri(rawInput);
    if (token == null) {
      _setError('invalid_qr', 'El código QR no corresponde a una iglesia de ATRIO.');
      return false;
    }

    // Pausar el escáner inmediatamente tras detectar el token válido
    setScannerActive(false);

    _step = JoinChurchStep.resolvingToken;
    _errorMessage = null;
    _errorCode = null;
    _lastResolvedToken = token;
    notifyListeners();

    try {
      // 1. Obtener datos públicos de la iglesia
      final preview = await _service.getChurchPreview(token);
      _currentPreview = preview;

      if (!preview.canJoin) {
        _setError('cannot_join', 'Esta iglesia no tiene habilitada la vinculación directa.');
        return false;
      }

      // 2. Verificar el estado de autenticación del feligrés
      final isAuthenticated = userProvider.isAuthenticated;
      String? accessToken;
      try {
        accessToken = await userProvider.api.getValidAccessToken();
      } catch (_) {}
      accessToken ??= await _tokenStorage.getAccessToken();

      if (!isAuthenticated || accessToken == null || accessToken.isEmpty) {
        // Guardar token en storage seguro para el flujo diferido (Deferred Join)
        await _savePendingToken(token);
        _step = JoinChurchStep.requiresLogin;
        notifyListeners();
        return true;
      }

      // Si ya está autenticado, pasa a confirmación visual
      _step = JoinChurchStep.previewReady;
      notifyListeners();
      return true;
    } on AtrioApiException catch (e) {
      _setError(e.code, e.message);
      return false;
    } catch (e) {
      _setError('unknown_error', 'Ocurrió un error inesperado al procesar el código: $e');
      return false;
    }
  }

  /// Ejecuta la confirmación del usuario para unirse formalmente a la iglesia.
  Future<bool> confirmJoinMembership({
    required UserProvider userProvider,
  }) async {
    final preview = _currentPreview;
    if (preview == null) {
      _setError('no_preview', 'No hay ninguna iglesia seleccionada para vincular.');
      return false;
    }

    String? accessToken;
    try {
      accessToken = await userProvider.api.getValidAccessToken();
    } catch (_) {}
    accessToken ??= await _tokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      _step = JoinChurchStep.requiresLogin;
      notifyListeners();
      return false;
    }

    _step = JoinChurchStep.submitting;
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();

    try {
      await _service.requestMembership(
        churchId: preview.church.id,
        accessToken: accessToken,
      );

      // Limpiar token diferido en caso de que existiera en storage
      await clearPendingToken();

      _step = JoinChurchStep.success;
      notifyListeners();

      // Refrescar el perfil del usuario en segundo plano para sincronizar el nuevo church_id
      await userProvider.refreshUserProfile();
      return true;
    } on AtrioApiException catch (e) {
      if (e.code == 'already_member' || e.statusCode == 400) {
        _step = JoinChurchStep.alreadyMember;
        _errorMessage = e.message;
        _errorCode = e.code;
        notifyListeners();
        return false;
      }

      _setError(e.code, e.message);
      return false;
    } catch (e) {
      _setError('submission_failed', 'No se pudo enviar la solicitud de membresía: $e');
      return false;
    }
  }

  /// Reanuda el flujo de vinculación diferida inmediatamente tras un login exitoso.
  /// Recupera el token guardado, lo elimina del almacenamiento y ejecuta [handleJoinToken].
  Future<bool> checkAndResumePendingJoin({
    required UserProvider userProvider,
  }) async {
    final pendingToken = await getPendingToken();
    if (pendingToken == null || pendingToken.isEmpty) {
      return false;
    }

    // Consumir inmediatamente el token para evitar reejecuciones no deseadas
    await clearPendingToken();

    return await handleJoinToken(
      rawInput: pendingToken,
      userProvider: userProvider,
    );
  }

  /// Guarda el token en almacenamiento cifrado seguro.
  Future<void> _savePendingToken(String token) async {
    await _secureStorage.write(key: keyPendingJoinToken, value: token);
  }

  /// Obtiene el token pendiente del almacenamiento seguro.
  Future<String?> getPendingToken() async {
    return await _secureStorage.read(key: keyPendingJoinToken);
  }

  /// Borra el token pendiente del almacenamiento seguro.
  Future<void> clearPendingToken() async {
    await _secureStorage.delete(key: keyPendingJoinToken);
  }

  /// Restablece el provider al estado inicial y reactiva el escáner.
  void reset() {
    _step = JoinChurchStep.idle;
    _currentPreview = null;
    _lastResolvedToken = null;
    _errorMessage = null;
    _errorCode = null;
    _isScannerActive = true;
    notifyListeners();
  }

  void _setError(String code, String message) {
    _errorCode = code;
    _errorMessage = message;
    _step = JoinChurchStep.error;
    notifyListeners();
  }
}
