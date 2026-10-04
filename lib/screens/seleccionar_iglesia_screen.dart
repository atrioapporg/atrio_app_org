import 'dart:convert';
import 'dart:math';

import 'package:atrio/providers/iglesia_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

//

class SeleccionarIglesiaScreen extends StatefulWidget {
  static const routeName = 'seleccionar_iglesia_screen';
  const SeleccionarIglesiaScreen({super.key});

  @override
  State<SeleccionarIglesiaScreen> createState() =>
      _SeleccionarIglesiaScreenState();
}

class _SeleccionarIglesiaScreenState extends State<SeleccionarIglesiaScreen> {
  // ---------------------------------------------------------------------
  // Paleta de la pantalla — antes vivían como variables locales dentro de
  // build() y se repetían como parámetros en _buildChurchInfoCard/_crearMarkers.
  // Al ser constantes de clase, cualquier método las usa directamente sin
  // tener que recibirlas ni pasarlas de un lado a otro.
  // ---------------------------------------------------------------------
  static const Color _azulFondo = Color(0xFF072B4F);
  static const Color _amarilloOro = Color(0xFFE5A023);
  static const Color _blancoFondo = Color(0xFFFAF7F0);
  static const Color _grisBorde = Color(0xFFE5E5E5);

  bool _estaBuscando = false;
  bool _isInit = true;
  bool _permisoUbicacionConcedido = false;

  GoogleMapController? _mapController;
  Map<String, dynamic>? _iglesiaSeleccionada;
  List<Map<String, dynamic>> _iglesiasData = [];
  Position? _currentPosition;

  final String _googleApiKey = "AIzaSyCwoPsfxubfarcNOomfPDeun9Lu-zj21Ec";
  final TextEditingController _searchController = TextEditingController();

