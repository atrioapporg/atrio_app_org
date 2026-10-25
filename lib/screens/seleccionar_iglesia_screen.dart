import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/atrio_database_helper.dart';
import '../l10n/app_localizations.dart';
import '../modelos/iglesia_explorar_model.dart';
import '../providers/ajustes_provider.dart';
import '../providers/explorar_provider.dart';
import '../providers/iglesia_provider.dart';
import '../providers/tradicion_cristiana_provider.dart';
import '../providers/user_provider.dart';
import '../servicios/map_style_service.dart';
import 'esperando_aprobacion_screen.dart';
import 'inicio_atrio_screen.dart';

/// Pantalla SeleccionarIglesiaScreen: Permite al usuario explorar y seleccionar su iglesia
/// en el mapa interactivo con soporte de persistencia en ambos modos (Modo Radio 10/25/50 km
/// vs. Modo Nacional por país actual del usuario), paginación estricta de 15 en 15 (Lazy Loading),
/// debounce de 500 ms y limitación estricta de fronteras sin cruzar hacia otros países.
class SeleccionarIglesiaScreen extends StatefulWidget {
  static const routeName = 'seleccionar_iglesia_screen';
  const SeleccionarIglesiaScreen({super.key});

  @override
  State<SeleccionarIglesiaScreen> createState() =>
      _SeleccionarIglesiaScreenState();
}

