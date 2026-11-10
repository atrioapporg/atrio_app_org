import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/data/atrio_database_helper.dart';
import 'package:atrio/data/database_helper.dart';
import 'package:atrio/atrio_api.dart';
import 'package:atrio/data/app_config.dart';
import 'package:atrio/modelos/user_model.dart';
import 'package:atrio/servicios/token_storage_service.dart';

// Rutas de destino
import 'package:atrio/screens/intro_encuentra_screen.dart';
import 'package:atrio/screens/inicio_sesion_screen.dart';
import 'package:atrio/screens/inicio_atrio_screen.dart';
import 'package:atrio/screens/seleccionar_iglesia_screen.dart';
import 'package:atrio/screens/iglesia_pendiente_activacion_screen.dart';

/// Pantalla de bienvenida inmersiva (Splash Screen) en Flutter.
/// Muestra la imagen de la iglesia al atardecer, el logotipo corporativo,
/// el slogan oficial y un indicador de carga mientras inicializa las bases
/// de datos locales y el estado de la sesión de forma fluida y multiplataforma.
class SplashScreen extends StatefulWidget {
  static const String routeName = '/splash';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializarYRedirigir();
    });
  }

  Future<void> _inicializarYRedirigir() async {
    // 1. Inicialización inmediata de servicios y sesión sin demoras artificiales
    final String rutaDestino = await _ejecutarInicializaciones();

    if (!mounted) return;

    // 2. Transición directa a la pantalla de destino
    Navigator.of(context).pushReplacementNamed(rutaDestino);
  }

  Future<String> _ejecutarInicializaciones() async {
    try {
      // Inicialización segura de bases de datos SQLite
      try {
        await DatabaseHelper.instance.database;
        await AtrioDatabaseHelper.instance.database;
      } catch (e) {
        debugPrint('⚠️ [SPLASH] Error inicializando bases de datos SQLite: $e');
      }

      // Lectura de preferencias de usuario
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

      // Determinar ruta inicial de acuerdo al ciclo de vida real
      if (!introVista) {
        return IntroEncuentraScreen.routeName;
      }

      if (!tieneSesionActiva) {
        return InicioSesionScreen.routeName;
      }

      String rutaInicial = InicioAtrioScreen.routeName;

      // Si hay sesión iniciada en Odoo 19, resolver el stage exacto
      if (api.isAuthenticated) {
        try {
          final me = await api.me().timeout(const Duration(seconds: 2));
          final stage = resolveStage(me);
          switch (stage) {
            case AppStage.chooseChurch:
              final String? iglesiaGuardada = prefs.getString(
                'iglesia_guardada',
              );
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
          if (e is AtrioApiException && e.isUnauthorized) {
            debugPrint(
              '🔒 [SPLASH] Sesión expirada definitivamente tras fallo fatal de refresh. Redirigiendo a InicioSesionScreen.',
            );
            await prefs.setBool('isLoggedIn', false);
            return InicioSesionScreen.routeName;
          }
          debugPrint('ℹ️ [SPLASH] Modo offline o timeout en AppStage: $e');
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
        // Sesión activa respaldada en SharedPreferences (prefsLoggedIn == true)
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

      return rutaInicial;
    } catch (e) {
      debugPrint('💥 [SPLASH] Error durante bootstrap: $e');
      return InicioSesionScreen.routeName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF072B4F),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Capa 1: Fondo institucional unificado (#072B4F)
          SplashBackgroundView(),

          // Capa 2: Contenido central e inferior
          SafeArea(
            child: Column(
              children: [
                Spacer(flex: 3),
                // Emblema, Logotipo y Slogan de ATRIO
                SplashBrandingHeader(),
                Spacer(flex: 4),
                // Indicador de progreso elegante y etiqueta de carga
                SplashLoadingFooter(),
                SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Capa de fondo que proyecta el color institucional #072B4F continuo con el splash nativo.
class SplashBackgroundView extends StatelessWidget {
  const SplashBackgroundView({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF072B4F),
    );
  }
}

/// Cabecera con el logotipo y slogan oficial de ATRIO.
class SplashBrandingHeader extends StatelessWidget {
  const SplashBrandingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final String sloganTexto = l10n?.sloganAtrio ?? 'JUNTOS EN LA FE, MÁS CERCA DE TI';

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logotipo institucional
          Image.asset(
            'assets/images/logo_encabezado_sinfondo.png',
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 12),
          // Slogan corporativo localizado
          Text(
            sloganTexto,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
              shadows: [
                Shadow(
                  color: Colors.black54,
                  offset: Offset(0, 1.5),
                  blurRadius: 4.0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pie con animación de progreso dorada y texto de carga.
class SplashLoadingFooter extends StatelessWidget {
  const SplashLoadingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final String cargandoTexto = l10n?.cargandoAtrio ?? 'Cargando...';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.8,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE5A023)),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          cargandoTexto,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.1,
            shadows: [
              Shadow(
                color: Colors.black45,
                offset: Offset(0, 1),
                blurRadius: 3.0,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
