import 'dart:async';

import 'package:atrio/screens/emisoras_cristianas_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';

import '../data/atrio_database_helper.dart';
import '../l10n/app_localizations.dart';
import '../modelos/anuncio_model.dart';
import '../modelos/post_model.dart';
import '../providers/ajustes_provider.dart';
import '../providers/iglesia_provider.dart';
import '../providers/user_provider.dart';
import '../servicios/anuncio_service.dart';
import '../widgets/hero_banner_card.dart';
import 'explorar_screen.dart';
import 'iglesia_screen.dart';
import 'notificaciones_screen.dart';
import 'perfil_screen.dart';
import 'tradicion_cristiana_screen.dart';
import '../servicios/atrio_upgrader_messages.dart';

class InicioAtrioScreen extends StatefulWidget {
  static const routeName = 'inicio_atrio_screen';
  const InicioAtrioScreen({super.key});

  @override
  State<InicioAtrioScreen> createState() => _InicioAtrioScreenState();
}

class _InicioAtrioScreenState extends State<InicioAtrioScreen> {
  int _currentNavIndex = 0;
  String? _iglesiaLocal;
  bool _isInit = true;

  // 3 avisos ficticios temporales (preparados para Odoo 19) con rotación automática
  int _avisoActivoIndex = 0;
  Timer? _avisosTimer;
  late final PageController _avisosPageController;
  int? _ultimoIntervaloAvisos;

  final List<Map<String, String>> _avisosFicticios = [
    {
      'titulo': 'Nuevo aviso',
      'mensaje': 'Cambio de horario · Miércoles, 7:00 p. m.',
      'categoria': 'Servicios',
      'tag': '1/3',
    },
    {
      'titulo': 'Inscripciones abiertas',
      'mensaje': 'Retiro Anual 2026 · Cupos limitados',
      'categoria': 'Eventos',
      'tag': '2/3',
    },
    {
      'titulo': 'Acción solidaria',
      'mensaje': 'Campaña "Manos que Bendicen" · Donaciones',
      'categoria': 'Comunidad',
      'tag': '3/3',
    },
  ];

  List<Map<String, String>> _obtenerAvisos(AppLocalizations? l10n) => [
    {
      'titulo': l10n?.nuevoAviso ?? 'Nuevo aviso',
      'mensaje':
          l10n?.cambioHorarioAviso ??
          'Cambio de horario · Miércoles, 7:00 p. m.',
      'categoria': l10n?.categoriaServicios ?? 'Servicios',
      'tag': '1/3',
    },
    {
      'titulo': l10n?.inscripcionesAbiertas ?? 'Inscripciones abiertas',
      'mensaje':
          l10n?.retiroAnualAviso ?? 'Retiro Anual 2026 · Cupos limitados',
      'categoria': l10n?.eventos ?? 'Eventos',
      'tag': '2/3',
    },
    {
      'titulo': l10n?.accionSolidaria ?? 'Acción solidaria',
      'mensaje':
          l10n?.campanaDonacionesAviso ??
          'Campaña "Manos que Bendicen" · Donaciones',
      'categoria': l10n?.categoriaComunidad ?? 'Comunidad',
      'tag': '3/3',
    },
  ];

  // Servicio y estado de Anuncios Interdenominacionales (conciertos y eventos globales Odoo 19)
  final AnuncioService _anuncioService = AnuncioService();
  List<AnuncioModel> _anuncios = [];
  int _anuncioActivoIndex = 0;
  Timer? _anunciosTimer;
  late final PageController _anunciosPageController;

  // Estado de publicaciones de la iglesia (Odoo 19 GET /posts)
  List<PostModel> _posts = [];
  bool _cargandoPosts = false;
  int _notificacionesSinLeer = 0;

  // Upgrader para notificaciones de actualización con estilo Cupertino e i18n
  late final AtrioUpgraderMessages _upgraderMessages;
  late final Upgrader _upgrader;

