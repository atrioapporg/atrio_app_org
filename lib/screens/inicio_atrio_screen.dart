import 'package:atrio/screens/emisoras_cristianas_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/atrio_database_helper.dart';
import '../providers/iglesia_provider.dart';
import '../widgets/hero_banner_card.dart';
import '../widgets/modal_versiculo_imagen.dart';
import 'explorar_screen.dart';
import 'iglesia_screen.dart';
import 'perfil_screen.dart';

class InicioAtrioScreen extends StatefulWidget {
  static const routeName = 'inicio_atrio_screen';
  const InicioAtrioScreen({super.key});

  @override
  State<InicioAtrioScreen> createState() => _InicioAtrioScreenState();
}

class _InicioAtrioScreenState extends State<InicioAtrioScreen> {
  int _currentNavIndex = 0;
  String _nombreUsuario = 'Usuario';
  String? _iglesiaLocal;
  bool _isInit = true;

  // Bandera estática para asegurar que el modal del versículo
  // aparezca una sola vez por cada inicio de sesión / apertura de la app.
  static bool _versiculoMostradoEnSesion = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosPerfil();

    // Muestra el modal del versículo automáticamente al terminar de renderizar la pantalla inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_versiculoMostradoEnSesion && mounted) {
        _versiculoMostradoEnSesion = true;
        ModalVersiculoImagen.mostrar(context);
      }
    });
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
        final String nombreCompleto =
            (usuarioMap['nombre'] as String?)?.trim() ?? 'Usuario';
        final String primerNombre = nombreCompleto.isNotEmpty
            ? nombreCompleto.split(' ').first
            : 'Usuario';

        final String? iglesia = usuarioMap['iglesia_nombre'] as String?;

        setState(() {
          _nombreUsuario = primerNombre;
          _iglesiaLocal = (iglesia != null && iglesia.trim().isNotEmpty)
              ? iglesia.trim()
              : null;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar datos del usuario desde atrio.db: $e');
    }
  }

  String _obtenerSaludo() {
    final int hora = DateTime.now().hour;
    if (hora >= 5 && hora < 12) {
      return 'Buen día';
    } else if (hora >= 12 && hora < 19) {
      return 'Buenas tardes';
    } else {
      return 'Buenas noches';
    }
  }

  void _mostrarDialogoSalida(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFAF7F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '¿Deseas salir de atrio?',
          style: TextStyle(
            color: Color(0xFF072B4F),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Presiona "Salir" para cerrar la aplicación.',
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF072B4F)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              SystemNavigator.pop();
            },
            child: const Text(
              'Salir',
              style: TextStyle(
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

    const Color azulFondo = Color(0xFF072B4F); //
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);
    const Color grisBorde = Color(0xFFEFEFEF);

    final List<Widget> vistasPrincipales = [
      _buildHomeView(
        screenWidth,
        usableHeight,
        azulFondo,
        amarilloOro,
        blancoFondo,
        grisBorde,
      ),
      const IglesiaScreen(),
      const ExplorarScreen(),
      const EmisorasCristianasScreen(),
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
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: azulFondo),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.church_outlined),
              selectedIcon: Icon(Icons.church, color: azulFondo),
              label: 'Iglesia',
            ),
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore, color: azulFondo),
              label: 'Explorar',
            ),
            NavigationDestination(
              icon: Icon(Icons.radio_outlined),
              selectedIcon: Icon(Icons.radio, color: azulFondo),
              label: 'Radio',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: azulFondo),
              label: 'Perfil',
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: SizedBox(
            width: screenWidth,
            child: vistasPrincipales[_currentNavIndex],
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
  ) {
    return Column(
      children: [
        Container(
          width: screenWidth,
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //SizedBox(height: usableHeight * 0.01),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Encabezado Superior (Logo Horizontal Atrio)
                  SizedBox(
                    height: usableHeight * 0.08,
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo_encabezado.png',
                        height: usableHeight * 0.060,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // Fin Encabezado Superior--------------------
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: screenWidth * 0.075,
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
                          child: const Center(
                            child: Text(
                              '3',
                              style: TextStyle(
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
                ],
              ),
              //SizedBox(height: usableHeight * 0.012),
              // Saludo dinámico con el primer nombre real desde SQLite
              Text(
                '${_obtenerSaludo()}, $_nombreUsuario',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.060,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Selector interactivo con el nombre de la iglesia:
              // Prioriza el provider y usa como fallback el dato de atrio.db
              Consumer<IglesiaProvider>(
                builder: (context, provider, child) {
                  final String nombreIglesia =
                      provider.iglesiaActual?.nombre ??
                      _iglesiaLocal ??
                      'Sin iglesia seleccionada';
                  return GestureDetector(
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        'seleccionar_iglesia_screen',
                      );
                      // Refrescamos por si cambió de iglesia
                      _cargarDatosPerfil();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                        vertical: usableHeight * 0.008,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.025,
                        ),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.church_outlined,
                            color: amarilloOro,
                            size: screenWidth * 0.045,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Flexible(
                            child: Text(
                              nombreIglesia,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.034,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.white70,
                            size: screenWidth * 0.045,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: usableHeight * 0.012),

              SizedBox(height: usableHeight * 0.015),
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.030,
                  vertical: usableHeight * 0.02,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeroBannerCard(
                      title: 'Culto en vivo',
                      subtitle: 'Domingo · 10:00 a. m.',
                      buttonText: 'Ver ahora',
                      heightFactor: 0.18,
                      backgroundImage: 'assets/images/biblia3.jpg',
                      watermarkIcon: Icons.add,
                      onButtonPressed: () {
                        Navigator.pushNamed(
                          context,
                          'videos_transmisiones_screen',
                        );
                      },
                    ),
                    SizedBox(height: usableHeight * 0.018),
                    _buildNoticeBar(
                      screenWidth: screenWidth,
                      usableHeight: usableHeight,
                      azulFondo: azulFondo,
                    ),
                    SizedBox(height: usableHeight * 0.02),
                    Text(
                      'Para ti',
                      style: TextStyle(
                        color: azulFondo,
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.012),
                    _buildActionGrid(
                      screenWidth,
                      usableHeight,
                      azulFondo,
                      grisBorde,
                    ),
                    SizedBox(height: usableHeight * 0.02),
                    _buildAnnouncementCard(
                      screenWidth,
                      usableHeight,
                      azulFondo,
                      amarilloOro,
                      grisBorde,
                    ),
                    SizedBox(height: usableHeight * 0.015),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDot(true, amarilloOro, screenWidth),
                        _buildDot(false, amarilloOro, screenWidth),
                        _buildDot(false, amarilloOro, screenWidth),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.02),
                  ],
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
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: usableHeight * 0.012,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1F5),
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active_outlined,
            color: azulFondo,
            size: screenWidth * 0.065,
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nuevo aviso',
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.034,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Cambio de horario · Miércoles, 7:00 p. m.',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: screenWidth * 0.03,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: azulFondo,
            size: screenWidth * 0.05,
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(
    double screenWidth,
    double usableHeight,
    Color azulFondo,
    Color grisBorde,
  ) {
    final List<Map<String, dynamic>> items = [
      {
        'title': 'Biblia',
        'icon': Icons.menu_book_outlined,
        'color': const Color(0xFF0055A5),
        'route': 'biblia_screen',
      },
      {
        'title': 'Eventos',
        'icon': Icons.calendar_today_outlined,
        'color': const Color(0xFFE5A023),
        'route': 'eventos_screen',
      },
      {
        'title': 'Solicitudes',
        'icon': Icons.edit_note_outlined,
        'color': const Color(0xFF2B7A78),
        'route': 'tipos_solicitud_screen',
      },
      {
        'title': 'Donaciones',
        'icon': Icons.favorite_border_rounded,
        'color': const Color(0xFF4A7C59),
        'route': 'donaciones_screen',
      },
      {
        'title': 'Proyectos\nsolidarios',
        'icon': Icons.health_and_safety,
        'color': const Color(0xFF2B7A78),
        'route': 'proyecto_solidario_screen',
      },
      {
        'title': 'Tienda',
        'icon': Icons.store_rounded,
        'color': const Color(0xFF4A7C59),
        'route': 'tienda_screen',
      },
      {
        'title': 'Libros',
        'icon': Icons.book_outlined,
        'color': const Color(0xFF2B7A78),
        'route': 'libros_screen',
      },
      {
        'title': 'Videos\nEN VIVO',
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

  Widget _buildAnnouncementCard(
    double screenWidth,
    double usableHeight,
    Color azulFondo,
    Color amarilloOro,
    Color grisBorde,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7FC),
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
        border: Border.all(color: grisBorde),
      ),
      padding: EdgeInsets.all(screenWidth * 0.03),
      child: Row(
        children: [
          Container(
            width: screenWidth * 0.22,
            height: usableHeight * 0.09,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
            ),
            child: Icon(
              Icons.people_alt_rounded,
              color: azulFondo,
              size: screenWidth * 0.09,
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ANUNCIO',
                  style: TextStyle(
                    color: const Color(0xFF0055A5),
                    fontSize: screenWidth * 0.026,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Retiro de familias',
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Inscripciones abiertas',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: screenWidth * 0.03,
                  ),
                ),
                SizedBox(height: usableHeight * 0.004),
                Row(
                  children: [
                    Text(
                      'Más información',
                      style: TextStyle(
                        color: amarilloOro,
                        fontSize: screenWidth * 0.03,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: amarilloOro,
                      size: screenWidth * 0.04,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
