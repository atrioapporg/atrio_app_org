import 'package:flutter/material.dart';
import '../data/atrio_database_helper.dart';
import '../modelos/ajustes_model.dart';

class AjustesProvider extends ChangeNotifier {
  AjustesModel _ajustes = AjustesModel.predeterminado();
  bool _isLoading = true;

  AjustesModel get ajustes => _ajustes;
  bool get isLoading => _isLoading;

  // Getters directos para reactividad en la UI
  String get idiomaCodigo => _ajustes.idiomaCodigo;
  String get paisRegion => _ajustes.paisRegion;
  String get temaModo => _ajustes.temaModo;

  ThemeMode get themeMode {
    switch (_ajustes.temaModo) {
      case 'oscuro':
        return ThemeMode.dark;
      case 'claro':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  Locale get locale => Locale(_ajustes.idiomaCodigo, _ajustes.paisRegion);

  bool get notifVersiculoDia => _ajustes.notifVersiculoDia;
  bool get notifPalabraDia => _ajustes.notifPalabraDia;
  bool get notifCultosEnVivo => _ajustes.notifCultosEnVivo;
  bool get notifAnunciosEventos => _ajustes.notifAnunciosEventos;
  String get horaNotifDevocional => _ajustes.horaNotifDevocional;

  String get bibliaVersionPredeterminada =>
      _ajustes.bibliaVersionPredeterminada;
  double get tamanoFuenteLectura => _ajustes.tamanoFuenteLectura;
  bool get mantenerPantallaActiva => _ajustes.mantenerPantallaActiva;

  bool get reproduccionAutomaticaRadio =>
      _ajustes.reproduccionAutomaticaRadio;
  String get calidadAudioStreaming => _ajustes.calidadAudioStreaming;
  bool get soloDescargarConWifi => _ajustes.soloDescargarConWifi;
  int get tiempoTransicionBannerSegundos =>
      _ajustes.tiempoTransicionBannerSegundos;

  AjustesProvider() {
    cargarAjustes();
  }

  /// Carga la configuración inicial desde la base de datos atrio.db
  Future<void> cargarAjustes() async {
    _isLoading = true;
    notifyListeners();
    try {
      _ajustes = await AtrioDatabaseHelper.instance.getAjustes();
      // Si el usuario tenía configurado un idioma previo ya no soportado, restablecer a 'es'
      if (_ajustes.idiomaCodigo != 'es' && _ajustes.idiomaCodigo != 'en') {
        _ajustes = _ajustes.copyWith(idiomaCodigo: 'es', paisRegion: 'DO');
        await AtrioDatabaseHelper.instance
            .actualizarAjusteCampo('idioma_codigo', 'es');
        await AtrioDatabaseHelper.instance
            .actualizarAjusteCampo('pais_region', 'DO');
      }
    } catch (e) {
      debugPrint('[AJUSTES_PROVIDER] Error cargando ajustes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cambia el idioma preferido ('es' para Castellano/Latinoamérica, 'en' para Inglés americano)
  Future<void> cambiarIdioma(String codigo, {String? region}) async {
    final codigoNormalizado = (codigo == 'en') ? 'en' : 'es';
    final nuevaRegion = region ?? (codigoNormalizado == 'es' ? 'DO' : 'US');
    _ajustes = _ajustes.copyWith(
      idiomaCodigo: codigoNormalizado,
      paisRegion: nuevaRegion,
    );
    notifyListeners();

    await AtrioDatabaseHelper.instance
        .actualizarAjusteCampo('idioma_codigo', codigoNormalizado);
    await AtrioDatabaseHelper.instance
        .actualizarAjusteCampo('pais_region', nuevaRegion);
  }

  /// Cambia el modo de tema ('claro', 'oscuro', 'sistema')
  Future<void> cambiarTema(String modo) async {
    _ajustes = _ajustes.copyWith(temaModo: modo);
    notifyListeners();

    await AtrioDatabaseHelper.instance
        .actualizarAjusteCampo('tema_modo', modo);
  }

  /// Conmuta individualmente los tipos de notificaciones
  Future<void> toggleNotificacion(String tipo, bool activo) async {
    switch (tipo) {
      case 'versiculo':
        _ajustes = _ajustes.copyWith(notifVersiculoDia: activo);
        await AtrioDatabaseHelper.instance
            .actualizarAjusteCampo('notif_versiculo_dia', activo);
        break;
      case 'palabra':
        _ajustes = _ajustes.copyWith(notifPalabraDia: activo);
        await AtrioDatabaseHelper.instance
            .actualizarAjusteCampo('notif_palabra_dia', activo);
        break;
      case 'cultos':
        _ajustes = _ajustes.copyWith(notifCultosEnVivo: activo);
        await AtrioDatabaseHelper.instance
            .actualizarAjusteCampo('notif_cultos_en_vivo', activo);
        break;
      case 'anuncios':
        _ajustes = _ajustes.copyWith(notifAnunciosEventos: activo);
        await AtrioDatabaseHelper.instance
            .actualizarAjusteCampo('notif_anuncios_eventos', activo);
        break;
    }
    notifyListeners();
  }

  /// Cambia la hora del recordatorio devocional matutino
  Future<void> cambiarHoraDevocional(String hora) async {
    _ajustes = _ajustes.copyWith(horaNotifDevocional: hora);
    notifyListeners();

    await AtrioDatabaseHelper.instance
        .actualizarAjusteCampo('hora_notif_devocional', hora);
  }

  /// Cambia la versión de la Biblia por defecto (RVR1960, NVI, DHH)
  Future<void> cambiarVersionBiblia(String version) async {
    _ajustes = _ajustes.copyWith(bibliaVersionPredeterminada: version);
    notifyListeners();

    await AtrioDatabaseHelper.instance
        .actualizarAjusteCampo('biblia_version_predeterminada', version);
  }

  /// Ajusta el tamaño de la fuente de lectura (escala 0.8 a 1.4)
  Future<void> cambiarTamanoFuente(double factor) async {
    _ajustes = _ajustes.copyWith(tamanoFuenteLectura: factor);
    notifyListeners();

    await AtrioDatabaseHelper.instance
        .actualizarAjusteCampo('tamano_fuente_lectura', factor);
  }

  /// Mantener pantalla activa mientras se lee
  Future<void> toggleMantenerPantalla(bool activo) async {
    _ajustes = _ajustes.copyWith(mantenerPantallaActiva: activo);
    notifyListeners();

    await AtrioDatabaseHelper.instance
        .actualizarAjusteCampo('mantener_pantalla_activa', activo);
  }

  /// Reproducción automática al abrir emisoras
  Future<void> toggleAutoplayRadio(bool activo) async {
    _ajustes = _ajustes.copyWith(reproduccionAutomaticaRadio: activo);
    notifyListeners();

    await AtrioDatabaseHelper.instance
        .actualizarAjusteCampo('reproduccion_automatica_radio', activo);
  }

  /// Calidad de audio streaming ('baja', 'media', 'alta')
  Future<void> cambiarCalidadAudio(String calidad) async {
    _ajustes = _ajustes.copyWith(calidadAudioStreaming: calidad);
    notifyListeners();

    await AtrioDatabaseHelper.instance
        .actualizarAjusteCampo('calidad_audio_streaming', calidad);
  }

  /// Forzar descargas o streaming solo por Wi-Fi
  Future<void> toggleSoloWifi(bool activo) async {
    _ajustes = _ajustes.copyWith(soloDescargarConWifi: activo);
    notifyListeners();

    await AtrioDatabaseHelper.instance
        .actualizarAjusteCampo('solo_descargar_con_wifi', activo);
  }

  /// Ajusta el tiempo de transición (desvanecimiento) del banner principal (3 a 10 segundos)
  Future<void> cambiarTiempoTransicionBanner(int segundos) async {
    final segValidos = segundos.clamp(3, 10);
    _ajustes = _ajustes.copyWith(tiempoTransicionBannerSegundos: segValidos);
    notifyListeners();

    await AtrioDatabaseHelper.instance
        .actualizarAjusteCampo('tiempo_transicion_banner', segValidos);
  }

  /// Restaura todas las configuraciones a sus valores predeterminados de fábrica
  Future<void> restaurarValoresPredeterminados() async {
    _ajustes = AjustesModel.predeterminado();
    notifyListeners();
    await AtrioDatabaseHelper.instance.guardarAjustes(_ajustes);
  }
}
