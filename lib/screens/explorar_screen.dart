import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../modelos/iglesia_explorar_model.dart';
import '../providers/ajustes_provider.dart';
import '../providers/explorar_provider.dart';
import 'iglesias_en_mapa_screen.dart';

/// Pantalla ExplorarScreen: Búsqueda dual estricta al país actual del usuario
/// (si está en RD, solo busca en RD; si está en Colombia, solo busca en Colombia).
/// Paginación estricta de 15 en 15 (Lazy Loading / Scroll infinito), mitigación de costos
/// de Google Places API (Debounce de 500 ms + Cache TTL) y diseño 100% responsivo Material 3.
class ExplorarScreen extends StatefulWidget {
  const ExplorarScreen({super.key});

  @override
  State<ExplorarScreen> createState() => _ExplorarScreenState();
}

class _ExplorarScreenState extends State<ExplorarScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFEFEFEF);

  final List<String> _filtrosKeys = [
    'todos',
    'catolica',
    'evangelica',
    'pentecostal',
    'bautista',
    'adventista',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _inicializarExploracion();
      }
    });
  }

  void _onSearchTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Listener para scroll infinito: solicita el siguiente lote de 15 cuando se acerca al final
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 250) {
      context.read<ExplorarProvider>().cargarSiguientePagina();
    }
  }

  /// Inicializa la ubicación GPS y sincroniza con el país actual del usuario
  Future<void> _inicializarExploracion() async {
    final explorarProv = context.read<ExplorarProvider>();
    final ajustesProv = context.read<AjustesProvider>();

    // Sincronizar país de residencia actual desde ajustes
    explorarProv.sincronizarPais(ajustesProv.paisRegion);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        explorarProv.buscar(ignorarDebounce: true);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        // setUbicacion también detecta geográficamente el país de las coordenadas
        explorarProv.setUbicacion(pos);
      }
    } catch (e) {
      debugPrint('Aviso obteniendo ubicación GPS inicial: $e');
    }

    // Ejecutar búsqueda inicial limitada estrictamente al país actual
    explorarProv.buscar(ignorarDebounce: true);
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
              l10n?.noSePudoAbrirNavegacion ?? 'No se pudo abrir la navegación.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error abriendo mapa: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final screenWidth = size.width;
    final usableHeight = size.height - padding.top - padding.bottom;

    final provider = context.watch<ExplorarProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Encabezado institucional superior
        _buildHeader(context, provider, l10n, screenWidth, usableHeight),

        // 2. Canvas principal aprovechando el 100% del alto restante
        Expanded(
          child: Container(
            width: screenWidth,
            decoration: BoxDecoration(
              color: blancoFondo,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(screenWidth * 0.075),
                topRight: Radius.circular(screenWidth * 0.075),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: screenWidth * 0.04,
                  offset: Offset(0, -usableHeight * 0.005),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(screenWidth * 0.075),
                topRight: Radius.circular(screenWidth * 0.075),
              ),
              child: RefreshIndicator(
                color: azulFondo,
                backgroundColor: amarilloOro,
                onRefresh: () async {
                  await provider.refrescar();
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // Área superior de controles (Modo, Buscador, Denominaciones y Banner)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          screenWidth * 0.045,
                          usableHeight * 0.02,
                          screenWidth * 0.045,
                          usableHeight * 0.01,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Selector de Modo y Radio estricto al país actual
                            _buildModeAndRangeBar(
                              context,
                              provider,
                              l10n,
                              screenWidth,
                              usableHeight,
                            ),
                            SizedBox(height: usableHeight * 0.016),

                            // Barra de búsqueda con Debounce de 500 ms
                            _buildSearchBar(
                              context,
                              provider,
                              l10n,
                              screenWidth,
                              usableHeight,
                            ),
                            SizedBox(height: usableHeight * 0.016),

                            // Filtros de Denominación interactivos
                            _buildFilterChips(
                              context,
                              provider,
                              l10n,
                              screenWidth,
                              usableHeight,
                            ),
                            SizedBox(height: usableHeight * 0.02),

                            // Banner interactivo hacia el mapa general
                            _buildMapBanner(
                              context,
                              l10n,
                              screenWidth,
                              usableHeight,
                            ),
                            SizedBox(height: usableHeight * 0.022),

                            // Cabecera de la sección de resultados
                            _buildSectionHeader(
                              context,
                              provider,
                              l10n,
                              screenWidth,
                              usableHeight,
                            ),
                            SizedBox(height: usableHeight * 0.012),
                          ],
                        ),
                      ),
                    ),

                    // Estados Dinámicos y Lista de Resultados con Paginación
                    if (provider.isLoading)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildLoadingState(
                          l10n,
                          screenWidth,
                          usableHeight,
                        ),
                      )
                    else if (provider.errorMessage != null)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildErrorState(
                          provider,
                          l10n,
                          screenWidth,
                          usableHeight,
                        ),
                      )
                    else if (provider.iglesiasMostradas.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(
                          provider,
                          l10n,
                          screenWidth,
                          usableHeight,
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          screenWidth * 0.045,
                          0,
                          screenWidth * 0.045,
                          usableHeight * 0.03,
                        ),
                        sliver: SliverList.builder(
                          itemCount: provider.iglesiasMostradas.length +
                              (provider.isLoadingMore || provider.hasMoreData
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index == provider.iglesiasMostradas.length) {
                              return _buildBottomPaginationLoader(
                                provider,
                                l10n,
                                screenWidth,
                                usableHeight,
                              );
                            }

                            final iglesia = provider.iglesiasMostradas[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: usableHeight * 0.014,
                              ),
                              child: _buildChurchCard(
                                context: context,
                                screenWidth: screenWidth,
                                usableHeight: usableHeight,
                                iglesia: iglesia,
                                l10n: l10n,
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
        ),
      ],
    );
  }

  /// Encabezado superior con título y estado de cobertura
  Widget _buildHeader(
    BuildContext context,
    ExplorarProvider provider,
    AppLocalizations? l10n,
    double screenWidth,
    double usableHeight,
  ) {
    final idioma = Localizations.localeOf(context).languageCode;
    final paisNombre = provider.getPaisNombre(idioma);
    final esNacional = provider.modo == ModoExploracion.nacional;
    final subtitulo = esNacional
        ? (l10n?.busquedaEnTodoPaisConBandera(
                paisNombre,
                provider.paisBandera,
              ) ??
            'Búsqueda en todo $paisNombre ${provider.paisBandera}')
        : (l10n?.encuentraTuFeEn10Km ??
            l10n?.comunidadesCristianasCercanas ??
            'Comunidades cristianas cercanas');

    return Container(
      width: screenWidth,
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.05,
        usableHeight * 0.012,
        screenWidth * 0.05,
        usableHeight * 0.018,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n?.explorar ?? 'Explorar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.068,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: usableHeight * 0.003),
                Text(
                  subtitulo,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: screenWidth * 0.036,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Botón indicador interactivo que actualiza GPS
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _inicializarExploracion,
              borderRadius: BorderRadius.circular(screenWidth * 0.06),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: usableHeight * 0.008,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(screenWidth * 0.06),
                  border: Border.all(
                    color: amarilloOro.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      provider.paisBandera,
                      style: TextStyle(fontSize: screenWidth * 0.038),
                    ),
                    SizedBox(width: screenWidth * 0.012),
                    Text(
                      esNacional
                          ? provider.paisCodigo
                          : '${provider.radioKm.toInt()} km',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.032,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Barra de control dual: Selector de Modo (Radio vs. Nacional) y Bloqueo estricto al país actual
  Widget _buildModeAndRangeBar(
    BuildContext context,
    ExplorarProvider provider,
    AppLocalizations? l10n,
    double screenWidth,
    double usableHeight,
  ) {
    final idioma = Localizations.localeOf(context).languageCode;
    final paisNombre = provider.getPaisNombre(idioma);
    final esRadio = provider.modo == ModoExploracion.radio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Selector de Modo: Por Radio vs. Nacional
        Container(
          width: screenWidth,
          padding: EdgeInsets.all(screenWidth * 0.01),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(screenWidth * 0.035),
            border: Border.all(color: grisBorde),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => provider.cambiarModo(ModoExploracion.radio),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      vertical: usableHeight * 0.01,
                    ),
                    decoration: BoxDecoration(
                      color: esRadio ? azulFondo : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        screenWidth * 0.028,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.radar_rounded,
                          color: esRadio ? amarilloOro : azulFondo,
                          size: screenWidth * 0.042,
                        ),
                        SizedBox(width: screenWidth * 0.015),
                        Text(
                          l10n?.busquedaPorRadio ?? 'Por radio',
                          style: TextStyle(
                            color: esRadio ? Colors.white : azulFondo,
                            fontSize: screenWidth * 0.034,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => provider.cambiarModo(ModoExploracion.nacional),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      vertical: usableHeight * 0.01,
                    ),
                    decoration: BoxDecoration(
                      color: !esRadio ? azulFondo : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        screenWidth * 0.028,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          provider.paisBandera,
                          style: TextStyle(fontSize: screenWidth * 0.038),
                        ),
                        SizedBox(width: screenWidth * 0.015),
                        Text(
                          l10n?.busquedaNacional ?? 'Nacional',
                          style: TextStyle(
                            color: !esRadio ? Colors.white : azulFondo,
                            fontSize: screenWidth * 0.034,
                            fontWeight: FontWeight.bold,
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
        SizedBox(height: usableHeight * 0.012),

        // 2. Sub-controles según el modo
        if (esRadio)
          // Selector de rangos de kilometraje: 10 km, 25 km, 50 km
          Row(
            children: [
              Text(
                l10n?.radioEtiqueta ?? 'Radio:',
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.033,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: screenWidth * 0.025),
              ...[10.0, 25.0, 50.0].map((km) {
                final isSelected = provider.radioKm == km;
                return Padding(
                  padding: EdgeInsets.only(right: screenWidth * 0.02),
                  child: GestureDetector(
                    onTap: () => provider.cambiarRadio(km),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.032,
                        vertical: usableHeight * 0.005,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? azulFondo : Colors.white,
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.025,
                        ),
                        border: Border.all(
                          color: isSelected ? azulFondo : grisBorde,
                        ),
                      ),
                      child: Text(
                        '${km.toInt()} km',
                        style: TextStyle(
                          color: isSelected ? Colors.white : azulFondo,
                          fontSize: screenWidth * 0.03,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          )
        else
          // Indicador estricto de país actual (Bloqueado al país del usuario)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.035,
              vertical: usableHeight * 0.008,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              border: Border.all(color: grisBorde),
            ),
            child: Row(
              children: [
                Text(
                  provider.paisBandera,
                  style: TextStyle(fontSize: screenWidth * 0.045),
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Text(
                    l10n?.busquedaExclusivaEn(paisNombre) ??
                        'Búsqueda exclusiva en: $paisNombre',
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.032,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.02,
                    vertical: usableHeight * 0.003,
                  ),
                  decoration: BoxDecoration(
                    color: azulFondo.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: azulFondo,
                        size: screenWidth * 0.032,
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Text(
                        l10n?.tuPais ?? 'Tu país',
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.026,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Buscador Material 3 con debounce de 500 ms y longitud mínima de 3 caracteres
  Widget _buildSearchBar(
    BuildContext context,
    ExplorarProvider provider,
    AppLocalizations? l10n,
    double screenWidth,
    double usableHeight,
  ) {
    final idioma = Localizations.localeOf(context).languageCode;
    final paisNombre = provider.getPaisNombre(idioma);
    final hint = provider.modo == ModoExploracion.nacional
        ? (l10n?.buscarEnPaisPlaceholder(paisNombre) ??
            'Buscar en $paisNombre...')
        : (l10n?.buscarIglesiasPlaceholder ??
            'Ej. Iglesia cristiana, Bautista...');

    final texto = _searchController.text.trim();
    final advertenciaMinCaracteres = texto.isNotEmpty && texto.length < 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
            border: Border.all(
              color: advertenciaMinCaracteres ? amarilloOro : grisBorde,
              width: advertenciaMinCaracteres ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: screenWidth * 0.02,
                offset: Offset(0, usableHeight * 0.003),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.035,
            vertical: usableHeight * 0.004,
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: azulFondo,
                size: screenWidth * 0.058,
              ),
              SizedBox(width: screenWidth * 0.025),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: (val) {
                    provider.onTextoBusquedaCambiado(val);
                  },
                  onSubmitted: (val) {
                    _searchFocusNode.unfocus();
                    final texto = val.trim();
                    if (texto.isEmpty) {
                      provider.limpiarBusqueda();
                    } else {
                      provider.ejecutarBusquedaInmediata(texto);
                    }
                  },
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: screenWidth * 0.034,
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: usableHeight * 0.014,
                    ),
                  ),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    _searchFocusNode.unfocus();
                    provider.limpiarBusqueda();
                  },
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.01),
                    child: Icon(
                      Icons.cancel_rounded,
                      color: Colors.grey.shade400,
                      size: screenWidth * 0.048,
                    ),
                  ),
                ),
              SizedBox(width: screenWidth * 0.01),
              Material(
                color: amarilloOro,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                child: InkWell(
                  onTap: () {
                    _searchFocusNode.unfocus();
                    final texto = _searchController.text.trim();
                    if (texto.isEmpty) {
                      provider.limpiarBusqueda();
                    } else {
                      provider.ejecutarBusquedaInmediata(texto);
                    }
                  },
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.02),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: azulFondo,
                      size: screenWidth * 0.046,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (advertenciaMinCaracteres) ...[
          SizedBox(height: usableHeight * 0.005),
          Padding(
            padding: EdgeInsets.only(left: screenWidth * 0.02),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.orange.shade800,
                  size: screenWidth * 0.032,
                ),
                SizedBox(width: screenWidth * 0.01),
                Text(
                  l10n?.escribeAlMenos3Caracteres ??
                      'Escribe al menos 3 caracteres',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontSize: screenWidth * 0.028,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Barra horizontal interactiva de denominaciones
  Widget _buildFilterChips(
    BuildContext context,
    ExplorarProvider provider,
    AppLocalizations? l10n,
    double screenWidth,
    double usableHeight,
  ) {
    return SizedBox(
      height: usableHeight * 0.046,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filtrosKeys.length,
        separatorBuilder: (context, index) =>
            SizedBox(width: screenWidth * 0.022),
        itemBuilder: (context, index) {
          final isSelected = provider.filtroDenominacionIndex == index;
          final label = _getFiltroLabel(index, l10n);

          return GestureDetector(
            onTap: () {
              provider.cambiarDenominacion(index);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
              ),
              decoration: BoxDecoration(
                color: isSelected ? azulFondo : Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.05),
                border: Border.all(
                  color: isSelected ? azulFondo : grisBorde,
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: azulFondo.withValues(alpha: 0.18),
                          blurRadius: screenWidth * 0.02,
                          offset: Offset(0, usableHeight * 0.003),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      Container(
                        width: screenWidth * 0.016,
                        height: screenWidth * 0.016,
                        decoration: const BoxDecoration(
                          color: amarilloOro,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.018),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : azulFondo,
                        fontSize: screenWidth * 0.033,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Banner interactivo con gradiente para navegar al mapa general
  Widget _buildMapBanner(
    BuildContext context,
    AppLocalizations? l10n,
    double screenWidth,
    double usableHeight,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          IglesiasEnMapaScreen.routeName,
        ),
        borderRadius: BorderRadius.circular(screenWidth * 0.045),
        child: Ink(
          width: screenWidth,
          padding: EdgeInsets.all(screenWidth * 0.04),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(screenWidth * 0.045),
            gradient: const LinearGradient(
              colors: [azulFondo, Color(0xFF133E68)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: azulFondo.withValues(alpha: 0.22),
                blurRadius: screenWidth * 0.03,
                offset: Offset(0, usableHeight * 0.006),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: screenWidth * 0.125,
                height: screenWidth * 0.125,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: amarilloOro.withValues(alpha: 0.5),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.map_rounded,
                    color: amarilloOro,
                    size: screenWidth * 0.065,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.035),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n?.visualizaIglesiasEnMapa ??
                          'Visualiza las iglesias en el Mapa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.042,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.003),
                    Text(
                      l10n?.exploraTemplosSubtitulo ??
                          'Explora templos, rutas y detalles en vivo',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: screenWidth * 0.03,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: screenWidth * 0.035,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Título de sección de resultados con conteo y descripción del filtro
  Widget _buildSectionHeader(
    BuildContext context,
    ExplorarProvider provider,
    AppLocalizations? l10n,
    double screenWidth,
    double usableHeight,
  ) {
    final idioma = Localizations.localeOf(context).languageCode;
    final paisNombre = provider.getPaisNombre(idioma);
    final totalMostradas = provider.iglesiasMostradas.length;
    final totalCargadas = provider.totalResultadosCargados;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n?.comunidadesSugeridas ?? 'Comunidades sugeridas',
              style: TextStyle(
                color: azulFondo,
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!provider.isLoading && totalMostradas > 0) ...[
              SizedBox(width: screenWidth * 0.02),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.022,
                  vertical: usableHeight * 0.003,
                ),
                decoration: BoxDecoration(
                  color: azulFondo.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
                child: Text(
                  totalCargadas > totalMostradas
                      ? (l10n?.conteoResultadosDeTotal(
                              '$totalMostradas',
                              '$totalCargadas',
                            ) ??
                          '$totalMostradas de $totalCargadas')
                      : '$totalMostradas',
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (!provider.isLoading && totalMostradas > 0)
          Text(
            provider.modo == ModoExploracion.radio
                ? (l10n?.radioMenorQueKm(provider.radioKm.toInt().toString()) ??
                    'Radio < ${provider.radioKm.toInt()} km')
                : paisNombre,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }

  /// Tarjeta de Iglesia responsiva Material 3
  Widget _buildChurchCard({
    required BuildContext context,
    required double screenWidth,
    required double usableHeight,
    required IglesiaExplorarModel iglesia,
    required AppLocalizations? l10n,
  }) {
    final String distanciaStr = iglesia.distanciaKm > 0
        ? (l10n?.aDistanciaKm(iglesia.distanciaKm.toStringAsFixed(1)) ??
            'A ${iglesia.distanciaKm.toStringAsFixed(1)} km')
        : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        border: Border.all(color: grisBorde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: screenWidth * 0.02,
            offset: Offset(0, usableHeight * 0.003),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          onTap: () => _abrirNavegacion(iglesia.latLng, iglesia.nombre),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.035),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar con icono de iglesia
                Container(
                  width: screenWidth * 0.13,
                  height: screenWidth * 0.13,
                  decoration: BoxDecoration(
                    color: iglesia.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(screenWidth * 0.032),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.church_rounded,
                      color: iglesia.color,
                      size: screenWidth * 0.075,
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.032),

                // Contenido textual
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        iglesia.nombre,
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: usableHeight * 0.004),
                      Text(
                        iglesia.denominacion,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: screenWidth * 0.032,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: usableHeight * 0.006),

                      // Fila de metadatos (Calificación y Distancia)
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.018,
                              vertical: usableHeight * 0.002,
                            ),
                            decoration: BoxDecoration(
                              color: amarilloOro.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.02,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: amarilloOro,
                                  size: screenWidth * 0.035,
                                ),
                                SizedBox(width: screenWidth * 0.008),
                                Text(
                                  iglesia.rating.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: azulFondo,
                                    fontSize: screenWidth * 0.028,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (distanciaStr.isNotEmpty) ...[
                            SizedBox(width: screenWidth * 0.02),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.near_me_outlined,
                                  color: Colors.grey.shade500,
                                  size: screenWidth * 0.032,
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
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),

                // Botón CTA para Navegación
                Material(
                  color: azulFondo.withValues(alpha: 0.07),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () =>
                        _abrirNavegacion(iglesia.latLng, iglesia.nombre),
                    child: Padding(
                      padding: EdgeInsets.all(screenWidth * 0.024),
                      child: Icon(
                        Icons.directions_rounded,
                        color: azulFondo,
                        size: screenWidth * 0.055,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Indicador al pie de lista para la carga perezosa de 15 en 15 elementos
  Widget _buildBottomPaginationLoader(
    ExplorarProvider provider,
    AppLocalizations? l10n,
    double screenWidth,
    double usableHeight,
  ) {
    if (provider.isLoadingMore) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: usableHeight * 0.02),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: screenWidth * 0.05,
                height: screenWidth * 0.05,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: amarilloOro,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Text(
                l10n?.cargandoMasIglesias ?? 'Cargando más comunidades...',
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.032,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!provider.hasMoreData && provider.iglesiasMostradas.length >= 15) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: usableHeight * 0.02),
        child: Center(
          child: Text(
            l10n?.finDeResultados ?? 'Has llegado al final de los resultados',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: screenWidth * 0.03,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// Estado de Carga
  Widget _buildLoadingState(
    AppLocalizations? l10n,
    double screenWidth,
    double usableHeight,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: screenWidth * 0.12,
              height: screenWidth * 0.12,
              child: const CircularProgressIndicator(
                color: amarilloOro,
                strokeWidth: 3.5,
              ),
            ),
            SizedBox(height: usableHeight * 0.025),
            Text(
              l10n?.localizandoComunidades ??
                  l10n?.obteniendoUbicacionEspera ??
                  'Localizando comunidades cristianas...',
              style: TextStyle(
                color: azulFondo,
                fontSize: screenWidth * 0.038,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Estado de Error con botón de reintento
  Widget _buildErrorState(
    ExplorarProvider provider,
    AppLocalizations? l10n,
    double screenWidth,
    double usableHeight,
  ) {
    final mensajeError = provider.errorMessage != null
        ? (l10n?.noSePudieronCargarIglesias ?? provider.errorMessage!)
        : '';

    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_off_rounded,
                color: Colors.red.shade400,
                size: screenWidth * 0.12,
              ),
            ),
            SizedBox(height: usableHeight * 0.02),
            Text(
              mensajeError,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: screenWidth * 0.036,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: usableHeight * 0.025),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: amarilloOro,
                foregroundColor: azulFondo,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.06,
                  vertical: usableHeight * 0.014,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
              ),
              onPressed: () => provider.buscar(
                ignorarDebounce: true,
                forzarRecarga: true,
              ),
              icon: Icon(Icons.refresh_rounded, size: screenWidth * 0.045),
              label: Text(
                l10n?.reintentar ?? 'Reintentar',
                style: TextStyle(
                  fontSize: screenWidth * 0.036,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Estado Vacío
  Widget _buildEmptyState(
    ExplorarProvider provider,
    AppLocalizations? l10n,
    double screenWidth,
    double usableHeight,
  ) {
    final idioma = Localizations.localeOf(context).languageCode;
    final paisNombre = provider.getPaisNombre(idioma);
    final textoBusqueda = provider.textoBusqueda.trim();
    final String mensaje;
    if (textoBusqueda.isNotEmpty) {
      mensaje = l10n?.noSeEncontraronIglesiasConTermino(textoBusqueda) ??
          'No se encontraron iglesias con "$textoBusqueda" en su nombre.';
    } else if (provider.modo == ModoExploracion.radio) {
      mensaje = l10n?.noSeEncontraronIglesiasRadioEnPais(
            provider.radioKm.toInt().toString(),
            paisNombre,
          ) ??
          'No se encontraron iglesias a menos de ${provider.radioKm.toInt()} km en $paisNombre.';
    } else {
      mensaje = l10n?.noSeEncontraronIglesiasEnPais(paisNombre) ??
          'No se encontraron iglesias en $paisNombre.';
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                color: azulFondo.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.church_outlined,
                color: azulFondo.withValues(alpha: 0.4),
                size: screenWidth * 0.14,
              ),
            ),
            SizedBox(height: usableHeight * 0.02),
            Text(
              mensaje,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: screenWidth * 0.038,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: usableHeight * 0.02),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: azulFondo,
                side: const BorderSide(color: azulFondo),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: usableHeight * 0.012,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
              ),
              onPressed: () {
                _searchController.clear();
                provider.cambiarDenominacion(0);
                provider.limpiarBusqueda();
              },
              icon: Icon(Icons.restore_rounded, size: screenWidth * 0.045),
              label: Text(
                l10n?.todos ?? 'Ver todas',
                style: TextStyle(
                  fontSize: screenWidth * 0.034,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
