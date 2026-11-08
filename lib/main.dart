import 'package:atrio/atrio_api.dart';
import 'package:atrio/data/app_config.dart';
import 'package:atrio/data/atrio_database_helper.dart';
import 'package:atrio/data/database_helper.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/providers/admin_provider.dart';
import 'package:atrio/providers/ads_provider.dart';
import 'package:atrio/providers/ajustes_provider.dart';
import 'package:atrio/providers/aporte_provider.dart';
// Providers
import 'package:atrio/providers/app_provider.dart';
import 'package:atrio/providers/biblia_provider.dart';
import 'package:atrio/providers/explorar_provider.dart';
import 'package:atrio/providers/iglesia_provider.dart';
import 'package:atrio/providers/join_church_provider.dart';
import 'package:atrio/providers/moderation_provider.dart';
import 'package:atrio/providers/proyecto_solidario_provider.dart';
import 'package:atrio/providers/recomendacion_iglesia_provider.dart';
import 'package:atrio/providers/tradicion_cristiana_provider.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/acceso_social_screen.dart';
import 'package:atrio/screens/admin_ads_screen.dart';
import 'package:atrio/screens/admin_requests_screen.dart';
import 'package:atrio/screens/aportar_a_proyecto_screen.dart';
import 'package:atrio/screens/ayuda_soporte_screen.dart';
import 'package:atrio/screens/biblia_screen.dart';
import 'package:atrio/screens/church_admin_dashboard_screen.dart';
import 'package:atrio/screens/church_poster_preview_screen.dart';
import 'package:atrio/screens/configuracion_screen.dart';
import 'package:atrio/screens/confirmar_donacion_screen.dart';
import 'package:atrio/screens/crear_cuenta_screen.dart';
import 'package:atrio/screens/crear_evento_screen.dart';
import 'package:atrio/screens/crear_mi_iglesia_screen.dart';
import 'package:atrio/screens/crear_predica_screen.dart';
import 'package:atrio/screens/create_ad_campaign_screen.dart';
import 'package:atrio/screens/detalle_libro_biblia_screen.dart';
// Screens - Donaciones / Aportes
import 'package:atrio/screens/donaciones_screen.dart';
import 'package:atrio/screens/emisoras_screen.dart';
// Screens - Contenido / Tienda / Biblia
import 'package:atrio/screens/escuchar_libro_biblia_screen.dart';
import 'package:atrio/screens/esperando_aprobacion_screen.dart';
import 'package:atrio/screens/eventos_screen.dart';
import 'package:atrio/screens/exito_recomendacion_screen.dart';
import 'package:atrio/screens/iglesia_pendiente_activacion_screen.dart';
import 'package:atrio/screens/iglesias_en_mapa_screen.dart';
// Screens - Principal
import 'package:atrio/screens/inicio_atrio_screen.dart';
import 'package:atrio/screens/inicio_sesion_screen.dart';
// Screens - Autenticación / Onboarding

