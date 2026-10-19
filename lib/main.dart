import 'package:atrio/data/atrio_database_helper.dart';
import 'package:atrio/data/database_helper.dart';
import 'package:atrio/screens/emisoras_cristianas_screen.dart';
import 'package:atrio/screens/mis_favoritos_screen.dart';
import 'package:atrio/screens/mis_notas_screen.dart';
import 'package:atrio/servicios/connectivity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Paquetes - Google Maps
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

// Providers
import 'package:atrio/providers/app_provider.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/providers/iglesia_provider.dart';
import 'package:atrio/providers/aporte_provider.dart';
import 'package:atrio/providers/proyecto_solidario_provider.dart';
import 'package:atrio/providers/explorar_provider.dart';
import 'package:atrio/providers/biblia_provider.dart';
import 'package:atrio/providers/tradicion_cristiana_provider.dart';
import 'package:atrio/providers/ajustes_provider.dart';

// Screens - Autenticación / Onboarding
import 'package:atrio/screens/intro_encuentra_screen.dart';
import 'package:atrio/screens/inicio_sesion_screen.dart';
import 'package:atrio/screens/acceso_social_screen.dart';
import 'package:atrio/screens/crear_cuenta_screen.dart';
import 'package:atrio/screens/recuperar_clave_screen.dart';
import 'package:atrio/screens/seleccionar_iglesia_screen.dart';
import 'package:atrio/screens/tradicion_cristiana_screen.dart';

// Screens - Principal
import 'package:atrio/screens/inicio_atrio_screen.dart';
import 'package:atrio/screens/perfil_screen.dart';
import 'package:atrio/screens/biblia_screen.dart';
import 'package:atrio/screens/eventos_screen.dart';
import 'package:atrio/screens/iglesias_en_mapa_screen.dart';
import 'package:atrio/screens/notificaciones_screen.dart';
import 'package:atrio/screens/ayuda_soporte_screen.dart';
import 'package:atrio/screens/terminos_privacidad_screen.dart';
import 'package:atrio/screens/configuracion_screen.dart';

// Screens - Donaciones / Aportes
import 'package:atrio/screens/donaciones_screen.dart';
import 'package:atrio/screens/mis_donaciones_screen.dart';
import 'package:atrio/screens/confirmar_donacion_screen.dart';
import 'package:atrio/screens/realizar_aporte_screen.dart';
import 'package:atrio/screens/aportar_a_proyecto_screen.dart';
import 'package:atrio/screens/proyecto_solidario_screen.dart';

// Screens - Solicitudes
import 'package:atrio/screens/tipos_solicitud_screen.dart';
import 'package:atrio/screens/nueva_solicitud_screen.dart';
import 'package:atrio/screens/seguimiento_solicitud_screen.dart';

// Screens - Contenido / Tienda / Biblia
import 'package:atrio/screens/escuchar_libro_biblia_screen.dart';
import 'package:atrio/screens/lectura_capitulo_screen.dart';
import 'package:atrio/screens/detalle_libro_biblia_screen.dart';
import 'package:atrio/screens/libros_de_biblia.dart';
import 'package:atrio/screens/tienda_screen.dart';
import 'package:atrio/screens/mis_pedidos_screen.dart';
import 'package:atrio/screens/libros_screen.dart';
import 'package:atrio/screens/videos_transmisiones_screen.dart';

// Screens - Pruebas
import 'package:atrio/screens/test_pago_screen.dart';

Future<void> main() async {
  // 1. Vincular motor de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Bloqueo estricto a orientación vertical
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // 3. Inicializar renderizador de Google Maps
  try {
    final GoogleMapsFlutterPlatform mapsImplementation =
        GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      await mapsImplementation.initializeWithRenderer(
        AndroidMapRenderer.latest,
      );
    }
  } catch (e) {
    debugPrint('Error al inicializar Google Maps Renderer: $e');
  }
  //
  // =========================================================================
  // 4. INICIALIZACIÓN DE BASES DE DATOS LOCALES
  // =========================================================================
  try {
    // A) Base de datos de la Biblia (copia desde assets si es la primera vez)
    await DatabaseHelper.instance.database;
    debugPrint('✅ [DB] biblia_audio.db lista');

    // B) NUEVA BASE DE DATOS LOCAL: atrio.db
    // Se ejecuta onCreate, genera las tablas 'usuario' y 'config_atrio'
    await AtrioDatabaseHelper.instance.database;
    debugPrint('✅ [DB] atrio.db inicializada');
  } catch (e) {
    debugPrint('💥 Error inicializando bases de datos SQLite: $e');
  }

  // 4. Determinar la ruta inicial según el estado de bienvenida y autenticación
  final prefs = await SharedPreferences.getInstance();
  final bool introVista = prefs.getBool('intro_vista') ?? false;
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final String rutaInicial = !introVista
      ? IntroEncuentraScreen.routeName
      : (isLoggedIn
            ? InicioAtrioScreen.routeName
            : InicioSesionScreen.routeName);

  //
  // Iniciar monitoreo de internet en toda la app
  ConnectivityService.instance.startMonitoring();
  // 5. Arrancar la app
  runApp(AppState(initialRoute: rutaInicial));
}

