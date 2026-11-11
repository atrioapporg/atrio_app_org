import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../data/atrio_database_helper.dart';
import '../l10n/app_localizations.dart';
import '../modelos/emisora_model.dart';
import '../providers/ajustes_provider.dart';
import '../servicios/connectivity_service.dart';
import '../servicios/radio_player_service.dart';
import '../widgets/atrio_connectivity_alert.dart';

class CambiarTabAtrioNotification extends Notification {
  final int nuevoIndice;
  const CambiarTabAtrioNotification(this.nuevoIndice);
}

/// Estado inmutable del reproductor para aislar reconstrucciones mediante [ValueNotifier].
@immutable
class _PlaybackUiState {
  final EmisoraModel? emisoraActual;
  final bool isPlaying;
  final bool isBuffering;

  const _PlaybackUiState({
    this.emisoraActual,
    this.isPlaying = false,
    this.isBuffering = false,
  });

  _PlaybackUiState copyWith({
    EmisoraModel? emisoraActual,
    bool clearEmisora = false,
    bool? isPlaying,
    bool? isBuffering,
  }) {
    return _PlaybackUiState(
      emisoraActual: clearEmisora
          ? null
          : (emisoraActual ?? this.emisoraActual),
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _PlaybackUiState &&
          runtimeType == other.runtimeType &&
          emisoraActual == other.emisoraActual &&
          isPlaying == other.isPlaying &&
          isBuffering == other.isBuffering;

  @override
  int get hashCode => Object.hash(emisoraActual, isPlaying, isBuffering);
}

/// Gestor de caché en disco y memoria para logos de emisoras con límite de concurrencia.
/// Evita descargas repetidas de red y saturación de sockets HTTP durante el scroll rápido.
class _EmisoraLogoCacheManager {
  _EmisoraLogoCacheManager._();
  static final _EmisoraLogoCacheManager instance = _EmisoraLogoCacheManager._();

  static const int _maxConcurrentDownloads = 4;
  static Directory? _cacheDir;
  static final Map<String, String> _resolvedPaths = <String, String>{};
  static final Set<String> _failedUrls = <String>{};
  static final Map<String, Future<File?>> _inFlight = <String, Future<File?>>{};
  static final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();
  static int _activeDownloads = 0;

  Future<Directory> _getCacheDirectory() async {
    if (_cacheDir != null) return _cacheDir!;
    final String dbBase = await getDatabasesPath();
    final Directory dir = Directory(p.join(dbBase, 'radio_logos_cache'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    _cacheDir = dir;
    return dir;
  }

  String? getCachedFilePathSync(String url) => _resolvedPaths[url];

  Future<File?> getLogoFile(String rawUrl) async {
    final String url = rawUrl.trim();
    if (url.isEmpty || _failedUrls.contains(url)) return null;

    final String? cachedPath = _resolvedPaths[url];
    if (cachedPath != null) {
      final File f = File(cachedPath);
      if (f.existsSync()) return f;
      _resolvedPaths.remove(url);
    }

    if (_inFlight.containsKey(url)) {
      return _inFlight[url];
    }

    final Future<File?> task = _fetchOrReadDisk(url);
    _inFlight[url] = task;
    try {
      return await task;
    } finally {
      _inFlight.remove(url);
    }
  }

  /// Hash FNV-1a de 32 bits rápido y determinista compatible con todas las plataformas.
  static String fastHashBytes(List<int> bytes) {
    int hash = 0x811c9dc5;
    for (int i = 0; i < bytes.length; i++) {
      hash ^= bytes[i];
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return '${bytes.length}_${hash.toRadixString(16)}';
  }

  Future<File?> _fetchOrReadDisk(String url) async {
    try {
      final Directory dir = await _getCacheDirectory();
      final String hash = fastHashBytes(url.codeUnits);
      final File diskFile = File(p.join(dir.path, '$hash.img'));

      if (diskFile.existsSync() && diskFile.lengthSync() > 0) {
        _resolvedPaths[url] = diskFile.path;
        return diskFile;
      }

      await _acquireSlot();
      try {
        final http.Response response = await http
            .get(
              Uri.parse(url),
              headers: const <String, String>{'User-Agent': 'AtrioApp/1.0'},
            )
            .timeout(const Duration(seconds: 6));

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          await diskFile.writeAsBytes(response.bodyBytes, flush: false);
          _resolvedPaths[url] = diskFile.path;
          return diskFile;
        } else {
          _failedUrls.add(url);
        }
      } finally {
        _releaseSlot();
      }
    } catch (_) {
      _failedUrls.add(url);
    }
    return null;
  }

  Future<void> _acquireSlot() async {
    if (_activeDownloads < _maxConcurrentDownloads) {
      _activeDownloads++;
      return;
    }
    final Completer<void> completer = Completer<void>();
    _waitQueue.addLast(completer);
    await completer.future;
  }

  void _releaseSlot() {
    if (_waitQueue.isNotEmpty) {
      final Completer<void> next = _waitQueue.removeFirst();
      next.complete();
    } else if (_activeDownloads > 0) {
      _activeDownloads--;
    }
  }
}

class EmisorasScreen extends StatefulWidget {
  static const String routeName = 'emisoras_screen';
  final bool isActive;
  const EmisorasScreen({super.key, this.isActive = true});

  /// Métodos estáticos públicos de utilidad y localización
  static String obtenerNombreDenominacion(
    String codigo,
    AppLocalizations l10n,
  ) => _EmisorasScreenState.obtenerNombreDenominacion(codigo, l10n);

  static IconData obtenerIconoDenominacion(String codigo) =>
      _EmisorasScreenState.obtenerIconoDenominacion(codigo);

  static String obtenerNombrePais(String codigo, AppLocalizations l10n) =>
      _EmisorasScreenState.obtenerNombrePais(codigo, l10n);

  @override
  State<EmisorasScreen> createState() => _EmisorasScreenState();
}

class _EmisorasScreenState extends State<EmisorasScreen> {
  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFE5E5E5);
  static const Color rojoError = Color(0xFFC0392B);

  static const List<Color> _paletaIconos = <Color>[
    Color(0xFFE53935),
    Color(0xFF4CAF50),
    Color(0xFF29B6F6),
    Color(0xFFFF9800),
    Color(0xFFAB47BC),
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFFEC407A),
  ];

  // Endpoint directo de Google Sheets sin redirección 307
  static const String _sheetUrl =
      'https://docs.google.com/spreadsheets/d/1t0UqJ50KhUiNRh0bCvfyi6Z7nF83eJYdji98nUw6SuU/gviz/tq?tqx=out:csv&sheet=emisoras';

  // Configuración de paginación perezosa (Lazy Loading en bloques de 30 emisoras)
  static const int _tamanoPagina = 30;
  // TTL de caché persistente en SQLite antes de revalidar en segundo plano (12 horas)
  static const Duration _cacheTtl = Duration(hours: 12);
  static const String _prefKeyLastSyncMs = 'emisoras_last_sync_epoch_ms';
  static const String _prefKeyCsvHash = 'emisoras_csv_sha256';

  // Caché L1 en memoria RAM para cambio de pestaña en 0 ms
  static List<EmisoraModel>? _cacheEmisoras;
  static List<String>? _cachePaisesDisponibles;
  static Future<void>? _cargaEnProgreso;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<_PlaybackUiState> _playbackNotifier =
      ValueNotifier<_PlaybackUiState>(const _PlaybackUiState());

  Timer? _searchDebounce;
  AudioPlayer get _audioPlayer => RadioPlayerService.instance.player;
  final Set<String> _favoritosIds = <String>{};

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<PlaybackEvent>? _playbackEventSub;

  bool _mostrandoBuscador = false;
  String _filtroBusqueda = '';
  String _paisSeleccionado = 'TODOS';
  String _denominacionSeleccionada = 'TODOS';
  String _idiomaSeleccionado = 'TODOS';
  List<String> _paisesDisponibles = <String>['TODOS'];
  List<String> _denominacionesDisponibles = <String>['TODOS'];
  Map<String, int> _conteoPorDenominacion = <String, int>{};

  bool _isLoading = true;
  List<EmisoraModel> _todasEmisoras = const <EmisoraModel>[];
  List<EmisoraModel> _emisorasFiltradas = const <EmisoraModel>[];
  int _cantidadVisible = _tamanoPagina;

  bool _mostrarSoloFavoritos = false;

  /// Traduce el código ISO de país usando exclusivamente [AppLocalizations].
  static String obtenerNombrePais(String codigo, AppLocalizations l10n) {
    final String codigoUpper = codigo.toUpperCase().trim();
    switch (codigoUpper) {
      case 'TODOS':
        return l10n.todosLosPaises;
      case 'OTROS':
        return l10n.otrosPaises;
      case 'AR':
        return l10n.paisAR;
      case 'BO':
        return l10n.paisBO;
      case 'BR':
        return l10n.paisBR;
      case 'CL':
        return l10n.paisCL;
      case 'CO':
        return l10n.paisCO;
      case 'CR':
        return l10n.paisCR;
      case 'CU':
        return l10n.paisCU;
      case 'DO':
        return l10n.paisDO;
      case 'EC':
        return l10n.paisEC;
      case 'ES':
        return l10n.paisES;
      case 'GT':
        return l10n.paisGT;
      case 'HN':
        return l10n.paisHN;
      case 'MX':
        return l10n.paisMX;
      case 'NI':
        return l10n.paisNI;
      case 'PA':
        return l10n.paisPA;
      case 'PE':
        return l10n.paisPE;
      case 'PR':
        return l10n.paisPR;
      case 'PY':
        return l10n.paisPY;
      case 'SV':
        return l10n.paisSV;
      case 'US':
        return l10n.paisUS;
      case 'UY':
        return l10n.paisUY;
      case 'VE':
        return l10n.paisVE;
      default:
        return codigo.trim().length > 3 ? codigo.trim() : codigoUpper;
    }
  }

  static Color obtenerColorEmisora(int index) =>
      _paletaIconos[index % _paletaIconos.length];

  static IconData obtenerIconoFallback(String frecuencia) {
    if (frecuencia.toLowerCase().contains('online')) {
      return Icons.wifi_tethering_rounded;
    }
    if (frecuencia.contains('AM')) return Icons.speaker_rounded;
    return Icons.radio_rounded;
  }

  /// Traduce el código o nombre de denominación usando exclusivamente [AppLocalizations].
  static String obtenerNombreDenominacion(
    String codigo,
    AppLocalizations l10n,
  ) {
    switch (codigo.toUpperCase().trim()) {
      case 'TODOS':
        return l10n.todasLasDenominaciones;
      case 'OTRAS':
        return l10n.denominacionOtras;
      case 'EVANGÉLICA':
      case 'EVANGELICA':
        return l10n.denominacionEvangelica;
      case 'CATÓLICA':
      case 'CATOLICA':
        return l10n.denominacionCatolica;
      case 'PENTECOSTAL':
        return l10n.denominacionPentecostal;
      case 'ADVENTISTA':
        return l10n.denominacionAdventista;
      case 'BAUTISTA':
        return l10n.denominacionBautista;
      case 'REFORMADA':
        return l10n.denominacionReformada;
      default:
        return codigo;
    }
  }

  /// Retorna un icono minimalista representativo para la denominación cristiana.
  static IconData obtenerIconoDenominacion(String codigo) {
    switch (codigo.toUpperCase().trim()) {
      case 'TODOS':
        return Icons.radio_rounded;
      case 'OTRAS':
        return Icons.auto_awesome_outlined;
      case 'CATÓLICA':
      case 'CATOLICA':
        return Icons.church_rounded;
      case 'EVANGÉLICA':
      case 'EVANGELICA':
        return Icons.menu_book_rounded;
      case 'PENTECOSTAL':
        return Icons.local_fire_department_rounded;
      case 'ADVENTISTA':
        return Icons.wb_sunny_outlined;
      case 'BAUTISTA':
        return Icons.water_drop_outlined;
      case 'REFORMADA':
        return Icons.history_edu_rounded;
      default:
        return Icons.church_outlined;
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScrollPaginacion);
    _cargarFavoritos();
    _iniciarListenerDeAudio();

    if (_cacheEmisoras != null && _cacheEmisoras!.isNotEmpty) {
      _todasEmisoras = _cacheEmisoras!;
      _paisesDisponibles = List<String>.from(
        _cachePaisesDisponibles ?? const <String>['TODOS'],
      );
      _actualizarDenominacionesDisponibles();
      _recalcularEmisorasFiltradas(resetPaginacion: true);
      _isLoading = false;
    } else {
      _isLoading = true;
      _inicializarCatalogoConCacheLocal();
    }
  }

  void _onScrollPaginacion() {
    if (!_scrollController.hasClients) return;
    final ScrollPosition pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 320) {
      _cargarSiguienteLote();
    }
  }

  void _cargarSiguienteLote() {
    if (_cantidadVisible >= _emisorasFiltradas.length) return;
    setState(() {
      _cantidadVisible = (_cantidadVisible + _tamanoPagina).clamp(
        0,
        _emisorasFiltradas.length,
      );
    });
  }

  Future<void> _cargarFavoritos() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? favs = prefs.getStringList('emisoras_favoritas');
    if (favs != null && mounted) {
      setState(() {
        _favoritosIds.addAll(favs);
        if (_mostrarSoloFavoritos) {
          _recalcularEmisorasFiltradas(resetPaginacion: false);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _playerStateSub?.cancel();
    _playbackEventSub?.cancel();
    _scrollController
      ..removeListener(_onScrollPaginacion)
      ..dispose();
    _searchController.dispose();
    if (_playbackNotifier.value.emisoraActual != null || _audioPlayer.playing) {
      _audioPlayer.stop();
    }
    _playbackNotifier.dispose();
    super.dispose();
  }

  // ===========================================================================
  // AUDIO (AISLADO CON VALUENOTIFIER PARA EVITAR REBUILD DEL GRID COMPLETO)
  // ===========================================================================
  void _iniciarListenerDeAudio() {
    try {
      _playerStateSub = _audioPlayer.playerStateStream.listen((
        PlayerState state,
      ) {
        if (!mounted) return;
        final bool buffering =
            state.processingState == ProcessingState.loading ||
            state.processingState == ProcessingState.buffering;
        _playbackNotifier.value = _playbackNotifier.value.copyWith(
          isBuffering: buffering,
          isPlaying: state.playing,
        );
      });

      _playbackEventSub = _audioPlayer.playbackEventStream.listen(
        (PlaybackEvent event) {},
        onError: (Object e, StackTrace stackTrace) async {
          debugPrint('[RADIO_ERROR] Error en streaming: $e');
          if (!mounted) return;
          final AppLocalizations l10n = AppLocalizations.of(context)!;
          final bool hasInternet = await ConnectivityService.instance
              .hasRealInternet();
          if (!mounted) return;
          final EmisoraModel? actual = _playbackNotifier.value.emisoraActual;
          if (!hasInternet) {
            AtrioConnectivityAlert.show(
              context,
              message: l10n.sinInternetSintonizar,
              onRetry: actual != null ? () => _reproducirEmisora(actual) : null,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: rojoError,
                content: Text(l10n.errorEmisoraNoDisponible),
              ),
            );
          }
          _playbackNotifier.value = _playbackNotifier.value.copyWith(
            isBuffering: false,
            isPlaying: false,
          );
        },
      );
    } catch (e) {
      debugPrint('[RADIO_ERROR] Excepción listeners audio: $e');
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    // Si tras un Hot Reload la lista en el State montado quedó vacía, recargamos inmediatamente
    if (_todasEmisoras.isEmpty) {
      if (_cacheEmisoras != null && _cacheEmisoras!.isNotEmpty) {
        _aplicarCatalogoEnEstado(_cacheEmisoras!);
      } else {
        _isLoading = true;
        _inicializarCatalogoConCacheLocal();
      }
    } else if (_emisorasFiltradas.isEmpty) {
      _recalcularEmisorasFiltradas(resetPaginacion: true);
    }
  }

  @override
  void didUpdateWidget(EmisorasScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      _detenerReproduccion();
    } else if (!oldWidget.isActive &&
        widget.isActive &&
        _todasEmisoras.isEmpty &&
        _cargaEnProgreso == null) {
      _isLoading = true;
      _inicializarCatalogoConCacheLocal();
    }
  }

  void _manejarRetroceso() {
    _detenerReproduccion();
    if (ModalRoute.of(context)?.settings.name == 'inicio_atrio_screen') {
      const CambiarTabAtrioNotification(0).dispatch(context);
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      const CambiarTabAtrioNotification(0).dispatch(context);
    }
  }

  Future<void> _reproducirEmisora(EmisoraModel emisora) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool tieneInternet = await AtrioConnectivityAlert.checkAndNotify(
      context,
      message: l10n.sinInternetSintonizar,
      onRetry: () => _reproducirEmisora(emisora),
    );
    if (!tieneInternet || !mounted) return;

    _playbackNotifier.value = _playbackNotifier.value.copyWith(
      emisoraActual: emisora,
      isBuffering: true,
    );

    try {
      await _audioPlayer.stop();

      final String streamUrl = emisora.streamUrl.trim();
      final String idStr = emisora.id.trim();
      final String logoUrl = emisora.logo.trim();

      final MediaItem mediaItem = MediaItem(
        id: idStr.isNotEmpty ? idStr : streamUrl,
        album: emisora.denomination.isNotEmpty
            ? emisora.denomination
            : l10n.radioCristiana,
        title: emisora.name.isNotEmpty ? emisora.name : l10n.emisora,
        artUri: logoUrl.isNotEmpty ? Uri.tryParse(logoUrl) : null,
      );

      final AudioSource source = AudioSource.uri(
        Uri.parse(streamUrl),
        tag: mediaItem,
      );

      try {
        await _audioPlayer.setAudioSource(source);
      } catch (sourceErr) {
        final String errText = sourceErr.toString();
        if (errText.contains('_audioHandler') ||
            errText.contains('single player instance')) {
          await _playerStateSub?.cancel();
          await _playbackEventSub?.cancel();
          await RadioPlayerService.instance.recoverFromHandlerError();
          _iniciarListenerDeAudio();
          await _audioPlayer.setAudioSource(source);
        } else {
          rethrow;
        }
      }
      unawaited(_audioPlayer.play());
    } catch (e) {
      debugPrint('[RADIO_ERROR] Error al reproducir stream: $e');
      if (!mounted) return;
      _playbackNotifier.value = _playbackNotifier.value.copyWith(
        isBuffering: false,
        isPlaying: false,
      );
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_audioPlayer.playing) {
        unawaited(_audioPlayer.pause());
      } else {
        if (_playbackNotifier.value.emisoraActual != null) {
          final AppLocalizations l10n = AppLocalizations.of(context)!;
          final bool tieneInternet =
              await AtrioConnectivityAlert.checkAndNotify(
                context,
                message: l10n.sinInternetSintonizar,
                onRetry: _togglePlayPause,
              );
          if (!tieneInternet || !mounted) return;
        }
        unawaited(_audioPlayer.play());
      }
    } catch (e) {
      debugPrint('[RADIO_ERROR] Error togglePlayPause: $e');
    }
  }

  void _detenerReproduccion() {
    _playbackNotifier.value = const _PlaybackUiState();
    _audioPlayer.stop();
  }

  // ===========================================================================
  // FASE 1: PERSISTENCIA LOCAL (SQLITE) + STALE-WHILE-REVALIDATE + ISOLATE.RUN
  // ===========================================================================
  Future<void> _inicializarCatalogoConCacheLocal({
    bool forzarRed = false,
  }) async {
    if (_cargaEnProgreso != null) {
      await _cargaEnProgreso;
      if (mounted && _cacheEmisoras != null) {
        _aplicarCatalogoEnEstado(_cacheEmisoras!);
      }
      return;
    }

    _cargaEnProgreso = _ejecutarFlujoStaleWhileRevalidate(forzarRed: forzarRed);
    try {
      await _cargaEnProgreso;
    } finally {
      _cargaEnProgreso = null;
    }
  }

  Future<void> _ejecutarFlujoStaleWhileRevalidate({
    required bool forzarRed,
  }) async {
    // 1. Lectura rápida desde SQLite (< 15 ms) para renderizado instantáneo sin bloquear la UI
    if (!forzarRed) {
      try {
        final List<EmisoraModel> desdeSqlite = await AtrioDatabaseHelper
            .instance
            .obtenerCatalogoEmisoras();
        if (desdeSqlite.isNotEmpty) {
          debugPrint(
            '[RADIO_LOG] Catálogo cargado desde SQLite local (${desdeSqlite.length} emisoras).',
          );
          _actualizarCachesEstables(desdeSqlite);
          if (mounted) {
            _aplicarCatalogoEnEstado(desdeSqlite);
          }

          // Verificar si el TTL (12h) sigue vigente para evitar petición de red innecesaria
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          final int lastSyncMs = prefs.getInt(_prefKeyLastSyncMs) ?? 0;
          final int elapsedMs =
              DateTime.now().millisecondsSinceEpoch - lastSyncMs;
          if (elapsedMs < _cacheTtl.inMilliseconds) {
            return;
          }
        }
      } catch (e) {
        debugPrint('[RADIO_ERROR] Error leyendo caché SQLite: $e');
      }
    }

    // 2. Descarga desde Google Sheets y parseo con `compute` (función estática pura sin capturar `this`)
    List<EmisoraModel> nuevasEmisoras = const <EmisoraModel>[];
    String? nuevoHash;
    try {
      debugPrint('[RADIO_LOG] Descargando catálogo desde Google Sheets...');
      final http.Response response = await http
          .get(
            Uri.parse(_sheetUrl),
            headers: const <String, String>{
              'Accept': 'text/csv, text/plain, */*',
              'User-Agent': 'AtrioApp/1.0',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final Uint8List bodyBytes = response.bodyBytes;
        nuevoHash = _EmisoraLogoCacheManager.fastHashBytes(bodyBytes);
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? hashAnterior = prefs.getString(_prefKeyCsvHash);

        // Si ya tenemos datos en memoria y el hash del CSV no cambió, solo renovamos el TTL
        if (!forzarRed &&
            hashAnterior == nuevoHash &&
            _cacheEmisoras != null &&
            _cacheEmisoras!.isNotEmpty) {
          await prefs.setInt(
            _prefKeyLastSyncMs,
            DateTime.now().millisecondsSinceEpoch,
          );
          if (mounted && _todasEmisoras.isEmpty) {
            _aplicarCatalogoEnEstado(_cacheEmisoras!);
          }
          return;
        }

        // Usamos `compute` con función estática top-level/static para no capturar `this` (_EmisorasScreenState)
        try {
          nuevasEmisoras = await compute(
            EmisorasCatalogParser.parseCsvBytes,
            bodyBytes,
          );
        } catch (isolateErr) {
          debugPrint(
            '[RADIO_LOG] Fallback síncrono de parseo CSV: $isolateErr',
          );
          nuevasEmisoras = EmisorasCatalogParser.parseCsvBytes(bodyBytes);
        }
      }
    } catch (e) {
      debugPrint('[RADIO_ERROR] Error HTTP sincronizando Google Sheets: $e');
    }

    // 3. Fallback local JSON si SQLite y red estaban vacíos
    if (nuevasEmisoras.isEmpty &&
        (_cacheEmisoras == null || _cacheEmisoras!.isEmpty)) {
      try {
        debugPrint('[RADIO_LOG] Cargando respaldo local JSON...');
        final String jsonString = await rootBundle.loadString(
          'assets/json/emisoras_rd.json',
        );
        try {
          nuevasEmisoras = await compute(
            EmisorasCatalogParser.parseFallbackJson,
            jsonString,
          );
        } catch (_) {
          nuevasEmisoras = EmisorasCatalogParser.parseFallbackJson(jsonString);
        }
      } catch (e) {
        debugPrint('[RADIO_ERROR] Error cargando fallback JSON: $e');
      }
    }

    // 4. Actualizar estado de UI de inmediato antes de escribir en SQLite
    if (nuevasEmisoras.isNotEmpty) {
      _actualizarCachesEstables(nuevasEmisoras);
      if (mounted) {
        _aplicarCatalogoEnEstado(nuevasEmisoras);
      }
      debugPrint(
        '[RADIO_LOG] ¡Éxito! Catálogo activo en UI con ${nuevasEmisoras.length} emisoras.',
      );

      // 5. Persistir en SQLite de forma resiliente en segundo plano
      try {
        await AtrioDatabaseHelper.instance.guardarCatalogoEmisorasBatch(
          nuevasEmisoras,
        );
        if (nuevoHash != null) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefKeyCsvHash, nuevoHash);
          await prefs.setInt(
            _prefKeyLastSyncMs,
            DateTime.now().millisecondsSinceEpoch,
          );
        }
      } catch (dbErr) {
        debugPrint('[RADIO_ERROR] Error guardando caché SQLite: $dbErr');
      }
    } else if (_cacheEmisoras != null && _cacheEmisoras!.isNotEmpty) {
      if (mounted) {
        _aplicarCatalogoEnEstado(_cacheEmisoras!);
      }
    } else if (mounted && _isLoading) {
      setState(() => _isLoading = false);
    }
  }