import 'package:atrio/screens/intro_encuentra_screen.dart';
import 'package:atrio/screens/lectura_capitulo_screen.dart';
import 'package:atrio/screens/libros_de_biblia.dart';
import 'package:atrio/screens/libros_screen.dart';
import 'package:atrio/screens/mis_donaciones_screen.dart';
import 'package:atrio/screens/mis_favoritos_screen.dart';
import 'package:atrio/screens/mis_notas_screen.dart';
import 'package:atrio/screens/mis_pedidos_screen.dart';
import 'package:atrio/screens/moderation_screen.dart';
import 'package:atrio/screens/moderation_words_screen.dart';
import 'package:atrio/screens/notificaciones_screen.dart';
import 'package:atrio/screens/nueva_solicitud_screen.dart';
import 'package:atrio/screens/perfil_screen.dart';
import 'package:atrio/screens/proyecto_solidario_screen.dart';
import 'package:atrio/screens/qr_join_scanner_screen.dart';
import 'package:atrio/screens/realizar_aporte_screen.dart';
import 'package:atrio/screens/recomendar_iglesia_mapa_screen.dart';
import 'package:atrio/screens/recuperar_clave_screen.dart';
import 'package:atrio/screens/seguimiento_solicitud_screen.dart';
import 'package:atrio/screens/seleccionar_iglesia_screen.dart';
import 'package:atrio/screens/splash_screen.dart';
import 'package:atrio/screens/terminos_privacidad_screen.dart';
// Screens - Pruebas
import 'package:atrio/screens/test_pago_screen.dart';
import 'package:atrio/screens/tienda_screen.dart';
// Screens - Solicitudes
import 'package:atrio/screens/tipos_solicitud_screen.dart';
import 'package:atrio/screens/tradicion_cristiana_screen.dart';
import 'package:atrio/screens/videos_transmisiones_screen.dart';
import 'package:atrio/servicios/connectivity_service.dart';
import 'package:atrio/servicios/daily_verse_notification_service.dart';
import 'package:atrio/servicios/daily_verse_scheduler.dart';
import 'package:atrio/servicios/deep_link_service.dart';
import 'package:atrio/servicios/device_notification_service.dart';
import 'package:atrio/servicios/radio_player_service.dart';
import 'package:atrio/servicios/token_storage_service.dart';
import 'package:atrio/widgets/daily_prayer_modal_sheet.dart';
import 'package:atrio/theme/atrio_feedback_theme.dart';
import 'package:atrio/widgets/atrio_better_feedback.dart';
import 'package:atrio/widgets/atrio_feedback_form.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Paquetes - Google Maps
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  // 1. Vincular motor de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 1.1 Inicializar servicio de audio en segundo plano (iOS Lock Screen / Control Center y Android Notification)
  await RadioPlayerService.initBackgroundAudio();

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

  // 4. Inicialización segura de bases de datos locales SQLite
  try {
    await DatabaseHelper.instance.database;
    await AtrioDatabaseHelper.instance.database;
  } catch (e) {
    debugPrint('💥 Error inicializando bases de datos SQLite: $e');
  }

  // 5. Determinar la ruta inicial de forma condicional y nativa.
  // Mientras este proceso asíncrono se ejecuta, el sistema operativo presenta nativamente
  // el Splash Screen (API oficial de Splash Screen en Android 12+ o LaunchTheme en Android <12)
  // sin incurrir en demoras artificiales ni mostrar pantallas intermedias innecesarias.
  final prefs = await SharedPreferences.getInstance();
  final bool introVista = prefs.getBool('intro_vista') ?? false;

  final tokenStorage = TokenStorageService();
  final api = AtrioApi(
    baseUrl: AppConfig.odooBaseUrl,
    storageService: tokenStorage,
  );
  await api.initFromStorage();

  final bool prefsLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final bool tieneSesionActiva = prefsLoggedIn || api.isAuthenticated;

  String rutaInicial;

  if (!introVista) {
    // Usuario nuevo que no ha completado el onboarding inicial
    rutaInicial = IntroEncuentraScreen.routeName;
  } else if (!tieneSesionActiva) {
    // Usuario que ya completó onboarding pero no tiene sesión activa
    rutaInicial = InicioSesionScreen.routeName;
  } else {
    // Usuario con sesión activa: predeterminar HomeScreen para no mostrar login
    rutaInicial = InicioAtrioScreen.routeName;

    // Si cuenta con autenticación en Odoo 19, resolver AppStage exacto
    if (api.isAuthenticated) {
      try {
        final me = await api.me().timeout(const Duration(seconds: 2));
        final stage = resolveStage(me);
        switch (stage) {
          case AppStage.chooseChurch:
            // Regla de bypass: si el usuario ya seleccionó una iglesia localmente en SQLite o SharedPreferences,
            // omitir la pantalla de elección y entrar directo a HomeScreen.
            final String? iglesiaGuardada = prefs.getString('iglesia_guardada');
            Map<String, dynamic>? usuario;
            try {
              usuario = await AtrioDatabaseHelper.instance.getUsuario();
            } catch (_) {}
            final bool tieneIglesiaLocal =
                (iglesiaGuardada != null &&
                    iglesiaGuardada.trim().isNotEmpty &&
                    !UserModel.isDefaultOrDemoChurchName(iglesiaGuardada)) ||
                (usuario != null &&
                    usuario['iglesia_nombre'] != null &&
                    !UserModel.isDefaultOrDemoChurchName(
                      usuario['iglesia_nombre'].toString(),
                    ));

            rutaInicial = tieneIglesiaLocal
                ? InicioAtrioScreen.routeName
                : SeleccionarIglesiaScreen.routeName;
            break;
          case AppStage.waitingApproval:
            // Solicitud pendiente de aprobación: redirigir a HomeScreen donde se presenta el banner reactivo
            rutaInicial = InicioAtrioScreen.routeName;
            break;
          case AppStage.churchPendingActivation:
            rutaInicial = IglesiaPendienteActivacionScreen.routeName;
            break;
          case AppStage.welcome:
          case AppStage.memberHome:
          case AppStage.adminHome:
          case AppStage.platformAdmin:
            rutaInicial = InicioAtrioScreen.routeName;
            break;
        }
      } catch (e) {
        debugPrint(
          'ℹ️ [MAIN] Timeout o arranque offline al resolver AppStage: $e. Aplicando bypass con datos locales.',
        );
        final String? iglesiaGuardada = prefs.getString('iglesia_guardada');
        Map<String, dynamic>? usuario;
        try {
          usuario = await AtrioDatabaseHelper.instance.getUsuario();
        } catch (_) {}
        final bool tieneIglesiaLocal =
            (iglesiaGuardada != null &&
                iglesiaGuardada.trim().isNotEmpty &&
                !UserModel.isDefaultOrDemoChurchName(iglesiaGuardada)) ||
            (usuario != null &&
                usuario['iglesia_nombre'] != null &&
                !UserModel.isDefaultOrDemoChurchName(
                  usuario['iglesia_nombre'].toString(),
                ));

        rutaInicial = tieneIglesiaLocal
            ? InicioAtrioScreen.routeName
            : SeleccionarIglesiaScreen.routeName;
      }
    } else {
      // Sesión activa respaldada por SharedPreferences (prefsLoggedIn == true)
      final String? iglesiaGuardada = prefs.getString('iglesia_guardada');
      Map<String, dynamic>? usuario;
      try {
        usuario = await AtrioDatabaseHelper.instance.getUsuario();
      } catch (_) {}
      final bool tieneIglesiaLocal =
          (iglesiaGuardada != null &&
              iglesiaGuardada.trim().isNotEmpty &&
              !UserModel.isDefaultOrDemoChurchName(iglesiaGuardada)) ||
          (usuario != null &&
              usuario['iglesia_nombre'] != null &&
              !UserModel.isDefaultOrDemoChurchName(
                usuario['iglesia_nombre'].toString(),
              ));

      rutaInicial = tieneIglesiaLocal
          ? InicioAtrioScreen.routeName
          : SeleccionarIglesiaScreen.routeName;
    }
  }

  // 6. Iniciar monitoreo de conectividad en toda la app
  ConnectivityService.instance.startMonitoring();

  // 7. Arrancar la app proyectando directamente la ruta calculada
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
        ChangeNotifierProvider(create: (_) => JoinChurchProvider()),
        ChangeNotifierProxyProvider<UserProvider, AdminProvider>(
          create: (ctx) => AdminProvider(api: ctx.read<UserProvider>().api),
          update: (ctx, userProvider, previous) =>
              previous ?? AdminProvider(api: userProvider.api),
        ),
        ChangeNotifierProxyProvider<UserProvider, RecomendacionIglesiaProvider>(
          create: (ctx) =>
              RecomendacionIglesiaProvider(api: ctx.read<UserProvider>().api),
          update: (ctx, userProvider, previous) =>
              previous ?? RecomendacionIglesiaProvider(api: userProvider.api),
        ),
        ChangeNotifierProxyProvider<UserProvider, AdsProvider>(
          create: (ctx) => AdsProvider(api: ctx.read<UserProvider>().api),
          update: (ctx, userProvider, previous) =>
              previous ?? AdsProvider(api: userProvider.api),
        ),
        ChangeNotifierProxyProvider<UserProvider, ModerationProvider>(
          create: (ctx) =>
              ModerationProvider(api: ctx.read<UserProvider>().api),
          update: (ctx, userProvider, previous) =>
              previous ?? ModerationProvider(api: userProvider.api),
        ),
      ],
      child: MyApp(initialRoute: initialRoute),
    );
  }
}

