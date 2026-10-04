import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class IglesiasEnMapaScreen extends StatefulWidget {
  static const routeName = 'iglesias_en_mapa_screen';
  const IglesiasEnMapaScreen({super.key});

  @override
  State createState() => _IglesiasEnMapaScreenState();
}

class _IglesiasEnMapaScreenState extends State {
  final TextEditingController _searchController = TextEditingController();
  bool _estaBuscando = false;
  bool _isInit = true;
  bool _permisoUbicacionConcedido = false;
  GoogleMapController? _mapController;
  Map<String, dynamic>? _iglesiaSeleccionada;
  List<Map<String, dynamic>> _iglesiasData = [];
  Position? _currentPosition;

  final String _googleApiKey = "AIzaSyCwoPsfxubfarcNOomfPDeun9Lu-zj21Ec";

  static const Map<String, List<String>> _terminosPorTradicion = {
    'catolica': [
      'Iglesia católica',
      'Parroquia',
      'Capilla',
      'Catedral',
      'Basílica',
      'Santuario',
      'Horarios de misa',
      'Misa dominical',
      'Virgen de la Altagracia',
    ],
    'evangelica': [
      'Iglesia evangélica',
      'Iglesia cristiana',
      'Templo evangélico',
      'Ministerio',
      'Concilio',
      'Culto',
      'Iglesia de Dios',
      'Asambleas de Dios',
    ],
    'pentecostal': [
      'Iglesia pentecostal',
      'Templo pentecostal',
      'Asambleas de Dios',
      'Iglesia de Dios',
      'Culto pentecostal',
      'Ministerio pentecostal',
    ],
    'bautista': [
      'Iglesia bautista',
      'Templo bautista',
      'Iglesia bíblica',
      'Comunidad bautista',
    ],
    'adventista': [
      'Iglesia adventista',
      'Adventista del Séptimo Día',
      'Templo adventista',
      'Iglesia ASD',
    ],
    'ortodoxa': ['Iglesia ortodoxa', 'Parroquia ortodoxa', 'Catedral ortodoxa'],
    'no_denominacional': [
      'Iglesia cristiana',
      'Comunidad cristiana',
      'Iglesia independiente',
      'Ministerio cristiano',
      'Centro cristiano',
    ],
    'otra': [
      'Católica',
      'Evangélica',
      'Pentecostal',
      'Bautista',
      'Adventista',
      'Ortodoxa',
    ],
  };

  List<String> _sugerenciasBusqueda =
      _terminosPorTradicion['otra'] ?? const ['Iglesia cristiana'];

  static const CameraPosition _posicionInicial = CameraPosition(
    target: LatLng(18.4812, -69.9158),
    zoom: 13.5,
  );

  @override
  void initState() {
    super.initState();
    _verificarYPedirPermisosUbicacion();
  }

