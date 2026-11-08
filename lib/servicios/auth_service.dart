import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:atrio/data/app_config.dart';

/// Resultado unificado del inicio de sesión con Google Sign-In.
/// Soporta tanto el flujo estándar con `idToken` (OAuth Web Client ID) como
/// el modo de contingencia (`usedFallbackMode`) cuando el certificado del APK
/// (ej. Play App Signing en Google Play Console) aún no tiene su SHA-1 propagado.
class GoogleSignInResult {
  final GoogleSignInAccount account;
  final String? idToken;
  final String? accessToken;
  final String? serverAuthCode;
  final bool usedFallbackMode;

  const GoogleSignInResult({
    required this.account,
    this.idToken,
    this.accessToken,
    this.serverAuthCode,
    this.usedFallbackMode = false,
  });
}

/// Servicio centralizado de autenticación y gestión de sesiones OAuth (Google Sign-In).
/// Garantiza la desconexión estricta de credenciales nativas, la prevención de auto-relogueo
/// por caché y la resiliencia ante errores de firma/certificado (ApiException 10).
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static String get _effectiveServerClientId =>
      AppConfig.googleServerClientId.isNotEmpty
          ? AppConfig.googleServerClientId
          : '641023137906-6m8nt5665cljeeb0ob56q6kbl7ks8cad.apps.googleusercontent.com';

  static GoogleSignIn _activeGoogleSignIn = _createPrimaryClient();

  static GoogleSignIn _createPrimaryClient() {
    // En iOS, el serverClientId de un proyecto web ajeno causa fallos en AppAuth (org.openid.appauth.oauth_token).
    // Para iOS se utiliza la configuración nativa declarada en Info.plist (GIDClientID).
    final bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    return GoogleSignIn(
      scopes: const <String>['email', 'profile'],
      serverClientId: isIOS ? null : _effectiveServerClientId,
    );
  }

  static GoogleSignIn _createFallbackClient() {
    // Instancia básica DEFAULT_SIGN_IN sin serverClientId ni scopes adicionales
    // para evitar rechazos por huella SHA-1 en Android o desajustes de AppAuth en iOS.
    return GoogleSignIn(
      scopes: const <String>['email', 'profile'],
    );
  }

  /// Instancia oficial y unificada de GoogleSignIn para toda la aplicación.
  static GoogleSignIn get googleSignIn => _activeGoogleSignIn;

  /// Detecta si una excepción corresponde a error de configuración del desarrollador:
  /// - En Android: `ApiException: 10` (`DEVELOPER_ERROR`) por desajuste de SHA-1 o `serverClientId`.
  /// - En iOS: Errores de AppAuth (`org.openid.appauth.oauth_token`, `oauth_token`, etc.).
  static bool isDeveloperConfigError(Object error) {
    if (error is PlatformException) {
      final String msg = error.message ?? '';
      final String full = error.toString();
      final bool isAndroidDevError = msg.contains('ApiException: 10') ||
          msg.contains(' 10:') ||
          msg.contains(': 10') ||
          msg.contains('DEVELOPER_ERROR') ||
          (error.code == 'sign_in_failed' &&
              (msg.contains('10') || full.contains('ApiException: 10')));
      final bool isIOSAuthError = msg.contains('org.openid.appauth') ||
          msg.contains('oauth_token') ||
          msg.contains('authorization_error') ||
          full.contains('org.openid.appauth');
      return isAndroidDevError || isIOSAuthError;
    }
    final String str = error.toString();
    return str.contains('ApiException: 10') ||
        str.contains('DEVELOPER_ERROR') ||
        str.contains('org.openid.appauth') ||
        str.contains('oauth_token');
  }

  /// Inicia el flujo interactivo de Google Sign-In con recuperación automática
  /// ante `ApiException: 10` (`DEVELOPER_ERROR`).
  ///
  /// 1. Intenta primero con el `serverClientId` oficial para obtener el `idToken` de Odoo.
  /// 2. Si Google Play Services devuelve `ApiException: 10` (por ejemplo, en el App Bundle
  ///    re-firmado por Google Play Console / Play App Signing cuya huella SHA-1 aún no
  ///    se ha registrado o propagado en Google Cloud Console), reintenta automáticamente
  ///    con `DEFAULT_SIGN_IN` básico sin `serverClientId`.
  static Future<GoogleSignInResult?> signInWithGoogle() async {
    _activeGoogleSignIn = _createPrimaryClient();

    try {
      final GoogleSignInAccount? account = await _activeGoogleSignIn.signIn();
      if (account == null) {
        return null;
      }

      String? idToken;
      String? accessToken;
      try {
        final GoogleSignInAuthentication auth = await account.authentication;
        idToken = auth.idToken;
        accessToken = auth.accessToken;
      } catch (authError) {
        debugPrint(
          '⚠️ [AuthService] Advertencia obteniendo tokens en flujo primario de Google Sign-In: $authError',
        );
      }

      return GoogleSignInResult(
        account: account,
        idToken: idToken,
        accessToken: accessToken,
        serverAuthCode: account.serverAuthCode,
        usedFallbackMode: false,
      );
    } on PlatformException catch (pe) {
      if (!isDeveloperConfigError(pe)) {
        rethrow;
      }

      debugPrint(
        '⚠️ [AuthService] ApiException 10 (DEVELOPER_ERROR) detectado con serverClientId. '
        'Activando modo de contingencia (DEFAULT_SIGN_IN sin serverClientId)...',
      );

      try {
        await _activeGoogleSignIn.signOut();
      } catch (_) {}

      // Reintentar con cliente básico sin serverClientId (fuerza nueva inicialización nativa)
      _activeGoogleSignIn = _createFallbackClient();
      final GoogleSignInAccount? fallbackAccount =
          await _activeGoogleSignIn.signIn();
      if (fallbackAccount == null) {
        return null;
      }

      return GoogleSignInResult(
        account: fallbackAccount,
        idToken: null,
        accessToken: null,
        serverAuthCode: fallbackAccount.serverAuthCode,
        usedFallbackMode: true,
      );
    }
  }

  /// Revoca de manera estricta y profunda la sesión de Google Sign-In.
  ///
  /// 1. `disconnect()`: Revoca el grant OAuth y desvincula la cuenta de los servicios
  ///    de Google y del SDK nativo (Google Play Services / Keychain). Esto fuerza al selector
  ///    de cuentas a aparecer en el próximo intento de login, previniendo la reutilización
  ///    silenciosa de la cuenta anterior.
  /// 2. `signOut()`: Limpia el usuario activo en memoria y la caché local del plugin.
  static Future<void> revokeGoogleSession() async {
    debugPrint('🔒 [AuthService] Iniciando revocación estricta de Google Sign-In...');
    try {
      // 1. Intentar desconexión / revocación del grant OAuth en Google
      try {
        await _activeGoogleSignIn.disconnect();
        debugPrint('✅ [AuthService] GoogleSignIn.disconnect() completado exitosamente.');
      } catch (e) {
        // disconnect() puede fallar o lanzar PlatformException si el usuario no estaba
        // autenticado previamente con Google (ej: login por credenciales estándar o Apple).
        debugPrint('⚠️ [AuthService] Advertencia en GoogleSignIn.disconnect() (no activo o ya desconectado): $e');
      }

      // 2. Limpiar sesión en el plugin de Google Sign-In
      try {
        await _activeGoogleSignIn.signOut();
        debugPrint('✅ [AuthService] GoogleSignIn.signOut() completado exitosamente.');
      } catch (e) {
        debugPrint('⚠️ [AuthService] Advertencia en GoogleSignIn.signOut(): $e');
      }
    } catch (e) {
      debugPrint('💥 [AuthService] Error general en revokeGoogleSession(): $e');
    }
  }
}
