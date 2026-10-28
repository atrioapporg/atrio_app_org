import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:atrio/data/app_config.dart';

/// Servicio centralizado de autenticación y gestión de sesiones OAuth (Google Sign-In).
/// Garantiza la desconexión estricta de credenciales nativas y la prevención de auto-relogueo por caché.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// Instancia oficial y unificada de GoogleSignIn para toda la aplicación.
  static final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: AppConfig.googleServerClientId.isNotEmpty
        ? AppConfig.googleServerClientId
        : '641023137906-6m8nt5665cljeeb0ob56q6kbl7ks8cad.apps.googleusercontent.com',
  );

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
        await googleSignIn.disconnect();
        debugPrint('✅ [AuthService] GoogleSignIn.disconnect() completado exitosamente.');
      } catch (e) {
        // disconnect() puede fallar o lanzar PlatformException si el usuario no estaba
        // autenticado previamente con Google (ej: login por credenciales estándar o Apple).
        debugPrint('⚠️ [AuthService] Advertencia en GoogleSignIn.disconnect() (no activo o ya desconectado): $e');
      }

      // 2. Limpiar sesión en el plugin de Google Sign-In
      try {
        await googleSignIn.signOut();
        debugPrint('✅ [AuthService] GoogleSignIn.signOut() completado exitosamente.');
      } catch (e) {
        debugPrint('⚠️ [AuthService] Advertencia en GoogleSignIn.signOut(): $e');
      }
    } catch (e) {
      debugPrint('💥 [AuthService] Error general en revokeGoogleSession(): $e');
    }
  }
}
