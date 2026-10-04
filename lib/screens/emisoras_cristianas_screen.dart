// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:async';
import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../servicios/connectivity_service.dart';

class EmisorasCristianasScreen extends StatefulWidget {
  static const String routeName = 'emisoras_cristianas_screen';
  const EmisorasCristianasScreen({super.key});

  @override
  State<EmisorasCristianasScreen> createState() =>
      _EmisorasCristianasScreenState();
}

class _EmisorasCristianasScreenState extends State<EmisorasCristianasScreen> {
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

  static const Map<String, String> _nombresPaises = <String, String>{
    'AR': 'Argentina',
    'BO': 'Bolivia',
    'BR': 'Brasil',
    'CL': 'Chile',
    'CO': 'Colombia',
    'CR': 'Costa Rica',
    'CU': 'Cuba',
    'DO': 'República Dominicana',
    'EC': 'Ecuador',
    'ES': 'España',
    'GT': 'Guatemala',
    'HN': 'Honduras',
    'MX': 'México',
    'NI': 'Nicaragua',
    'PA': 'Panamá',
    'PE': 'Perú',
    'PR': 'Puerto Rico',
    'PY': 'Paraguay',
    'SV': 'El Salvador',
    'US': 'Estados Unidos',
    'UY': 'Uruguay',
    'VE': 'Venezuela',
    'OTROS': 'Otros países',
  };

  static String _obtenerNombrePais(String codigo) {
    final String codigoUpper = codigo.toUpperCase().trim();
    if (codigoUpper == 'TODOS') return 'Todos los países';
    if (_nombresPaises.containsKey(codigoUpper)) {
      return _nombresPaises[codigoUpper]!;
    }
    if (codigo.trim().length > 3) {
      return codigo.trim();
    }
    return codigoUpper;
  }

  // Hoja: "emisoras_cristianas" (gid: 1021727370)
  static const String _sheetUrl =
      'https://docs.google.com/spreadsheets/d/12VyJ9cWJrpqWq1J3uot4I1h9g57pcHhcMYgv4G07pEE/export?format=csv&gid=1021727370';

  // Memoria caché estática para cargar UNA SOLA VEZ durante la vida de la app
  static List<Map<String, dynamic>>? _cacheEmisoras;
  static List<String>? _cachePaisesDisponibles;
  static Future<void>? _cargaEnProgreso;

  final TextEditingController _searchController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Set<String> _favoritosIds = <String>{};

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<PlaybackEvent>? _playbackEventSub;

  bool _mostrandoBuscador = false;
  String _filtroBusqueda = '';
  String _paisSeleccionado = 'TODOS';
  List<String> _paisesDisponibles = <String>['TODOS'];

  bool _isLoading = true;
  List<Map<String, dynamic>> _todasEmisoras = <Map<String, dynamic>>[];
  Map<String, dynamic>? _emisoraActual;

  bool _mostrarSoloFavoritos = false;
  bool _isReproduciendo = false;
  bool _isBuffering = false;

  @override
  void initState() {
    super.initState();
    _cargarFavoritos();
    _iniciarListenerDeAudio();

    if (_cacheEmisoras != null && _cacheEmisoras!.isNotEmpty) {
      // Ya cargadas previamente en memoria: uso instantáneo sin peticiones ni spinner
      _todasEmisoras = List<Map<String, dynamic>>.from(_cacheEmisoras!);
      _paisesDisponibles = List<String>.from(
        _cachePaisesDisponibles ?? <String>['TODOS'],
      );
      _isLoading = false;
      debugPrint(
        '[RADIO_LOG] Emisoras cargadas instantáneamente desde memoria (${_todasEmisoras.length})',
      );
    } else {
      _isLoading = true;
      _cargarEmisoras();
    }
  }

