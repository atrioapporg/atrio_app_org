import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../modelos/iglesia_explorar_model.dart';
import '../providers/ajustes_provider.dart';
import '../providers/explorar_provider.dart';
import '../widgets/atrio_connectivity_alert.dart';
import 'iglesias_en_mapa_screen.dart';

const Color azulFondo = Color(0xFF072B4F);
const Color amarilloOro = Color(0xFFE5A023);
const Color blancoFondo = Color(0xFFFAF7F0);
const Color grisBorde = Color(0xFFEFEFEF);

const List<String> _filtrosKeys = [
  'todos',
  'catolica',
  'evangelica',
  'pentecostal',
  'bautista',
  'adventista',
];

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

  Future<void> _abrirNavegacion(LatLng? latLng, String nombre) async {
    if (latLng == null) return;

    final hasInternet = await AtrioConnectivityAlert.checkAndNotify(context);
    if (!hasInternet || !mounted) return;

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
        _ExplorarHeader(
          provider: provider,
          l10n: l10n,
          screenWidth: screenWidth,
          usableHeight: usableHeight,
          onLocationTap: _inicializarExploracion,
        ),

        // 2. Canvas principal aprovechando el 100% del alto restante
        Expanded(
          child: Container(
            width: screenWidth,
            decoration: BoxDecoration(
              color: blancoFondo,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(screenWidth * 0.075),
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
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(screenWidth * 0.075),
              ),
              child: RefreshIndicator(
                color: azulFondo,
                backgroundColor: amarilloOro,
                onRefresh: () async {
                  final hasInternet =
                      await AtrioConnectivityAlert.checkAndNotify(context);
                  if (!hasInternet) return;
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
                        padding: EdgeInsetsDirectional.fromSTEB(
                          screenWidth * 0.045,
                          usableHeight * 0.02,
                          screenWidth * 0.045,
                          usableHeight * 0.01,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Selector de Modo y Radio estricto al país actual
                            _ModeAndRangeBar(
                              provider: provider,
                              l10n: l10n,
                              screenWidth: screenWidth,
                              usableHeight: usableHeight,
                            ),
                            SizedBox(height: usableHeight * 0.016),

                            // Barra de búsqueda con Debounce de 500 ms
                            _ExplorarSearchBar(
                              provider: provider,
                              l10n: l10n,
                              screenWidth: screenWidth,
                              usableHeight: usableHeight,
                              searchController: _searchController,
                              searchFocusNode: _searchFocusNode,
                            ),
                            SizedBox(height: usableHeight * 0.016),

                            // Filtros de Denominación interactivos
                            _FilterChipsBar(
                              provider: provider,
                              l10n: l10n,
                              screenWidth: screenWidth,
                              usableHeight: usableHeight,
                            ),
                            SizedBox(height: usableHeight * 0.02),

                            // Banner interactivo hacia el mapa general
                            _MapBanner(
                              l10n: l10n,
                              screenWidth: screenWidth,
                              usableHeight: usableHeight,
                              onTap: () async {
                                final hasInternet =
                                    await AtrioConnectivityAlert.checkAndNotify(
                                      context,
                                    );
                                if (!hasInternet || !context.mounted) return;
                                Navigator.pushNamed(
                                  context,
                                  IglesiasEnMapaScreen.routeName,
                                );
                              },
                            ),
                            SizedBox(height: usableHeight * 0.022),

                            // Cabecera de la sección de resultados
                            _SectionHeader(
                              provider: provider,
                              l10n: l10n,
                              screenWidth: screenWidth,
                              usableHeight: usableHeight,
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
                        child: _LoadingState(
                          l10n: l10n,
                          screenWidth: screenWidth,
                          usableHeight: usableHeight,
                        ),
                      )
                    else if (provider.errorMessage != null)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _ErrorState(
                          provider: provider,
                          l10n: l10n,
                          screenWidth: screenWidth,
                          usableHeight: usableHeight,
                          onRetry: () async {
                            final hasInternet =
                                await AtrioConnectivityAlert.checkAndNotify(
                                  context,
                                );
                            if (!hasInternet) return;
                            provider.buscar(
                              ignorarDebounce: true,
                              forzarRecarga: true,
                            );
                          },
                        ),
                      )
                    else if (provider.iglesiasMostradas.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          provider: provider,
                          l10n: l10n,
                          screenWidth: screenWidth,
                          usableHeight: usableHeight,
                          onReset: () {
                            _searchController.clear();
                            provider.cambiarDenominacion(0);
                            provider.limpiarBusqueda();
                          },
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          screenWidth * 0.045,
                          0,
                          screenWidth * 0.045,
                          usableHeight * 0.03,
                        ),
                        sliver: SliverList.builder(
                          itemCount:
                              provider.iglesiasMostradas.length +
                              (provider.isLoadingMore || provider.hasMoreData
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index == provider.iglesiasMostradas.length) {
                              return _BottomPaginationLoader(
                                provider: provider,
                                l10n: l10n,
                                screenWidth: screenWidth,
                                usableHeight: usableHeight,
                              );
                            }

                            final iglesia = provider.iglesiasMostradas[index];
                            return Padding(
                              padding: EdgeInsetsDirectional.only(
                                bottom: usableHeight * 0.014,
                              ),
                              child: _ChurchCard(
                                screenWidth: screenWidth,
                                usableHeight: usableHeight,
                                iglesia: iglesia,
                                l10n: l10n,
                                onNavigationTap: () => _abrirNavegacion(
                                  iglesia.latLng,
                                  iglesia.nombre,
                                ),
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
}

class _ExplorarHeader extends StatelessWidget {
  final ExplorarProvider provider;
  final AppLocalizations? l10n;
  final double screenWidth;
  final double usableHeight;
  final VoidCallback onLocationTap;

  const _ExplorarHeader({
    required this.provider,
    required this.l10n,
    required this.screenWidth,
    required this.usableHeight,
    required this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
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

    final locale = Localizations.localeOf(context).toString();
    final radioNumStr = NumberFormat.decimalPattern(locale)
        .format(provider.radioKm.toInt());

    return Container(
      width: screenWidth,
      padding: EdgeInsetsDirectional.fromSTEB(
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
              onTap: onLocationTap,
              borderRadius: BorderRadius.circular(screenWidth * 0.06),
              child: Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: usableHeight * 0.008,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(screenWidth * 0.06),
                  border: Border.all(color: amarilloOro.withValues(alpha: 0.4)),
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
                      esNacional ? provider.paisCodigo : '$radioNumStr km',
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
}

class _ModeAndRangeBar extends StatelessWidget {
  final ExplorarProvider provider;
  final AppLocalizations? l10n;
  final double screenWidth;
  final double usableHeight;

  const _ModeAndRangeBar({
    required this.provider,
    required this.l10n,
    required this.screenWidth,
    required this.usableHeight,
  });

  @override
  Widget build(BuildContext context) {
    final idioma = Localizations.localeOf(context).languageCode;
    final locale = Localizations.localeOf(context).toString();
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
                      borderRadius: BorderRadius.circular(screenWidth * 0.028),
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
                      borderRadius: BorderRadius.circular(screenWidth * 0.028),
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
                final kmFormatted = NumberFormat.decimalPattern(locale)
                    .format(km.toInt());

                return Padding(
                  padding: EdgeInsetsDirectional.only(end: screenWidth * 0.02),
                  child: GestureDetector(
                    onTap: () => provider.cambiarRadio(km),
                    child: Container(
                      padding: EdgeInsetsDirectional.symmetric(
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
                        '$kmFormatted km',
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
            padding: EdgeInsetsDirectional.symmetric(
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
                  padding: EdgeInsetsDirectional.symmetric(
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
}

class _ExplorarSearchBar extends StatelessWidget {
  final ExplorarProvider provider;
  final AppLocalizations? l10n;
  final double screenWidth;
  final double usableHeight;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;

  const _ExplorarSearchBar({
    required this.provider,
    required this.l10n,
    required this.screenWidth,
    required this.usableHeight,
    required this.searchController,
    required this.searchFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    final idioma = Localizations.localeOf(context).languageCode;
    final paisNombre = provider.getPaisNombre(idioma);
    final hint = provider.modo == ModoExploracion.nacional
        ? (l10n?.buscarEnPaisPlaceholder(paisNombre) ??
              'Buscar en $paisNombre...')
        : (l10n?.buscarIglesiasPlaceholder ??
              'Ej. Iglesia cristiana, Bautista...');

    final texto = searchController.text.trim();
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
          padding: EdgeInsetsDirectional.symmetric(
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
                  controller: searchController,
                  focusNode: searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: (val) {
                    provider.onTextoBusquedaCambiado(val);
                  },
                  onSubmitted: (val) {
                    searchFocusNode.unfocus();
                    final textoSubmitted = val.trim();
                    if (textoSubmitted.isEmpty) {
                      provider.limpiarBusqueda();
                    } else {
                      provider.ejecutarBusquedaInmediata(textoSubmitted);
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
                    contentPadding: EdgeInsetsDirectional.symmetric(
                      vertical: usableHeight * 0.014,
                    ),
                  ),
                ),
              ),
              if (searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    searchController.clear();
                    searchFocusNode.unfocus();
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
                    searchFocusNode.unfocus();
                    final textoAction = searchController.text.trim();
                    if (textoAction.isEmpty) {
                      provider.limpiarBusqueda();
                    } else {
                      provider.ejecutarBusquedaInmediata(textoAction);
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
            padding: EdgeInsetsDirectional.only(start: screenWidth * 0.02),
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
}

class _FilterChipsBar extends StatelessWidget {
  final ExplorarProvider provider;
  final AppLocalizations? l10n;
  final double screenWidth;
  final double usableHeight;

  const _FilterChipsBar({
    required this.provider,
    required this.l10n,
    required this.screenWidth,
    required this.usableHeight,
  });

  @override
  Widget build(BuildContext context) {
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
              padding: EdgeInsetsDirectional.symmetric(
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
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
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
}

class _MapBanner extends StatelessWidget {
  final AppLocalizations? l10n;
  final double screenWidth;
  final double usableHeight;
  final VoidCallback onTap;

  const _MapBanner({
    required this.l10n,
    required this.screenWidth,
    required this.usableHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
                  border: Border.all(color: amarilloOro.withValues(alpha: 0.5)),
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
}

class _SectionHeader extends StatelessWidget {
  final ExplorarProvider provider;
  final AppLocalizations? l10n;
  final double screenWidth;
  final double usableHeight;

  const _SectionHeader({
    required this.provider,
    required this.l10n,
    required this.screenWidth,
    required this.usableHeight,
  });

  @override
  Widget build(BuildContext context) {
    final idioma = Localizations.localeOf(context).languageCode;
    final locale = Localizations.localeOf(context).toString();
    final paisNombre = provider.getPaisNombre(idioma);
    final totalMostradas = provider.iglesiasMostradas.length;
    final totalCargadas = provider.totalResultadosCargados;

    final totalMostradasFormatted = NumberFormat.decimalPattern(locale)
        .format(totalMostradas);
    final totalCargadasFormatted = NumberFormat.decimalPattern(locale)
        .format(totalCargadas);
    final radioFormatted = NumberFormat.decimalPattern(locale)
        .format(provider.radioKm.toInt());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  l10n?.comunidadesSugeridas ?? 'Sugeridas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.042,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!provider.isLoading && totalMostradas > 0) ...[
                SizedBox(width: screenWidth * 0.02),
                Container(
                  padding: EdgeInsetsDirectional.symmetric(
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
                                totalMostradasFormatted,
                                totalCargadasFormatted,
                              ) ??
                              '$totalMostradasFormatted de $totalCargadasFormatted')
                        : totalMostradasFormatted,
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
        ),
        if (!provider.isLoading && totalMostradas > 0) ...[
          SizedBox(width: screenWidth * 0.02),
          Text(
            provider.modo == ModoExploracion.radio
                ? (l10n?.radioMenorQueKm(radioFormatted) ??
                      'Radio < $radioFormatted km')
                : paisNombre,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _ChurchCard extends StatelessWidget {
  final double screenWidth;
  final double usableHeight;
  final IglesiaExplorarModel iglesia;
  final AppLocalizations? l10n;
  final VoidCallback onNavigationTap;

  const _ChurchCard({
    required this.screenWidth,
    required this.usableHeight,
    required this.iglesia,
    required this.l10n,
    required this.onNavigationTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final ratingFormatted = NumberFormat('0.0', locale).format(iglesia.rating);
    final distanciaFormatted = NumberFormat(
      '0.0',
      locale,
    ).format(iglesia.distanciaKm);

    final String distanciaStr = iglesia.distanciaKm > 0
        ? (l10n?.aDistanciaKm(distanciaFormatted) ?? 'A $distanciaFormatted km')
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
          onTap: onNavigationTap,
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
                            padding: EdgeInsetsDirectional.symmetric(
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
                                  ratingFormatted,
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
                    onTap: onNavigationTap,
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
}

class _BottomPaginationLoader extends StatelessWidget {
  final ExplorarProvider provider;
  final AppLocalizations? l10n;
  final double screenWidth;
  final double usableHeight;

  const _BottomPaginationLoader({
    required this.provider,
    required this.l10n,
    required this.screenWidth,
    required this.usableHeight,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _LoadingState extends StatelessWidget {
  final AppLocalizations? l10n;
  final double screenWidth;
  final double usableHeight;

  const _LoadingState({
    required this.l10n,
    required this.screenWidth,
    required this.usableHeight,
  });

  @override
  Widget build(BuildContext context) {
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
}

class _ErrorState extends StatelessWidget {
  final ExplorarProvider provider;
  final AppLocalizations? l10n;
  final double screenWidth;
  final double usableHeight;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.provider,
    required this.l10n,
    required this.screenWidth,
    required this.usableHeight,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
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
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: screenWidth * 0.06,
                  vertical: usableHeight * 0.014,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
              ),
              onPressed: onRetry,
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
}

class _EmptyState extends StatelessWidget {
  final ExplorarProvider provider;
  final AppLocalizations? l10n;
  final double screenWidth;
  final double usableHeight;
  final VoidCallback onReset;

  const _EmptyState({
    required this.provider,
    required this.l10n,
    required this.screenWidth,
    required this.usableHeight,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final idioma = Localizations.localeOf(context).languageCode;
    final locale = Localizations.localeOf(context).toString();
    final paisNombre = provider.getPaisNombre(idioma);
    final textoBusqueda = provider.textoBusqueda.trim();
    final radioFormatted = NumberFormat.decimalPattern(locale)
        .format(provider.radioKm.toInt());

    final String mensaje;
    if (textoBusqueda.isNotEmpty) {
      mensaje =
          l10n?.noSeEncontraronIglesiasConTermino(textoBusqueda) ??
          'No se encontraron iglesias con "$textoBusqueda" en su nombre.';
    } else if (provider.modo == ModoExploracion.radio) {
      mensaje =
          l10n?.noSeEncontraronIglesiasRadioEnPais(
            radioFormatted,
            paisNombre,
          ) ??
          'No se encontraron iglesias a menos de $radioFormatted km en $paisNombre.';
    } else {
      mensaje =
          l10n?.noSeEncontraronIglesiasEnPais(paisNombre) ??
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
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: usableHeight * 0.012,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
              ),
              onPressed: onReset,
              icon: Icon(Icons.restore_rounded, size: screenWidth * 0.045),
              label: Text(
                l10n?.verTodas ?? l10n?.todos ?? 'Ver todas',
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
