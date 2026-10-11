class AjustesModel {
  final int? id;
  // 1. Idioma y Región
  final String idiomaCodigo; // 'es', 'en', 'pt', 'fr'
  final String paisRegion; // 'DO', 'US', 'CO', etc.

  // 2. Apariencia y Tema
  final String temaModo; // 'claro', 'oscuro', 'sistema'

  // 3. Notificaciones y Recordatorios
  final bool notifVersiculoDia;
  final bool notifPalabraDia;
  final bool notifCultosEnVivo;
  final bool notifAnunciosEventos;
  final String horaNotifDevocional; // Ej: '07:00'

  // 4. Lectura Bíblica
  final String bibliaVersionPredeterminada; // 'RVR1960', 'NVI', 'DHH'
  final double tamanoFuenteLectura; // 0.8 a 1.4 (escala)
  final bool mantenerPantallaActiva;

  // 5. Streaming y Reproducción de Audio
  final bool reproduccionAutomaticaRadio;
  final String calidadAudioStreaming; // 'baja', 'media', 'alta'
  final bool soloDescargarConWifi;

  // 6. Ventana emergente inicial (Versículo del día)
  final int tiempoCierreModalVersiculoSegundos; // 3 a 10 seg (por defecto 4)

  // 7. Transición del Banner Principal (HeroBannerCard)
  final int tiempoTransicionBannerSegundos; // 3 a 10 seg (por defecto 5)

  // 8. Auditoría
  final String? actualizadoEn;

  const AjustesModel({
    this.id = 1,
    this.idiomaCodigo = 'es',
    this.paisRegion = 'DO',
    this.temaModo = 'sistema',
    this.notifVersiculoDia = true,
    this.notifPalabraDia = true,
    this.notifCultosEnVivo = true,
    this.notifAnunciosEventos = true,
    this.horaNotifDevocional = '07:00',
    this.bibliaVersionPredeterminada = 'RVR1960',
    this.tamanoFuenteLectura = 1.0,
    this.mantenerPantallaActiva = true,
    this.reproduccionAutomaticaRadio = false,
    this.calidadAudioStreaming = 'alta',
    this.soloDescargarConWifi = true,
    this.tiempoCierreModalVersiculoSegundos = 4,
    this.tiempoTransicionBannerSegundos = 5,
    this.actualizadoEn,
  });

  /// Valores iniciales recomendados por defecto
  factory AjustesModel.predeterminado() => const AjustesModel();

  /// Deserializa desde Map/SQLite
  factory AjustesModel.fromMap(Map<String, dynamic> map) {
    return AjustesModel(
      id: map['id'] as int? ?? 1,
      idiomaCodigo: map['idioma_codigo'] as String? ?? 'es',
      paisRegion: map['pais_region'] as String? ?? 'DO',
      temaModo: map['tema_modo'] as String? ?? 'sistema',
      notifVersiculoDia: (map['notif_versiculo_dia'] as int? ?? 1) == 1,
      notifPalabraDia: (map['notif_palabra_dia'] as int? ?? 1) == 1,
      notifCultosEnVivo: (map['notif_cultos_en_vivo'] as int? ?? 1) == 1,
      notifAnunciosEventos: (map['notif_anuncios_eventos'] as int? ?? 1) == 1,
      horaNotifDevocional:
          map['hora_notif_devocional'] as String? ?? '07:00',
      bibliaVersionPredeterminada:
          map['biblia_version_predeterminada'] as String? ?? 'RVR1960',
      tamanoFuenteLectura:
          (map['tamano_fuente_lectura'] as num? ?? 1.0).toDouble(),
      mantenerPantallaActiva:
          (map['mantener_pantalla_activa'] as int? ?? 1) == 1,
      reproduccionAutomaticaRadio:
          (map['reproduccion_automatica_radio'] as int? ?? 0) == 1,
      calidadAudioStreaming:
          map['calidad_audio_streaming'] as String? ?? 'alta',
      soloDescargarConWifi:
          (map['solo_descargar_con_wifi'] as int? ?? 1) == 1,
      tiempoCierreModalVersiculoSegundos:
          map['tiempo_cierre_modal_versiculo'] as int? ?? 4,
      tiempoTransicionBannerSegundos:
          map['tiempo_transicion_banner'] as int? ?? 5,
      actualizadoEn: map['actualizado_en'] as String?,
    );
  }

  /// Serializa para inserción o actualización en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id ?? 1,
      'idioma_codigo': idiomaCodigo,
      'pais_region': paisRegion,
      'tema_modo': temaModo,
      'notif_versiculo_dia': notifVersiculoDia ? 1 : 0,
      'notif_palabra_dia': notifPalabraDia ? 1 : 0,
      'notif_cultos_en_vivo': notifCultosEnVivo ? 1 : 0,
      'notif_anuncios_eventos': notifAnunciosEventos ? 1 : 0,
      'hora_notif_devocional': horaNotifDevocional,
      'biblia_version_predeterminada': bibliaVersionPredeterminada,
      'tamano_fuente_lectura': tamanoFuenteLectura,
      'mantener_pantalla_activa': mantenerPantallaActiva ? 1 : 0,
      'reproduccion_automatica_radio': reproduccionAutomaticaRadio ? 1 : 0,
      'calidad_audio_streaming': calidadAudioStreaming,
      'solo_descargar_con_wifi': soloDescargarConWifi ? 1 : 0,
      'tiempo_cierre_modal_versiculo': tiempoCierreModalVersiculoSegundos,
      'tiempo_transicion_banner': tiempoTransicionBannerSegundos,
      'actualizado_en': actualizadoEn ?? DateTime.now().toIso8601String(),
    };
  }

  /// Método para clonar con modificaciones inmutables
  AjustesModel copyWith({
    int? id,
    String? idiomaCodigo,
    String? paisRegion,
    String? temaModo,
    bool? notifVersiculoDia,
    bool? notifPalabraDia,
    bool? notifCultosEnVivo,
    bool? notifAnunciosEventos,
    String? horaNotifDevocional,
    String? bibliaVersionPredeterminada,
    double? tamanoFuenteLectura,
    bool? mantenerPantallaActiva,
    bool? reproduccionAutomaticaRadio,
    String? calidadAudioStreaming,
    bool? soloDescargarConWifi,
    int? tiempoCierreModalVersiculoSegundos,
    int? tiempoTransicionBannerSegundos,
    String? actualizadoEn,
  }) {
    return AjustesModel(
      id: id ?? this.id,
      idiomaCodigo: idiomaCodigo ?? this.idiomaCodigo,
      paisRegion: paisRegion ?? this.paisRegion,
      temaModo: temaModo ?? this.temaModo,
      notifVersiculoDia: notifVersiculoDia ?? this.notifVersiculoDia,
      notifPalabraDia: notifPalabraDia ?? this.notifPalabraDia,
      notifCultosEnVivo: notifCultosEnVivo ?? this.notifCultosEnVivo,
      notifAnunciosEventos:
          notifAnunciosEventos ?? this.notifAnunciosEventos,
      horaNotifDevocional:
          horaNotifDevocional ?? this.horaNotifDevocional,
      bibliaVersionPredeterminada:
          bibliaVersionPredeterminada ?? this.bibliaVersionPredeterminada,
      tamanoFuenteLectura:
          tamanoFuenteLectura ?? this.tamanoFuenteLectura,
      mantenerPantallaActiva:
          mantenerPantallaActiva ?? this.mantenerPantallaActiva,
      reproduccionAutomaticaRadio:
          reproduccionAutomaticaRadio ?? this.reproduccionAutomaticaRadio,
      calidadAudioStreaming:
          calidadAudioStreaming ?? this.calidadAudioStreaming,
      soloDescargarConWifi:
          soloDescargarConWifi ?? this.soloDescargarConWifi,
      tiempoCierreModalVersiculoSegundos:
          tiempoCierreModalVersiculoSegundos ??
              this.tiempoCierreModalVersiculoSegundos,
      tiempoTransicionBannerSegundos:
          tiempoTransicionBannerSegundos ??
              this.tiempoTransicionBannerSegundos,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }
}