  Future<void> _cargarFavoritos() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? favs = prefs.getStringList('emisoras_favoritas');
    if (favs != null) {
      setState(() {
        _favoritosIds.addAll(favs);
      });
    }
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _playbackEventSub?.cancel();
    _searchController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ===========================================================================
  // AUDIO
  // ===========================================================================
  void _iniciarListenerDeAudio() {
    try {
      _playerStateSub = _audioPlayer.playerStateStream.listen((state) {
        if (!mounted) return;
        setState(() {
          _isBuffering =
              state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering;
          _isReproduciendo = state.playing;
        });
      });

      _playbackEventSub = _audioPlayer.playbackEventStream.listen(
        (event) {},
        onError: (Object e, StackTrace stackTrace) {
          debugPrint('[RADIO_ERROR] Error en streaming: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: rojoError,
              content: Text(
                'Error: La emisora no está disponible en este momento.',
              ),
            ),
          );
          setState(() {
            _isBuffering = false;
            _isReproduciendo = false;
          });
        },
      );
    } catch (e) {
      debugPrint('[RADIO_ERROR] Excepción listeners audio: $e');
    }
  }

  Future<void> _reproducirEmisora(
    Map<String, dynamic> emisora,
    double screenWidth,
  ) async {
    final bool tieneInternet = await ConnectivityService.instance
        .hasRealInternet();
    if (!mounted) return;

    if (!tieneInternet) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: rojoError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          content: Row(
            children: <Widget>[
              Icon(
                Icons.wifi_off_rounded,
                color: Colors.white,
                size: screenWidth * 0.06,
              ),
              SizedBox(width: screenWidth * 0.03),
              const Expanded(
                child: Text(
                  'No hay conexión a internet para sintonizar la emisora.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _emisoraActual = Map<String, dynamic>.from(emisora));

    try {
      await _audioPlayer.stop();

      final String streamUrl = (emisora['streamUrl'] ?? '').toString().trim();
      final String idStr = (emisora['id'] ?? '').toString().trim();
      final String logoUrl = (emisora['logo'] ?? '').toString().trim();

      try {
        final source = AudioSource.uri(
          Uri.parse(streamUrl),
          tag: MediaItem(
            id: idStr.isNotEmpty ? idStr : streamUrl,
            album: (emisora['denomination'] ?? 'Radio Cristiana').toString(),
            title: (emisora['name'] ?? 'Emisora').toString(),
            artUri: logoUrl.isNotEmpty ? Uri.parse(logoUrl) : null,
          ),
        );
        await _audioPlayer.setAudioSource(source);
      } catch (sourceErr) {
        debugPrint('[RADIO_LOG] Fallback a setUrl directo: $sourceErr');
        await _audioPlayer.setUrl(streamUrl);
      }

      unawaited(_audioPlayer.play());
    } catch (e) {
      debugPrint('[RADIO_ERROR] Error al reproducir stream: $e');
      if (!mounted) return;
      setState(() {
        _isBuffering = false;
        _isReproduciendo = false;
      });
    }
  }

  void _togglePlayPause() {
    try {
      if (_audioPlayer.playing) {
        _audioPlayer.pause();
      } else {
        unawaited(_audioPlayer.play());
      }
    } catch (e) {
      debugPrint('[RADIO_ERROR] Error togglePlayPause: $e');
    }
  }

  void _detenerReproduccion() {
    setState(() {
      _emisoraActual = null;
      _isReproduciendo = false;
    });
    _audioPlayer.stop();
  }

  // ===========================================================================
  // CARGA DE EMISORAS (UNA SOLA VEZ EN MEMORIA)
  // ===========================================================================
  Future<void> _cargarEmisoras({bool forzarRecarga = false}) async {
    if (!forzarRecarga &&
        _cacheEmisoras != null &&
        _cacheEmisoras!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _todasEmisoras = List<Map<String, dynamic>>.from(_cacheEmisoras!);
          _paisesDisponibles = List<String>.from(
            _cachePaisesDisponibles ?? <String>['TODOS'],
          );
          if (!_paisesDisponibles.contains(_paisSeleccionado)) {
            _paisSeleccionado = 'TODOS';
          }
          _isLoading = false;
        });
      }
      return;
    }

    if (_cargaEnProgreso != null) {
      await _cargaEnProgreso;
      if (mounted && _cacheEmisoras != null) {
        setState(() {
          _todasEmisoras = List<Map<String, dynamic>>.from(_cacheEmisoras!);
          _paisesDisponibles = List<String>.from(
            _cachePaisesDisponibles ?? <String>['TODOS'],
          );
          if (!_paisesDisponibles.contains(_paisSeleccionado)) {
            _paisSeleccionado = 'TODOS';
          }
          _isLoading = false;
        });
      }
      return;
    }

    _cargaEnProgreso = _ejecutarCargaEmisoras();
    try {
      await _cargaEnProgreso;
    } finally {
      _cargaEnProgreso = null;
    }
  }

  Future<void> _ejecutarCargaEmisoras() async {
    List<Map<String, dynamic>> resultado = <Map<String, dynamic>>[];

    try {
      debugPrint('[RADIO_LOG] Descargando desde Google Sheets con GID...');
      final response = await http
          .get(Uri.parse(_sheetUrl))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final String csvString = utf8.decode(
          response.bodyBytes,
          allowMalformed: true,
        );
        final String lowerCsv = csvString.trim().toLowerCase();

        if (lowerCsv.startsWith('<!doctype html') ||
            lowerCsv.startsWith('<html')) {
          debugPrint('[RADIO_ERROR] Google devolvió HTML. Verifica permisos.');
        } else {
          final List<List<dynamic>> filas = csv.decode(csvString);

          if (filas.length > 1) {
            final List<String> headers = filas.first
                .map((e) => e.toString().trim().toLowerCase())
                .toList();
            debugPrint('[RADIO_LOG] Cabeceras reales detectadas: $headers');

            for (int i = 1; filas.length > i; i++) {
              try {
                final List<dynamic> row = filas[i];
                final Map<String, dynamic> rowData = <String, dynamic>{};
                for (int j = 0; headers.length > j; j++) {
                  rowData[headers[j]] = (row.length > j) ? row[j] : '';
                }

                bool isActive = true;
                String activeKey = '';
                for (final String key in headers) {
                  if (key == 'isactive' ||
                      key == 'is_active' ||
                      key == 'activo' ||
                      key == 'es_activo' ||
                      key == 'estado') {
                    activeKey = key;
                    break;
                  }
                }

                if (activeKey.isNotEmpty) {
                  final String raw = rowData[activeKey]
                      .toString()
                      .toLowerCase()
                      .trim();
                  isActive = const [
                    'true',
                    '1',
                    'verdadero',
                    'si',
                    'sí',
                    'yes',
                    'activo',
                  ].contains(raw);
                }

                if (!isActive) continue;

                String rawUrl =
                    (rowData['streamurl'] ??
                            rowData['emisora_url'] ??
                            rowData['url'] ??
                            '')
                        .toString()
                        .trim();

                if (rawUrl.contains('src="')) {
                  final int inicio = rawUrl.indexOf('src="') + 5;
                  final int fin = rawUrl.indexOf('"', inicio);
                  if (fin > inicio) {
                    rawUrl = rawUrl.substring(inicio, fin);
                  }
                } else if (rawUrl.contains("src='")) {
                  final int inicio = rawUrl.indexOf("src='") + 5;
                  final int fin = rawUrl.indexOf("'", inicio);
                  if (fin > inicio) {
                    rawUrl = rawUrl.substring(inicio, fin);
                  }
                }

                final String nombre =
                    (rowData['emisora_nombre'] ??
                            rowData['name'] ??
                            rowData['nombre'] ??
                            '')
                        .toString()
                        .trim();

                if (nombre.isEmpty && rawUrl.isEmpty) continue;

                final String rawPais =
                    (rowData['pais_codigo'] ??
                            rowData['pais'] ??
                            rowData['country'] ??
                            '')
                        .toString()
                        .trim()
                        .toUpperCase();

                final String logo =
                    (rowData['emisora_poster'] ??
                            rowData['logo'] ??
                            rowData['poster'] ??
                            '')
                        .toString()
                        .trim();

                final String id =
                    (rowData['emisora_id'] ?? rowData['id'] ?? i.toString())
                        .toString()
                        .trim();

                final String paisCodigo = rawPais.isEmpty ? 'OTROS' : rawPais;
                final String paisNombre =
                    (rowData['pais'] ??
                            rowData['pais_nombre'] ??
                            rowData['country'] ??
                            '')
                        .toString()
                        .trim();

                final String nombrePaisReal = paisNombre.isNotEmpty
                    ? paisNombre
                    : _obtenerNombrePais(paisCodigo);

                resultado.add({
                  'id': id.isNotEmpty ? id : i.toString(),
                  'name': nombre,
                  'frequency': (rowData['frequency'] ?? 'Online')
                      .toString()
                      .trim(),
                  'city': (rowData['city'] ?? rowData['pais'] ?? '')
                      .toString()
                      .trim(),
                  'region': (rowData['region'] ?? '').toString().trim(),
                  'pais_codigo': paisCodigo,
                  'pais_nombre': nombrePaisReal,
                  'streamUrl': rawUrl,
                  'logo': logo,
                  'denomination':
                      (rowData['denomination'] ??
                              rowData['denominacion'] ??
                              'Cristiana')
                          .toString()
                          .trim(),
                  'description': (rowData['description'] ?? '')
                      .toString()
                      .trim(),
                  'tags': <String>[],
                  'priority': 3,
                });
              } catch (e) {
                debugPrint('[RADIO_ERROR] Error mapeando fila $i: $e');
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[RADIO_ERROR] Error HTTP al descargar hoja: $e');
    }

    if (resultado.isEmpty) {
      debugPrint('[RADIO_LOG] Intentando cargar respaldo local JSON...');
      resultado = await _cargarDesdeJsonLocal();
    } else {
      debugPrint(
        '[RADIO_LOG] ¡Éxito! Se cargaron ${resultado.length} emisoras desde Google Sheets.',
      );
    }

    final Set<String> paisesSet = <String>{};
    for (final e in resultado) {
      final String pais = (e['pais_codigo'] ?? '')
          .toString()
          .trim()
          .toUpperCase();
      if (pais.isNotEmpty) paisesSet.add(pais);
    }

    final List<String> ordenadasPaises = paisesSet.toList()
      ..sort((a, b) => _obtenerNombrePais(a).compareTo(_obtenerNombrePais(b)));

    if (resultado.isNotEmpty) {
      _cacheEmisoras = resultado;
      _cachePaisesDisponibles = <String>['TODOS'] + ordenadasPaises;
      debugPrint(
        '[RADIO_LOG] Emisoras guardadas en memoria caché: ${_cacheEmisoras!.length}',
      );
    }

    if (!mounted) return;
    setState(() {
      _todasEmisoras = resultado;
      _paisesDisponibles = <String>['TODOS'] + ordenadasPaises;
      if (!_paisesDisponibles.contains(_paisSeleccionado)) {
        _paisSeleccionado = 'TODOS';
      }
      _isLoading = false;
    });
  }

  Future<List<Map<String, dynamic>>> _cargarDesdeJsonLocal() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/json/emisoras_rd.json',
      );
      final List<dynamic> data = json.decode(jsonString) as List<dynamic>;
      final List<Map<String, dynamic>> listaParseada = <Map<String, dynamic>>[];

      for (int i = 0; data.length > i; i++) {
        final Map<String, dynamic> e = Map<String, dynamic>.from(
          data[i] as Map,
        );

        if (e['isActive'] == false) continue;

        String rawUrl = (e['streamUrl'] ?? e['emisora_url'] ?? e['url'] ?? '')
            .toString()
            .trim();

        if (rawUrl.contains("src='")) {
          final int inicio = rawUrl.indexOf("src='") + 5;
          final int fin = rawUrl.indexOf("'", inicio);
          if (fin > inicio) {
            rawUrl = rawUrl.substring(inicio, fin);
          }
        } else if (rawUrl.contains('src="')) {
          final int inicio = rawUrl.indexOf('src="') + 5;
          final int fin = rawUrl.indexOf('"', inicio);
          if (fin > inicio) {
            rawUrl = rawUrl.substring(inicio, fin);
          }
        }

        final String rawPais = (e['pais_codigo'] ?? e['pais'] ?? 'DO')
            .toString()
            .trim()
            .toUpperCase();
        final String idPais = rawPais.isEmpty ? 'DO' : rawPais;
        final String id = (e['id'] ?? e['emisora_id'] ?? i.toString())
            .toString()
            .trim();
        final String nombre =
            (e['name'] ?? e['emisora_nombre'] ?? e['nombre'] ?? '')
                .toString()
                .trim();

        if (nombre.isEmpty && rawUrl.isEmpty) continue;

        final String poster =
            (e['logo'] ?? e['emisora_poster'] ?? e['poster'] ?? '')
                .toString()
                .trim();
        final String paisNombre =
            (e['pais'] ?? e['pais_nombre'] ?? 'República Dominicana')
                .toString()
                .trim();
        final String nombrePaisReal = paisNombre.isNotEmpty
            ? paisNombre
            : _obtenerNombrePais(idPais);

        listaParseada.add({
          'id': id.isNotEmpty ? id : i.toString(),
          'name': nombre,
          'frequency': (e['frequency'] ?? 'Online').toString().trim(),
          'city': (e['city'] ?? paisNombre).toString().trim(),
          'region': (e['region'] ?? paisNombre).toString().trim(),
          'pais_codigo': idPais,
          'pais_nombre': nombrePaisReal,
          'streamUrl': rawUrl,
          'logo': poster,
          'denomination':
              (e['denomination'] ?? e['denominacion'] ?? 'Cristiana')
                  .toString()
                  .trim(),
          'description': (e['description'] ?? '').toString().trim(),
          'tags': List<String>.from(e['tags'] ?? <String>[]),
          'priority': e['priority'] ?? 3,
        });
      }

      debugPrint(
        '[RADIO_LOG] Fallback JSON local cargado con éxito. Emisoras: ${listaParseada.length}',
      );
      return listaParseada;
    } catch (e) {
      debugPrint('[RADIO_ERROR] Error al cargar fallback local: $e');
      return <Map<String, dynamic>>[];
    }
  }

  // ===========================================================================
  // FILTRADO ROBUSTO
  // ===========================================================================
  Future<void> _toggleFavorito(String id) async {
    setState(() {
      if (!_favoritosIds.remove(id)) _favoritosIds.add(id);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('emisoras_favoritas', _favoritosIds.toList());
  }

  IconData _obtenerIconoFallback(String frecuencia) {
    if (frecuencia.toLowerCase().contains('online')) {
      return Icons.wifi_tethering_rounded;
    }
    if (frecuencia.contains('AM')) return Icons.speaker_rounded;
    return Icons.radio_rounded;
  }

  Color _obtenerColorEmisora(int index) =>
      _paletaIconos[index % _paletaIconos.length];

  List<Map<String, dynamic>> _filtrarEmisoras() {
    final String query = _filtroBusqueda.toLowerCase().trim();
    final String paisFiltro = _paisSeleccionado.toUpperCase().trim();

    return _todasEmisoras.where((Map<String, dynamic> emisora) {
      // 0. FILTRO DE FAVORITOS
      if (_mostrarSoloFavoritos) {
        final String id = (emisora['id'] ?? '').toString();
        if (!_favoritosIds.contains(id)) return false;
      }

      // 1. FILTRO DE PAÍS
      if (paisFiltro != 'TODOS') {
        final String paisEmisora = (emisora['pais_codigo'] ?? '')
            .toString()
            .toUpperCase()
            .trim();
        if (paisEmisora != paisFiltro) {
          return false;
        }
      }

      // 2. BUSCADOR DE TEXTO
      if (query.isEmpty) {
        return true;
      }

      final String nombre = (emisora['name'] ?? '').toString().toLowerCase();
      final String denominacion = (emisora['denomination'] ?? '')
          .toString()
          .toLowerCase();
      final String ciudad = (emisora['city'] ?? '').toString().toLowerCase();
      final String region = (emisora['region'] ?? '').toString().toLowerCase();
      final String paisCodigo = (emisora['pais_codigo'] ?? '')
          .toString()
          .toLowerCase();
      final String paisNombre =
          (emisora['pais_nombre'] ??
                  _obtenerNombrePais(emisora['pais_codigo'] ?? ''))
              .toString()
              .toLowerCase();

      return nombre.contains(query) ||
          denominacion.contains(query) ||
          ciudad.contains(query) ||
          region.contains(query) ||
          paisCodigo.contains(query) ||
          paisNombre.contains(query);
    }).toList();
  }

  // ===========================================================================
  // WIDGETS
  // ===========================================================================
  Widget _buildCustomDropdown(double screenWidth, double usableHeight) {
    final String valorSeguro = _paisesDisponibles.contains(_paisSeleccionado)
        ? _paisSeleccionado
        : 'TODOS';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.05,
        usableHeight * 0.015,
        screenWidth * 0.05,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.035),
                border: Border.all(color: grisBorde),
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
                    color: azulFondo,
                    size: screenWidth * 0.06,
                  ),
                  dropdownColor: Colors.white,
                  style: TextStyle(
                    color: azulFondo,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.038,
                  ),
                  onChanged: (String? nuevoPais) {
                    if (nuevoPais != null) {
                      setState(() {
                        _paisSeleccionado = nuevoPais;
                      });
                      debugPrint('[RADIO_LOG] País seleccionado: $nuevoPais');
                    }
                  },
                  items: _paisesDisponibles.map<DropdownMenuItem<String>>((
                    String codigo,
                  ) {
                    final String nombrePais = _obtenerNombrePais(codigo);
                    return DropdownMenuItem<String>(
                      value: codigo,
                      child: Row(
                        children: <Widget>[
                          Icon(
                            codigo == 'TODOS'
                                ? Icons.public_rounded
                                : Icons.flag_circle_rounded,
                            color: amarilloOro,
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
            onTap: () {
              setState(() {
                _mostrarSoloFavoritos = !_mostrarSoloFavoritos;
              });
            },
            child: Container(
              padding: EdgeInsets.all(screenWidth * 0.035),
              decoration: BoxDecoration(
                color: _mostrarSoloFavoritos ? amarilloOro : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _mostrarSoloFavoritos ? amarilloOro : grisBorde,
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
                _mostrarSoloFavoritos
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _mostrarSoloFavoritos ? Colors.white : azulFondo,
                size: screenWidth * 0.06,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerFavoritos(
    double screenWidth,
    double usableHeight,
    int totalMostradas,
  ) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        screenWidth * 0.05,
        0,
        screenWidth * 0.05,
        usableHeight * 0.012,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.035,
        vertical: usableHeight * 0.01,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        border: Border.all(
          color: amarilloOro.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(screenWidth * 0.015),
            decoration: const BoxDecoration(
              color: amarilloOro,
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
              'Mostrando solo favoritas ($totalMostradas)',
              style: TextStyle(
                color: azulFondo,
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.033,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _mostrarSoloFavoritos = false;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.025,
                vertical: usableHeight * 0.006,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                border: Border.all(color: amarilloOro),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Ver todas',
                    style: TextStyle(
                      color: azulFondo,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.03,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  Icon(
                    Icons.close_rounded,
                    color: azulFondo,
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

  Widget _buildLogoWidget({
    required String? logoUrl,
    required String frecuencia,
    required int index,
    required double size,
  }) {
    final Widget fallback = Icon(
      _obtenerIconoFallback(frecuencia),
      color: _obtenerColorEmisora(index).withValues(alpha: 0.85),
      size: size * 0.55,
    );

    if (logoUrl == null || logoUrl.trim().isEmpty) return fallback;

    return Image.network(
      logoUrl,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: SizedBox(
            width: size * 0.35,
            height: size * 0.35,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: amarilloOro,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }

  Widget _buildHeader(double screenWidth, double usableHeight) {
    return Container(
      width: screenWidth,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: usableHeight * 0.015,
      ),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.white,
                  size: screenWidth * 0.085,
                ),
              ),
              Text(
                'Emisoras Cristianas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _mostrandoBuscador = !_mostrandoBuscador;
                    if (!_mostrandoBuscador) {
                      _searchController.clear();
                      _filtroBusqueda = '';
                    }
                  });
                },
                icon: Icon(
                  _mostrandoBuscador
                      ? Icons.close_rounded
                      : Icons.search_rounded,
                  color: Colors.white,
                  size: screenWidth * 0.07,
                ),
              ),
            ],
          ),
          if (_mostrandoBuscador) ...<Widget>[
            SizedBox(height: usableHeight * 0.012),
            Container(
              height: usableHeight * 0.055,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) => setState(() => _filtroBusqueda = val),
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.04,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre, denominación, ciudad...',
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
                  contentPadding: EdgeInsets.symmetric(
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

  Widget _buildEmisoraCard({
    required Map<String, dynamic> emisora,
    required int index,
    required double screenWidth,
    required double usableHeight,
  }) {
    final bool isPlayingThis =
        _emisoraActual?['id'] == emisora['id'] && _isReproduciendo;
    final String id = (emisora['id'] ?? '').toString();
    final bool isFav = _favoritosIds.contains(id);

    final String name = (emisora['name'] ?? '').toString();
    final String denomination = (emisora['denomination'] ?? 'Cristiana')
        .toString();
    final String frequency = (emisora['frequency'] ?? 'Online').toString();

    return GestureDetector(
      onTap: () => _reproducirEmisora(emisora, screenWidth),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.02),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
                border: Border.all(
                  color: isPlayingThis ? amarilloOro : grisBorde,
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
                alignment: Alignment.center,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    child: _buildLogoWidget(
                      logoUrl: emisora['logo'] as String?,
                      frecuencia: frequency,
                      index: index,
                      size: screenWidth * 0.22,
                    ),
                  ),
                  if (isPlayingThis)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.01),
                        decoration: const BoxDecoration(
                          color: amarilloOro,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.graphic_eq_rounded,
                          color: Colors.white,
                          size: screenWidth * 0.032,
                        ),
                      ),
                    ),
                  Positioned(
                    top: screenWidth * 0.01,
                    right: screenWidth * 0.01,
                    child: GestureDetector(
                      onTap: () => _toggleFavorito(id),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.012),
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
              color: azulFondo,
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            denomination.isNotEmpty && denomination != 'Cristiana'
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

  Widget _buildGrid(
    List<Map<String, dynamic>> emisoras,
    double screenWidth,
    double usableHeight,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: amarilloOro));
    }

    if (emisoras.isEmpty) {
      final String mensajeVacio;
      final IconData iconoVacio;

      if (_mostrarSoloFavoritos) {
        iconoVacio = Icons.favorite_border_rounded;
        if (_paisSeleccionado != 'TODOS') {
          final String nombrePais = _obtenerNombrePais(_paisSeleccionado);
          mensajeVacio =
              'No tienes emisoras favoritas guardadas en $nombrePais.\n\nToca el botón de corazón arriba para ver todas las emisoras.';
        } else {
          mensajeVacio = 'No tienes emisoras favoritas guardadas todavía.\n\nToca el botón de corazón arriba para ver todas las emisoras.';
        }
      } else if (_filtroBusqueda.isNotEmpty) {
        iconoVacio = Icons.search_off_rounded;
        mensajeVacio =
            'No se encontraron emisoras que coincidan con "$_filtroBusqueda".';
      } else {
        iconoVacio = Icons.radio_outlined;
        final String nombrePais = _obtenerNombrePais(_paisSeleccionado);
        mensajeVacio =
            'No se encontraron emisoras disponibles para $nombrePais.';
      }

      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                iconoVacio,
                size: screenWidth * 0.12,
                color: _mostrarSoloFavoritos
                    ? amarilloOro
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
              if (_mostrarSoloFavoritos) ...<Widget>[
                SizedBox(height: usableHeight * 0.02),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _mostrarSoloFavoritos = false;
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, color: azulFondo),
                  label: const Text(
                    'Ver todas las emisoras',
                    style: TextStyle(
                      color: azulFondo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      side: const BorderSide(color: grisBorde),
                    ),
                    padding: EdgeInsets.symmetric(
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

    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.05,
        0,
        screenWidth * 0.05,
        _emisoraActual != null ? usableHeight * 0.02 : usableHeight * 0.05,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: screenWidth * 0.035,
        mainAxisSpacing: screenWidth * 0.035,
        childAspectRatio: 0.90,
      ),
      itemCount: emisoras.length,
      itemBuilder: (context, index) => _buildEmisoraCard(
        emisora: emisoras[index],
        index: index,
        screenWidth: screenWidth,
        usableHeight: usableHeight,
      ),
    );
  }

  Widget _buildMiniPlayer(
    Map<String, dynamic> emisora,
    double screenWidth,
    double usableHeight,
    double safeAreaBottom,
  ) {
    final String nombre = (emisora['name'] ?? 'Emisora').toString();
    final String denominacion = (emisora['denomination'] ?? 'Cristiana')
        .toString();
    final String frecuencia = (emisora['frequency'] ?? 'Online').toString();

    return Container(
      width: screenWidth,
      padding: EdgeInsets.only(
        bottom: safeAreaBottom > 0 ? safeAreaBottom : usableHeight * 0.015,
        top: usableHeight * 0.014,
        left: screenWidth * 0.04,
        right: screenWidth * 0.04,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1F5),
        border: const Border(top: BorderSide(color: grisBorde)),
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
            padding: EdgeInsets.all(screenWidth * 0.012),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              border: Border.all(color: grisBorde),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
              child: _buildLogoWidget(
                logoUrl: emisora['logo'] as String?,
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
                    color: azulFondo,
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _isBuffering
                      ? 'Sintonizando audio...'
                      : denominacion.isNotEmpty && denominacion != 'Cristiana'
                      ? 'En vivo · $denominacion ($frecuencia)'
                      : 'En vivo · $frecuencia',
                  style: TextStyle(
                    color: _isBuffering ? amarilloOro : Colors.grey.shade700,
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
            onTap: _isBuffering ? null : _togglePlayPause,
            child: Container(
              padding: EdgeInsets.all(screenWidth * 0.024),
              decoration: const BoxDecoration(
                color: amarilloOro,
                shape: BoxShape.circle,
              ),
              child: _isBuffering
                  ? SizedBox(
                      width: screenWidth * 0.055,
                      height: screenWidth * 0.055,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isReproduciendo
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: screenWidth * 0.065,
                    ),
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          IconButton(
            onPressed: _detenerReproduccion,
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

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final EdgeInsets padding = MediaQuery.paddingOf(context);
    final double screenWidth = size.width;
    final double screenHeight = size.height;
    final double safeAreaTop = padding.top;
    final double safeAreaBottom = padding.bottom;
    final double usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    final List<Map<String, dynamic>> emisorasFiltradas = _filtrarEmisoras();
    final Map<String, dynamic>? actual = _emisoraActual;

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: false,
        child: SizedBox(
          width: screenWidth,
          height: screenHeight - safeAreaTop,
          child: Column(
            children: <Widget>[
              _buildHeader(screenWidth, usableHeight),
              // CONTENEDOR BLANCO CON LISTADO
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
                        // FILTRO POR PAÍS Y BOTÓN DE FAVORITOS
                        _buildCustomDropdown(screenWidth, usableHeight),
                        SizedBox(height: usableHeight * 0.015),
                        // BANNER INDICADOR DE FAVORITOS
                        if (_mostrarSoloFavoritos)
                          _buildBannerFavoritos(
                            screenWidth,
                            usableHeight,
                            emisorasFiltradas.length,
                          ),
                        // CUADRÍCULA DE EMISORAS
                        Expanded(
                          child: _buildGrid(
                            emisorasFiltradas,
                            screenWidth,
                            usableHeight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // MINIRREPRODUCTOR
              if (actual != null)
                _buildMiniPlayer(
                  actual,
                  screenWidth,
                  usableHeight,
                  safeAreaBottom,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