class _SeleccionarIglesiaScreenState extends State<SeleccionarIglesiaScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  GoogleMapController? _mapController;
  IglesiaExplorarModel? _iglesiaSeleccionada;
  bool _permisoUbicacionConcedido = false;
  bool _isInit = true;
  bool _guardandoIglesia = false;
  String? _mapDarkStyle;

  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFE5E5E5);

  final List<String> _filtrosKeys = [
    'todos',
    'catolica',
    'evangelica',
    'pentecostal',
    'bautista',
    'adventista',
  ];

  static const CameraPosition _posicionInicial = CameraPosition(
    target: LatLng(18.4812, -69.9158),
    zoom: 12.5,
  );

  @override
  void initState() {
    super.initState();
    MapStyleService.getDarkStyle().then((style) {
      if (mounted) setState(() => _mapDarkStyle = style);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _verificarYPedirPermisosUbicacion();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final provider = context.read<ExplorarProvider>();
      final ajustes = context.read<AjustesProvider>();

      // Sincronizar país de residencia actual desde ajustes (no llama notifyListeners)
      provider.sincronizarPais(ajustes.paisRegion);

      // Si se pasa tradición como argumento de ruta o existe previamente en TradicionCristianaProvider
      final args = ModalRoute.of(context)?.settings.arguments;
      String rawId = '';
      String rawTitulo = '';

      if (args is Map) {
        rawId = (args['tradicionId'] ?? '').toString();
        rawTitulo = (args['tradicionTitulo'] ?? '').toString();
      }

      // Si no vino en argumentos, verificar si ya está seleccionada en TradicionCristianaProvider
      if (rawId.isEmpty && rawTitulo.isEmpty) {
        try {
          final tradicionProvider = context.read<TradicionCristianaProvider>();
          if (tradicionProvider.tradicionSeleccionada != null) {
            rawId = tradicionProvider.tradicionSeleccionada!.id;
            rawTitulo = tradicionProvider.tradicionSeleccionada!.titulo;
          }
        } catch (_) {}
      }

      final textoCombinado = '$rawId $rawTitulo'.toLowerCase();

      int? nuevaDenominacion;
      if (textoCombinado.contains('catolica') ||
          textoCombinado.contains('católica')) {
        nuevaDenominacion = 1;
      } else if (textoCombinado.contains('evangelica') ||
          textoCombinado.contains('evangélica')) {
        nuevaDenominacion = 2;
      } else if (textoCombinado.contains('pentecostal')) {
        nuevaDenominacion = 3;
      } else if (textoCombinado.contains('bautista')) {
        nuevaDenominacion = 4;
      } else if (textoCombinado.contains('adventista')) {
        nuevaDenominacion = 5;
      }

      if (nuevaDenominacion != null && nuevaDenominacion > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<ExplorarProvider>().cambiarDenominacion(
              nuevaDenominacion!,
              recargar: false,
            );
          }
        });
      }

      // Sincronizar texto de búsqueda si ya existía en el provider
      if (provider.textoBusqueda.isNotEmpty && _searchController.text.isEmpty) {
        _searchController.text = provider.textoBusqueda;
      }

      _isInit = false;
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _verificarYPedirPermisosUbicacion() async {
    final provider = context.read<ExplorarProvider>();
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        provider.buscar(ignorarDebounce: true, forzarRecarga: true);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          provider.buscar(ignorarDebounce: true, forzarRecarga: true);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        provider.buscar(ignorarDebounce: true, forzarRecarga: true);
        return;
      }

      setState(() {
        _permisoUbicacionConcedido = true;
      });

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      provider.setUbicacion(pos);

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 12.5),
        );
      }

      await provider.buscar(ignorarDebounce: true, forzarRecarga: true);

      _ajustarCamaraSegunResultados(
        provider.iglesiasMostradas,
        provider.modo,
        provider.radioKm,
        pos,
      );
    } catch (e) {
      debugPrint('Error al verificar permisos de ubicación en mapa: $e');
      if (provider.iglesiasMostradas.isEmpty) {
        provider.buscar(ignorarDebounce: true);
      }
    }
  }

  /// Ajusta la cámara del mapa suavemente según el modo y las iglesias cargadas
  void _ajustarCamaraSegunResultados(
    List<IglesiaExplorarModel> iglesias,
    ModoExploracion modo,
    double radioKm,
    Position? pos,
  ) {
    if (_mapController == null) return;

    if (modo == ModoExploracion.radio && pos != null) {
      double zoom = 12.2;
      if (radioKm >= 50.0) {
        zoom = 9.4;
      } else if (radioKm >= 25.0) {
        zoom = 10.6;
      }
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), zoom),
      );
    } else {
      // Modo Nacional: Encuadrar los límites (LatLngBounds) de las iglesias
      final coords = iglesias
          .where((i) => i.latLng != null)
          .map((i) => i.latLng!)
          .toList();

      if (coords.isEmpty) return;

      if (coords.length == 1) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(coords.first, 14.0),
        );
        return;
      }

      double minLat = coords.first.latitude;
      double maxLat = coords.first.latitude;
      double minLng = coords.first.longitude;
      double maxLng = coords.first.longitude;

      for (final c in coords) {
        if (c.latitude < minLat) minLat = c.latitude;
        if (c.latitude > maxLat) maxLat = c.latitude;
        if (c.longitude < minLng) minLng = c.longitude;
        if (c.longitude > maxLng) maxLng = c.longitude;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
    }
  }

  Future<void> _abrirNavegacion(LatLng? latLng, String nombre) async {
    if (latLng == null) return;
    final double lat = latLng.latitude;
    final double lng = latLng.longitude;

    final Uri uriNativa = Uri.parse(
      'geo:$lat,$lng?q=$lat,$lng(${Uri.encodeComponent(nombre)})',
    );
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

  /// Genera un ID local único temporal para guardar la selección de iglesia
  int _generarIdLocal() {
    final marcaTiempo = DateTime.now().millisecondsSinceEpoch % 100000;
    final aleatorio = Random().nextInt(900) + 100;
    return marcaTiempo * 1000 + aleatorio;
  }

  /// Registra la iglesia seleccionada y la guarda localmente en el provider y SQLite
  Future<void> _registrarIglesia(IglesiaExplorarModel iglesia) async {
    if (_guardandoIglesia) return;
    setState(() => _guardandoIglesia = true);

    try {
      final l10n = mounted ? AppLocalizations.of(context) : null;
      final Map<String, dynamic> datosParaGuardar = {
        "id": _generarIdLocal(),
        "nombre": iglesia.nombre,
        "denominacion": iglesia.denominacion,
        "calificacion": iglesia.rating,
        "total_resenas": iglesia.totalResenas,
        "distancia": iglesia.distanciaKm > 0
            ? (l10n?.aDistanciaKm(iglesia.distanciaKm.toStringAsFixed(1)) ??
                  "A ${iglesia.distanciaKm.toStringAsFixed(1)} km")
            : (l10n?.distanciaAproximadaDefault ?? "A 1.8 km"),
        "es_verificada": true,
        "direccion": iglesia.direccion.isNotEmpty
            ? iglesia.direccion
            : iglesia.denominacion,
        "plus_code":
            l10n?.codigoPlusNoDisponible ?? "Código Plus no disponible",
        "telefono": "(809) 000-0000",
        "sitio_web": "https://atrio.app",
        "proximo_culto": {
          "titulo": l10n?.servicioDeBienvenida ?? "Servicio de Bienvenida",
          "dia_hora": l10n?.diaHoraDomingo10am ?? "Domingo · 10:00 a. m.",
          "estado":
              l10n?.estadoCerradoAbreDomingo ??
              "Cerrado · Abre a las 10 a.m. del dom",
        },
        "horarios": [
          {
            "dia": l10n?.diaDomingo ?? "Domingo",
            "detalle":
                l10n?.cultoDominical10am ?? "10:00 a. m. · Culto Dominical",
            "tipo": "culto",
          },
          {
            "dia": l10n?.diaMiercoles ?? "Miércoles",
            "detalle":
                l10n?.estudioBiblico730pm ?? "7:30 p. m. · Estudio Bíblico",
            "tipo": "estudio",
          },
        ],
        "aviso_actual": {
          "titulo":
              l10n?.bienvenidoNuevaComunidad ??
              "¡Bienvenido a tu nueva comunidad!",
          "descripcion": l10n?.descripcionRegistroIglesia ?? "Te has registrado correctamente en esta iglesia a través de atrio.",
        },
      };

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final iglesiaProvider = Provider.of<IglesiaProvider>(
        context,
        listen: false,
      );

      final String nombreIglesia = iglesia.nombre.trim();
      if (nombreIglesia.isNotEmpty) {
        await AtrioDatabaseHelper.instance.guardarIglesiaNombre(nombreIglesia);
      }

      if (userProvider.isAuthenticated) {
        final churchId = int.tryParse(iglesia.id) ?? 0;
        if (churchId > 0) {
          await userProvider.solicitarMembresia(
            churchId,
            churchName: nombreIglesia,
          );
        }
        final String jsonString = jsonEncode(datosParaGuardar);
        await iglesiaProvider.guardarIglesiaLocal(jsonString);

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          EsperandoAprobacionScreen.routeName,
          (route) => false,
        );
        return;
      }

      // Si el usuario es un invitado no autenticado:
      final String jsonString = jsonEncode(datosParaGuardar);
      await iglesiaProvider.guardarIglesiaLocal(jsonString);

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        InicioAtrioScreen.routeName,
        (route) => false,
      );
    } catch (e) {
      debugPrint('Error al registrar iglesia: $e');
      if (mounted) {
        setState(() => _guardandoIglesia = false);
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.errorGuardarSeleccionLocal ??
                  'No se pudo guardar la selección localmente.',
            ),
          ),
        );
      }
    }
  }

  String _getFiltroLabel(int index, AppLocalizations? l10n) {
    switch (index) {
      case 0:
        return l10n?.todos ?? 'Todas';
      case 1:
        return l10n?.catolica ?? 'Católica';
      case 2:
        return l10n?.evangelica ?? 'Evangélica';
      case 3:
        return l10n?.pentecostal ?? 'Pentecostal';
      case 4:
        return l10n?.bautista ?? 'Bautista';
      case 5:
        return l10n?.adventista ?? 'Adventista';
      default:
        return '';
    }
  }

  Set<Marker> _crearMarkers(List<IglesiaExplorarModel> iglesias) {
    return <Marker>{
      for (final iglesia in iglesias)
        if (iglesia.latLng != null)
          Marker(
            markerId: MarkerId(
              iglesia.id.isNotEmpty ? iglesia.id : iglesia.nombre,
            ),
            position: iglesia.latLng!,
            infoWindow: InfoWindow(
              title: iglesia.nombre,
              snippet:
                  '${iglesia.denominacion} · ${iglesia.distanciaKm > 0 ? '${iglesia.distanciaKm.toStringAsFixed(1)} km' : ''}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _iglesiaSeleccionada?.id == iglesia.id
                  ? BitmapDescriptor.hueOrange
                  : BitmapDescriptor.hueAzure,
            ),
            onTap: () {
              setState(() {
                _iglesiaSeleccionada = iglesia;
              });
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(iglesia.latLng!, 15.5),
              );
            },
          ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final screenWidth = size.width;
    final usableHeight = size.height - padding.top - padding.bottom;

    final provider = context.watch<ExplorarProvider>();

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: false,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight + padding.bottom,
          child: Column(
            children: [
              // 1. Encabezado Superior con controles de búsqueda y modo
              Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.045,
                  vertical: usableHeight * 0.012,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila 1: Botón Volver + Título + Insignia de país actual
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n?.seleccionaTuIglesia ??
                                    'Selecciona tu iglesia',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.052,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                provider.modo == ModoExploracion.radio
                                    ? (l10n?.radioKmEnPais(
                                            provider.radioKm.toInt().toString(),
                                            provider.paisNombre,
                                          ) ??
                                          'Radio < ${provider.radioKm.toInt()} km en ${provider.paisNombre}')
                                    : (l10n?.todoElPaisConBandera(
                                            provider.paisNombre,
                                            provider.paisBandera,
                                          ) ??
                                          'Todo ${provider.paisNombre} ${provider.paisBandera}'),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: screenWidth * 0.03,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Insignia fija del país actual
                        Tooltip(
                          message:
                              l10n?.busquedaExclusivaEn(provider.paisNombre) ??
                              'Búsqueda exclusiva en ${provider.paisNombre}',
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.025,
                              vertical: usableHeight * 0.006,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.04,
                              ),
                              border: Border.all(
                                color: amarilloOro.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  provider.paisBandera,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.038,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.01),
                                Text(
                                  provider.paisCodigo,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.03,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              'inicio_atrio_screen',
                              (route) => false,
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.025,
                              vertical: usableHeight * 0.006,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.04,
                              ),
                              border: Border.all(
                                color: amarilloOro.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              l10n?.omitir ?? 'Omitir',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.028,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.012),

                    // Fila 2: Selector de Modo (Radio vs. Nacional)
                    _buildModeSelector(
                      provider,
                      l10n,
                      screenWidth,
                      usableHeight,
                    ),
                    SizedBox(height: usableHeight * 0.01),

                    // Fila 3: Buscador con Debounce de 500 ms
                    _buildSearchBar(provider, l10n, screenWidth, usableHeight),
                    SizedBox(height: usableHeight * 0.01),

                    // Fila 4: Filtros de Denominación
                    _buildDenominacionChips(
                      provider,
                      l10n,
                      screenWidth,
                      usableHeight,
                    ),
                  ],
                ),
              ),

              // 2. Contenedor de Google Maps con capas de control y paginación
              Expanded(
                child: Container(
                  width: screenWidth,
                  decoration: BoxDecoration(
                    color: blancoFondo,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.075),
                      topRight: Radius.circular(screenWidth * 0.075),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.075),
                      topRight: Radius.circular(screenWidth * 0.075),
                    ),
                    child: Stack(
                      children: [
                        // Mapa de Google Maps
                        GoogleMap(
                          style: MapStyleService.esDeNoche(context)
                              ? _mapDarkStyle
                              : null,
                          initialCameraPosition: _posicionInicial,
                          myLocationEnabled: _permisoUbicacionConcedido,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                          markers: _crearMarkers(
                            provider.modo == ModoExploracion.radio
                                ? provider.bufferResultados
                                : provider.iglesiasMostradas,
                          ),
                          onMapCreated: (GoogleMapController controller) {
                            _mapController = controller;
                            final iglesias =
                                provider.modo == ModoExploracion.radio
                                ? provider.bufferResultados
                                : provider.iglesiasMostradas;
                            if (iglesias.isNotEmpty) {
                              _ajustarCamaraSegunResultados(
                                iglesias,
                                provider.modo,
                                provider.radioKm,
                                provider.currentPosition,
                              );
                            }
                          },
                          onTap: (_) {
                            setState(() => _iglesiaSeleccionada = null);
                            _searchFocusNode.unfocus();
                          },
                        ),

                        // Botón flotante para recientes/centrar ubicación
                        Positioned(
                          right: screenWidth * 0.045,
                          top: usableHeight * 0.02,
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            elevation: 4,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                if (provider.currentPosition != null &&
                                    _mapController != null) {
                                  _mapController!.animateCamera(
                                    CameraUpdate.newLatLngZoom(
                                      LatLng(
                                        provider.currentPosition!.latitude,
                                        provider.currentPosition!.longitude,
                                      ),
                                      14.0,
                                    ),
                                  );
                                } else {
                                  _verificarYPedirPermisosUbicacion();
                                }
                              },
                              child: Padding(
                                padding: EdgeInsets.all(screenWidth * 0.03),
                                child: Icon(
                                  Icons.my_location_rounded,
                                  color: azulFondo,
                                  size: screenWidth * 0.06,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Barra Flotante Superior: Contador e Indicador de Carga de 15 en 15
                        Positioned(
                          left: screenWidth * 0.045,
                          top: usableHeight * 0.02,
                          child: _buildFloatingPaginationChip(
                            provider,
                            screenWidth,
                            usableHeight,
                            l10n,
                          ),
                        ),

                        // Tarjeta Inferior de Información y Selección de Iglesia
                        if (_iglesiaSeleccionada != null)
                          Positioned(
                            left: screenWidth * 0.045,
                            right: screenWidth * 0.045,
                            bottom: usableHeight * 0.03 + padding.bottom,
                            child: _buildChurchInfoCard(
                              iglesia: _iglesiaSeleccionada!,
                              screenWidth: screenWidth,
                              usableHeight: usableHeight,
                              l10n: l10n,
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

  /// Selector de Modo Dual (Radio vs. Nacional) + Selector de Radio
  Widget _buildModeSelector(
    ExplorarProvider provider,
    AppLocalizations? l10n,
    double screenWidth,
    double usableHeight,
  ) {
    final esRadio = provider.modo == ModoExploracion.radio;

    return Row(
      children: [
        // Botón modo radio
        GestureDetector(
          onTap: () {
            provider.cambiarModo(ModoExploracion.radio);
            _ajustarCamaraSegunResultados(
              provider.iglesiasMostradas,
              ModoExploracion.radio,
              provider.radioKm,
              provider.currentPosition,
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: usableHeight * 0.007,
            ),
            decoration: BoxDecoration(
              color: esRadio
                  ? amarilloOro
                  : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.radar_rounded,
                  color: esRadio ? azulFondo : Colors.white,
                  size: screenWidth * 0.038,
                ),
                SizedBox(width: screenWidth * 0.01),
                Text(
                  l10n?.busquedaPorRadio ?? 'Radio',
                  style: TextStyle(
                    color: esRadio ? azulFondo : Colors.white,
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.02),

        // Botón modo nacional
        GestureDetector(
          onTap: () {
            provider.cambiarModo(ModoExploracion.nacional);
            _ajustarCamaraSegunResultados(
              provider.iglesiasMostradas,
              ModoExploracion.nacional,
              provider.radioKm,
              provider.currentPosition,
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: usableHeight * 0.007,
            ),
            decoration: BoxDecoration(
              color: !esRadio
                  ? amarilloOro
                  : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  provider.paisBandera,
                  style: TextStyle(fontSize: screenWidth * 0.035),
                ),
                SizedBox(width: screenWidth * 0.01),
                Text(
                  l10n?.busquedaNacional ?? 'Nacional',
                  style: TextStyle(
                    color: !esRadio ? azulFondo : Colors.white,
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.02),

        // Selector de Kilometraje cuando está en Modo Radio
        if (esRadio)
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [10.0, 25.0, 50.0].map((km) {
                final isSelected = provider.radioKm == km;
                return Padding(
                  padding: EdgeInsets.only(left: screenWidth * 0.015),
                  child: GestureDetector(
                    onTap: () {
                      provider.cambiarRadio(km);
                      _ajustarCamaraSegunResultados(
                        provider.bufferResultados,
                        ModoExploracion.radio,
                        km,
                        provider.currentPosition,
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.025,
                        vertical: usableHeight * 0.005,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      ),
                      child: Text(
                        '${km.toInt()}k',
                        style: TextStyle(
                          color: isSelected ? azulFondo : Colors.white,
                          fontSize: screenWidth * 0.028,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          )
        else
          Expanded(
            child: Text(
              l10n?.enTodoPais(provider.paisNombre) ??
                  'En todo ${provider.paisNombre}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: screenWidth * 0.028,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  /// Buscador Material 3 con Debounce de 500 ms integrado
  Widget _buildSearchBar(
    ExplorarProvider provider,
    AppLocalizations? l10n,
    double screenWidth,
    double usableHeight,
  ) {
    final hint = provider.modo == ModoExploracion.nacional
        ? (l10n?.buscarEnPaisPlaceholder(provider.paisNombre) ??
              'Buscar en ${provider.paisNombre} (ej. Altagracia...)')
        : (l10n?.buscarEnRadioPlaceholder ??
              'Buscar templo o denominación en radio...');

    return Container(
      height: usableHeight * 0.052,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        textInputAction: TextInputAction.search,
        onChanged: (val) {
          provider.onTextoBusquedaCambiado(val);
        },
        onSubmitted: (val) {
          _searchFocusNode.unfocus();
          provider.ejecutarBusquedaInmediata(val);
        },
        style: TextStyle(
          color: azulFondo,
          fontSize: screenWidth * 0.036,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: screenWidth * 0.032,
          ),
          prefixIcon: provider.isLoading
              ? Padding(
                  padding: EdgeInsets.all(screenWidth * 0.025),
                  child: const CircularProgressIndicator(
                    color: azulFondo,
                    strokeWidth: 2.0,
                  ),
                )
              : Icon(
                  Icons.search_rounded,
                  color: azulFondo,
                  size: screenWidth * 0.052,
                ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.cancel_rounded,
                    color: Colors.grey.shade400,
                    size: screenWidth * 0.045,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    provider.ejecutarBusquedaInmediata('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: usableHeight * 0.012),
        ),
      ),
    );
  }

  /// Barra horizontal interactiva de denominaciones
  Widget _buildDenominacionChips(
    ExplorarProvider provider,
    AppLocalizations? l10n,
    double screenWidth,
    double usableHeight,
  ) {
    return SizedBox(
      height: usableHeight * 0.04,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filtrosKeys.length,
        separatorBuilder: (context, index) =>
            SizedBox(width: screenWidth * 0.02),
        itemBuilder: (context, index) {
          final isSelected = provider.filtroDenominacionIndex == index;
          final label = _getFiltroLabel(index, l10n);

          return GestureDetector(
            onTap: () {
              provider.cambiarDenominacion(index);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.035),
              decoration: BoxDecoration(
                color: isSelected
                    ? amarilloOro
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? azulFondo : Colors.white,
                    fontSize: screenWidth * 0.03,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Chip Flotante de Paginación de 15 en 15 y Carga Perezosa en Mapa
  Widget _buildFloatingPaginationChip(
    ExplorarProvider provider,
    double screenWidth,
    double usableHeight,
    AppLocalizations? l10n,
  ) {
    final totalMostradas = provider.iglesiasMostradas.length;
    final totalCargadas = provider.totalResultadosCargados;

    return Container(
      decoration: BoxDecoration(
        color: azulFondo,
        borderRadius: BorderRadius.circular(screenWidth * 0.05),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: provider.hasMoreData
              ? () async {
                  await provider.cargarSiguientePagina();
                  _ajustarCamaraSegunResultados(
                    provider.iglesiasMostradas,
                    provider.modo,
                    provider.radioKm,
                    provider.currentPosition,
                  );
                }
              : null,
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.035,
              vertical: usableHeight * 0.008,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (provider.isLoadingMore)
                  SizedBox(
                    width: screenWidth * 0.038,
                    height: screenWidth * 0.038,
                    child: const CircularProgressIndicator(
                      color: amarilloOro,
                      strokeWidth: 2.0,
                    ),
                  )
                else
                  Icon(
                    provider.hasMoreData
                        ? Icons.add_location_alt_rounded
                        : Icons.check_circle_outline_rounded,
                    color: amarilloOro,
                    size: screenWidth * 0.042,
                  ),
                SizedBox(width: screenWidth * 0.015),
                Text(
                  provider.modo == ModoExploracion.radio
                      ? '${provider.bufferResultados.length} ${l10n?.iglesiasEnMapa ?? "iglesias en mapa"}'
                      : (provider.hasMoreData
                            ? (l10n?.verMasPaginacion(
                                    totalMostradas.toString(),
                                    totalCargadas.toString(),
                                  ) ??
                                  'Ver 15 más ($totalMostradas de $totalCargadas)')
                            : (l10n?.totalIglesiasEnMapa(
                                    totalMostradas.toString(),
                                  ) ??
                                  '$totalMostradas iglesias en mapa')),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.029,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tarjeta flotante de información de la iglesia seleccionada y botón de registro
  Widget _buildChurchInfoCard({
    required IglesiaExplorarModel iglesia,
    required double screenWidth,
    required double usableHeight,
    required AppLocalizations? l10n,
  }) {
    final distanciaStr = iglesia.distanciaKm > 0
        ? (l10n?.aDistanciaKm(iglesia.distanciaKm.toStringAsFixed(1)) ??
              'A ${iglesia.distanciaKm.toStringAsFixed(1)} km')
        : '';

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.045),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 15,
            offset: const Offset(0, 6),
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
                  iglesia.denominacion.isNotEmpty
                      ? iglesia.denominacion
                      : (l10n?.comunidadCristiana ?? 'Comunidad cristiana'),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: screenWidth * 0.032,
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
                  SizedBox(width: screenWidth * 0.008),
                  Text(
                    iglesia.rating.toStringAsFixed(1),
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.032,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (iglesia.totalResenas > 0)
                    Text(
                      ' (${iglesia.totalResenas})',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: screenWidth * 0.028,
                      ),
                    ),
                  SizedBox(width: screenWidth * 0.02),
                  GestureDetector(
                    onTap: () => setState(() => _iglesiaSeleccionada = null),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.grey.shade400,
                      size: screenWidth * 0.05,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: usableHeight * 0.006),
          Text(
            iglesia.nombre.isNotEmpty
                ? iglesia.nombre
                : (l10n?.sinNombre ?? 'Sin nombre'),
            style: TextStyle(
              color: azulFondo,
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (iglesia.direccion.isNotEmpty) ...[
            SizedBox(height: usableHeight * 0.004),
            Text(
              iglesia.direccion,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: screenWidth * 0.03,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: usableHeight * 0.01),
          Row(
            children: [
              if (distanciaStr.isNotEmpty) ...[
                Icon(
                  Icons.near_me_outlined,
                  color: Colors.grey.shade600,
                  size: screenWidth * 0.034,
                ),
                SizedBox(width: screenWidth * 0.008),
                Text(
                  distanciaStr,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const Spacer(),
              // Botón "Cómo llegar" opcional rápido
              if (iglesia.latLng != null) ...[
                IconButton(
                  tooltip: l10n?.comoLlegar ?? 'Cómo llegar',
                  onPressed: () =>
                      _abrirNavegacion(iglesia.latLng, iglesia.nombre),
                  icon: Icon(
                    Icons.directions_rounded,
                    color: azulFondo,
                    size: screenWidth * 0.06,
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
              ],
              // Botón Principal: Seleccionar Iglesia
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: amarilloOro,
                  foregroundColor: azulFondo,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.045,
                    vertical: usableHeight * 0.012,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                  ),
                ),
                onPressed: _guardandoIglesia
                    ? null
                    : () => _registrarIglesia(iglesia),
                icon: _guardandoIglesia
                    ? SizedBox(
                        width: screenWidth * 0.04,
                        height: screenWidth * 0.04,
                        child: const CircularProgressIndicator(
                          color: azulFondo,
                          strokeWidth: 2.0,
                        ),
                      )
                    : Icon(
                        Icons.check_circle_rounded,
                        size: screenWidth * 0.046,
                      ),
                label: Text(
                  l10n?.seleccionarIglesia ?? 'Seleccionar iglesia',
                  style: TextStyle(
                    fontSize: screenWidth * 0.034,
                    fontWeight: FontWeight.bold,
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