  @override
  void initState() {
    super.initState();
    _avisosPageController = PageController();
    _anunciosPageController = PageController();
    _upgraderMessages = AtrioUpgraderMessages();
    _upgrader = Upgrader(
      messages: _upgraderMessages,
      durationUntilAlertAgain: const Duration(days: 1),
    );
    _cargarAnuncios();
    _cargarPosts();
    _cargarNotificacionesContador();
    _cargarDatosPerfil();
  }

  Future<void> _cargarPosts() async {
    if (mounted) setState(() => _cargandoPosts = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final res = await userProvider.api.posts(limit: 10);
      final listRaw = res['posts'] as List? ?? [];
      final parsed = listRaw
          .map((e) => PostModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (mounted) {
        setState(() {
          _posts = parsed;
          _cargandoPosts = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cargandoPosts = false;
        });
      }
    }
  }

  Future<void> _cargarNotificacionesContador() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final res = await userProvider.api.notifications();
      final listRaw = res['notifications'] as List? ?? [];
      if (mounted) {
        setState(() {
          _notificacionesSinLeer = listRaw.length;
        });
      }
    } catch (_) {}
  }

  Future<void> _cargarAnuncios() async {
    try {
      final lista = await _anuncioService.obtenerAnuncios();
      if (mounted) {
        setState(() {
          _anuncios = lista;
        });
        _iniciarTimerAnuncios(_ultimoIntervaloAvisos);
      }
    } catch (e) {
      debugPrint('Error al cargar anuncios: $e');
    }
  }

  int _obtenerIntervaloAvisos() {
    try {
      final prov = Provider.of<AjustesProvider>(context, listen: false);
      return prov.tiempoTransicionBannerSegundos.clamp(3, 10);
    } catch (_) {
      return 5;
    }
  }

  void _iniciarTimerAvisos([int? segundos]) {
    _avisosTimer?.cancel();
    final int intervalo = (segundos ?? _obtenerIntervaloAvisos()).clamp(3, 10);
    _avisosTimer = Timer.periodic(Duration(seconds: intervalo), (_) {
      if (!mounted) return;
      if (_avisosPageController.hasClients) {
        final siguienteIndex =
            (_avisoActivoIndex + 1) % _avisosFicticios.length;
        _avisosPageController.animateToPage(
          siguienteIndex,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _iniciarTimerAnuncios([int? segundos]) {
    _anunciosTimer?.cancel();
    if (_anuncios.length <= 1) return;
    final int intervalo = (segundos ?? _obtenerIntervaloAvisos()).clamp(3, 10);
    _anunciosTimer = Timer.periodic(Duration(seconds: intervalo), (_) {
      if (!mounted) return;
      if (_anunciosPageController.hasClients) {
        final siguienteIndex = (_anuncioActivoIndex + 1) % _anuncios.length;
        _anunciosPageController.animateToPage(
          siguienteIndex,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _avisosTimer?.cancel();
    _anunciosTimer?.cancel();
    _avisosPageController.dispose();
    _anunciosPageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Provider.of<IglesiaProvider>(
            context,
            listen: false,
          ).cargarIglesiaSeleccionada();
        }
      });
      _isInit = false;
    }

    // Sincronizar intervalo de rotación de avisos y anuncios con la configuración global
    try {
      final nuevoIntervalo = Provider.of<AjustesProvider>(context)
          .tiempoTransicionBannerSegundos;
      if (_ultimoIntervaloAvisos != nuevoIntervalo) {
        _ultimoIntervaloAvisos = nuevoIntervalo;
        _iniciarTimerAvisos(nuevoIntervalo);
        _iniciarTimerAnuncios(nuevoIntervalo);
      }
    } catch (_) {}
  }

  // =========================================================================
  // CARGA DE DATOS REALES DESDE LA BASE DE DATOS LOCAL (atrio.db -> usuario)
  // =========================================================================
  Future<void> _cargarDatosPerfil() async {
    try {
      final Map<String, dynamic>? usuarioMap = await AtrioDatabaseHelper
          .instance
          .getUsuario();

      if (usuarioMap != null && mounted) {
        final String? iglesia = usuarioMap['iglesia_nombre'] as String?;

        setState(() {
          _iglesiaLocal = (iglesia != null && iglesia.trim().isNotEmpty)
              ? iglesia.trim()
              : null;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar datos del usuario desde atrio.db: $e');
    }
  }

  void _mostrarDialogoSalida(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFAF7F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n?.deseasSalirAtrio ?? '¿Deseas salir de atrio?',
          style: const TextStyle(
            color: Color(0xFF072B4F),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          l10n?.presionaSalirCerrar ??
              'Presiona "Salir" para cerrar la aplicación.',
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n?.cancelar ?? 'Cancelar',
              style: const TextStyle(color: Color(0xFF072B4F)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              SystemNavigator.pop();
            },
            child: Text(
              l10n?.salir ?? 'Salir',
              style: const TextStyle(
                color: Color(0xFFC0392B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;
    // 0xFF072B4F
    const Color azulFondo = Color(0xFF072B4F); //
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);
    const Color grisBorde = Color(0xFFEFEFEF);

    final l10n = AppLocalizations.of(context);
    _upgraderMessages.context = context;

    final List<Widget> vistasPrincipales = [
      _buildHomeView(
        screenWidth,
        usableHeight,
        azulFondo,
        amarilloOro,
        blancoFondo,
        grisBorde,
        l10n,
      ),
      const IglesiaScreen(),
      const ExplorarScreen(),
      EmisorasCristianasScreen(isActive: _currentNavIndex == 3),
      const PerfilScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        if (_currentNavIndex != 0) {
          setState(() {
            _currentNavIndex = 0;
          });
          return;
        }
        _mostrarDialogoSalida(context);
      },
      child: Scaffold(
        backgroundColor: azulFondo,
        bottomNavigationBar: NavigationBar(
          backgroundColor: Colors.white,
          indicatorColor: amarilloOro,
          surfaceTintColor: Colors.transparent,
          selectedIndex: _currentNavIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentNavIndex = index;
            });
            // Si el usuario vuelve a la pantalla de Inicio desde Perfil, refrescamos los datos
            if (index == 0) {
              _cargarDatosPerfil();
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home, color: azulFondo),
              label: l10n?.inicio ?? 'Inicio',
            ),
            NavigationDestination(
              icon: const Icon(Icons.church_outlined),
              selectedIcon: const Icon(Icons.church, color: azulFondo),
              label: l10n?.iglesia ?? 'Iglesia',
            ),
            NavigationDestination(
              icon: const Icon(Icons.explore_outlined),
              selectedIcon: const Icon(Icons.explore, color: azulFondo),
              label: l10n?.explorar ?? 'Explorar',
            ),
            NavigationDestination(
              icon: const Icon(Icons.radio_outlined),
              selectedIcon: const Icon(Icons.radio, color: azulFondo),
              label: l10n?.radio ?? 'Radio',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person, color: azulFondo),
              label: l10n?.perfil ?? 'Perfil',
            ),
          ],
        ),
        body: CupertinoTheme(
          data: CupertinoTheme.of(context).copyWith(primaryColor: azulFondo),
          child: UpgradeAlert(
            upgrader: _upgrader,
            dialogStyle: UpgradeDialogStyle.cupertino,
            showIgnore: true,
            showLater: true,
            showReleaseNotes: true,
            barrierDismissible: false,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                width: screenWidth,
                child: NotificationListener<CambiarTabAtrioNotification>(
                  onNotification: (notification) {
                    setState(() {
                      _currentNavIndex = notification.nuevoIndice;
                    });
                    if (notification.nuevoIndice == 0) {
                      _cargarDatosPerfil();
                    }
                    return true;
                  },
                  child: IndexedStack(
                    index: _currentNavIndex,
                    children: vistasPrincipales,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeView(
    double screenWidth,
    double usableHeight,
    Color azulFondo,
    Color amarilloOro,
    Color blancoFondo,
    Color grisBorde,
    AppLocalizations? l10n,
  ) {
    return Column(
      children: [
        SizedBox(
          width: screenWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Encabezado Superior (Logo Horizontal Atrio)
                    SizedBox(
                      height: usableHeight * 0.06,
                      child: Center(
                        child: Image.asset(
                          'assets/images/logo_encabezado.png',
                          height: usableHeight * 0.060,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    // Fin Encabezado Superior--------------------
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          NotificacionesScreen.routeName,
                        );
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: screenWidth * 0.080,
                          ),
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: EdgeInsets.all(screenWidth * 0.008),
                              decoration: BoxDecoration(
                                color: amarilloOro,
                                shape: BoxShape.circle,
                              ),
                              constraints: BoxConstraints(
                                minWidth: screenWidth * 0.04,
                                minHeight: screenWidth * 0.04,
                              ),
                              child: Center(
                                child: Text(
                                  '${_notificacionesSinLeer > 0 ? _notificacionesSinLeer : 3}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: usableHeight * 0.010),
              // Botón interactivo: Nombre de la iglesia y cambio rápido de comunidad
              Consumer<IglesiaProvider>(
                builder: (context, provider, child) {
                  final String sinIglesia =
                      l10n?.sinIglesiaSeleccionada ??
                      'Sin iglesia seleccionada';
                  final String nombreIglesia =
                      (provider.tieneIglesiaGuardada &&
                          provider.iglesiaActual != null &&
                          provider.iglesiaActual!.nombre.trim().isNotEmpty)
                      ? provider.iglesiaActual!.nombre.trim()
                      : ((_iglesiaLocal != null &&
                                _iglesiaLocal!.trim().isNotEmpty &&
                                _iglesiaLocal != 'Sin iglesia seleccionada')
                            ? _iglesiaLocal!.trim()
                            : sinIglesia);

                  return SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            TradicionCristianaScreen.routeName,
                          );
                          if (context.mounted) {
                            context
                                .read<IglesiaProvider>()
                                .cargarIglesiaSeleccionada();
                            _cargarDatosPerfil();
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                            vertical: usableHeight * 0.010,
                          ),

                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          l10n?.miIglesia ?? 'Mi Iglesia',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: screenWidth * 0.027,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(width: screenWidth * 0.015),
                                        Text(
                                          l10n?.tocaParaCambiar ??
                                              '· Toca para cambiar',
                                          style: TextStyle(
                                            color: amarilloOro,
                                            fontSize: screenWidth * 0.026,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: usableHeight * 0.002),
                                    Text(
                                      nombreIglesia,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: screenWidth * 0.046,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.020),
                              Container(
                                padding: EdgeInsets.all(screenWidth * 0.016),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.swap_horiz_rounded,
                                  color: Colors.white,
                                  size: screenWidth * 0.046,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: usableHeight * 0.008),
            ],
          ),
        ),
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
              child: RefreshIndicator(
                color: amarilloOro,
                backgroundColor: Colors.white,
                onRefresh: () async {
                  await Future.wait([
                    _cargarAnuncios(),
                    _cargarPosts(),
                    _cargarNotificacionesContador(),
                    _cargarDatosPerfil(),
                  ]);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.0210,
                    vertical: usableHeight * 0.012,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<AjustesProvider>(
                        builder: (context, ajustesProv, _) => HeroBannerCard(
                          heightFactor: 0.195,
                          duracionTransicionSegundos:
                              ajustesProv.tiempoTransicionBannerSegundos,
                        ),
                      ),
                      SizedBox(height: usableHeight * 0.015),
                      _buildNoticeBar(
                        screenWidth: screenWidth,
                        usableHeight: usableHeight,
                        azulFondo: azulFondo,
                        l10n: l10n,
                      ),
                      SizedBox(height: usableHeight * 0.012),
                      _buildActionGrid(
                        screenWidth,
                        usableHeight,
                        azulFondo,
                        grisBorde,
                        l10n,
                      ),
                      SizedBox(height: usableHeight * 0.02),
                      _buildAnnouncementsSection(
                        screenWidth,
                        usableHeight,
                        azulFondo,
                        amarilloOro,
                        grisBorde,
                        l10n,
                      ),
                      SizedBox(height: usableHeight * 0.02),
                      _buildPostsSection(
                        screenWidth,
                        usableHeight,
                        azulFondo,
                        amarilloOro,
                        grisBorde,
                        l10n,
                      ),
                      SizedBox(height: usableHeight * 0.03),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoticeBar({
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required AppLocalizations? l10n,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, NotificacionesScreen.routeName);
      },
      child: Container(
        height: usableHeight * 0.092,
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.040,
          vertical: usableHeight * 0.010,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F1F5),
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          border: Border.all(color: azulFondo.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.022),
              decoration: BoxDecoration(
                color: azulFondo.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active_outlined,
                color: azulFondo,
                size: screenWidth * 0.065,
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: PageView.builder(
                controller: _avisosPageController,
                itemCount: _obtenerAvisos(l10n).length,
                onPageChanged: (index) {
                  setState(() {
                    _avisoActivoIndex = index;
                  });
                  _iniciarTimerAvisos(_ultimoIntervaloAvisos);
                },
                itemBuilder: (context, index) {
                  final aviso = _obtenerAvisos(l10n)[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            aviso['titulo'] ?? 'Aviso',
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.042,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE5A023)
                                  .withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              aviso['tag'] ?? '',
                              style: TextStyle(
                                color: const Color(0xFF9E6500),
                                fontSize: screenWidth * 0.028,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: usableHeight * 0.003),
                      Text(
                        aviso['mensaje'] ?? '',
                        style: TextStyle(
                          color: Colors.grey.shade900,
                          fontSize: screenWidth * 0.036,
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: azulFondo,
              size: screenWidth * 0.065,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid(
    double screenWidth,
    double usableHeight,
    Color azulFondo,
    Color grisBorde,
    AppLocalizations? l10n,
  ) {
    final List<Map<String, dynamic>> items = [
      {
        'title': l10n?.biblia ?? 'Biblia',
        'icon': Icons.menu_book_outlined,
        'color': const Color(0xFF0055A5),
        'route': 'biblia_screen',
      },
      {
        'title': l10n?.eventos ?? 'Eventos',
        'icon': Icons.calendar_today_outlined,
        'color': const Color(0xFFE5A023),
        'route': 'eventos_screen',
      },
      {
        'title': l10n?.solicitudes ?? 'Solicitudes',
        'icon': Icons.edit_note_outlined,
        'color': const Color(0xFF2B7A78),
        'route': 'tipos_solicitud_screen',
      },
      {
        'title': l10n?.donaciones ?? 'Donaciones',
        'icon': Icons.favorite_border_rounded,
        'color': const Color(0xFF4A7C59),
        'route': 'donaciones_screen',
      },
      {
        'title': l10n?.proyectosSolidarios ?? 'Proyectos\nsolidarios',
        'icon': Icons.health_and_safety,
        'color': const Color(0xFF2B7A78),
        'route': 'proyecto_solidario_screen',
      },
      {
        'title': l10n?.tienda ?? 'Tienda',
        'icon': Icons.store_rounded,
        'color': const Color(0xFF4A7C59),
        'route': 'tienda_screen',
      },
      {
        'title': l10n?.libros ?? 'Libros',
        'icon': Icons.book_outlined,
        'color': const Color(0xFF2B7A78),
        'route': 'libros_screen',
      },
      {
        'title': l10n?.videos ?? 'Videos',
        'icon': Icons.video_camera_front,
        'color': const Color(0xFF4A7C59),
        'route': 'videos_transmisiones_screen',
      },
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: screenWidth * 0.03,
        mainAxisSpacing: usableHeight * 0.012,
        childAspectRatio: 2.3,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            if (item['route'] != null) {
              Navigator.pushNamed(context, item['route']);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              border: Border.all(color: grisBorde),
            ),
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
            child: Row(
              children: [
                Icon(
                  item['icon'],
                  color: item['color'],
                  size: screenWidth * 0.07,
                ),
                SizedBox(width: screenWidth * 0.025),
                Expanded(
                  child: Text(
                    item['title'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.045,
                      height: 1.15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnnouncementsSection(
    double screenWidth,
    double usableHeight,
    Color azulFondo,
    Color amarilloOro,
    Color grisBorde,
    AppLocalizations? l10n,
  ) {
    if (_anuncios.isEmpty) {
      return Container(
        height: usableHeight * 0.160,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF7FC),
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          border: Border.all(color: grisBorde),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.035,
          vertical: usableHeight * 0.008,
        ),
        child: Row(
          children: [
            Container(
              width: screenWidth * 0.22,
              height: usableHeight * 0.120,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
              ),
              child: Icon(
                Icons.music_note_rounded,
                color: azulFondo,
                size: screenWidth * 0.08,
              ),
            ),
            SizedBox(width: screenWidth * 0.035),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n?.anunciosYConciertos ?? 'ANUNCIOS & CONCIERTOS',
                    style: TextStyle(
                      color: const Color(0xFF0055A5),
                      fontSize: screenWidth * 0.028,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.003),
                  Text(
                    l10n?.cargandoNovedades ?? 'Cargando novedades...',
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.038,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: usableHeight * 0.160,
          child: PageView.builder(
            controller: _anunciosPageController,
            itemCount: _anuncios.length,
            onPageChanged: (index) {
              setState(() {
                _anuncioActivoIndex = index;
              });
              _iniciarTimerAnuncios(_ultimoIntervaloAvisos);
            },
            itemBuilder: (context, index) {
              final anuncio = _anuncios[index];
              return _buildAnnouncementCardItem(
                anuncio: anuncio,
                screenWidth: screenWidth,
                usableHeight: usableHeight,
                azulFondo: azulFondo,
                amarilloOro: amarilloOro,
                grisBorde: grisBorde,
                onTap: () => _showAnuncioDetailModal(context, anuncio),
              );
            },
          ),
        ),
        SizedBox(height: usableHeight * 0.012),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _anuncios.length,
            (index) => _buildDot(
              _anuncioActivoIndex == index,
              amarilloOro,
              screenWidth,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementCardItem({
    required AnuncioModel anuncio,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color amarilloOro,
    required Color grisBorde,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.005),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF7FC),
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          border: Border.all(color: grisBorde),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.030,
          vertical: usableHeight * 0.008,
        ),
        child: Row(
          children: [
            // Afiche / Imagen con fallback
            Container(
              width: screenWidth * 0.22,
              height: usableHeight * 0.125,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                child: Image.network(
                  anuncio.imagenUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Color(int.parse(anuncio.fallbackBgColor)),
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_note_rounded,
                          color: Color(int.parse(anuncio.fallbackTextColor)),
                          size: screenWidth * 0.065,
                        ),
                        Text(
                          anuncio.etiqueta,
                          style: TextStyle(
                            color: Color(int.parse(anuncio.fallbackTextColor)),
                            fontSize: screenWidth * 0.020,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.032),

            // Contenido con tipografía accesible para público de 30-70 años
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0055A5)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          anuncio.etiqueta,
                          style: TextStyle(
                            color: const Color(0xFF0055A5),
                            fontSize: screenWidth * 0.026,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        child: Text(
                          anuncio.categoria,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: screenWidth * 0.026,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.003),
                  Text(
                    anuncio.artista,
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.040,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    anuncio.subtitulo,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: screenWidth * 0.033,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: usableHeight * 0.003),
                  Row(
                    children: [
                      Text(
                        anuncio.textoAccion,
                        style: TextStyle(
                          color: amarilloOro,
                          fontSize: screenWidth * 0.032,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: amarilloOro,
                        size: screenWidth * 0.045,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnuncioDetailModal(BuildContext context, AnuncioModel anuncio) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final usableHeight = screenHeight - MediaQuery.of(context).padding.top;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          decoration: BoxDecoration(
            color: blancoFondo,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(screenWidth * 0.06),
              topRight: Radius.circular(screenWidth * 0.06),
            ),
          ),
          padding: EdgeInsets.only(
            left: screenWidth * 0.06,
            right: screenWidth * 0.06,
            top: usableHeight * 0.018,
            bottom:
                MediaQuery.of(modalContext).padding.bottom +
                usableHeight * 0.02,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de arrastre
              Center(
                child: Container(
                  width: screenWidth * 0.12,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: usableHeight * 0.02),

              // Afiche amplio del evento
              ClipRRect(
                borderRadius: BorderRadius.circular(screenWidth * 0.035),
                child: Container(
                  width: double.infinity,
                  height: usableHeight * 0.19,
                  decoration: BoxDecoration(
                    color: azulFondo,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Image.network(
                    anuncio.imagenUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Color(int.parse(anuncio.fallbackBgColor)),
                      child: Center(
                        child: Icon(
                          Icons.music_note_rounded,
                          color: Colors.white70,
                          size: screenWidth * 0.15,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: usableHeight * 0.015),

              // Etiquetas
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: usableHeight * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: amarilloOro.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(screenWidth * 0.015),
                    ),
                    child: Text(
                      anuncio.etiqueta,
                      style: TextStyle(
                        color: const Color(0xFF9E6500),
                        fontSize: screenWidth * 0.030,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: usableHeight * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: azulFondo.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(screenWidth * 0.015),
                    ),
                    child: Text(
                      anuncio.categoria,
                      style: TextStyle(
                        color: azulFondo,
                        fontSize: screenWidth * 0.030,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: usableHeight * 0.012),

              // Artista / Presentador
              Text(
                anuncio.artista,
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.048,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: usableHeight * 0.004),

              // Título de la gira
              Text(
                anuncio.titulo,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: screenWidth * 0.040,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: usableHeight * 0.012),

              // Fecha y Lugar con alta legibilidad
              Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    size: screenWidth * 0.045,
                    color: Colors.grey.shade700,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Text(
                      anuncio.fecha,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: screenWidth * 0.036,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: usableHeight * 0.006),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: screenWidth * 0.045,
                    color: Colors.grey.shade700,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Text(
                      anuncio.lugar,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: screenWidth * 0.036,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: usableHeight * 0.015),

              // Descripción con accesibilidad visual garantizada
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: Text(
                  anuncio.descripcion,
                  style: TextStyle(
                    color: Colors.grey.shade900,
                    fontSize: screenWidth * 0.040,
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(height: usableHeight * 0.02),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: amarilloOro,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          vertical: usableHeight * 0.016,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.025,
                          ),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(modalContext);
                        final l10nModal = AppLocalizations.of(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10nModal?.infoArtistaEnviada(anuncio.artista) ??
                                  'Información sobre "${anuncio.artista}" enviada.',
                              style: const TextStyle(fontSize: 15),
                            ),
                            backgroundColor: azulFondo,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.confirmation_number_rounded),
                      label: Text(
                        anuncio.textoAccion,
                        style: TextStyle(
                          fontSize: screenWidth * 0.040,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: azulFondo,
                      side: BorderSide(color: azulFondo, width: 1.5),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.045,
                        vertical: usableHeight * 0.016,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.025,
                        ),
                      ),
                    ),
                    onPressed: () => Navigator.pop(modalContext),
                    child: Text(
                      AppLocalizations.of(context)?.cerrar ?? 'Cerrar',
                      style: TextStyle(
                        fontSize: screenWidth * 0.038,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostsSection(
    double screenWidth,
    double usableHeight,
    Color azulFondo,
    Color amarilloOro,
    Color grisBorde,
    AppLocalizations? l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado de la sección
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.015),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.018),
                    decoration: BoxDecoration(
                      color: azulFondo.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.newspaper_rounded,
                      color: azulFondo,
                      size: screenWidth * 0.05,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.025),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n?.publicacionesIglesia ?? 'Publicaciones de la iglesia',
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.042,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n?.novedadesComunidad ??
                            'Novedades y noticias de tu comunidad',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: screenWidth * 0.028,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_posts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: amarilloOro.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_posts.length}',
                    style: TextStyle(
                      color: const Color(0xFF9E6500),
                      fontSize: screenWidth * 0.03,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: usableHeight * 0.015),

        // Contenido de las publicaciones
        if (_cargandoPosts && _posts.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: usableHeight * 0.03),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.035),
              border: Border.all(color: grisBorde),
            ),
            child: Column(
              children: [
                CircularProgressIndicator(color: amarilloOro),
                SizedBox(height: usableHeight * 0.015),
                Text(
                  l10n?.cargandoPublicaciones ?? 'Cargando publicaciones...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: screenWidth * 0.034,
                  ),
                ),
              ],
            ),
          )
        else if (_posts.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: usableHeight * 0.025,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.035),
              border: Border.all(color: grisBorde),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.article_outlined,
                  color: Colors.grey.shade400,
                  size: screenWidth * 0.08,
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Text(
                    l10n?.sinPublicacionesRecientes ??
                        'No hay publicaciones recientes de tu comunidad.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: screenWidth * 0.034,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _posts.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: usableHeight * 0.014),
            itemBuilder: (context, index) {
              final post = _posts[index];
              return _buildPostCardItem(
                post: post,
                screenWidth: screenWidth,
                usableHeight: usableHeight,
                azulFondo: azulFondo,
                amarilloOro: amarilloOro,
                grisBorde: grisBorde,
                l10n: l10n,
              );
            },
          ),
      ],
    );
  }

  Widget _buildPostCardItem({
    required PostModel post,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color amarilloOro,
    required Color grisBorde,
    required AppLocalizations? l10n,
  }) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final String? fullImageUrl = post.imageUrl.isNotEmpty
        ? userProvider.api.imageUrl(post.imageUrl)
        : null;

    return GestureDetector(
      onTap: () => _mostrarDetallePublicacion(context, post, l10n, fullImageUrl),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          border: Border.all(color: grisBorde),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fullImageUrl != null)
              SizedBox(
                height: usableHeight * 0.16,
                width: double.infinity,
                child: Image.network(
                  fullImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: azulFondo.withValues(alpha: 0.08),
                    child: Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: azulFondo.withValues(alpha: 0.4),
                        size: screenWidth * 0.1,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.035),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0055A5).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          post.audience == 'todos' ? 'Comunidad' : post.audience,
                          style: TextStyle(
                            color: const Color(0xFF0055A5),
                            fontSize: screenWidth * 0.026,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (post.publishDate.isNotEmpty)
                        Text(
                          post.publishDate.split('T').first,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: screenWidth * 0.028,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.008),
                  Text(
                    post.title,
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.040,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (post.plainContent.isNotEmpty) ...[
                    SizedBox(height: usableHeight * 0.005),
                    Text(
                      post.plainContent,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: screenWidth * 0.032,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: usableHeight * 0.01),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        l10n?.verPublicacion ?? 'Ver publicación',
                        style: TextStyle(
                          color: amarilloOro,
                          fontSize: screenWidth * 0.032,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.01),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: amarilloOro,
                        size: screenWidth * 0.036,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetallePublicacion(
    BuildContext context,
    PostModel post,
    AppLocalizations? l10n,
    String? fullImageUrl,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    const Color azulFondo = Color(0xFF072B4F);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.06),
        ),
      ),
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: usableHeight * 0.85),
          padding: EdgeInsets.fromLTRB(
            screenWidth * 0.05,
            usableHeight * 0.02,
            screenWidth * 0.05,
            usableHeight * 0.02 + safeAreaBottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: screenWidth * 0.12,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: usableHeight * 0.02),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (fullImageUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.035,
                          ),
                          child: Image.network(
                            fullImageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                        SizedBox(height: usableHeight * 0.02),
                      ],
                      if (post.publishDate.isNotEmpty)
                        Text(
                          post.publishDate.split('T').first,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: screenWidth * 0.030,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      SizedBox(height: usableHeight * 0.005),
                      Text(
                        post.title,
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.052,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Divider(height: usableHeight * 0.03),
                      Text(
                        post.plainContent,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: screenWidth * 0.038,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: usableHeight * 0.03),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: usableHeight * 0.056,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azulFondo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        screenWidth * 0.03,
                      ),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    l10n?.cerrarPublicacion ?? 'Cerrar',
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
      },
    );
  }

  Widget _buildDot(bool isActive, Color color, double screenWidth) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.008),
      height: screenWidth * 0.015,
      width: isActive ? screenWidth * 0.04 : screenWidth * 0.015,
      decoration: BoxDecoration(
        color: isActive ? color : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(screenWidth * 0.01),
      ),
    );
  }
}