  Future _verificarYPedirPermisosUbicacion() async {
    bool serviceEnabled;
    LocationPermission permission;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      setState(() {
        _permisoUbicacionConcedido = true;
      });

      _currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (_mapController != null && _currentPosition != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            13.5,
          ),
        );
      }

      if (_searchController.text.isNotEmpty) {
        _buscarEnGooglePlaces(_searchController.text);
      } else if (_sugerenciasBusqueda.isNotEmpty) {
        _buscarEnGooglePlaces(_sugerenciasBusqueda.first);
      }
    } catch (e) {
      debugPrint('Error al verificar permisos de ubicación: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        final String rawId = (args['tradicionId'] ?? '')
            .toString()
            .toLowerCase();
        final String rawTitulo = (args['tradicionTitulo'] ?? '')
            .toString()
            .toLowerCase();

        if (rawId.contains('catolica') ||
            rawTitulo.contains('católica') ||
            rawTitulo.contains('catolica')) {
          _sugerenciasBusqueda = _terminosPorTradicion['catolica']!;
        } else if (rawId.contains('evangelica') ||
            rawTitulo.contains('evangélica') ||
            rawTitulo.contains('evangelica')) {
          _sugerenciasBusqueda = _terminosPorTradicion['evangelica']!;
        } else if (rawId.contains('ortodoxa') ||
            rawTitulo.contains('ortodoxa')) {
          _sugerenciasBusqueda = _terminosPorTradicion['ortodoxa']!;
        } else if (rawId.contains('no_denominacional') ||
            rawTitulo.contains('no denominacional')) {
          _sugerenciasBusqueda = _terminosPorTradicion['no_denominacional']!;
        } else {
          _sugerenciasBusqueda = _terminosPorTradicion['otra']!;
        }

        if (_sugerenciasBusqueda.isNotEmpty && _searchController.text.isEmpty) {
          _searchController.text = _sugerenciasBusqueda.first;
          _buscarEnGooglePlaces(_sugerenciasBusqueda.first);
        }
      }
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future _abrirNavegacion(LatLng latLng, String nombre) async {
    final double lat = latLng.latitude;
    final double lng = latLng.longitude;
    final Uri uriNativa = Uri.parse(
      'geo:\(lat,\)lng?q=\(lat,\)lng(${Uri.encodeComponent(nombre)})',
    );
    final Uri uriWeb = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=\(lat,\)lng',
    );
    try {
      if (await canLaunchUrl(uriNativa)) {
        await launchUrl(uriNativa, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(uriWeb)) {
        await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la navegación.')),
        );
      }
    } catch (e) {
      debugPrint('Error abriendo mapa: $e');
    }
  }

  Future _buscarEnGooglePlaces(String query) async {
    if (query.trim().isEmpty) return;
    final lat = _currentPosition?.latitude ?? 18.4812;
    final lng = _currentPosition?.longitude ?? -69.9158;

    setState(() {
      _estaBuscando = true;
      _iglesiaSeleccionada = null;
    });

    FocusScope.of(context).unfocus();
    final uri = Uri.parse('https://places.googleapis.com/v1/places:searchText');
    final body = jsonEncode({
      "textQuery": query,
      "includedType": "church",
      "languageCode": "es",
      "locationBias": {
        "circle": {
          "center": {"latitude": lat, "longitude": lng},
          "radius": 5000.0,
        },
      },
    });

    const fieldMask =
        'places.id,places.displayName,places.formattedAddress,'
        'places.location,places.rating,places.userRatingCount,places.currentOpeningHours.openNow';

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
        final data = jsonDecode(response.body) as Map;
        final List resultados = data['places'] ?? [];
        final List<Map<String, dynamic>> nuevasIglesias = [];

        for (var place in resultados) {
          final location = place['location'];
          if (location == null) continue;
          final double placeLat = (location['latitude'] as num).toDouble();
          final double placeLng = (location['longitude'] as num).toDouble();
          double distanceInMeters = 0;

          if (_currentPosition != null) {
            distanceInMeters = Geolocator.distanceBetween(
              lat,
              lng,
              placeLat,
              placeLng,
            );
          }

          if (_currentPosition == null || distanceInMeters <= 5000.0) {
            final openingHours = place['currentOpeningHours'];
            final isOpen = openingHours != null
                ? openingHours['openNow'] as bool?
                : true;

            nuevasIglesias.add({
              'id': place['id'],
              'nombre': place['displayName']?['text'] ?? 'Sin nombre',
              'denominacion':
                  (place['formattedAddress'] as String?)?.split(',').first ??
                  'Comunidad cristiana',
              'rating': (place['rating'] ?? 0.0).toString(),
              'resenas': (place['userRatingCount'] ?? 0).toString(),
              'distanciaNum': distanceInMeters,
              'distancia': _currentPosition != null
                  ? 'A ${(distanceInMeters / 1000).toStringAsFixed(1)} km'
                  : 'Ubicación aproximada',
              'latLng': LatLng(placeLat, placeLng),
              'abierto': isOpen ?? true,
              'destacada': false,
            });
          }
        }

        nuevasIglesias.sort(
          (a, b) => (a['distanciaNum'] as double).compareTo(
            b['distanciaNum'] as double,
          ),
        );

        if (mounted) {
          setState(() {
            _iglesiasData = nuevasIglesias;
            _estaBuscando = false;
          });

          if (nuevasIglesias.isNotEmpty) {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(
                _currentPosition != null
                    ? LatLng(lat, lng)
                    : nuevasIglesias.first['latLng'],
                13.5,
              ),
            );
          } else {
            _mostrarError('No hay resultados a menos de 5 km para "$query".');
          }
        }
      } else {
        _mostrarError('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) _mostrarError('Error de conexión. Verifica tu internet.');
    }
  }

  void _mostrarError(String mensaje) {
    setState(() => _estaBuscando = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Set<Marker> _crearMarkers(Color amarilloOro) {
    return <Marker>{
      for (final iglesia in _iglesiasData)
        Marker(
          markerId: MarkerId(iglesia['id']),
          position: iglesia['latLng'],
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          onTap: () {
            setState(() {
              _iglesiaSeleccionada = iglesia;
            });
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(iglesia['latLng'], 16.0),
            );
          },
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);
    const Color grisBorde = Color(0xFFE5E5E5);

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: false,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight + safeAreaBottom,
          child: Column(
            children: [
              // Encabezado Superior Limpio y Modernizado
              Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: usableHeight * 0.014,
                ),
                child: Column(
                  children: [
                    // Fila 1: Botón Volver circular + Título + Notificaciones
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.all(screenWidth * 0.02),
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
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Text(
                            'Iglesias en mapa',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.056,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: EdgeInsets.all(screenWidth * 0.02),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.white,
                                size: screenWidth * 0.058,
                              ),
                            ),
                            Positioned(
                              top: screenWidth * 0.015,
                              right: screenWidth * 0.015,
                              child: Container(
                                width: screenWidth * 0.022,
                                height: screenWidth * 0.022,
                                decoration: const BoxDecoration(
                                  color: amarilloOro,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.015),

                    // Fila 2: Buscador Autocomplete con sombra y bordes redondeados
                    Container(
                      height: usableHeight * 0.052,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.035,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return _sugerenciasBusqueda;
                          }
                          return _sugerenciasBusqueda.where((String item) {
                            return item.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            );
                          });
                        },
                        onSelected: (String seleccion) {
                          _searchController.text = seleccion;
                          _buscarEnGooglePlaces(seleccion);
                        },
                        fieldViewBuilder:
                            (
                              BuildContext context,
                              TextEditingController textEditingController,
                              FocusNode focusNode,
                              VoidCallback onFieldSubmitted,
                            ) {
                              if (_searchController.text.isNotEmpty &&
                                  textEditingController.text.isEmpty) {
                                textEditingController.text =
                                    _searchController.text;
                              }
                              return TextField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                onSubmitted: (String value) {
                                  onFieldSubmitted();
                                  _searchController.text = value;
                                  _buscarEnGooglePlaces(value);
                                },
                                style: TextStyle(
                                  color: azulFondo,
                                  fontSize: screenWidth * 0.037,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Buscar templo o denominación...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: screenWidth * 0.034,
                                  ),
                                  prefixIcon: _estaBuscando
                                      ? Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: CircularProgressIndicator(
                                            color: azulFondo,
                                            strokeWidth: 2.0,
                                          ),
                                        )
                                      : Icon(
                                          Icons.search_rounded,
                                          color: azulFondo,
                                          size: screenWidth * 0.055,
                                        ),
                                  suffixIcon:
                                      textEditingController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.cancel_rounded,
                                            color: Colors.grey.shade400,
                                            size: screenWidth * 0.048,
                                          ),
                                          onPressed: () {
                                            textEditingController.clear();
                                            _searchController.clear();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: usableHeight * 0.013,
                                  ),
                                ),
                              );
                            },
                        optionsViewBuilder:
                            (
                              BuildContext context,
                              AutocompleteOnSelected<String> onSelected,
                              Iterable<String> options,
                            ) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4.0,
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.03,
                                  ),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight: usableHeight * 0.32,
                                      maxWidth: screenWidth * 0.9,
                                    ),
                                    child: ListView.separated(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      separatorBuilder: (context, index) =>
                                          Divider(
                                            height: 1,
                                            color: Colors.grey.shade200,
                                          ),
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                            final String option = options
                                                .elementAt(index);
                                            return InkWell(
                                              onTap: () => onSelected(option),
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      screenWidth * 0.04,
                                                  vertical:
                                                      usableHeight * 0.015,
                                                ),
                                                child: Text(
                                                  option,
                                                  style: TextStyle(
                                                    color: azulFondo,
                                                    fontSize:
                                                        screenWidth * 0.035,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                              );
                            },
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.006),
                  ],
                ),
              ),

              // Contenedor del Mapa
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
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: _posicionInicial,
                          myLocationEnabled: _permisoUbicacionConcedido,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          markers: _crearMarkers(amarilloOro),
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                            if (_currentPosition != null) {
                              _mapController?.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                  LatLng(
                                    _currentPosition!.latitude,
                                    _currentPosition!.longitude,
                                  ),
                                  13.5,
                                ),
                              );
                            }
                          },
                          onTap: (_) {
                            setState(() => _iglesiaSeleccionada = null);
                            FocusScope.of(context).unfocus();
                          },
                        ),
                        if (_iglesiaSeleccionada != null)
                          Positioned(
                            left: screenWidth * 0.05,
                            right: screenWidth * 0.05,
                            bottom: usableHeight * 0.03 + safeAreaBottom,
                            child: _buildChurchInfoCard(
                              datos: _iglesiaSeleccionada!,
                              screenWidth: screenWidth,
                              usableHeight: usableHeight,
                              azulFondo: azulFondo,
                              amarilloOro: amarilloOro,
                              grisBorde: grisBorde,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChurchInfoCard({
    required Map datos,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color amarilloOro,
    required Color grisBorde,
  }) {
    final bool estaAbierto = datos['abierto'] ?? false;
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.045),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: grisBorde),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  datos['denominacion'],
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: amarilloOro,
                    size: screenWidth * 0.04,
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  Text(
                    datos['rating'],
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.032,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    ' (${datos['resenas']})',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: screenWidth * 0.028,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: usableHeight * 0.008),
          Text(
            datos['nombre'],
            style: TextStyle(
              color: azulFondo,
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: usableHeight * 0.01),
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.02,
                  vertical: usableHeight * 0.003,
                ),
                decoration: BoxDecoration(
                  color: estaAbierto
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFDECEA),
                  borderRadius: BorderRadius.circular(screenWidth * 0.01),
                ),
                child: Text(
                  estaAbierto ? 'Abierto ahora' : 'Cerrado',
                  style: TextStyle(
                    color: estaAbierto
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFD32F2F),
                    fontSize: screenWidth * 0.028,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Icon(
                Icons.location_on,
                color: Colors.grey.shade500,
                size: screenWidth * 0.035,
              ),
              SizedBox(width: screenWidth * 0.01),
              Text(
                datos['distancia'],
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: screenWidth * 0.032,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: usableHeight * 0.02),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: azulFondo,
                    side: const BorderSide(color: Color(0xFF072B4F)),
                    padding: EdgeInsets.symmetric(
                      vertical: usableHeight * 0.012,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.025),
                    ),
                  ),
                  onPressed: () {},
                  child: Text(
                    'Ver ficha',
                    style: TextStyle(
                      fontSize: screenWidth * 0.034,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: amarilloOro,
                    foregroundColor: azulFondo,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      vertical: usableHeight * 0.012,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.025),
                    ),
                  ),
                  onPressed: () =>
                      _abrirNavegacion(datos['latLng'], datos['nombre']),
                  child: Text(
                    'Cómo llegar',
                    style: TextStyle(
                      fontSize: screenWidth * 0.034,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
