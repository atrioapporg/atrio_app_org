import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import 'iglesias_en_mapa_screen.dart';

class ExplorarScreen extends StatefulWidget {
  const ExplorarScreen({super.key});

  @override
  State<ExplorarScreen> createState() => _ExplorarScreenState();
}

class _ExplorarScreenState extends State<ExplorarScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilterIndex = 0;

  bool _isLoading = true;
  String? _errorMessage;
  Position? _currentPosition;
  List<Map<String, dynamic>> _iglesiasSugeridas = [];

  static const String _googleApiKey = "AIzaSyCwoPsfxubfarcNOomfPDeun9Lu-zj21Ec";

  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFEFEFEF);

  final List<String> _filtros = [
    'Católica',
    'Evangélica',
    'Pentecostal',
    'Bautista',
    'Adventista',
  ];

  String _getFiltroLabel(int index, AppLocalizations? l10n) {
    switch (index) {
      case 0:
        return l10n?.catolica ?? _filtros[0];
      case 1:
        return l10n?.evangelica ?? _filtros[1];
      case 2:
        return l10n?.pentecostal ?? _filtros[2];
      case 3:
        return l10n?.bautista ?? _filtros[3];
      case 4:
        return l10n?.adventista ?? _filtros[4];
      default:
        return _filtros[index];
    }
  }

  final List<Color> _brandColors = const [
    Color(0xFF0055A5),
    Color(0xFF4A7C59),
    Color(0xFFE5A023),
    Color(0xFF2B7A78),
  ];
  //
  Future<void> _abrirNavegacion(LatLng latLng, String nombre) async {
    final double lat = latLng.latitude;
    final double lng = latLng.longitude;

    // Esquema universal nativo para abrir Google Maps, Waze, etc.
    final Uri uriNativa = Uri.parse(
      'geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(nombre)})',
    );

    // Respaldo web directo si no hay app de mapas disponible
    final Uri uriWeb = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    try {
      if (await canLaunchUrl(uriNativa)) {
        await launchUrl(uriNativa, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(uriWeb)) {
        await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.noSePudoAbrirNavegacion ??
                  'No se pudo abrir la navegación.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error abriendo mapa: $e');
    }
  }
  //

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _obtenerUbicacionYBuscar();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 1. Obtener la ubicación con alta precisión
  Future<void> _obtenerUbicacionYBuscar() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final l10n = mounted ? AppLocalizations.of(context) : null;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          l10n?.gpsDesactivado ??
              'El GPS está desactivado. Por favor, enciéndelo.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(
            l10n?.permisosUbicacionDenegados ??
                'Permisos de ubicación denegados.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          l10n?.permisosUbicacionPermanentemente ?? 'Permisos de ubicación denegados permanentemente en tu dispositivo.',
        );
      }

      // Solicitamos alta precisión para evitar coordenadas nulas o en caché
      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await _buscarIglesiasEnRadio('iglesia');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _buscarIglesiasEnRadio(String query) async {
    final l10n = mounted ? AppLocalizations.of(context) : null;
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.obteniendoUbicacionEspera ??
                'Obteniendo tu ubicación, por favor intenta en un momento...',
          ),
        ),
      );
      return;
    }

    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final uri = Uri.parse('https://places.googleapis.com/v1/places:searchText');

    // Usamos locationBias (soportado por Google) y filtraremos los 10km en la app
    final body = jsonEncode({
      "textQuery": query,
      "includedType": "church",
      "languageCode": "es",
      "locationBias": {
        "circle": {
          "center": {
            "latitude": _currentPosition!.latitude,
            "longitude": _currentPosition!.longitude,
          },
          "radius": 5000.0,
        },
      },
    });

    const fieldMask =
        'places.id,places.displayName,places.formattedAddress,'
        'places.location,places.rating,places.userRatingCount';

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _googleApiKey,
          'X-Goog-FieldMask': fieldMask,
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List resultados = data['places'] ?? [];

        final List<Map<String, dynamic>> nuevasIglesias = [];
        int colorIndex = 0;

        for (var place in resultados) {
          final location = place['location'];
          if (location == null) continue;

          final double placeLat = (location['latitude'] as num).toDouble();
          final double placeLng = (location['longitude'] as num).toDouble();

          final double distanceInMeters = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            placeLat,
            placeLng,
          );

          // FILTRO ESTRICTO: Solo agregamos a la lista si la distancia real es menor o igual a 10 km
          if (distanceInMeters <= 10000.0) {
            final distanciaKm = (distanceInMeters / 1000).toStringAsFixed(1);
            nuevasIglesias.add({
              'id': place['id'],
              'nombre':
                  place['displayName']?['text'] ??
                  (l10n?.sinNombre ?? 'Sin nombre'),
              'denominacion':
                  (place['formattedAddress'] as String?)?.split(',').first ??
                  (l10n?.comunidadCristiana ?? 'Comunidad cristiana'),
              'rating': (place['rating'] ?? 0.0).toString(),
              'distanciaNum': distanceInMeters / 1000,
              'distanciaKm': distanciaKm,
              'distancia': 'A $distanciaKm km',
              'color': _brandColors[colorIndex % _brandColors.length],
              'latLng': LatLng(placeLat, placeLng),
            });
            colorIndex++;
          }
        }

        // Ordenamos las iglesias desde la más cercana a la más lejana
        nuevasIglesias.sort(
          (a, b) => (a['distanciaNum'] as double).compareTo(
            b['distanciaNum'] as double,
          ),
        );

        if (mounted) {
          setState(() {
            _iglesiasSugeridas = nuevasIglesias;
            _isLoading = false;
          });
        }
      } else {
        // Ahora capturamos el mensaje de error real del servidor de Google
        throw Exception('Código ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        final l10nCatch = AppLocalizations.of(context);
        setState(() {
          _errorMessage = l10nCatch?.errorCargarMapa ?? '😕 ¡Ups! No se pudo cargar el Mapa\n\n📡 Revisa tu conexión a internet e inténtalo de nuevo';
          _isLoading = false;
          debugPrint(e.toString());
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final usableHeight = MediaQuery.sizeOf(context).height - safeAreaTop;

    return Column(
      children: [
        // Encabezado
        Container(
          width: screenWidth,
          padding: EdgeInsets.fromLTRB(
            screenWidth * 0.05,
            usableHeight * 0.01,
            screenWidth * 0.05,
            usableHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.explorar ?? 'Explorar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.068,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: usableHeight * 0.004),
              Text(
                l10n?.encuentraTuFeEn10Km ?? 'Encuentra tu Fe ideal en 10 km',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: screenWidth * 0.045,
                ),
              ),
            ],
          ),
        ),

        // Contenedor blanco con scroll
        Expanded(
          child: Container(
            width: screenWidth,
            decoration: const BoxDecoration(
              color: blancoFondo,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: usableHeight * 0.025,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Buscador
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.035,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.035,
                        ),
                        border: Border.all(color: grisBorde),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: Colors.grey.shade500,
                            size: screenWidth * 0.05,
                          ),
                          SizedBox(width: screenWidth * 0.025),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: (value) {
                                if (value.isNotEmpty) {
                                  _buscarIglesiasEnRadio(value);
                                }
                              },
                              decoration: InputDecoration(
                                hintText:
                                    l10n?.buscarIglesiasPlaceholder ??
                                    'Ej. Iglesia cristiana, Bautista...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: screenWidth * 0.036,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: usableHeight * 0.016,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.02),

                    // Filtros Horizontales
                    SizedBox(
                      height: usableHeight * 0.045,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _filtros.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(width: screenWidth * 0.025),
                        itemBuilder: (context, index) {
                          final isSelected = _selectedFilterIndex == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedFilterIndex = index;
                                final String termino = 'iglesia';
                                _searchController.text = termino;
                                _buscarIglesiasEnRadio(termino);
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? azulFondo : Colors.white,
                                borderRadius: BorderRadius.circular(
                                  screenWidth * 0.05,
                                ),
                                border: Border.all(
                                  color: isSelected ? azulFondo : grisBorde,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _getFiltroLabel(index, l10n),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : azulFondo,
                                    fontSize: screenWidth * 0.032,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.025),

                    // Banner de navegación al mapa general
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        context,
                        IglesiasEnMapaScreen.routeName,
                      ),
                      child: Container(
                        width: screenWidth,
                        padding: EdgeInsets.all(screenWidth * 0.045),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.04,
                          ),
                          gradient: const LinearGradient(
                            colors: [azulFondo, Color(0xFF1B4965)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(screenWidth * 0.025),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.map_outlined,
                                color: amarilloOro,
                                size: screenWidth * 0.07,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.035),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n?.visualizaIglesiasEnMapa ??
                                        'Visualiza las iglesias en el Mapa',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.055,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                              size: screenWidth * 0.06,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.03),

                    // Título de Sección
                    Text(
                      l10n?.comunidadesSugeridas ?? 'Comunidades sugeridas',
                      style: TextStyle(
                        color: azulFondo,
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.015),

                    // Estado dinámico: Carga / Error / Resultados
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: CircularProgressIndicator(color: amarilloOro),
                        ),
                      )
                    else if (_errorMessage != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Column(
                            children: [
                              Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 15),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: amarilloOro,
                                ),
                                onPressed: _obtenerUbicacionYBuscar,
                                child: Text(
                                  l10n?.reintentar ?? 'Reintentar',
                                  style: const TextStyle(
                                    color: azulFondo,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_iglesiasSugeridas.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30.0),
                          child: Text(
                            l10n?.noSeEncontraronIglesias10km ??
                                'No se encontraron iglesias a menos de 10 km.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: screenWidth * 0.035,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ..._iglesiasSugeridas.map(
                        (iglesia) => Padding(
                          padding: EdgeInsets.only(
                            bottom: usableHeight * 0.015,
                          ),
                          child: _buildChurchTile(
                            context: context,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            nombre: iglesia['nombre'],
                            denominacion: iglesia['denominacion'],
                            distancia:
                                l10n?.aDistanciaKm(
                                  iglesia['distanciaKm'] ??
                                      iglesia['distancia'] ??
                                      '',
                                ) ??
                                (iglesia['distancia'] ?? ''),
                            rating: iglesia['rating'],
                            color: iglesia['color'],
                            latLng:
                                iglesia['latLng']
                                    as LatLng, // <--- Envío de coordenadas
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  //
  Widget _buildChurchTile({
    required BuildContext context,
    required double screenWidth,
    required double usableHeight,
    required String nombre,
    required String denominacion,
    required String distancia,
    required String rating,
    required Color color,
    required LatLng latLng, // <--- Coordenadas añadidas
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
        border: Border.all(color: grisBorde),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          onTap: () => _abrirNavegacion(latLng, nombre), // <--- Acción al tocar
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.035),
            child: Row(
              children: [
                Container(
                  width: screenWidth * 0.12,
                  height: screenWidth * 0.20,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  child: Icon(
                    Icons.church_outlined,
                    color: color,
                    size: screenWidth * 0.085,
                  ),
                ),
                SizedBox(width: screenWidth * 0.035),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.055,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: usableHeight * 0.003),
                      Text(
                        denominacion,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: screenWidth * 0.031,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: usableHeight * 0.005),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: amarilloOro,
                            size: screenWidth * 0.035,
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Text(
                            rating,
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.03,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' · $distancia',
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: screenWidth * 0.045,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  //
}