  void _actualizarCachesEstables(List<EmisoraModel> catalogo) {
    final Set<String> paisesSet = <String>{};
    for (final EmisoraModel e in catalogo) {
      final String pais = e.paisCodigo.trim().toUpperCase();
      if (pais.isNotEmpty) paisesSet.add(pais);
    }
    final List<String> ordenadasPaises = paisesSet.toList()..sort();
    _cacheEmisoras = List<EmisoraModel>.unmodifiable(catalogo);
    _cachePaisesDisponibles = List<String>.unmodifiable(<String>[
      'TODOS',
      ...ordenadasPaises,
    ]);
  }

  void _actualizarDenominacionesDisponibles() {
    final Map<String, int> conteos = <String, int>{};
    int totalCount = 0;
    int otrasCount = 0;

    final String paisFiltro = _paisSeleccionado.toUpperCase().trim();
    final String idiomaFiltro = _idiomaSeleccionado.toLowerCase().trim();

    for (final EmisoraModel e in _todasEmisoras) {
      if (_mostrarSoloFavoritos && !_favoritosIds.contains(e.id)) continue;
      if (paisFiltro != 'TODOS' && e.paisCodigo.toUpperCase() != paisFiltro) {
        continue;
      }
      if (idiomaFiltro != 'todos' && e.idioma.toLowerCase() != idiomaFiltro) {
        continue;
      }

      totalCount++;
      final String denom = e.denomination.trim();
      final String denomLower = denom.toLowerCase();

      if (denom.isEmpty ||
          denomLower == 'desconocida' ||
          denomLower == 'cristiana') {
        otrasCount++;
      } else {
        conteos[denom] = (conteos[denom] ?? 0) + 1;
      }
    }

    // Ordenamos las denominaciones por cantidad de emisoras (mayor a menor)
    final List<String> sortedDenoms = conteos.keys.toList()
      ..sort((String a, String b) {
        final int cmp = (conteos[b] ?? 0).compareTo(conteos[a] ?? 0);
        if (cmp != 0) return cmp;
        return a.compareTo(b);
      });

    conteos['TODOS'] = totalCount;
    if (otrasCount > 0) {
      conteos['OTRAS'] = otrasCount;
      sortedDenoms.add('OTRAS');
    }

    _conteoPorDenominacion = conteos;
    _denominacionesDisponibles = <String>['TODOS', ...sortedDenoms];
  }