class AppState extends StatelessWidget {
  final String initialRoute;
  const AppState({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => IglesiaProvider()),
        ChangeNotifierProvider(create: (_) => AporteProvider()),
        ChangeNotifierProvider(create: (_) => ProyectoSolidarioProvider()),
        ChangeNotifierProvider(create: (_) => BibliaProvider()),
        ChangeNotifierProvider(create: (_) => TradicionCristianaProvider()),
        ChangeNotifierProvider(create: (_) => ExplorarProvider()),
        ChangeNotifierProvider(create: (_) => AjustesProvider()),
      ],
      child: MyApp(initialRoute: initialRoute),
    );
  }
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    final ajustes = context.watch<AjustesProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ATRIO',
      locale: ajustes.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routes: _routes,
      initialRoute: initialRoute,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(
              minScaleFactor: 0.80,
              maxScaleFactor: 0.95,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  // =========================================================
  // RUTAS CENTRALIZADAS (Static routeName)
  // =========================================================
  static final Map<String, WidgetBuilder> _routes = {
    // ---------- Autenticación / Onboarding ----------
    IntroEncuentraScreen.routeName: (_) => const IntroEncuentraScreen(),
    InicioSesionScreen.routeName: (_) => const InicioSesionScreen(),
    AccesoSocialScreen.routeName: (_) => const AccesoSocialScreen(),
    CrearCuentaScreen.routeName: (_) => const CrearCuentaScreen(),
    RecuperarClaveScreen.routeName: (_) => const RecuperarClaveScreen(),
    SeleccionarIglesiaScreen.routeName: (_) => const SeleccionarIglesiaScreen(),
    TradicionCristianaScreen.routeName: (_) => const TradicionCristianaScreen(),

    // ---------- Principal ----------
    InicioAtrioScreen.routeName: (_) => const InicioAtrioScreen(),
    PerfilScreen.routeName: (_) => const PerfilScreen(),
    BibliaScreen.routeName: (_) => const BibliaScreen(),
    EventosScreen.routeName: (_) => const EventosScreen(),
    IglesiasEnMapaScreen.routeName: (_) => const IglesiasEnMapaScreen(),
    NotificacionesScreen.routeName: (_) => const NotificacionesScreen(),
    AyudaSoporteScreen.routeName: (_) => const AyudaSoporteScreen(),
    TerminosPrivacidadScreen.routeName: (_) => const TerminosPrivacidadScreen(),
    ConfiguracionScreen.routeName: (_) => const ConfiguracionScreen(),

    // ---------- Donaciones y Aportes ----------
    DonacionesScreen.routeName: (_) => const DonacionesScreen(),
    MisDonacionesScreen.routeName: (_) => const MisDonacionesScreen(),
    ConfirmarDonacionScreen.routeName: (_) => const ConfirmarDonacionScreen(),
    RealizarAporteScreen.routeName: (_) => const RealizarAporteScreen(),
    AportarAProyectoScreen.routeName: (_) => const AportarAProyectoScreen(),
    ProyectoSolidarioScreen.routeName: (_) => const ProyectoSolidarioScreen(),

    // ---------- Solicitudes ----------
    TiposSolicitudScreen.routeName: (_) => const TiposSolicitudScreen(),
    NuevaSolicitudScreen.routeName: (_) => const NuevaSolicitudScreen(),
    SeguimientoSolicitudScreen.routeName: (_) =>
        const SeguimientoSolicitudScreen(),

    // ---------- Contenido / Tienda / Biblia ----------
    EscucharLibroBibliaScreen.routeName: (_) =>
        const EscucharLibroBibliaScreen(),
    LecturaCapituloScreen.routeName: (_) => const LecturaCapituloScreen(),
    DetalleLibroBibliaScreen.routeName: (_) => const DetalleLibroBibliaScreen(),
    LibrosDeBibliaScreen.routeName: (_) => const LibrosDeBibliaScreen(),
    TiendaScreen.routeName: (_) => const TiendaScreen(),
    MisPedidosScreen.routeName: (_) => const MisPedidosScreen(),
    LibrosScreen.routeName: (_) => const LibrosScreen(),
    // EmisorasCristianasScreen
    EmisorasCristianasScreen.routeName: (_) => const EmisorasCristianasScreen(),
    MisFavoritosScreen.routeName: (_) => const MisFavoritosScreen(),
    MisNotasScreen.routeName: (_) => const MisNotasScreen(),
    VideosTransmisionesScreen.routeName: (_) =>
        const VideosTransmisionesScreen(),

    // ---------- Pruebas ----------
    TestPagoScreen.routeName: (_) => const TestPagoScreen(),
  };
}
