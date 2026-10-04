// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../servicios/connectivity_service.dart';

class EmisorasCristianasScreen extends StatefulWidget {
  static const routeName = 'emisoras_cristianas_screen';
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

  final TextEditingController _searchController = TextEditingController();
  bool _mostrandoBuscador = false;
  String _filtroBusqueda = '';

  // Filtro activo por denominación ('Todas' por defecto)
  int _tabSeleccionado = 0;
  List<String> _tabsDenominaciones = ['Todas', 'Favoritas'];

  bool _isLoadingJson = true;
  List<Map<String, dynamic>> _todasEmisoras = [];
  final Set<String> _favoritosIds = {};

  final AudioPlayer _audioPlayer = AudioPlayer();
  Map<String, dynamic>? _emisoraActual;
  bool _isReproduciendo = false;
  bool _isBuffering = false;

  static const List<Color> _paletaIconos = [
    Color(0xFFE53935),
    Color(0xFF4CAF50),
    Color(0xFF29B6F6),
    Color(0xFFFF9800),
    Color(0xFFAB47BC),
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFFEC407A),
  ];

  @override
  void initState() {
    super.initState();
    _cargarEmisorasJson();
    _iniciarListenerDeAudio();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _iniciarListenerDeAudio() {
    _audioPlayer.playerStateStream.listen((state) {
      debugPrint(
        '[RADIO_LOG] Estado interno: ${state.processingState.name} | Reproduciendo: ${state.playing}',
      );
      if (mounted) {
        setState(() {
          _isBuffering =
              state.processingState == ProcessingState.loading ||
              state.processingState == ProcessingState.buffering;
          _isReproduciendo = state.playing;
        });
      }
    });

    _audioPlayer.playbackEventStream.listen(
      (event) {},
      onError: (Object e, StackTrace stackTrace) {
        debugPrint('[RADIO_ERROR] Error de streaming: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFFC0392B),
              content: Text(
                'Error: La emisora no está disponible en este momento.',
              ),
            ),
          );
          setState(() {
            _isBuffering = false;
            _isReproduciendo = false;
          });
        }
      },
    );
  }

  Future<void> _cargarEmisorasJson() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/json/emisoras_rd.json',
      );
      final List<dynamic> data = json.decode(jsonString);
      if (mounted) {
        final List<Map<String, dynamic>> parsedList = data
            .where((e) => e['isActive'] == true)
            .map((e) {
              return {
                'id': e['id'] ?? '',
                'name': e['name'] ?? '',
                'frequency': e['frequency'] ?? 'Online',
                'city': e['city'] ?? '',
                'region': e['region'] ?? '',
                'streamUrl': e['streamUrl'] ?? '',
                'logo': e['logo'] ?? '',
                'denomination': (e['denomination'] ?? '').toString().trim(),
                'description': e['description'] ?? '',
                'tags': List<String>.from(e['tags'] ?? []),
                'priority': e['priority'] ?? 3,
              };
            })
            .toList();

        // Extraer denominaciones únicas para generar las pestañas dinámicamente
        final Set<String> denominacionesSet = {};
        for (var e in parsedList) {
          final String denom = e['denomination'];
          if (denom.isNotEmpty) {
            denominacionesSet.add(denom);
          }
        }

        final List<String> ordenadas = denominacionesSet.toList()..sort();

        setState(() {
          _todasEmisoras = parsedList;
          _tabsDenominaciones = ['Todas', ...ordenadas, 'Favoritas'];
          _isLoadingJson = false;
        });
      }
    } catch (e) {
      debugPrint('[RADIO_ERROR] Error al cargar JSON: $e');
      if (mounted) setState(() => _isLoadingJson = false);
    }
  }

  Future<void> _reproducirEmisora(
    Map<String, dynamic> emisora,
    double screenWidth,
  ) async {
    final tieneInternet = await ConnectivityService.instance.hasRealInternet();
    if (!tieneInternet) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFC0392B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          content: Row(
            children: [
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

    setState(() {
      _emisoraActual = emisora;
    });

    debugPrint(
      '[RADIO_LOG] ▶️ Conectando: ${emisora['name']} (${emisora['denomination']}) -> ${emisora['streamUrl']}',
    );

    try {
      await _audioPlayer.stop();
      await _audioPlayer.setUrl(emisora['streamUrl']);
      _audioPlayer.play();
    } catch (e) {
      debugPrint('[RADIO_ERROR] Falló conexión: $e');
    }
  }

  void _togglePlayPause() {
    if (_audioPlayer.playing) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  void _toggleFavorito(String id) {
    setState(() {
      if (_favoritosIds.contains(id)) {
        _favoritosIds.remove(id);
      } else {
        _favoritosIds.add(id);
      }
    });
  }

  IconData _obtenerIconoFallback(String frecuencia) {
    if (frecuencia.toLowerCase().contains('online'))
      return Icons.wifi_tethering_rounded;
    if (frecuencia.contains('AM')) return Icons.speaker_rounded;
    return Icons.radio_rounded;
  }

  Color _obtenerColorEmisora(int index) {
    return _paletaIconos[index % _paletaIconos.length];
  }

  Widget _buildLogoWidget({
    required String? logoUrl,
    required String frecuencia,
    required int index,
    required double size,
  }) {
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
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
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            _obtenerIconoFallback(frecuencia),
            color: _obtenerColorEmisora(index).withOpacity(0.85),
            size: size * 0.55,
          );
        },
      );
    }

    return Icon(
      _obtenerIconoFallback(frecuencia),
      color: _obtenerColorEmisora(index).withOpacity(0.85),
      size: size * 0.55,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    final String tabActual =
        _tabsDenominaciones.isNotEmpty &&
            _tabSeleccionado < _tabsDenominaciones.length
        ? _tabsDenominaciones[_tabSeleccionado]
        : 'Todas';

    // Filtrado exclusivo por Denominación + Búsqueda
    final List<Map<String, dynamic>> emisorasFiltradas = _todasEmisoras.where((
      e,
    ) {
      // 1. Filtro por Denominación de Iglesia
      bool pasaDenominacion = false;
      if (tabActual == 'Todas') {
        pasaDenominacion = true;
      } else if (tabActual == 'Favoritas') {
        pasaDenominacion = _favoritosIds.contains(e['id']);
      } else {
        pasaDenominacion = e['denomination'] == tabActual;
      }

      if (!pasaDenominacion) return false;

      // 2. Filtro por caja de texto
      final query = _filtroBusqueda.toLowerCase().trim();
      if (query.isEmpty) return true;

      return e['name'].toString().toLowerCase().contains(query) ||
          e['denomination'].toString().toLowerCase().contains(query) ||
          e['city'].toString().toLowerCase().contains(query) ||
          e['region'].toString().toLowerCase().contains(query) ||
          (e['tags'] as List<String>).any(
            (tag) => tag.toLowerCase().contains(query),
          );
    }).toList();

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: false,
        child: SizedBox(
          width: screenWidth,
          height: screenHeight - safeAreaTop,
          child: Column(
            children: [
              // ENCABEZADO
              Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: usableHeight * 0.015,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                            fontSize: screenWidth * 0.050,
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
                    if (_mostrandoBuscador) ...[
                      SizedBox(height: usableHeight * 0.012),
                      Container(
                        height: usableHeight * 0.055,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.03,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: (val) =>
                              setState(() => _filtroBusqueda = val),
                          style: TextStyle(
                            color: azulFondo,
                            fontSize: screenWidth * 0.04,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Buscar por nombre, denominación, ciudad...',
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
              ),

              // CONTENEDOR BLANCO
              Expanded(
                child: Container(
                  width: screenWidth,
                  decoration: BoxDecoration(
                    color: blancoFondo,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.08),
                      topRight: Radius.circular(screenWidth * 0.08),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.08),
                      topRight: Radius.circular(screenWidth * 0.08),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: usableHeight * 0.02),

                        // PESTAÑAS EXCLUSIVAS DE DENOMINACIÓN
                        SizedBox(
                          height: usableHeight * 0.045,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05,
                            ),
                            itemCount: _tabsDenominaciones.length,
                            itemBuilder: (context, index) {
                              final bool isSelected = _tabSeleccionado == index;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _tabSeleccionado = index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: EdgeInsets.only(
                                    right: screenWidth * 0.025,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.045,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? azulFondo
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(
                                      screenWidth * 0.05,
                                    ),
                                    border: Border.all(
                                      color: isSelected ? azulFondo : grisBorde,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _tabsDenominaciones[index],
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: screenWidth * 0.033,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: usableHeight * 0.018),

                        // CUADRÍCULA DE EMISORAS
                        Expanded(
                          child: _isLoadingJson
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: amarilloOro,
                                  ),
                                )
                              : emisorasFiltradas.isEmpty
                              ? Center(
                                  child: Text(
                                    tabActual == 'Favoritas'
                                        ? 'Aún no tienes emisoras favoritas guardadas.'
                                        : 'No hay emisoras en esta denominación.',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: screenWidth * 0.038,
                                    ),
                                  ),
                                )
                              : GridView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding: EdgeInsets.fromLTRB(
                                    screenWidth * 0.05,
                                    0,
                                    screenWidth * 0.05,
                                    _emisoraActual != null
                                        ? usableHeight * 0.02
                                        : usableHeight * 0.05,
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: screenWidth * 0.035,
                                        mainAxisSpacing: screenWidth * 0.035,
                                        childAspectRatio: 0.69,
                                      ),
                                  itemCount: emisorasFiltradas.length,
                                  itemBuilder: (context, index) {
                                    final emisora = emisorasFiltradas[index];
                                    final bool isPlayingThis =
                                        _emisoraActual?['id'] ==
                                            emisora['id'] &&
                                        _isReproduciendo;
                                    final bool isFav = _favoritosIds.contains(
                                      emisora['id'],
                                    );

                                    return GestureDetector(
                                      onTap: () => _reproducirEmisora(
                                        emisora,
                                        screenWidth,
                                      ),
                                      child: Column(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              width: double.infinity,
                                              padding: EdgeInsets.all(
                                                screenWidth * 0.02,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      screenWidth * 0.04,
                                                    ),
                                                border: Border.all(
                                                  color: isPlayingThis
                                                      ? amarilloOro
                                                      : grisBorde,
                                                  width: isPlayingThis
                                                      ? 2.0
                                                      : 1.0,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.03),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          screenWidth * 0.02,
                                                        ),
                                                    child: _buildLogoWidget(
                                                      logoUrl: emisora['logo'],
                                                      frecuencia:
                                                          emisora['frequency'],
                                                      index: index,
                                                      size: screenWidth * 0.22,
                                                    ),
                                                  ),
                                                  if (isPlayingThis)
                                                    Positioned(
                                                      bottom: 0,
                                                      right: 0,
                                                      child: Container(
                                                        padding: EdgeInsets.all(
                                                          screenWidth * 0.01,
                                                        ),
                                                        decoration:
                                                            const BoxDecoration(
                                                              color:
                                                                  amarilloOro,
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                        child: Icon(
                                                          Icons
                                                              .graphic_eq_rounded,
                                                          color: Colors.white,
                                                          size:
                                                              screenWidth *
                                                              0.032,
                                                        ),
                                                      ),
                                                    ),
                                                  Positioned(
                                                    top: 0,
                                                    right: 0,
                                                    child: GestureDetector(
                                                      onTap: () =>
                                                          _toggleFavorito(
                                                            emisora['id'],
                                                          ),
                                                      child: Container(
                                                        padding: EdgeInsets.all(
                                                          screenWidth * 0.01,
                                                        ),
                                                        color:
                                                            Colors.transparent,
                                                        child: Icon(
                                                          isFav
                                                              ? Icons
                                                                    .favorite_rounded
                                                              : Icons
                                                                    .favorite_border_rounded,
                                                          color: isFav
                                                              ? Colors.redAccent
                                                              : Colors
                                                                    .grey
                                                                    .shade400,
                                                          size:
                                                              screenWidth *
                                                              0.045,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: usableHeight * 0.006,
                                          ),
                                          Text(
                                            emisora['name'],
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: azulFondo,
                                              fontSize: screenWidth * 0.030,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${emisora['denomination']} · ${emisora['frequency']}',
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
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // MINIRREPRODUCTOR FLOTANTE
              if (_emisoraActual != null)
                Container(
                  width: screenWidth,
                  padding: EdgeInsets.only(
                    bottom: safeAreaBottom > 0
                        ? safeAreaBottom
                        : usableHeight * 0.015,
                    top: usableHeight * 0.014,
                    left: screenWidth * 0.04,
                    right: screenWidth * 0.04,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F1F5),
                    border: const Border(top: BorderSide(color: grisBorde)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: screenWidth * 0.12,
                        height: screenWidth * 0.12,
                        padding: EdgeInsets.all(screenWidth * 0.012),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.03,
                          ),
                          border: Border.all(color: grisBorde),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.02,
                          ),
                          child: _buildLogoWidget(
                            logoUrl: _emisoraActual!['logo'],
                            frecuencia: _emisoraActual!['frequency'],
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
                          children: [
                            Text(
                              _emisoraActual!['name'],
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
                                  : 'En vivo · ${_emisoraActual!['denomination']} (${_emisoraActual!['frequency']})',
                              style: TextStyle(
                                color: _isBuffering
                                    ? amarilloOro
                                    : Colors.grey.shade700,
                                fontSize: screenWidth * 0.030,
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
                        onPressed: () {
                          setState(() {
                            _emisoraActual = null;
                            _isReproduciendo = false;
                          });
                          _audioPlayer.stop();
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade600,
                          size: screenWidth * 0.06,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
