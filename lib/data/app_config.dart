// ==============================================================================
// CONFIGURACIÓN CENTRALIZADA DE ENTORNO (ATRIO)
// Lee las variables de entorno inyectadas con --dart-define-from-file=.env
// o provee valores de contingencia para desarrollo local.
// ==============================================================================

class AppConfig {
  static const String odooBaseUrl = String.fromEnvironment(
    'ODOO_BASE_URL',
    defaultValue: 'https://staging-erp.atrio.org',
  );

  static const String odooDatabase = String.fromEnvironment(
    'ODOO_DATABASE',
    defaultValue: 'atrio_staging',
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

  static const String appEnvironment = String.fromEnvironment(
    'APP_ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isProduction => appEnvironment.toLowerCase() == 'production';
}
