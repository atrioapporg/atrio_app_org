/// Contrato que debe cumplir cualquier backend de analítica de producto
/// (Firebase Analytics hoy; PostHog, Mixpanel, etc. en el futuro).
///
/// La UI de ATRIO **nunca** depende de un SDK concreto: siempre habla con
/// `AnalyticsService`, que reenvía las llamadas a uno o varios
/// [AnalyticsProvider]. Así se puede añadir o sustituir una herramienta sin
/// tocar pantallas ni widgets.
abstract class AnalyticsProvider {
  /// Nombre legible del backend (solo para logs de depuración).
  String get name;

  /// Prepara el SDK. Debe ser tolerante a fallos (p. ej. si falta la
  /// configuración nativa de Firebase en una plataforma).
  Future<void> initialize();

  /// Activa o desactiva la recolección según el consentimiento del usuario.
  Future<void> setCollectionEnabled(bool enabled);

  /// Registra un evento personalizado.
  Future<void> logEvent(String name, Map<String, Object>? parameters);

  /// Registra la visualización de una pantalla.
  Future<void> logScreenView({required String screenName, String? screenClass});

  /// Asocia un identificador **seudónimo** (nunca email ni nombre).
  Future<void> setUserId(String? id);

  /// Establece una propiedad de usuario para segmentar informes.
  Future<void> setUserProperty(String name, String? value);

  /// Borra el identificador y los datos locales de analítica (p. ej. al
  /// cerrar sesión o revocar el consentimiento).
  Future<void> reset();
}