  void _aplicarCatalogoEnEstado(List<EmisoraModel> catalogo) {
    setState(() {
      _todasEmisoras = catalogo;
      _paisesDisponibles = List<String>.from(
        _cachePaisesDisponibles ?? const <String>['TODOS'],
      );
      if (!_paisesDisponibles.contains(_paisSeleccionado)) {
        _paisSeleccionado = 'TODOS';
      }
      _actualizarDenominacionesDisponibles();
      if (!_denominacionesDisponibles.contains(_denominacionSeleccionada)) {
        _denominacionSeleccionada = 'TODOS';
      }
      _isLoading = false;
      _recalcularEmisorasFiltradas(resetPaginacion: false);
    });
  }

  // ===========================================================================
  // FASE 2 & 4: FILTRADO O(1) CON SEARCH_BLOB PRE-COMPUTADO + DEBOUNCE
  // ===========================================================================
  void _onSearchQueryChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() {
        _filtroBusqueda = value;
        _recalcularEmisorasFiltradas(resetPaginacion: true);
      });
    });
  }

  void _recalcularEmisorasFiltradas({required bool resetPaginacion}) {
    final String queryNorm = EmisoraModel.normalizeForSearch(_filtroBusqueda);
    final String paisFiltro = _paisSeleccionado.toUpperCase().trim();
    final String idiomaFiltro = _idiomaSeleccionado.toLowerCase().trim();
    final String denomFiltro = _denominacionSeleccionada.trim();

    final List<EmisoraModel> resultado = _todasEmisoras
        .where((EmisoraModel emisora) {
          if (_mostrarSoloFavoritos && !_favoritosIds.contains(emisora.id)) {
            return false;
          }
          if (paisFiltro != 'TODOS' &&
              emisora.paisCodigo.toUpperCase() != paisFiltro) {
            return false;
          }
          if (idiomaFiltro != 'todos' &&
              emisora.idioma.toLowerCase() != idiomaFiltro) {
            return false;
          }
          if (denomFiltro != 'TODOS') {
            final String ed = emisora.denomination.trim();
            final String edLower = ed.toLowerCase();
            if (denomFiltro == 'OTRAS') {
              if (ed.isNotEmpty &&
                  edLower != 'desconocida' &&
                  edLower != 'cristiana') {
                return false;
              }
            } else {
              if (edLower != denomFiltro.toLowerCase()) {
                return false;
              }
            }
          }
          if (queryNorm.isEmpty) return true;
          return emisora.searchBlob.contains(queryNorm);
        })
        .toList(growable: false);

    _emisorasFiltradas = resultado;
    if (resetPaginacion) {
      _cantidadVisible = _tamanoPagina.clamp(0, _emisorasFiltradas.length);
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    } else {
      if (_cantidadVisible < _tamanoPagina) {
        _cantidadVisible = _tamanoPagina.clamp(0, _emisorasFiltradas.length);
      } else if (_cantidadVisible > _emisorasFiltradas.length) {
        _cantidadVisible = _emisorasFiltradas.length;
      }
    }
  }

  Future<void> _toggleFavorito(String id) async {
    setState(() {
      if (!_favoritosIds.remove(id)) {
        _favoritosIds.add(id);
      }
      if (_mostrarSoloFavoritos) {
        _actualizarDenominacionesDisponibles();
        _recalcularEmisorasFiltradas(resetPaginacion: false);
      }
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('emisoras_favoritas', _favoritosIds.toList());
  }

  void _cambiarPais(String nuevoPais) {
    if (_paisSeleccionado == nuevoPais) return;
    setState(() {
      _paisSeleccionado = nuevoPais;
      _actualizarDenominacionesDisponibles();
      if (!_denominacionesDisponibles.contains(_denominacionSeleccionada)) {
        _denominacionSeleccionada = 'TODOS';
      }
      _recalcularEmisorasFiltradas(resetPaginacion: true);
    });
  }

  void _cambiarDenominacion(String nuevaDenominacion) {
    if (_denominacionSeleccionada == nuevaDenominacion) return;
    HapticFeedback.selectionClick();
    setState(() {
      _denominacionSeleccionada = nuevaDenominacion;
      _recalcularEmisorasFiltradas(resetPaginacion: true);
    });
  }

  void _cambiarIdioma(String nuevoIdioma) {
    if (_idiomaSeleccionado == nuevoIdioma) return;
    setState(() {
      _idiomaSeleccionado = nuevoIdioma;
      _actualizarDenominacionesDisponibles();
      if (!_denominacionesDisponibles.contains(_denominacionSeleccionada)) {
        _denominacionSeleccionada = 'TODOS';
      }
      _recalcularEmisorasFiltradas(resetPaginacion: true);
    });
  }

  void _toggleFiltroSoloFavoritos() {
    setState(() {
      _mostrarSoloFavoritos = !_mostrarSoloFavoritos;
      _actualizarDenominacionesDisponibles();
      if (!_denominacionesDisponibles.contains(_denominacionSeleccionada)) {
        _denominacionSeleccionada = 'TODOS';
      }
      _recalcularEmisorasFiltradas(resetPaginacion: true);
    });
  }

  void _desactivarFiltroSoloFavoritos() {
    if (!_mostrarSoloFavoritos) return;
    setState(() {
      _mostrarSoloFavoritos = false;
      _actualizarDenominacionesDisponibles();
      _recalcularEmisorasFiltradas(resetPaginacion: true);
    });
  }

  void _restablecerTodosLosFiltros() {
    HapticFeedback.mediumImpact();
    setState(() {
      _paisSeleccionado = 'TODOS';
      _denominacionSeleccionada = 'TODOS';
      _idiomaSeleccionado = 'TODOS';
      _mostrarSoloFavoritos = false;
      _mostrandoBuscador = false;
      _searchController.clear();
      _filtroBusqueda = '';
      _actualizarDenominacionesDisponibles();
      _recalcularEmisorasFiltradas(resetPaginacion: true);
    });
  }

  void _toggleTema() {
    HapticFeedback.lightImpact();
    final AjustesProvider provider = context.read<AjustesProvider>();
    final bool currentDark =
        provider.temaModo == 'oscuro' ||
        (provider.temaModo == 'sistema' &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    provider.cambiarTema(currentDark ? 'claro' : 'oscuro');
  }

  void _toggleBuscador() {
    setState(() {
      _mostrandoBuscador = !_mostrandoBuscador;
      if (!_mostrandoBuscador) {
        _searchDebounce?.cancel();
        _searchController.clear();
        _filtroBusqueda = '';
        _recalcularEmisorasFiltradas(resetPaginacion: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AjustesProvider ajustesProvider = context.watch<AjustesProvider>();
    final bool isDark =
        ajustesProvider.temaModo == 'oscuro' ||
        (ajustesProvider.temaModo == 'sistema' &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    final Size size = MediaQuery.sizeOf(context);
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    final double screenWidth = size.width;
    final double screenHeight = size.height;
    final double safeAreaTop = padding.top;
    final double safeAreaBottom = padding.bottom;
    final double usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    final Color colorScaffold = isDark ? const Color(0xFF0A0F14) : azulFondo;
    final Color colorCuerpo = isDark ? const Color(0xFF0F172A) : blancoFondo;

    final int itemsToRender = _cantidadVisible.clamp(
      0,
      _emisorasFiltradas.length,
    );

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          _detenerReproduccion();
        }
      },
      child: Scaffold(
        backgroundColor: colorScaffold,
        body: SafeArea(
          bottom: false,
          child: SizedBox(
            width: screenWidth,
            height: screenHeight - safeAreaTop,
            child: Column(
              children: <Widget>[
                _EmisorasHeader(
                  screenWidth: screenWidth,
                  usableHeight: usableHeight,
                  isDark: isDark,
                  mostrandoBuscador: _mostrandoBuscador,
                  searchController: _searchController,
                  idiomaSeleccionado: _idiomaSeleccionado,
                  onBackTap: _manejarRetroceso,
                  onToggleTheme: _toggleTema,
                  onToggleSearch: _toggleBuscador,
                  onQueryChanged: _onSearchQueryChanged,
                  onIdiomaChanged: _cambiarIdioma,
                ),
                Expanded(
                  child: Container(
                    width: screenWidth,
                    decoration: BoxDecoration(
                      color: colorCuerpo,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(screenWidth * 0.08),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(screenWidth * 0.08),
                      ),
                      child: Column(
                        children: <Widget>[
                          _EmisorasFiltrosSuperiores(
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            isDark: isDark,
                            paisesDisponibles: _paisesDisponibles,
                            paisSeleccionado: _paisSeleccionado,
                            mostrarSoloFavoritos: _mostrarSoloFavoritos,
                            onPaisChanged: _cambiarPais,
                            onToggleFavoritos: _toggleFiltroSoloFavoritos,
                          ),
                          _EmisorasSelectorDenominacion(
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            isDark: isDark,
                            denominacionesDisponibles:
                                _denominacionesDisponibles,
                            denominacionSeleccionada: _denominacionSeleccionada,
                            conteoPorDenominacion: _conteoPorDenominacion,
                            onDenominacionSelected: _cambiarDenominacion,
                          ),
                          SizedBox(height: usableHeight * 0.012),
                          if (_mostrarSoloFavoritos)
                            _EmisorasBannerFavoritos(
                              screenWidth: screenWidth,
                              usableHeight: usableHeight,
                              isDark: isDark,
                              totalMostradas: _emisorasFiltradas.length,
                              onClearFilter: _desactivarFiltroSoloFavoritos,
                            ),
                          Expanded(
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: amarilloOro,
                                    ),
                                  )
                                : _emisorasFiltradas.isEmpty
                                ? _EmisorasEmptyState(
                                    screenWidth: screenWidth,
                                    usableHeight: usableHeight,
                                    isDark: isDark,
                                    mostrarSoloFavoritos: _mostrarSoloFavoritos,
                                    paisSeleccionado: _paisSeleccionado,
                                    denominacionSeleccionada:
                                        _denominacionSeleccionada,
                                    filtroBusqueda: _filtroBusqueda,
                                    onResetFilters: _restablecerTodosLosFiltros,
                                  )
                                : RefreshIndicator(
                                    color: amarilloOro,
                                    backgroundColor: isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white,
                                    onRefresh: () =>
                                        _inicializarCatalogoConCacheLocal(
                                          forzarRed: true,
                                        ),
                                    child: ValueListenableBuilder<_PlaybackUiState>(
                                      valueListenable: _playbackNotifier,
                                      builder:
                                          (
                                            BuildContext context,
                                            _PlaybackUiState playbackState,
                                            _,
                                          ) {
                                            return GridView.builder(
                                              controller: _scrollController,
                                              physics:
                                                  const AlwaysScrollableScrollPhysics(
                                                    parent:
                                                        BouncingScrollPhysics(),
                                                  ),
                                              addAutomaticKeepAlives: false,
                                              addRepaintBoundaries: true,
                                              padding:
                                                  EdgeInsetsDirectional.fromSTEB(
                                                    screenWidth * 0.05,
                                                    0,
                                                    screenWidth * 0.05,
                                                    playbackState
                                                                .emisoraActual !=
                                                            null
                                                        ? usableHeight * 0.02
                                                        : usableHeight * 0.05,
                                                  ),
                                              gridDelegate:
                                                  SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 2,
                                                    crossAxisSpacing:
                                                        screenWidth * 0.035,
                                                    mainAxisSpacing:
                                                        screenWidth * 0.035,
                                                    childAspectRatio: 0.90,
                                                  ),
                                              itemCount: itemsToRender,
                                              itemBuilder:
                                                  (
                                                    BuildContext context,
                                                    int index,
                                                  ) {
                                                    final EmisoraModel emisora =
                                                        _emisorasFiltradas[index];
                                                    final bool isPlayingThis =
                                                        playbackState
                                                                .emisoraActual
                                                                ?.id ==
                                                            emisora.id &&
                                                        playbackState.isPlaying;
                                                    final bool isFav =
                                                        _favoritosIds.contains(
                                                          emisora.id,
                                                        );

                                                    return _EmisoraGridCard(
                                                      key: ValueKey<String>(
                                                        emisora.id,
                                                      ),
                                                      emisora: emisora,
                                                      index: index,
                                                      isPlayingThis:
                                                          isPlayingThis,
                                                      isFav: isFav,
                                                      isDark: isDark,
                                                      screenWidth: screenWidth,
                                                      usableHeight:
                                                          usableHeight,
                                                      l10n: l10n,
                                                      onTap: () =>
                                                          _reproducirEmisora(
                                                            emisora,
                                                          ),
                                                      onToggleFav: () =>
                                                          _toggleFavorito(
                                                            emisora.id,
                                                          ),
                                                    );
                                                  },
                                            );
                                          },
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                RepaintBoundary(
                  child: ValueListenableBuilder<_PlaybackUiState>(
                    valueListenable: _playbackNotifier,
                    builder:
                        (
                          BuildContext context,
                          _PlaybackUiState playbackState,
                          _,
                        ) {
                          final EmisoraModel? actual =
                              playbackState.emisoraActual;
                          if (actual == null) return const SizedBox.shrink();
                          return _EmisorasMiniPlayer(
                            emisora: actual,
                            isPlaying: playbackState.isPlaying,
                            isBuffering: playbackState.isBuffering,
                            isDark: isDark,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            safeAreaBottom: safeAreaBottom,
                            onPlayPause: _togglePlayPause,
                            onStop: _detenerReproduccion,
                          );
                        },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// WIDGETS DEDICADOS CON CONSTRUCTORES CONST (CUMPLIMIENTO REGLA #6 AGENTS.MD)
// =============================================================================

class _EmisorasHeader extends StatelessWidget {
  final double screenWidth;
  final double usableHeight;
  final bool isDark;
  final bool mostrandoBuscador;
  final TextEditingController searchController;
  final String idiomaSeleccionado;
  final VoidCallback onBackTap;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onIdiomaChanged;

  const _EmisorasHeader({
    required this.screenWidth,
    required this.usableHeight,
    required this.isDark,
    required this.mostrandoBuscador,
    required this.searchController,
    required this.idiomaSeleccionado,
    required this.onBackTap,
    required this.onToggleTheme,
    required this.onToggleSearch,
    required this.onQueryChanged,
    required this.onIdiomaChanged,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Container(
      width: screenWidth,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: usableHeight * 0.015,
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              GestureDetector(
                onTap: onBackTap,
                child: Container(
                  padding: EdgeInsetsDirectional.all(screenWidth * 0.02),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white,
                    size: screenWidth * 0.07,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: _EmisorasHeaderLanguageFilter(
                  screenWidth: screenWidth,
                  usableHeight: usableHeight,
                  isDark: isDark,
                  idiomaSeleccionado: idiomaSeleccionado,
                  onIdiomaChanged: onIdiomaChanged,
                ),
              ),
              // Botón de opción rápida para alternar entre tema claro y tema oscuro
              IconButton(
                tooltip: isDark
                    ? l10n.cambiarTemaClaro
                    : l10n.cambiarTemaOscuro,
                onPressed: onToggleTheme,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return RotationTransition(
                          turns: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    key: ValueKey<bool>(isDark),
                    color: isDark
                        ? _EmisorasScreenState.amarilloOro
                        : Colors.white,
                    size: screenWidth * 0.065,
                  ),
                ),
              ),
              IconButton(
                onPressed: onToggleSearch,
                icon: Icon(
                  mostrandoBuscador
                      ? Icons.close_rounded
                      : Icons.search_rounded,
                  color: Colors.white,
                  size: screenWidth * 0.065,
                ),
              ),
            ],
          ),
          if (mostrandoBuscador) ...<Widget>[
            SizedBox(height: usableHeight * 0.012),
            Container(
              height: usableHeight * 0.055,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : Colors.transparent,
                ),
              ),
              child: TextField(
                controller: searchController,
                autofocus: true,
                onChanged: onQueryChanged,
                style: TextStyle(
                  color: isDark ? Colors.white : _EmisorasScreenState.azulFondo,
                  fontSize: screenWidth * 0.04,
                ),
                decoration: InputDecoration(
                  hintText: l10n.buscarEmisorasPlaceholder,
                  hintStyle: TextStyle(
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : Colors.grey.shade500,
                    fontSize: screenWidth * 0.035,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : Colors.grey.shade600,
                    size: screenWidth * 0.05,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsetsDirectional.symmetric(
                    vertical: usableHeight * 0.014,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmisorasFiltrosSuperiores extends StatelessWidget {
  final double screenWidth;
  final double usableHeight;
  final bool isDark;
  final List<String> paisesDisponibles;
  final String paisSeleccionado;
  final bool mostrarSoloFavoritos;
  final ValueChanged<String> onPaisChanged;
  final VoidCallback onToggleFavoritos;

  const _EmisorasFiltrosSuperiores({
    required this.screenWidth,
    required this.usableHeight,
    required this.isDark,
    required this.paisesDisponibles,
    required this.paisSeleccionado,
    required this.mostrarSoloFavoritos,
    required this.onPaisChanged,
    required this.onToggleFavoritos,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String valorSeguro = paisesDisponibles.contains(paisSeleccionado)
        ? paisSeleccionado
        : 'TODOS';

    // Ordenamos los países alfabéticamente según su nombre localizado (manteniendo TODOS primero)
    final List<String> paisesOrdenados = <String>[
      'TODOS',
      ...paisesDisponibles.where((String c) => c != 'TODOS').toList()..sort(
        (String a, String b) => _EmisorasScreenState.obtenerNombrePais(
          a,
          l10n,
        ).compareTo(_EmisorasScreenState.obtenerNombrePais(b, l10n)),
      ),
    ];

    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color borderCol = isDark
        ? const Color(0xFF334155)
        : _EmisorasScreenState.grisBorde;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        screenWidth * 0.05,
        usableHeight * 0.015,
        screenWidth * 0.05,
        0,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Container(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: screenWidth * 0.04,
              ),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(screenWidth * 0.035),
                border: Border.all(color: borderCol),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: valorSeguro,
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isDark
                        ? _EmisorasScreenState.amarilloOro
                        : _EmisorasScreenState.azulFondo,
                    size: screenWidth * 0.06,
                  ),
                  dropdownColor: cardBg,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white
                        : _EmisorasScreenState.azulFondo,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.038,
                  ),
                  onChanged: (String? nuevoPais) {
                    if (nuevoPais != null) {
                      onPaisChanged(nuevoPais);
                    }
                  },
                  items: paisesOrdenados.map<DropdownMenuItem<String>>((
                    String codigo,
                  ) {
                    final String nombrePais =
                        _EmisorasScreenState.obtenerNombrePais(codigo, l10n);
                    return DropdownMenuItem<String>(
                      value: codigo,
                      child: Row(
                        children: <Widget>[
                          Icon(
                            codigo == 'TODOS'
                                ? Icons.public_rounded
                                : Icons.flag_circle_rounded,
                            color: _EmisorasScreenState.amarilloOro,
                            size: screenWidth * 0.05,
                          ),
                          SizedBox(width: screenWidth * 0.025),
                          Expanded(
                            child: Text(
                              nombrePais,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : _EmisorasScreenState.azulFondo,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          GestureDetector(
            onTap: onToggleFavoritos,
            child: Container(
              padding: EdgeInsetsDirectional.all(screenWidth * 0.035),
              decoration: BoxDecoration(
                color: mostrarSoloFavoritos
                    ? _EmisorasScreenState.amarilloOro
                    : cardBg,
                shape: BoxShape.circle,
                border: Border.all(
                  color: mostrarSoloFavoritos
                      ? _EmisorasScreenState.amarilloOro
                      : borderCol,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                mostrarSoloFavoritos
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: mostrarSoloFavoritos
                    ? (isDark ? const Color(0xFF0D2235) : Colors.white)
                    : (isDark
                          ? const Color(0xFFCBD5E1)
                          : _EmisorasScreenState.azulFondo),
                size: screenWidth * 0.06,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector minimalista horizontal para filtrar emisoras según su denominación cristiana.
class _EmisorasSelectorDenominacion extends StatelessWidget {
  final double screenWidth;
  final double usableHeight;
  final bool isDark;
  final List<String> denominacionesDisponibles;
  final String denominacionSeleccionada;
  final Map<String, int> conteoPorDenominacion;
  final ValueChanged<String> onDenominacionSelected;

  const _EmisorasSelectorDenominacion({
    required this.screenWidth,
    required this.usableHeight,
    required this.isDark,
    required this.denominacionesDisponibles,
    required this.denominacionSeleccionada,
    required this.conteoPorDenominacion,
    required this.onDenominacionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String localeName = Localizations.localeOf(context).toString();

    return Padding(
      padding: EdgeInsetsDirectional.only(top: usableHeight * 0.012),
      child: SizedBox(
        height: usableHeight * 0.048,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: screenWidth * 0.05,
          ),
          itemCount: denominacionesDisponibles.length,
          separatorBuilder: (_, _) => SizedBox(width: screenWidth * 0.02),
          itemBuilder: (BuildContext context, int index) {
            final String codigo = denominacionesDisponibles[index];
            final bool seleccionado =
                codigo.toUpperCase() == denominacionSeleccionada.toUpperCase();
            final String label = _EmisorasScreenState.obtenerNombreDenominacion(
              codigo,
              l10n,
            );
            final IconData icono =
                _EmisorasScreenState.obtenerIconoDenominacion(codigo);
            final int count = conteoPorDenominacion[codigo] ?? 0;
            final String countStr = NumberFormat.decimalPattern(localeName)
                .format(count);

            return _ChipDenominacionItem(
              codigo: codigo,
              label: label,
              icono: icono,
              countFormatted: countStr,
              count: count,
              seleccionado: seleccionado,
              isDark: isDark,
              screenWidth: screenWidth,
              usableHeight: usableHeight,
              onTap: () => onDenominacionSelected(codigo),
            );
          },
        ),
      ),
    );
  }
}

class _ChipDenominacionItem extends StatelessWidget {
  final String codigo;
  final String label;
  final IconData icono;
  final String countFormatted;
  final int count;
  final bool seleccionado;
  final bool isDark;
  final double screenWidth;
  final double usableHeight;
  final VoidCallback onTap;

  const _ChipDenominacionItem({
    required this.codigo,
    required this.label,
    required this.icono,
    required this.countFormatted,
    required this.count,
    required this.seleccionado,
    required this.isDark,
    required this.screenWidth,
    required this.usableHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color borderColor;
    final Color textColor;
    final Color iconColor;
    final Color badgeBgColor;
    final Color badgeTextColor;

    if (seleccionado) {
      if (isDark) {
        backgroundColor = _EmisorasScreenState.amarilloOro;
        borderColor = _EmisorasScreenState.amarilloOro;
        textColor = const Color(0xFF0D2235);
        iconColor = const Color(0xFF0D2235);
        badgeBgColor = const Color(0xFF0D2235).withValues(alpha: 0.16);
        badgeTextColor = const Color(0xFF0D2235);
      } else {
        backgroundColor = _EmisorasScreenState.azulFondo;
        borderColor = _EmisorasScreenState.azulFondo;
        textColor = Colors.white;
        iconColor = _EmisorasScreenState.amarilloOro;
        badgeBgColor = Colors.white.withValues(alpha: 0.20);
        badgeTextColor = Colors.white;
      }
    } else {
      if (isDark) {
        backgroundColor = const Color(0xFF1E293B);
        borderColor = const Color(0xFF334155);
        textColor = const Color(0xFFCBD5E1);
        iconColor = const Color(0xFF94A3B8);
        badgeBgColor = const Color(0xFF0F172A);
        badgeTextColor = const Color(0xFF94A3B8);
      } else {
        backgroundColor = Colors.white;
        borderColor = _EmisorasScreenState.grisBorde;
        textColor = const Color(0xFF334155);
        iconColor = Colors.grey.shade600;
        badgeBgColor = const Color(0xFFF1F5F9);
        badgeTextColor = const Color(0xFF475569);
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: screenWidth * 0.028,
          vertical: usableHeight * 0.006,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          border: Border.all(
            color: borderColor,
            width: seleccionado ? 1.5 : 1.0,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(
                alpha: seleccionado ? 0.08 : (isDark ? 0.15 : 0.02),
              ),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icono, color: iconColor, size: screenWidth * 0.038),
            SizedBox(width: screenWidth * 0.015),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: screenWidth * 0.031,
                fontWeight: seleccionado ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            if (count > 0) ...<Widget>[
              SizedBox(width: screenWidth * 0.016),
              Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: screenWidth * 0.016,
                  vertical: screenWidth * 0.003,
                ),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Text(
                  countFormatted,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontSize: screenWidth * 0.024,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmisorasHeaderLanguageFilter extends StatelessWidget {
  final double screenWidth;
  final double usableHeight;
  final bool isDark;
  final String idiomaSeleccionado;
  final ValueChanged<String> onIdiomaChanged;

  const _EmisorasHeaderLanguageFilter({
    required this.screenWidth,
    required this.usableHeight,
    required this.isDark,
    required this.idiomaSeleccionado,
    required this.onIdiomaChanged,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Flexible(
          child: _HeaderLanguageChip(
            label: l10n.espanol,
            isSelected: idiomaSeleccionado == 'es',
            isDark: isDark,
            screenWidth: screenWidth,
            usableHeight: usableHeight,
            onTap: () {
              // Si ya está seleccionado, alternar a 'TODOS' para ver todas las emisoras
              onIdiomaChanged(idiomaSeleccionado == 'es' ? 'TODOS' : 'es');
            },
          ),
        ),
        SizedBox(width: screenWidth * 0.02),
        Flexible(
          child: _HeaderLanguageChip(
            label: l10n.ingles,
            isSelected: idiomaSeleccionado == 'en',
            isDark: isDark,
            screenWidth: screenWidth,
            usableHeight: usableHeight,
            onTap: () {
              // Si ya está seleccionado, alternar a 'TODOS' para ver todas las emisoras
              onIdiomaChanged(idiomaSeleccionado == 'en' ? 'TODOS' : 'en');
            },
          ),
        ),
      ],
    );
  }
}

class _HeaderLanguageChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final double screenWidth;
  final double usableHeight;
  final VoidCallback onTap;

  const _HeaderLanguageChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.screenWidth,
    required this.usableHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color borderColor;
    final Color textColor;

    if (isSelected) {
      backgroundColor = _EmisorasScreenState.amarilloOro;
      borderColor = _EmisorasScreenState.amarilloOro;
      textColor = const Color(0xFF0D2235);
    } else {
      backgroundColor = Colors.white.withValues(alpha: isDark ? 0.08 : 0.14);
      borderColor = Colors.white.withValues(alpha: isDark ? 0.16 : 0.22);
      textColor = Colors.white.withValues(alpha: 0.92);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: screenWidth * 0.028,
          vertical: usableHeight * 0.007,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          border: Border.all(color: borderColor, width: isSelected ? 1.4 : 1.0),
          boxShadow: isSelected
              ? <BoxShadow>[
                  BoxShadow(
                    color: _EmisorasScreenState.amarilloOro.withValues(
                      alpha: 0.35,
                    ),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: screenWidth * 0.033,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmisorasBannerFavoritos extends StatelessWidget {
  final double screenWidth;
  final double usableHeight;
  final bool isDark;
  final int totalMostradas;
  final VoidCallback onClearFilter;

  const _EmisorasBannerFavoritos({
    required this.screenWidth,
    required this.usableHeight,
    required this.isDark,
    required this.totalMostradas,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String localeName = Localizations.localeOf(context).toString();
    final String totalFormateado = NumberFormat.decimalPattern(localeName)
        .format(totalMostradas);

    final Color bannerBg = isDark
        ? const Color(0xFF261E0F)
        : const Color(0xFFFFF7E6);
    final Color borderCol = _EmisorasScreenState.amarilloOro.withValues(
      alpha: isDark ? 0.70 : 0.50,
    );
    final Color txtColor = isDark
        ? Colors.white
        : _EmisorasScreenState.azulFondo;

    return Container(
      margin: EdgeInsetsDirectional.fromSTEB(
        screenWidth * 0.05,
        0,
        screenWidth * 0.05,
        usableHeight * 0.012,
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: screenWidth * 0.035,
        vertical: usableHeight * 0.01,
      ),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        border: Border.all(color: borderCol, width: 1.2),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: EdgeInsetsDirectional.all(screenWidth * 0.015),
            decoration: const BoxDecoration(
              color: _EmisorasScreenState.amarilloOro,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_rounded,
              color: isDark ? const Color(0xFF0D2235) : Colors.white,
              size: screenWidth * 0.04,
            ),
          ),
          SizedBox(width: screenWidth * 0.025),
          Expanded(
            child: Text(
              l10n.mostrandoSoloFavoritas(totalFormateado),
              style: TextStyle(
                color: txtColor,
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.033,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onClearFilter,
            child: Container(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: screenWidth * 0.025,
                vertical: usableHeight * 0.006,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                border: Border.all(color: _EmisorasScreenState.amarilloOro),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    l10n.verTodas,
                    style: TextStyle(
                      color: isDark
                          ? _EmisorasScreenState.amarilloOro
                          : _EmisorasScreenState.azulFondo,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.03,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  Icon(
                    Icons.close_rounded,
                    color: isDark
                        ? _EmisorasScreenState.amarilloOro
                        : _EmisorasScreenState.azulFondo,
                    size: screenWidth * 0.035,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta individual en cuadrícula de 2 columnas con constructores const,
/// direcciones Bidi (`PositionedDirectional`) y logo redimensionado en caché.
class _EmisoraGridCard extends StatelessWidget {
  final EmisoraModel emisora;
  final int index;
  final bool isPlayingThis;
  final bool isFav;
  final bool isDark;
  final double screenWidth;
  final double usableHeight;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onToggleFav;

  const _EmisoraGridCard({
    super.key,
    required this.emisora,
    required this.index,
    required this.isPlayingThis,
    required this.isFav,
    required this.isDark,
    required this.screenWidth,
    required this.usableHeight,
    required this.l10n,
    required this.onTap,
    required this.onToggleFav,
  });

  @override
  Widget build(BuildContext context) {
    final String name = emisora.name;
    final String rawDenom = emisora.denomination.trim();
    final bool hasDenom =
        rawDenom.isNotEmpty &&
        rawDenom.toLowerCase() != 'desconocida' &&
        rawDenom.toLowerCase() != 'cristiana';
    final String denomination = hasDenom
        ? _EmisorasScreenState.obtenerNombreDenominacion(rawDenom, l10n)
        : l10n.denominacionCristiana;
    final String frequency = emisora.frequency.isNotEmpty
        ? emisora.frequency
        : l10n.frecuenciaOnline;

    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color borderCol = isPlayingThis
        ? _EmisorasScreenState.amarilloOro
        : (isDark ? const Color(0xFF334155) : _EmisorasScreenState.grisBorde);
    final Color titleColor = isDark
        ? Colors.white
        : _EmisorasScreenState.azulFondo;
    final Color subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : Colors.grey.shade600;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
                border: Border.all(
                  color: borderCol,
                  width: isPlayingThis ? 2.0 : 1.0,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                alignment: AlignmentDirectional.center,
                children: <Widget>[
                  _EmisoraCachedLogo(
                    logoUrl: emisora.logo,
                    frecuencia: frequency,
                    index: index,
                    fit: BoxFit.cover,
                  ),
                  if (isPlayingThis)
                    PositionedDirectional(
                      bottom: screenWidth * 0.02,
                      end: screenWidth * 0.02,
                      child: Container(
                        padding: EdgeInsetsDirectional.all(screenWidth * 0.012),
                        decoration: BoxDecoration(
                          color: _EmisorasScreenState.amarilloOro,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.graphic_eq_rounded,
                          color: Colors.white,
                          size: screenWidth * 0.035,
                        ),
                      ),
                    ),
                  PositionedDirectional(
                    top: screenWidth * 0.018,
                    start: screenWidth * 0.018,
                    child: Container(
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: screenWidth * 0.02,
                        vertical: screenWidth * 0.006,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isDark
                                    ? const Color(0xFF0F172A)
                                    : _EmisorasScreenState.azulFondo)
                                .withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.016,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        emisora.idioma.toUpperCase(),
                        style: TextStyle(
                          color: _EmisorasScreenState.amarilloOro,
                          fontWeight: FontWeight.w800,
                          fontSize: screenWidth * 0.024,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: screenWidth * 0.015,
                    end: screenWidth * 0.015,
                    child: GestureDetector(
                      onTap: onToggleFav,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: EdgeInsetsDirectional.all(screenWidth * 0.014),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A).withValues(alpha: 0.92)
                              : Colors.white.withValues(alpha: 0.92),
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.35 : 0.20,
                              ),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFav
                              ? Colors.redAccent
                              : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : Colors.grey.shade600),
                          size: screenWidth * 0.062,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: usableHeight * 0.006),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            hasDenom ? '$denomination · $frequency' : frequency,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: subtitleColor,
              fontSize: screenWidth * 0.024,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de logo con caché persistente en disco y decodificación limitada en VRAM (`cacheWidth`/`cacheHeight`).
/// Sustituye los `CircularProgressIndicator` en celda por un placeholder estático ligero para evitar jank a 60 FPS.
class _EmisoraCachedLogo extends StatefulWidget {
  final String? logoUrl;
  final String frecuencia;
  final int index;
  final double? size;
  final BoxFit fit;

  const _EmisoraCachedLogo({
    required this.logoUrl,
    required this.frecuencia,
    required this.index,
    this.size,
    this.fit = BoxFit.cover,
  });

  @override
  State<_EmisoraCachedLogo> createState() => _EmisoraCachedLogoState();
}

class _EmisoraCachedLogoState extends State<_EmisoraCachedLogo> {
  File? _cachedFile;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _resolveLogo();
  }

  @override
  void didUpdateWidget(_EmisoraCachedLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.logoUrl != widget.logoUrl) {
      _cachedFile = null;
      _loadFailed = false;
      _resolveLogo();
    }
  }

  void _resolveLogo() {
    final String url = (widget.logoUrl ?? '').trim();
    if (url.isEmpty || kIsWeb) return;

    final String? syncPath = _EmisoraLogoCacheManager.instance
        .getCachedFilePathSync(url);
    if (syncPath != null) {
      _cachedFile = File(syncPath);
      return;
    }

    _EmisoraLogoCacheManager.instance.getLogoFile(url).then((File? file) {
      if (!mounted) return;
      setState(() {
        _cachedFile = file;
        _loadFailed = file == null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double imageWidth = widget.size ?? double.infinity;
    final double imageHeight = widget.size ?? double.infinity;

    final Widget fallback = Center(
      child: Icon(
        _EmisorasScreenState.obtenerIconoFallback(widget.frecuencia),
        color: _EmisorasScreenState.obtenerColorEmisora(widget.index)
            .withValues(alpha: 0.85),
        size: widget.size != null ? widget.size! * 0.55 : screenWidth * 0.16,
      ),
    );

    final String url = (widget.logoUrl ?? '').trim();
    if (url.isEmpty || _loadFailed) return fallback;

    // Limitamos la decodificación de textura en VRAM al tamaño físico real de pantalla
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final double baseDimension = widget.size ?? (screenWidth * 0.45);
    final int targetPx = (baseDimension * dpr).round().clamp(64, 512);

    if (_cachedFile != null) {
      return Image.file(
        _cachedFile!,
        width: imageWidth,
        height: imageHeight,
        fit: widget.fit,
        cacheWidth: targetPx,
        cacheHeight: targetPx,
        filterQuality: FilterQuality.low,
        errorBuilder: (BuildContext context, Object error, StackTrace? _) =>
            fallback,
      );
    }

    if (kIsWeb) {
      return Image.network(
        url,
        width: imageWidth,
        height: imageHeight,
        fit: widget.fit,
        cacheWidth: targetPx,
        cacheHeight: targetPx,
        filterQuality: FilterQuality.low,
        errorBuilder: (BuildContext context, Object error, StackTrace? _) =>
            fallback,
      );
    }

    // Mientras se descarga en el pool de disco mostramos el icono estático sin animaciones pesadas
    return fallback;
  }
}

class _EmisorasEmptyState extends StatelessWidget {
  final double screenWidth;
  final double usableHeight;
  final bool isDark;
  final bool mostrarSoloFavoritos;
  final String paisSeleccionado;
  final String denominacionSeleccionada;
  final String filtroBusqueda;
  final VoidCallback onResetFilters;

  const _EmisorasEmptyState({
    required this.screenWidth,
    required this.usableHeight,
    required this.isDark,
    required this.mostrarSoloFavoritos,
    required this.paisSeleccionado,
    required this.denominacionSeleccionada,
    required this.filtroBusqueda,
    required this.onResetFilters,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String mensajeVacio;
    final IconData iconoVacio;

    if (mostrarSoloFavoritos) {
      iconoVacio = Icons.favorite_border_rounded;
      if (paisSeleccionado != 'TODOS') {
        final String nombrePais = _EmisorasScreenState.obtenerNombrePais(
          paisSeleccionado,
          l10n,
        );
        mensajeVacio = l10n.sinFavoritasEnPais(nombrePais);
      } else {
        mensajeVacio = l10n.sinFavoritasAun;
      }
    } else if (filtroBusqueda.isNotEmpty) {
      iconoVacio = Icons.search_off_rounded;
      mensajeVacio = l10n.noEmisorasCoincidencia(filtroBusqueda);
    } else if (denominacionSeleccionada != 'TODOS') {
      iconoVacio = Icons.church_outlined;
      mensajeVacio = l10n.sinEmisorasDenominacion;
    } else {
      iconoVacio = Icons.radio_outlined;
      final String nombrePais = _EmisorasScreenState.obtenerNombrePais(
        paisSeleccionado,
        l10n,
      );
      mensajeVacio = l10n.noEmisorasDisponiblesPais(nombrePais);
    }

    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color borderCol = isDark
        ? const Color(0xFF334155)
        : _EmisorasScreenState.grisBorde;
    final Color btnTextColor = isDark
        ? _EmisorasScreenState.amarilloOro
        : _EmisorasScreenState.azulFondo;

    return Center(
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: screenWidth * 0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              iconoVacio,
              size: screenWidth * 0.12,
              color: mostrarSoloFavoritos
                  ? _EmisorasScreenState.amarilloOro
                  : (isDark ? const Color(0xFF64748B) : Colors.grey.shade400),
            ),
            SizedBox(height: usableHeight * 0.015),
            Text(
              mensajeVacio,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade600,
                fontSize: screenWidth * 0.038,
                height: 1.3,
              ),
            ),
            SizedBox(height: usableHeight * 0.02),
            TextButton.icon(
              onPressed: onResetFilters,
              icon: Icon(Icons.refresh_rounded, color: btnTextColor),
              label: Text(
                mostrarSoloFavoritos
                    ? l10n.verTodasLasEmisoras
                    : l10n.restablecerFiltros,
                style: TextStyle(
                  color: btnTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  side: BorderSide(color: borderCol),
                ),
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: screenWidth * 0.045,
                  vertical: usableHeight * 0.012,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmisorasMiniPlayer extends StatelessWidget {
  final EmisoraModel emisora;
  final bool isPlaying;
  final bool isBuffering;
  final bool isDark;
  final double screenWidth;
  final double usableHeight;
  final double safeAreaBottom;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;

  const _EmisorasMiniPlayer({
    required this.emisora,
    required this.isPlaying,
    required this.isBuffering,
    required this.isDark,
    required this.screenWidth,
    required this.usableHeight,
    required this.safeAreaBottom,
    required this.onPlayPause,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String nombre = emisora.name.isNotEmpty ? emisora.name : l10n.emisora;
    final String rawDenom = emisora.denomination.trim();
    final bool hasDenom =
        rawDenom.isNotEmpty &&
        rawDenom.toLowerCase() != 'desconocida' &&
        rawDenom.toLowerCase() != 'cristiana';
    final String denominacion = hasDenom
        ? _EmisorasScreenState.obtenerNombreDenominacion(rawDenom, l10n)
        : l10n.denominacionCristiana;
    final String frecuencia = emisora.frequency.isNotEmpty
        ? emisora.frequency
        : l10n.frecuenciaOnline;

    final Color miniBg = isDark
        ? const Color(0xFF131D2A)
        : const Color(0xFFEEF4F8);
    final Color borderTopCol = isDark
        ? const Color(0xFF263548)
        : _EmisorasScreenState.grisBorde;
    final Color logoBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color titleCol = isDark
        ? Colors.white
        : _EmisorasScreenState.azulFondo;
    final Color subtitleCol = isBuffering
        ? _EmisorasScreenState.amarilloOro
        : (isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700);

    return Container(
      width: screenWidth,
      padding: EdgeInsetsDirectional.only(
        bottom: safeAreaBottom > 0 ? safeAreaBottom : usableHeight * 0.015,
        top: usableHeight * 0.014,
        start: screenWidth * 0.04,
        end: screenWidth * 0.04,
      ),
      decoration: BoxDecoration(
        color: miniBg,
        border: Border(top: BorderSide(color: borderTopCol)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: screenWidth * 0.125,
            height: screenWidth * 0.125,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: logoBg,
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : _EmisorasScreenState.grisBorde,
              ),
            ),
            child: _EmisoraCachedLogo(
              logoUrl: emisora.logo,
              frecuencia: frecuencia,
              index: 0,
              size: screenWidth * 0.125,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  nombre,
                  style: TextStyle(
                    color: titleCol,
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isBuffering
                      ? l10n.sintonizandoAudio
                      : hasDenom
                      ? l10n.enVivoConDenominacion(denominacion, frecuencia)
                      : l10n.enVivoFrecuencia(frecuencia),
                  style: TextStyle(
                    color: subtitleCol,
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: isBuffering ? null : onPlayPause,
            child: Container(
              padding: EdgeInsetsDirectional.all(screenWidth * 0.024),
              decoration: BoxDecoration(
                color: _EmisorasScreenState.amarilloOro,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: _EmisorasScreenState.amarilloOro.withValues(
                      alpha: 0.35,
                    ),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isBuffering
                  ? SizedBox(
                      width: screenWidth * 0.055,
                      height: screenWidth * 0.055,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: screenWidth * 0.065,
                    ),
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          IconButton(
            onPressed: onStop,
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
              size: screenWidth * 0.06,
            ),
          ),
        ],
      ),
    );
  }
}