/// Activa un disparo de prueba de la Oración Matutina 4 s después del arranque.
/// Uso: `flutter run --dart-define=ATRIO_TEST_DAILY_NOTIF=true`
const bool _kTestDailyNotification =
    bool.fromEnvironment('ATRIO_TEST_DAILY_NOTIF');

class MyApp extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final userProvider = context.read<UserProvider>();
        DeviceNotificationService.instance.initialize(
          api: userProvider.api,
          userProvider: userProvider,
          navigatorKey: MyApp.navigatorKey,
        );
        DeepLinkService().initDeepLinks();

        // Inicialización y manejo de toque (redirección in-app) para la Palabra del Día
        final navContext = MyApp.navigatorKey.currentContext;
        final activeLocale = context.read<AjustesProvider>().locale;
        final l10n =
            (navContext != null ? AppLocalizations.of(navContext) : null) ??
            lookupAppLocalizations(
              AppLocalizations.supportedLocales.any(
                    (l) => l.languageCode == activeLocale.languageCode,
                  )
                  ? Locale(activeLocale.languageCode)
                  : const Locale('es'),
            );
        await DailyVerseNotificationService.instance.initialize(
          channelName: l10n.dailyWordChannelName,
          channelDescription: l10n.dailyWordChannelDescription,
          onSelectPayload: (Map<String, dynamic> data) {
            if (data['type'] == 'daily_verse') {
              final navState = MyApp.navigatorKey.currentState;
              final currentCtx = MyApp.navigatorKey.currentContext;
              if (navState != null) {
                final String reference = data['reference']?.toString() ?? '';
                void abrirCapitulo() {
                  navState.pushNamed(
                    LecturaCapituloScreen.routeName,
                    arguments: {
                      'id': data['bookId'] is int ? data['bookId'] : 50,
                      'nombre': data['bookName']?.toString() ?? reference,
                      'capitulo': data['chapter'] is int ? data['chapter'] : 1,
                      'totalCapitulos': data['totalChapters'] is int
                          ? data['totalChapters']
                          : 1,
                      'subtitulo': reference,
                      'verso': data['verse'] is int ? data['verse'] : null,
                      'versoFin':
                          data['verseEnd'] is int ? data['verseEnd'] : null,
                    },
                  );
                }

                // Despliega el modal in-app elegante y moderno (estilo imagen adjunta)
                if (currentCtx != null && currentCtx.mounted) {
                  final activeL10n = AppLocalizations.of(currentCtx) ?? l10n;
                  DailyPrayerModalSheet.mostrar(
                    context: currentCtx,
                    title: activeL10n.dailyPrayerMorningTitle,
                    reference: reference,
                    body: data['body']?.toString() ??
                        activeL10n.dailyPrayerDefaultBody,
                    onGoToChapter: abrirCapitulo,
                  );
                } else {
                  abrirCapitulo();
                }
              }
            }
          },
        );

        // Solicitar permiso de notificaciones (el SO solo muestra el diálogo
        // la primera vez) y reprogramar el lote de Oraciones Matutinas según
        // los ajustes del usuario (activado, hora e idioma).
        await DailyVerseNotificationService.instance.requestPermissions();
        if (!mounted) return;
        final ajustesProvider = context.read<AjustesProvider>();
        await ajustesProvider.cargaInicial;
        await DailyVerseScheduler.sync(ajustesProvider.ajustes);

        // Disparo de prueba: flutter run --dart-define=ATRIO_TEST_DAILY_NOTIF=true
        if (_kTestDailyNotification) {
          await DailyVerseScheduler.showTest(ajustesProvider.ajustes);
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint(
        '[LIFECYCLE] App resumed: sincronizando sesión con Odoo 19...',
      );
      try {
        // Mantener siempre cubiertos los próximos días con la Oración Matutina.
        DailyVerseScheduler.sync(context.read<AjustesProvider>().ajustes);
        final userProvider = context.read<UserProvider>();
        if (userProvider.isAuthenticated) {
          userProvider
              .refreshUserProfile()
              .then((_) {
                if (!mounted) return;
                final stage = userProvider.currentStage;
                // Si el estado pasó a estar activo (aprobación de membresía o activación de congregación)
                if (stage == AppStage.memberHome ||
                    stage == AppStage.adminHome) {
                  final nav = MyApp.navigatorKey.currentState;
                  final currentCtx = MyApp.navigatorKey.currentContext;
                  if (nav != null && currentCtx != null && currentCtx.mounted) {
                    final currentRoute = ModalRoute.of(currentCtx)
                        ?.settings
                        .name;
                    if (currentRoute == EsperandoAprobacionScreen.routeName ||
                        currentRoute ==
                            IglesiaPendienteActivacionScreen.routeName) {
                      nav.pushNamedAndRemoveUntil(
                        InicioAtrioScreen.routeName,
                        (r) => false,
                      );
                    }
                  }
                }
              })
              .catchError((e) {
                debugPrint(
                  '[LIFECYCLE] Error pasivo en refreshUserProfile: $e',
                );
              });
        }
      } catch (e) {
        debugPrint('[LIFECYCLE] Error en didChangeAppLifecycleState: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ajustes = context.watch<AjustesProvider>();

    return AtrioBetterFeedback(
      theme: AtrioFeedbackTheme.theme,
      feedbackBuilder: (context, onSubmit, scrollController) {
        return AtrioFeedbackForm(
          onSubmit: onSubmit,
          scrollController: scrollController,
        );
      },
      localizationsDelegates: [GlobalFeedbackLocalizationsDelegate()],
      localeOverride: ajustes.locale,
      child: MaterialApp(
        navigatorKey: MyApp.navigatorKey,
        scaffoldMessengerKey: MyApp.scaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        title: 'ATRIO',
        locale: ajustes.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: _routes,
        initialRoute: widget.initialRoute,
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
      ),
    );
  }

  // =========================================================
  // RUTAS CENTRALIZADAS (Static routeName)
  // =========================================================
  static final Map<String, WidgetBuilder> _routes = {
    // ---------- Bienvenida / Splash ----------
    SplashScreen.routeName: (_) => const SplashScreen(),

    // ---------- Autenticación / Onboarding ----------
    IntroEncuentraScreen.routeName: (_) => const IntroEncuentraScreen(),
    InicioSesionScreen.routeName: (_) => const InicioSesionScreen(),
    AccesoSocialScreen.routeName: (_) => const AccesoSocialScreen(),
    CrearCuentaScreen.routeName: (_) => const CrearCuentaScreen(),
    RecuperarClaveScreen.routeName: (_) => const RecuperarClaveScreen(),
    SeleccionarIglesiaScreen.routeName: (_) => const SeleccionarIglesiaScreen(),
    TradicionCristianaScreen.routeName: (_) => const TradicionCristianaScreen(),
    EsperandoAprobacionScreen.routeName: (_) =>
        const EsperandoAprobacionScreen(),
    IglesiaPendienteActivacionScreen.routeName: (_) =>
        const IglesiaPendienteActivacionScreen(),
    CrearMiIglesiaScreen.routeName: (_) => const CrearMiIglesiaScreen(),
    RecomendarIglesiaMapaScreen.routeName: (_) =>
        const RecomendarIglesiaMapaScreen(),
    ExitoRecomendacionScreen.routeName: (_) => const ExitoRecomendacionScreen(),
    QrJoinScannerScreen.routeName: (_) => const QrJoinScannerScreen(),
    ChurchPosterPreviewScreen.routeName: (_) =>
        const ChurchPosterPreviewScreen(),

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
    EmisorasScreen.routeName: (_) => const EmisorasScreen(),
    MisFavoritosScreen.routeName: (_) => const MisFavoritosScreen(),
    MisNotasScreen.routeName: (_) => const MisNotasScreen(),
    VideosTransmisionesScreen.routeName: (_) =>
        const VideosTransmisionesScreen(),
    CrearEventoScreen.routeName: (_) => const CrearEventoScreen(),
    CrearPredicaScreen.routeName: (_) => const CrearPredicaScreen(),
    AdminAdsScreen.routeName: (_) => const AdminAdsScreen(),
    CreateAdCampaignScreen.routeName: (_) => const CreateAdCampaignScreen(),
    ModerationScreen.routeName: (_) => const ModerationScreen(),
    ModerationWordsScreen.routeName: (_) => const ModerationWordsScreen(),
    ChurchAdminDashboardScreen.routeName: (_) =>
        const ChurchAdminDashboardScreen(),
    AdminRequestsScreen.routeName: (_) => const AdminRequestsScreen(),

    // ---------- Pruebas ----------
    TestPagoScreen.routeName: (_) => const TestPagoScreen(),
  };
}