  // ---------------------------------------------------------------------
  // FIX #1: 'no_denominacional' antes tenía términos de tradición ortodoxa
  // ('Iglesia ortodoxa', 'Parroquia ortodoxa', 'Misión ortodoxa'). Se separó
  // en su propia clave 'ortodoxa' y 'no_denominacional' ahora tiene términos
  // que realmente corresponden a esa tradición.
  // ---------------------------------------------------------------------
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
      'Iglesia cristiana',
      'Templo cristiano',
      'Comunidad cristiana',
      'Ministerio',
    ],
  };

  // ---------------------------------------------------------------------
  // Palabras clave que identifican cada tradición dentro de tradicionId /
  // tradicionTitulo. Fuente única de verdad: agregar una tradición nueva es
  // agregar UNA entrada aquí — no hay que tocar la lógica de detección.
  // ---------------------------------------------------------------------
  static const Map<String, List<String>> _clavesPorTradicion = {
    'catolica': ['catolica', 'católica'],
    'evangelica': ['evangelica', 'evangélica'],
    'ortodoxa': ['ortodoxa'],
    'no_denominacional': ['no_denominacional', 'no denominacional'],
  };

  List<String> _sugerenciasBusqueda = _terminosPorTradicion['otra']!;

  static const CameraPosition _posicionInicial = CameraPosition(
    target: LatLng(18.4812, -69.9158),
    zoom: 13.5,
  );

  @override
  void initState() {
    super.initState();
    // La verificación de ubicación y búsqueda se inicializan en didChangeDependencies
    // una vez que los argumentos de la ruta y las sugerencias de tradición están listos.
  }

  Future<void> _verificarYPedirPermisosUbicacion() async {
    try {
      // 1. Comprobar si el servicio GPS está habilitado en el dispositivo
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'El GPS está desactivado. Actívalo para encontrar iglesias cercanas a ti.',
            ),
            action: SnackBarAction(
              label: 'Ajustes',
              onPressed: () => Geolocator.openLocationSettings(),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // 2. Comprobar y solicitar permisos de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Permiso de ubicación no concedido. Se mostrará ubicación predeterminada.',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        _ejecutarBusquedaInicial();
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Permisos de ubicación denegados permanentemente en los ajustes.',
              ),
              action: SnackBarAction(
                label: 'Ajustes',
                onPressed: () => Geolocator.openAppSettings(),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        _ejecutarBusquedaInicial();
        return;
      }

      // Permiso concedido
      if (mounted) {
        setState(() => _permisoUbicacionConcedido = true);
      }

      // 3. Obtener la última posición conocida para respuesta instantánea sin bloquear
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null && mounted) {
          setState(() => _currentPosition = lastKnown);
          _moverCamara(lastKnown.latitude, lastKnown.longitude);
        }
      } catch (e) {
        debugPrint('Aviso al obtener lastKnownPosition: $e');
      }

      // 4. Si el GPS está encendido, obtener la posición actual con timeout seguro
      if (serviceEnabled) {
        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 8),
            ),
          );
          if (mounted) {
            setState(() => _currentPosition = position);
            _moverCamara(position.latitude, position.longitude);
          }
        } catch (e) {
          debugPrint(
            'Aviso al obtener getCurrentPosition (se usará posición previa o fallback): $e',
          );
        }
      }

      // 5. Iniciar la búsqueda de iglesias cercanas
      _ejecutarBusquedaInicial();
    } catch (e) {
      debugPrint('Error al verificar permisos de ubicación: $e');
      _ejecutarBusquedaInicial();
    }
  }

  void _moverCamara(double lat, double lng) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(lat, lng), 14.0),
      );
    }
  }

  void _ejecutarBusquedaInicial() {
    final query = _searchController.text.isNotEmpty
        ? _searchController.text
        : (_sugerenciasBusqueda.isNotEmpty
              ? _sugerenciasBusqueda.first
              : 'iglesia');
    _buscarEnGooglePlaces(query);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInit) return;
    _isInit = false;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _sugerenciasBusqueda = _detectarSugerenciasPorTradicion(args);
    }

    if (_sugerenciasBusqueda.isNotEmpty && _searchController.text.isEmpty) {
      _searchController.text = _sugerenciasBusqueda.first;
    }

    _verificarYPedirPermisosUbicacion();
  }

  /// Determina qué lista de sugerencias usar según los argumentos de ruta.
  /// FIX #2: eliminada la línea muerta `rawTitulo.contains('iglesia');` que
  /// no asignaba a nada ni afectaba ninguna condición.
  List<String> _detectarSugerenciasPorTradicion(Map<String, dynamic> args) {
    final String rawId = (args['tradicionId'] ?? '').toString().toLowerCase();
    final String rawTitulo = (args['tradicionTitulo'] ?? '')
        .toString()
        .toLowerCase();
    final String textoCombinado = '$rawId $rawTitulo';

    for (final entry in _clavesPorTradicion.entries) {
      final bool coincide = entry.value.any(textoCombinado.contains);
      if (coincide) return _terminosPorTradicion[entry.key]!;
    }

    return _terminosPorTradicion['otra']!;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _buscarEnGooglePlaces(String query) async {
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
          "radius": 10000.0,
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

      if (response.statusCode != 200) {
        _mostrarError('Error del servidor: ${response.statusCode}');
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final List resultados = data['places'] ?? [];
      final nuevasIglesias = _filtrarYMapearResultados(resultados, lat, lng);

      nuevasIglesias.sort(
        (a, b) => (a['distanciaNum'] as double).compareTo(
          b['distanciaNum'] as double,
        ),
      );

      if (!mounted) return;

      setState(() {
        _iglesiasData = nuevasIglesias;
        _estaBuscando = false;
      });

      if (nuevasIglesias.isEmpty) {
        _mostrarError('No se encontraron iglesias cercanas para "$query".');
        return;
      }

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          _currentPosition != null
              ? LatLng(lat, lng)
              : nuevasIglesias.first['latLng'],
          13.5,
        ),
      );
    } catch (e) {
      if (mounted) _mostrarError('Error de conexión. Verifica tu internet.');
    }
  }

  /// Filtra los resultados crudos de Places dentro de 10 km reales y los
  /// convierte al formato que usa la UI. Separado de _buscarEnGooglePlaces
  /// para que el método de red no cargue también con la lógica de mapeo.
  List<Map<String, dynamic>> _filtrarYMapearResultados(
    List resultados,
    double lat,
    double lng,
  ) {
    final List<Map<String, dynamic>> iglesias = [];

    for (final place in resultados) {
      final location = place['location'];
      if (location == null) continue;

      final double placeLat = (location['latitude'] as num).toDouble();
      final double placeLng = (location['longitude'] as num).toDouble();

      final double distanceInMeters = _currentPosition != null
          ? Geolocator.distanceBetween(lat, lng, placeLat, placeLng)
          : 0;

      // Filtro real de iglesias cercanas hasta 10 km
      final bool dentroDelRadio =
          _currentPosition == null || distanceInMeters <= 10000.0;
      if (!dentroDelRadio) continue;

      final openingHours = place['currentOpeningHours'];
      final isOpen = openingHours != null
          ? openingHours['openNow'] as bool?
          : true;

      iglesias.add({
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
            : 'Ubicación exacta',
        'latLng': LatLng(placeLat, placeLng),
        'abierto': isOpen ?? true,
        'destacada': false,
      });
    }

    return iglesias;
  }

  /// Genera un ID local temporal. Combina timestamp + aleatorio para reducir
  /// el riesgo de colisión frente al rango fijo de 10000-99999 original.
  int _generarIdLocal() {
    final marcaTiempo = DateTime.now().millisecondsSinceEpoch % 100000;
    final aleatorio = Random().nextInt(900) + 100;
    return marcaTiempo * 1000 + aleatorio;
  }

  void _mostrarError(String mensaje) {
    setState(() => _estaBuscando = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  // ---------------------------------------------------------------------
  // TODO(backend): esta función arma un registro con datos de relleno
  // (teléfono, horarios, próximo culto) porque aún no hay integración real
  // con Odoo para este flujo. Cuando exista el modelo `atrio.church` o
  // similar, esto debería reemplazarse por una llamada real de creación/
  // vinculación (ej. OdooClient.create('atrio.church', {...})) y usar el ID
  // que devuelva el backend en vez de _generarIdLocal().
  // ---------------------------------------------------------------------
  void _registrarIglesia(Map<String, dynamic> datos) {
    final Map<String, dynamic> datosParaGuardar = {
      "id": _generarIdLocal(),
      "nombre": datos['nombre'],
      "denominacion": datos['denominacion'],
      "calificacion": double.tryParse(datos['rating'].toString()) ?? 0.0,
      "total_resenas": int.tryParse(datos['resenas'].toString()) ?? 0,
      "distancia": datos['distancia'] ?? "A 1.8 km",
      "es_verificada": true,
      "direccion": datos['denominacion'],
      "plus_code": "Código Plus no disponible",
      "telefono": "(809) 000-0000",
      "sitio_web": "https://atrio.app",
      "proximo_culto": {
        "titulo": "Servicio de Bienvenida",
        "dia_hora": "Domingo · 10:00 a. m.",
        "estado": "Cerrado · Abre a las 10 a.m. del dom",
      },
      "horarios": [
        {
          "dia": "Domingo",
          "detalle": "10:00 a. m. · Culto Dominical",
          "tipo": "culto",
        },
        {
          "dia": "Miércoles",
          "detalle": "7:30 p. m. · Estudio Bíblico",
          "tipo": "estudio",
        },
      ],
      "aviso_actual": {
        "titulo": "¡Bienvenido a tu nueva comunidad!",
        "descripcion": "Te has registrado correctamente en esta iglesia a través de atrio.",
      },
    };

    final String jsonString = jsonEncode(datosParaGuardar);
    final provider = Provider.of<IglesiaProvider>(context, listen: false);
    provider.guardarIglesiaLocal(jsonString);

    Navigator.pushNamedAndRemoveUntil(
      context,
      'inicio_atrio_screen',
      (route) => false,
    );
  }

  // FIX #3: se eliminó el parámetro `amarilloOro` que nunca se usaba dentro
  // del cuerpo de esta función — ahora usa la constante de clase _amarilloOro
  // solo donde de verdad hace falta (aquí, en realidad, en ningún lado).
  Set<Marker> _crearMarkers() {
    return _iglesiasData.map((iglesia) {
      return Marker(
        markerId: MarkerId(iglesia['id'].toString()),
        position: iglesia['latLng'],
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        onTap: () {
          setState(() => _iglesiaSeleccionada = iglesia);
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(iglesia['latLng'], 16.0),
          );
        },
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    return Scaffold(
      backgroundColor: _azulFondo,
      body: SafeArea(
        bottom: false,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight + safeAreaBottom,
          child: Column(
            children: [
              _buildEncabezado(screenWidth, usableHeight),
              Expanded(
                child: _buildMapa(screenWidth, usableHeight, safeAreaBottom),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEncabezado(double screenWidth, double usableHeight) {
    return Container(
      height: usableHeight * 0.21,
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Column(
        children: [
          // Nuevo Logo Horizontal Atrio
          Image.asset(
            'assets/images/logo_encabezado_sinfondo.png',
            height: usableHeight * 0.060,
            fit: BoxFit.contain,
          ),
          // FIN Nuevo Logo Horizontal Atrio

          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.white,
                  size: screenWidth * 0.085,
                ),
              ),
              SizedBox(width: screenWidth * 0.01),
              Text(
                'Selecciona tu iglesia',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.062,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: usableHeight * 0.015),
          _buildBuscador(screenWidth, usableHeight),
        ],
      ),
    );
  }

  Widget _buildBuscador(double screenWidth, double usableHeight) {
    return Container(
      height: usableHeight * 0.065,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) return _sugerenciasBusqueda;
          return _sugerenciasBusqueda.where(
            (item) => item.toLowerCase().contains(
              textEditingValue.text.toLowerCase(),
            ),
          );
        },
        onSelected: (String seleccion) {
          _searchController.text = seleccion;
          _buscarEnGooglePlaces(seleccion);
        },
        fieldViewBuilder:
            (context, textEditingController, focusNode, onFieldSubmitted) {
              if (_searchController.text.isNotEmpty &&
                  textEditingController.text.isEmpty) {
                textEditingController.text = _searchController.text;
              }
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                onSubmitted: (value) {
                  onFieldSubmitted();
                  _searchController.text = value;
                  _buscarEnGooglePlaces(value);
                },
                decoration: InputDecoration(
                  hintText: 'Buscar iglesia o denominación...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: screenWidth * 0.034,
                  ),
                  prefixIcon: _estaBuscando
                      ? Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(
                            color: _azulFondo,
                            strokeWidth: 2.0,
                          ),
                        )
                      : Icon(
                          Icons.search,
                          color: Colors.grey.shade600,
                          size: screenWidth * 0.055,
                        ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: usableHeight * 0.014,
                  ),
                ),
              );
            },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: usableHeight * 0.25,
                  maxWidth: screenWidth * 0.9,
                ),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return InkWell(
                      onTap: () => onSelected(option),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: usableHeight * 0.007,
                        ),
                        child: Text(
                          option,
                          style: TextStyle(
                            color: _azulFondo,
                            fontSize: screenWidth * 0.035,
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
    );
  }

  Widget _buildMapa(
    double screenWidth,
    double usableHeight,
    double safeAreaBottom,
  ) {
    return Container(
      width: screenWidth,
      decoration: BoxDecoration(
        color: _blancoFondo,
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
              markers: _crearMarkers(),
              onMapCreated: (controller) {
                _mapController = controller;
                if (_currentPosition != null) {
                  _moverCamara(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
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
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChurchInfoCard({
    required Map<String, dynamic> datos,
    required double screenWidth,
    required double usableHeight,
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
        border: Border.all(color: _grisBorde),
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
                    color: _amarilloOro,
                    size: screenWidth * 0.04,
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  Text(
                    datos['rating'],
                    style: TextStyle(
                      color: _azulFondo,
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
              color: _azulFondo,
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
            ],
          ),
          SizedBox(height: usableHeight * 0.02),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _amarilloOro,
                foregroundColor: _azulFondo,
                elevation: 0,
                padding: EdgeInsets.symmetric(vertical: usableHeight * 0.015),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                ),
              ),
              onPressed: () => _registrarIglesia(datos),
              child: Text(
                'Seleccionar iglesia',
                style: TextStyle(
                  fontSize: screenWidth * 0.038,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
