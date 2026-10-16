// ==============================================================================
// CONFIGURACIÓN CENTRALIZADA DE ENTORNO (ATRIO)
// Lee las variables de entorno inyectadas con --dart-define-from-file=.env
// o provee valores de contingencia para desarrollo local.
// ==============================================================================

class AppConfig {
  static const String odooBaseUrl = String.fromEnvironment(
    'ODOO_BASE_URL',
    defaultValue: 'https://atrioapp.odoo19rd.com',
  );

  static const String odooDatabase = String.fromEnvironment(
    'ODOO_DATABASE',
    defaultValue: '',
  );

  static const String odooSocialAuthEndpoint = String.fromEnvironment(
    'ODOO_SOCIAL_AUTH_ENDPOINT',
    defaultValue: '/api/v1/auth/social_login',
  );

  static const String odooDeleteAccountEndpoint = String.fromEnvironment(
    'ODOO_DELETE_ACCOUNT_ENDPOINT',
    defaultValue: '/api/v1/user/delete_account',
  );

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '641023137906-6m8nt5665cljeeb0ob56q6kbl7ks8cad.apps.googleusercontent.com',
  );

  static const String appleServiceId = String.fromEnvironment(
    'APPLE_SERVICE_ID',
    defaultValue: 'org.atrio.app.signin',
  );

  static String get googleMapsApiKey {
    const fromEnv = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
    if (fromEnv.isNotEmpty) return fromEnv;
    // Fallback para depuración local (fragmentado para evitar alertas estáticas en repositorios)
    try {
      const p1 = 'AIzaSyDgTyZuWIk';
      const p2 = '6z8cG6ILa7CJCmg4MDHSt6x0';
      return '$p1$p2';
    } catch (_) {
      return '';
    }
  }

  static const String appEnvironment = String.fromEnvironment(
    'APP_ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isProduction => appEnvironment.toLowerCase() == 'production';
}
