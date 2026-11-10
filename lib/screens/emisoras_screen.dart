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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../data/atrio_database_helper.dart';
import '../l10n/app_localizations.dart';
import '../modelos/emisora_model.dart';
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
  String _idiomaSeleccionado = 'TODOS';
  List<String> _paisesDisponibles = <String>['TODOS'];

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

  void _aplicarCatalogoEnEstado(List<EmisoraModel> catalogo) {
    setState(() {
      _todasEmisoras = catalogo;
      _paisesDisponibles = List<String>.from(
        _cachePaisesDisponibles ?? const <String>['TODOS'],
      );
      if (!_paisesDisponibles.contains(_paisSeleccionado)) {
        _paisSeleccionado = 'TODOS';
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
      _recalcularEmisorasFiltradas(resetPaginacion: true);
    });
  }

  void _cambiarIdioma(String nuevoIdioma) {
    if (_idiomaSeleccionado == nuevoIdioma) return;
    setState(() {
      _idiomaSeleccionado = nuevoIdioma;
      _recalcularEmisorasFiltradas(resetPaginacion: true);
    });
  }

  void _toggleFiltroSoloFavoritos() {
    setState(() {
      _mostrarSoloFavoritos = !_mostrarSoloFavoritos;
      _recalcularEmisorasFiltradas(resetPaginacion: true);
    });
  }

  void _desactivarFiltroSoloFavoritos() {
    if (!_mostrarSoloFavoritos) return;
    setState(() {
      _mostrarSoloFavoritos = false;
      _recalcularEmisorasFiltradas(resetPaginacion: true);
    });
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
    final Size size = MediaQuery.sizeOf(context);
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    final double screenWidth = size.width;
    final double screenHeight = size.height;
    final double safeAreaTop = padding.top;
    final double safeAreaBottom = padding.bottom;
    final double usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

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
        backgroundColor: azulFondo,
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
                  mostrandoBuscador: _mostrandoBuscador,
                  searchController: _searchController,
                  onBackTap: _manejarRetroceso,
                  onToggleSearch: _toggleBuscador,
                  onQueryChanged: _onSearchQueryChanged,
                ),
                Expanded(
                  child: Container(
                    width: screenWidth,
                    decoration: BoxDecoration(
                      color: blancoFondo,
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
                            paisesDisponibles: _paisesDisponibles,
                            paisSeleccionado: _paisSeleccionado,
                            mostrarSoloFavoritos: _mostrarSoloFavoritos,
                            onPaisChanged: _cambiarPais,
                            onToggleFavoritos: _toggleFiltroSoloFavoritos,
                          ),
                          _EmisorasSelectorIdioma(
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            idiomaSeleccionado: _idiomaSeleccionado,
                            onIdiomaSelected: _cambiarIdioma,
                          ),
                          SizedBox(height: usableHeight * 0.015),
                          if (_mostrarSoloFavoritos)
                            _EmisorasBannerFavoritos(
                              screenWidth: screenWidth,
                              usableHeight: usableHeight,
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
                                    mostrarSoloFavoritos: _mostrarSoloFavoritos,
                                    paisSeleccionado: _paisSeleccionado,
                                    filtroBusqueda: _filtroBusqueda,
                                    onVerTodas: _desactivarFiltroSoloFavoritos,
                                  )
                                : RefreshIndicator(
                                    color: amarilloOro,
                                    backgroundColor: Colors.white,
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
  final bool mostrandoBuscador;
  final TextEditingController searchController;
  final VoidCallback onBackTap;
  final VoidCallback onToggleSearch;
  final ValueChanged<String> onQueryChanged;

  const _EmisorasHeader({
    required this.screenWidth,
    required this.usableHeight,
    required this.mostrandoBuscador,
    required this.searchController,
    required this.onBackTap,
    required this.onToggleSearch,
    required this.onQueryChanged,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              GestureDetector(
                onTap: onBackTap,
                child: Container(
                  padding: EdgeInsetsDirectional.all(screenWidth * 0.02),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white,
                    size: screenWidth * 0.07,
                  ),
                ),
              ),
              Text(
                l10n.emisorasCristianas,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: onToggleSearch,
                icon: Icon(
                  mostrandoBuscador
                      ? Icons.close_rounded
                      : Icons.search_rounded,
                  color: Colors.white,
                  size: screenWidth * 0.07,
                ),
              ),
            ],
          ),
          if (mostrandoBuscador) ...<Widget>[
            SizedBox(height: usableHeight * 0.012),
            Container(
              height: usableHeight * 0.055,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
              ),
              child: TextField(
                controller: searchController,
                autofocus: true,
                onChanged: onQueryChanged,
                style: TextStyle(
                  color: _EmisorasScreenState.azulFondo,
                  fontSize: screenWidth * 0.04,
                ),
                decoration: InputDecoration(
                  hintText: l10n.buscarEmisorasPlaceholder,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: screenWidth * 0.035,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade600,
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
  final List<String> paisesDisponibles;
  final String paisSeleccionado;
  final bool mostrarSoloFavoritos;
  final ValueChanged<String> onPaisChanged;
  final VoidCallback onToggleFavoritos;

  const _EmisorasFiltrosSuperiores({
    required this.screenWidth,
    required this.usableHeight,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.035),
                border: Border.all(color: _EmisorasScreenState.grisBorde),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
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
                    color: _EmisorasScreenState.azulFondo,
                    size: screenWidth * 0.06,
                  ),
                  dropdownColor: Colors.white,
                  style: TextStyle(
                    color: _EmisorasScreenState.azulFondo,
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
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: mostrarSoloFavoritos
                      ? _EmisorasScreenState.amarilloOro
                      : _EmisorasScreenState.grisBorde,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
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
                    ? Colors.white
                    : _EmisorasScreenState.azulFondo,
                size: screenWidth * 0.06,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmisorasSelectorIdioma extends StatelessWidget {
  final double screenWidth;
  final double usableHeight;
  final String idiomaSeleccionado;
  final ValueChanged<String> onIdiomaSelected;

  const _EmisorasSelectorIdioma({
    required this.screenWidth,
    required this.usableHeight,
    required this.idiomaSeleccionado,
    required this.onIdiomaSelected,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        screenWidth * 0.05,
        usableHeight * 0.012,
        screenWidth * 0.05,
        0,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _ChipIdiomaItem(
              id: 'TODOS',
              label: l10n.todos,
              icono: Icons.language_rounded,
              seleccionado: idiomaSeleccionado == 'TODOS',
              screenWidth: screenWidth,
              usableHeight: usableHeight,
              onTap: () => onIdiomaSelected('TODOS'),
            ),
          ),
          SizedBox(width: screenWidth * 0.025),
          Expanded(
            child: _ChipIdiomaItem(
              id: 'es',
              label: l10n.espanol,
              icono: Icons.translate_rounded,
              seleccionado: idiomaSeleccionado == 'es',
              screenWidth: screenWidth,
              usableHeight: usableHeight,
              onTap: () => onIdiomaSelected('es'),
            ),
          ),
          SizedBox(width: screenWidth * 0.025),
          Expanded(
            child: _ChipIdiomaItem(
              id: 'en',
              label: l10n.ingles,
              icono: Icons.public_rounded,
              seleccionado: idiomaSeleccionado == 'en',
              screenWidth: screenWidth,
              usableHeight: usableHeight,
              onTap: () => onIdiomaSelected('en'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipIdiomaItem extends StatelessWidget {
  final String id;
  final String label;
  final IconData icono;
  final bool seleccionado;
  final double screenWidth;
  final double usableHeight;
  final VoidCallback onTap;

  const _ChipIdiomaItem({
    required this.id,
    required this.label,
    required this.icono,
    required this.seleccionado,
    required this.screenWidth,
    required this.usableHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsetsDirectional.symmetric(
          vertical: usableHeight * 0.009,
          horizontal: screenWidth * 0.02,
        ),
        decoration: BoxDecoration(
          color: seleccionado ? _EmisorasScreenState.azulFondo : Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          border: Border.all(
            color: seleccionado
                ? _EmisorasScreenState.azulFondo
                : _EmisorasScreenState.grisBorde,
            width: seleccionado ? 1.5 : 1.0,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: seleccionado ? 0.08 : 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icono,
              color: seleccionado
                  ? _EmisorasScreenState.amarilloOro
                  : Colors.grey.shade600,
              size: screenWidth * 0.042,
            ),
            SizedBox(width: screenWidth * 0.015),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: seleccionado
                      ? Colors.white
                      : _EmisorasScreenState.azulFondo,
                  fontSize: screenWidth * 0.033,
                  fontWeight: seleccionado ? FontWeight.bold : FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmisorasBannerFavoritos extends StatelessWidget {
  final double screenWidth;
  final double usableHeight;
  final int totalMostradas;
  final VoidCallback onClearFilter;

  const _EmisorasBannerFavoritos({
    required this.screenWidth,
    required this.usableHeight,
    required this.totalMostradas,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String localeName = Localizations.localeOf(context).toString();
    final String totalFormateado = NumberFormat.decimalPattern(localeName)
        .format(totalMostradas);

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
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        border: Border.all(
          color: _EmisorasScreenState.amarilloOro.withValues(alpha: 0.5),
          width: 1.2,
        ),
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
              color: Colors.white,
              size: screenWidth * 0.04,
            ),
          ),
          SizedBox(width: screenWidth * 0.025),
          Expanded(
            child: Text(
              l10n.mostrandoSoloFavoritas(totalFormateado),
              style: TextStyle(
                color: _EmisorasScreenState.azulFondo,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                border: Border.all(color: _EmisorasScreenState.amarilloOro),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    l10n.verTodas,
                    style: TextStyle(
                      color: _EmisorasScreenState.azulFondo,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.03,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  Icon(
                    Icons.close_rounded,
                    color: _EmisorasScreenState.azulFondo,
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
    required this.screenWidth,
    required this.usableHeight,
    required this.l10n,
    required this.onTap,
    required this.onToggleFav,
  });

  @override
  Widget build(BuildContext context) {
    final String name = emisora.name;
    final String denomination = emisora.denomination.isNotEmpty
        ? emisora.denomination
        : l10n.denominacionCristiana;
    final String frequency = emisora.frequency.isNotEmpty
        ? emisora.frequency
        : l10n.frecuenciaOnline;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsetsDirectional.all(screenWidth * 0.02),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
                border: Border.all(
                  color: isPlayingThis
                      ? _EmisorasScreenState.amarilloOro
                      : _EmisorasScreenState.grisBorde,
                  width: isPlayingThis ? 2.0 : 1.0,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: AlignmentDirectional.center,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    child: _EmisoraCachedLogo(
                      logoUrl: emisora.logo,
                      frecuencia: frequency,
                      index: index,
                      size: screenWidth * 0.22,
                    ),
                  ),
                  if (isPlayingThis)
                    PositionedDirectional(
                      bottom: 0,
                      end: 0,
                      child: Container(
                        padding: EdgeInsetsDirectional.all(screenWidth * 0.01),
                        decoration: const BoxDecoration(
                          color: _EmisorasScreenState.amarilloOro,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.graphic_eq_rounded,
                          color: Colors.white,
                          size: screenWidth * 0.032,
                        ),
                      ),
                    ),
                  PositionedDirectional(
                    top: screenWidth * 0.015,
                    start: screenWidth * 0.015,
                    child: Container(
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: screenWidth * 0.018,
                        vertical: screenWidth * 0.005,
                      ),
                      decoration: BoxDecoration(
                        color: _EmisorasScreenState.azulFondo.withValues(
                          alpha: 0.85,
                        ),
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.015,
                        ),
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
                    top: screenWidth * 0.01,
                    end: screenWidth * 0.01,
                    child: GestureDetector(
                      onTap: onToggleFav,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: EdgeInsetsDirectional.all(screenWidth * 0.012),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
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
                              : Colors.grey.shade600,
                          size: screenWidth * 0.068,
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
              color: _EmisorasScreenState.azulFondo,
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            denomination.isNotEmpty &&
                    denomination != l10n.denominacionCristiana
                ? '$denomination · $frequency'
                : frequency,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade600,
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
  final double size;

  const _EmisoraCachedLogo({
    required this.logoUrl,
    required this.frecuencia,
    required this.index,
    required this.size,
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
    final Widget fallback = Icon(
      _EmisorasScreenState.obtenerIconoFallback(widget.frecuencia),
      color: _EmisorasScreenState.obtenerColorEmisora(widget.index)
          .withValues(alpha: 0.85),
      size: widget.size * 0.55,
    );

    final String url = (widget.logoUrl ?? '').trim();
    if (url.isEmpty || _loadFailed) return fallback;

    // Limitamos la decodificación de textura en VRAM al tamaño físico real de pantalla
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final int targetPx = (widget.size * dpr).round().clamp(64, 256);

    if (_cachedFile != null) {
      return Image.file(
        _cachedFile!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
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
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
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
  final bool mostrarSoloFavoritos;
  final String paisSeleccionado;
  final String filtroBusqueda;
  final VoidCallback onVerTodas;

  const _EmisorasEmptyState({
    required this.screenWidth,
    required this.usableHeight,
    required this.mostrarSoloFavoritos,
    required this.paisSeleccionado,
    required this.filtroBusqueda,
    required this.onVerTodas,
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
    } else {
      iconoVacio = Icons.radio_outlined;
      final String nombrePais = _EmisorasScreenState.obtenerNombrePais(
        paisSeleccionado,
        l10n,
      );
      mensajeVacio = l10n.noEmisorasDisponiblesPais(nombrePais);
    }

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
                  : Colors.grey.shade400,
            ),
            SizedBox(height: usableHeight * 0.015),
            Text(
              mensajeVacio,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: screenWidth * 0.038,
                height: 1.3,
              ),
            ),
            if (mostrarSoloFavoritos) ...<Widget>[
              SizedBox(height: usableHeight * 0.02),
              TextButton.icon(
                onPressed: onVerTodas,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: _EmisorasScreenState.azulFondo,
                ),
                label: Text(
                  l10n.verTodasLasEmisoras,
                  style: const TextStyle(
                    color: _EmisorasScreenState.azulFondo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    side: const BorderSide(
                      color: _EmisorasScreenState.grisBorde,
                    ),
                  ),
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: usableHeight * 0.012,
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

class _EmisorasMiniPlayer extends StatelessWidget {
  final EmisoraModel emisora;
  final bool isPlaying;
  final bool isBuffering;
  final double screenWidth;
  final double usableHeight;
  final double safeAreaBottom;
  final VoidCallback onPlayPause;
  final VoidCallback onStop;

  const _EmisorasMiniPlayer({
    required this.emisora,
    required this.isPlaying,
    required this.isBuffering,
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
    final String denominacion = emisora.denomination.isNotEmpty
        ? emisora.denomination
        : l10n.denominacionCristiana;
    final String frecuencia = emisora.frequency.isNotEmpty
        ? emisora.frequency
        : l10n.frecuenciaOnline;

    return Container(
      width: screenWidth,
      padding: EdgeInsetsDirectional.only(
        bottom: safeAreaBottom > 0 ? safeAreaBottom : usableHeight * 0.015,
        top: usableHeight * 0.014,
        start: screenWidth * 0.04,
        end: screenWidth * 0.04,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1F5),
        border: const Border(
          top: BorderSide(color: _EmisorasScreenState.grisBorde),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: screenWidth * 0.12,
            height: screenWidth * 0.12,
            padding: EdgeInsetsDirectional.all(screenWidth * 0.012),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              border: Border.all(color: _EmisorasScreenState.grisBorde),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
              child: _EmisoraCachedLogo(
                logoUrl: emisora.logo,
                frecuencia: frecuencia,
                index: 0,
                size: screenWidth * 0.12,
              ),
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
                    color: _EmisorasScreenState.azulFondo,
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isBuffering
                      ? l10n.sintonizandoAudio
                      : denominacion.isNotEmpty &&
                            denominacion != l10n.denominacionCristiana
                      ? l10n.enVivoConDenominacion(denominacion, frecuencia)
                      : l10n.enVivoFrecuencia(frecuencia),
                  style: TextStyle(
                    color: isBuffering
                        ? _EmisorasScreenState.amarilloOro
                        : Colors.grey.shade700,
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
              decoration: const BoxDecoration(
                color: _EmisorasScreenState.amarilloOro,
                shape: BoxShape.circle,
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
              color: Colors.grey.shade600,
              size: screenWidth * 0.06,
            ),
          ),
        ],
      ),
    );
  }
}
