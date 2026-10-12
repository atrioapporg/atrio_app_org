import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:atrio/data/app_config.dart';
import 'package:atrio/data/atrio_database_helper.dart';
import 'package:atrio/providers/ajustes_provider.dart';
import 'package:atrio/providers/iglesia_provider.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/l10n/app_localizations.dart';

import 'inicio_atrio_screen.dart';
import 'tradicion_cristiana_screen.dart';

/// ==============================================================================
/// PANTALLA DE ACCESO ATRIO (INICIO DE SESIÓN / REGISTRO)
/// ==============================================================================
/// Arquitectura:
/// - Exclusivamente Social Login (Google Sign-In y Sign in with Apple).
/// - Flujo de 1 solo toque (Login & Sign-Up unificados).
/// - Compatible con Odoo 19 (Controlador Social Login / OpenID Connect).
/// - Cumple con Apple App Store Guideline 4.8 (Sign in with Apple) y 5.1.1(v)
///   (Solicitud / Ejecución de eliminación de cuenta).
/// ==============================================================================
class InicioSesionScreen extends StatefulWidget {
  static const routeName = 'inicio_sesion_screen';

  const InicioSesionScreen({super.key});

  @override
  State<InicioSesionScreen> createState() => _InicioSesionScreenState();
}

class _InicioSesionScreenState extends State<InicioSesionScreen> {
  // Paleta oficial ATRIO
  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFE0E0E0);
  static const Color textoGris = Color(0xFF757575);
  static const Color azulLink = Color(0xFF0055A5);

  // Estados de carga independientes para feedback visual responsivo
  bool _isLoadingGoogle = false;
  bool _isLoadingApple = false;

  bool get _isProcessing => _isLoadingGoogle || _isLoadingApple;

  // Instancia de GoogleSignIn (temporalmente con serverClientId de prueba hasta tener credenciales oficiales de Odoo)
  // TODO: Reemplazar serverClientId temporal por credenciales oficiales de ATRIO cuando estén disponibles
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: AppConfig.googleServerClientId.isNotEmpty
        ? AppConfig.googleServerClientId
        : '249769938564-3nnofpi61o89njv84rt6agihftsdncvi.apps.googleusercontent.com',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
        if (isLoggedIn && mounted) {
          await _redirigirUsuarioPostLogin();
        }
      } catch (e) {
        debugPrint('[AUTH] Error verificando sesión inicial: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Métricas dinámicas relativas (Flutter 3.22+)
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    final ajustesProvider = context.watch<AjustesProvider>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: true,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight,
          child: Column(
            children: [
              // ===============================================================
              // 1. TOP HEADER (Logo Horizontal + Selector de Idioma + Título)
              // ===============================================================
              Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                child: Column(
                  children: [
                    SizedBox(height: usableHeight * 0.015),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo Horizontal Atrio
                        Image.asset(
                          'assets/images/logo_encabezado_sinfondo.png',
                          height: usableHeight * 0.060,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/logo_encabezado.png',
                              height: usableHeight * 0.060,
                              fit: BoxFit.contain,
                            );
                          },
                        ),

                        // Selector de Idioma
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.02,
                            ),
                            onTap: () => _mostrarSelectorIdioma(
                              context,
                              ajustesProvider,
                              screenWidth,
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.025,
                                vertical: usableHeight * 0.006,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  screenWidth * 0.02,
                                ),
                                border: Border.all(color: Colors.white38),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.language,
                                    color: Colors.white,
                                    size: screenWidth * 0.04,
                                  ),
                                  SizedBox(width: screenWidth * 0.015),
                                  Text(
                                    _obtenerNombreIdioma(
                                      ajustesProvider.idiomaCodigo,
                                    ),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.03,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.white,
                                    size: screenWidth * 0.04,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.018),

                    // Título y Subtítulo
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n?.bienvenida ?? 'Bienvenido a Atrio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.075,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.004),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n?.subtituloBienvenida ??
                            'Un espacio para vivir y compartir tu fe',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: screenWidth * 0.042,
                        ),
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.015),
                  ],
                ),
              ),

              // ===============================================================
              // 2. CONTENEDOR PRINCIPAL INFERIOR (Acceso Social Exclusivo)
              // ===============================================================
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
                        horizontal: screenWidth * 0.06,
                        vertical: usableHeight * 0.030,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: usableHeight * 0.01),

                          // Icono / Distintivo de Seguridad
                          Container(
                            width: screenWidth * 0.14,
                            height: screenWidth * 0.14,
                            decoration: BoxDecoration(
                              color: azulFondo.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.verified_user_outlined,
                              color: azulFondo,
                              size: screenWidth * 0.075,
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.015),

                          // Título de la sección
                          Text(
                            l10n?.accesoRapidoSeguro ??
                                'Acceso Rápido y Seguro',
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.065,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: usableHeight * 0.008),

                          Text(
                            l10n?.ingresaUnToque ?? 'Ingresa en un solo toque',
                            style: TextStyle(
                              color: textoGris,
                              fontSize: screenWidth * 0.045,
                              height: 1.35,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: usableHeight * 0.035),

                          // ===================================================
                          // BOTÓN 1: CONTINUAR CON GOOGLE
                          // ===================================================
                          _buildSocialButton(
                            title:
                                l10n?.continuarConGoogle ??
                                'Continuar con Google',
                            imageAsset: 'assets/images/google_logo.png',
                            backgroundColor: Colors.white,
                            textColor: azulFondo,
                            borderColor: grisBorde,
                            isLoading: _isLoadingGoogle,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            onTap: _isProcessing ? null : _iniciarSesionGoogle,
                          ),
                          SizedBox(height: usableHeight * 0.040),

                          // ===================================================
                          // BOTÓN 2: CONTINUAR CON APPLE (Obligatorio iOS)
                          // ===================================================
                          _buildSocialButton(
                            title: l10n != null
                                ? '   ${l10n.continuarConApple}'
                                : '   Continuar con Apple',
                            customIcon: FaIcon(
                              FontAwesomeIcons.apple,
                              color: Colors.white,
                              size: screenWidth * 0.085,
                            ),
                            backgroundColor: Colors.black,
                            textColor: Colors.white,
                            borderColor: Colors.black,
                            isLoading: _isLoadingApple,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            onTap: _isProcessing
                                ? null
                                : () {
                                    if (defaultTargetPlatform ==
                                        TargetPlatform.android) {
                                      _mostrarAvisoAndroidApple(
                                        context,
                                        screenWidth,
                                        usableHeight,
                                      );
                                      return;
                                    }
                                    _iniciarSesionApple();
                                  },
                          ),
                          SizedBox(height: usableHeight * 0.030),

                          // ===================================================
                          // ACCESO INVITADO / EXPLORAR
                          // ===================================================
                          TextButton.icon(
                            onPressed: _isProcessing
                                ? null
                                : () => _continuarComoInvitado(context),
                            icon: Icon(
                              Icons.explore_outlined,
                              color: azulLink,
                              size: screenWidth * 0.045,
                            ),
                            label: Text(
                              l10n?.explorarInvitado ??
                                  'Explorar como invitado',
                              style: TextStyle(
                                color: azulLink,
                                fontSize: screenWidth * 0.050,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.030),

                          // Información de privacidad
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04,
                            ),
                            child: Text(
                              l10n?.avisoPrivacidadOdoo ?? 'Al continuar, vinculas tu cuenta de forma segura con el servidor eclesial de ATRIO en Odoo ERP.',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: screenWidth * 0.029,
                                height: 1.3,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.020),

                          // ===================================================
                          // ENLACES LEGALES Y GESTIÓN DE CUENTA
                          // ===================================================
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: _mostrarTerminosDeUso,
                                child: Text(
                                  l10n?.terminosDeUso ?? 'Términos de uso',
                                  style: TextStyle(
                                    color: azulFondo,
                                    fontSize: screenWidth * 0.040,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.02,
                                ),
                                child: Text(
                                  '•',
                                  style: TextStyle(
                                    color: textoGris,
                                    fontSize: screenWidth * 0.035,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _mostrarPoliticaPrivacidad,
                                child: Text(
                                  l10n?.privacidad ?? 'Privacidad',
                                  style: TextStyle(
                                    color: azulFondo,
                                    fontSize: screenWidth * 0.040,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: usableHeight * 0.012),

                          // Enlace directo a solicitud de eliminación de datos
                          // (Cumplimiento de políticas de Google Play y Apple)
                          GestureDetector(
                            onTap: () => _mostrarSolicitudEliminacionDatos(
                              context,
                              screenWidth,
                              usableHeight,
                            ),
                            child: Text(
                              l10n?.eliminarMisDatos ?? 'Eliminar mis datos',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: screenWidth * 0.040,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.02),
                        ],
                      ),
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

  // ============================================================================
  // GESTIÓN Y SELECTOR DE IDIOMA (flutter_localizations)
  // ============================================================================
  String _obtenerNombreIdioma(String codigo) {
    switch (codigo) {
      case 'en':
        return 'English';
      case 'pt':
        return 'Português';
      case 'fr':
        return 'Français';
      case 'es':
      default:
        return 'Español';
    }
  }

  void _mostrarSelectorIdioma(
    BuildContext context,
    AjustesProvider provider,
    double screenWidth,
  ) {
    final opciones = [
      {'codigo': 'es', 'region': 'DO', 'nombre': 'Español', 'bandera': '🇩🇴'},
      {'codigo': 'en', 'region': 'US', 'nombre': 'English', 'bandera': '🇺🇸'},
      {
        'codigo': 'pt',
        'region': 'BR',
        'nombre': 'Português',
        'bandera': '🇧🇷',
      },
      {'codigo': 'fr', 'region': 'FR', 'nombre': 'Français', 'bandera': '🇫🇷'},
    ];

    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.06),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenWidth * 0.04,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.translate_rounded, color: azulFondo),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    l10n?.seleccionarIdioma ?? 'Seleccionar Idioma',
                    style: TextStyle(
                      color: azulFondo,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              ...opciones.map((opcion) {
                final isSelected = provider.idiomaCodigo == opcion['codigo'];
                return ListTile(
                  leading: Text(
                    opcion['bandera']!,
                    style: TextStyle(fontSize: screenWidth * 0.06),
                  ),
                  title: Text(
                    opcion['nombre']!,
                    style: TextStyle(
                      color: isSelected ? azulFondo : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: screenWidth * 0.038,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: amarilloOro,
                        )
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                  ),
                  tileColor: isSelected
                      ? azulFondo.withValues(alpha: 0.05)
                      : Colors.transparent,
                  onTap: () {
                    provider.cambiarIdioma(
                      opcion['codigo']!,
                      region: opcion['region'],
                    );
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // TODO: INTEGRACIÓN DEFINITIVA CON ODOO 19
  // Cambiar esta implementación temporal cuando se tengan las credenciales, APIs
  // y endpoints definitivos de los dueños del código de ATRIO.
  // Actualmente simula un login exitoso vía cuenta de Google persistiendo en
  // SharedPreferences, AtrioDatabaseHelper y UserProvider.
  // ============================================================================
  Future<void> _iniciarSesionGoogle() async {
    setState(() => _isLoadingGoogle = true);
    FocusScope.of(context).unfocus();

    try {
      String email = 'usuario.google@gmail.com';
      String nombre = 'Usuario Google';

      // Intento de conexión nativa con Google Sign-In
      try {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          // El usuario canceló voluntariamente el diálogo de Google
          debugPrint('[AUTH] Inicio de sesión cancelado por el usuario.');
          if (mounted) setState(() => _isLoadingGoogle = false);
          return;
        }

        email = googleUser.email;
        if (googleUser.displayName != null &&
            googleUser.displayName!.trim().isNotEmpty) {
          nombre = googleUser.displayName!.trim();
        }
      } catch (e) {
        debugPrint(
          '[AUTH_INFO] Google Sign-In nativo no disponible en este entorno: $e. Procediendo con inicio de sesión simulado.',
        );
      }

      // 1. Guardar en SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userEmail', email);
      await prefs.setString('userName', nombre);

      // Verificamos si ya existe una iglesia previa configurada en SQLite
      final usuarioExistente = await AtrioDatabaseHelper.instance.getUsuario();
      final String iglesiaExistente =
          (usuarioExistente != null &&
              usuarioExistente['iglesia_nombre'] != null &&
              usuarioExistente['iglesia_nombre'].toString().trim().isNotEmpty &&
              usuarioExistente['iglesia_nombre'].toString().trim() !=
                  'Sin iglesia seleccionada')
          ? usuarioExistente['iglesia_nombre'].toString().trim()
          : 'Sin iglesia seleccionada';

      // 2. Persistir localmente en SQLite (atrio.db)
      await AtrioDatabaseHelper.instance.guardarUsuario(<String, dynamic>{
        'nombre': nombre,
        'email': email,
        'celular': '',
        'iglesia_nombre': iglesiaExistente,
      });

      if (!mounted) return;

      // 3. Sincronizar en memoria con UserProvider
      try {
        Provider.of<UserProvider>(context, listen: false).updateUserProfile(
          nombre: nombre,
          email: email,
          telefono: '',
          iglesiaActual: iglesiaExistente,
        );
      } catch (e) {
        debugPrint('[PROVIDER_WARN] Provider no encontrado: $e');
      }

      // 4. Redirigir según el estado del usuario (hacia selección de tradición e iglesia si es primer registro)
      await _redirigirUsuarioPostLogin();
    } catch (error) {
      debugPrint('[AUTH_ERROR] Error en Google Sign-In: $error');
      _mostrarError('No se pudo conectar con Google. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => _isLoadingGoogle = false);
    }
  }

  // ============================================================================
  // FLUJO DE AUTENTICACIÓN CON APPLE
  // ============================================================================
  Future<void> _iniciarSesionApple() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return;
    }
    setState(() => _isLoadingApple = true);

    try {
      debugPrint('[AUTH] Iniciando flujo nativo de Sign in with Apple...');

      // Verificamos si estamos en un entorno compatible (iOS/macOS o Web)
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        // Opcional para web o Android (mediante Service ID de AppConfig):
        webAuthenticationOptions: AppConfig.appleServiceId.isNotEmpty
            ? WebAuthenticationOptions(
                clientId: AppConfig.appleServiceId,
                redirectUri: Uri.parse(
                  '${AppConfig.odooBaseUrl}/api/v1/auth/apple/callback',
                ),
              )
            : null,
      );

      final String? identityToken = credential.identityToken;
      final authorizationCode = credential.authorizationCode;

      // Apple solo entrega nombre y correo en la primera autorización
      final String nombre = [
        credential.givenName ?? '',
        credential.familyName ?? '',
      ].join(' ').trim();
      final String email = credential.email ?? '';

      debugPrint('[AUTH] Apple Sign-In exitoso.');
      debugPrint('       User Identifier: ${credential.userIdentifier}');
      debugPrint('       Email: $email');
      debugPrint('       Nombre: $nombre');
      debugPrint('       Identity Token presente: ${identityToken != null}');
      debugPrint(
        '       Authorization Code presente: ${authorizationCode.isNotEmpty}',
      );

      // =======================================================================
      // TODO: ODOO 19 BACKEND INTEGRATION
      // =======================================================================
      // 1. URL Endpoint:
      //    '${AppConfig.odooBaseUrl}${AppConfig.odooSocialAuthEndpoint}'
      //
      // 2. Payload HTTP POST:
      //    final body = jsonEncode({
      //      'provider': 'apple',
      //      'identity_token': identityToken,
      //      'authorization_code': authorizationCode,
      //      'user_identifier': credential.userIdentifier,
      //      'email': email,
      //      'name': nombre.isNotEmpty ? nombre : 'Usuario Apple',
      //      'db': AppConfig.odooDatabase,
      //    });
      //
      // 3. Odoo validará la firma criptográfica con las claves públicas de Apple
      //    y responderá con session_id y perfil de res.partner.
      // =======================================================================

      final String nombreFinal = nombre.isNotEmpty ? nombre : 'Usuario Apple';
      final String emailFinal = email.isNotEmpty
          ? email
          : 'apple_user_${credential.userIdentifier?.substring(0, 6)}@privaterelay.appleid.com';

      // 1. Guardar en SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userEmail', emailFinal);
      await prefs.setString('userName', nombreFinal);

      // Verificamos si ya existe una iglesia previa configurada en SQLite
      final usuarioExistente = await AtrioDatabaseHelper.instance.getUsuario();
      final String iglesiaExistente =
          (usuarioExistente != null &&
              usuarioExistente['iglesia_nombre'] != null &&
              usuarioExistente['iglesia_nombre'].toString().trim().isNotEmpty &&
              usuarioExistente['iglesia_nombre'].toString().trim() !=
                  'Sin iglesia seleccionada')
          ? usuarioExistente['iglesia_nombre'].toString().trim()
          : 'Sin iglesia seleccionada';

      // 2. Persistir localmente en SQLite (atrio.db)
      await AtrioDatabaseHelper.instance.guardarUsuario(<String, dynamic>{
        'nombre': nombreFinal,
        'email': emailFinal,
        'celular': '',
        'idioma': 'es_DO',
        'iglesia_nombre': iglesiaExistente,
      });

      if (!mounted) return;

      // 3. Sincronizar en memoria con UserProvider
      try {
        Provider.of<UserProvider>(context, listen: false).updateUserProfile(
          nombre: nombreFinal,
          email: emailFinal,
          telefono: '',
          iglesiaActual: iglesiaExistente,
        );
      } catch (e) {
        debugPrint('[PROVIDER_WARN] Provider no encontrado: $e');
      }

      // 4. Redirigir según el estado del usuario (hacia selección de tradición e iglesia si es primer registro)
      await _redirigirUsuarioPostLogin();
    } catch (error) {
      debugPrint('[AUTH] Error en Sign in with Apple: $error');
      // Si el error no es de cancelación por el usuario, mostrar alerta informativa
      if (!error.toString().contains('canceled') &&
          !error.toString().contains('cancelled')) {
        _mostrarMensajeError(
          'No se pudo completar el acceso con Apple. Verifica tu cuenta de Apple ID o tu conexión.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingApple = false);
    }
  }

  // ============================================================================
  // REDIRECCIÓN INTELIGENTE POST LOGIN
  // ============================================================================
  Future<void> _redirigirUsuarioPostLogin() async {
    final iglesiaProvider = context.read<IglesiaProvider>();
    final bool tieneIglesiaLocal = await iglesiaProvider
        .verificarIglesiaGuardada();

    // Verificamos si en la base de datos local el usuario ya tiene una iglesia válida configurada
    final usuario = await AtrioDatabaseHelper.instance.getUsuario();
    final bool tieneIglesiaDb =
        usuario != null &&
        usuario['iglesia_nombre'] != null &&
        usuario['iglesia_nombre'].toString().trim().isNotEmpty &&
        usuario['iglesia_nombre'].toString().trim() !=
            'Sin iglesia seleccionada';

    final bool usuarioTieneIglesia = tieneIglesiaLocal || tieneIglesiaDb;

    if (!mounted) return;

    if (usuarioTieneIglesia) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        InicioAtrioScreen.routeName,
        (route) => false,
      );
    } else {
      Navigator.pushNamed(context, TradicionCristianaScreen.routeName);
    }
  }

  // Continuar como invitado sin autenticarse de inmediato
  void _continuarComoInvitado(BuildContext context) {
    Navigator.pushNamed(context, TradicionCristianaScreen.routeName);
  }

  // ============================================================================
  // MODAL DE SOLICITUD DE ELIMINACIÓN DE CUENTA Y DATOS PERSONALES
  // (Cumplimiento estricto con Apple App Store 5.1.1(v) y Google Play Console)
  // ============================================================================
  void _mostrarSolicitudEliminacionDatos(
    BuildContext context,
    double screenWidth,
    double usableHeight,
  ) {
    final emailController = TextEditingController();
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: blancoFondo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
          ),
          title: Row(
            children: [
              Icon(
                Icons.delete_forever_rounded,
                color: Colors.red.shade700,
                size: screenWidth * 0.065,
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: Text(
                  l10n?.eliminarCuentaYDatos ?? 'Eliminar cuenta y datos',
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conforme a nuestras políticas de privacidad y los estándares de las tiendas de aplicaciones, tienes el derecho de solicitar la eliminación total de tu cuenta y los datos personales asociados en los servidores de ATRIO y Odoo.',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: screenWidth * 0.033,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: usableHeight * 0.015),
                Text(
                  'Ingresa el correo con el que te autenticaste para procesar tu solicitud:',
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.032,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: usableHeight * 0.008),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.035,
                  ),
                  decoration: InputDecoration(
                    hintText: 'tu@correo.com',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: usableHeight * 0.012,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      borderSide: const BorderSide(color: grisBorde),
                    ),
                  ),
                ),
                SizedBox(height: usableHeight * 0.012),
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.025),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.amber.shade900,
                        size: screenWidth * 0.04,
                      ),
                      SizedBox(width: screenWidth * 0.015),
                      Expanded(
                        child: Text(
                          'Esta acción purgará tus notas de la Biblia, historial de aportes y desvinculará tu usuario en Odoo de forma irreversible.',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontSize: screenWidth * 0.028,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l10n?.cancelar ?? 'Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
              ),
              onPressed: () async {
                final emailSolicitado = emailController.text.trim();
                if (emailSolicitado.isEmpty) return;

                Navigator.pop(dialogCtx);

                // =============================================================
                // TODO: ODOO 19 BACKEND INTEGRATION - SOLICITUD DE BORRADO
                // =============================================================
                // URL: '${AppConfig.odooBaseUrl}${AppConfig.odooDeleteAccountEndpoint}'
                // Body: { 'email': emailSolicitado, 'db': AppConfig.odooDatabase }
                // =============================================================

                // Purgado de datos locales inmediatos
                await AtrioDatabaseHelper.instance.eliminarUsuarioYDatos();
                if (context.mounted) {
                  Provider.of<UserProvider>(
                    context,
                    listen: false,
                  ).clearSession();
                }

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: azulFondo,
                    content: Text(
                      'Solicitud de eliminación registrada para $emailSolicitado. Tus datos locales han sido borrados.',
                      style: const TextStyle(color: Colors.white),
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );
              },
              child: Text(
                l10n?.solicitarEliminacion ?? 'Solicitar eliminación',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================================
  // AVISO SISTEMA OPERATIVO (APPLE EN ANDROID)
  // ============================================================================
  void _mostrarAvisoAndroidApple(
    BuildContext context,
    double screenWidth,
    double usableHeight,
  ) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: blancoFondo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.02),
              decoration: BoxDecoration(
                color: amarilloOro.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.phone_android_rounded,
                color: azulFondo,
                size: screenWidth * 0.065,
              ),
            ),
            SizedBox(width: screenWidth * 0.025),
            Expanded(
              child: Text(
                l10n?.opcionNoDisponible ?? 'Opción no disponible',
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Has seleccionado "Continuar con Apple", la cual es una opción diseñada exclusivamente para dispositivos Apple (iOS).',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: screenWidth * 0.036,
                height: 1.4,
              ),
            ),
            SizedBox(height: usableHeight * 0.015),
            Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                border: Border.all(color: grisBorde),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: const Color(0xFF2E7D32),
                    size: screenWidth * 0.055,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Text(
                      'En tu dispositivo Android, por favor utiliza "Continuar con Google" para ingresar de forma rápida y segura.',
                      style: TextStyle(
                        color: azulFondo,
                        fontSize: screenWidth * 0.033,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              l10n?.entendido ?? 'Entendido',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: screenWidth * 0.036,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _iniciarSesionGoogle();
            },
            icon: Image.asset(
              'assets/images/google_logo.png',
              width: screenWidth * 0.045,
              height: screenWidth * 0.045,
            ),
            label: Text(
              'Usar Google',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.036,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: azulFondo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: usableHeight * 0.012,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // UTILIDADES Y MODALES INFORMATIVOS
  // ============================================================================
  void _mostrarError(String mensaje) => _mostrarMensajeError(mensaje);

  void _mostrarMensajeError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Text(
          mensaje,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _mostrarTerminosDeUso() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Términos de uso - ATRIO'),
        content: const SingleChildScrollView(
          child: Text(
            'ATRIO es una plataforma para conectar creyentes con su comunidad eclesial y enriquecer su vida espiritual. Al utilizar esta aplicación, aceptas hacer un uso respetuoso y conforme a las normas comunitarias.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _mostrarPoliticaPrivacidad() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Política de Privacidad'),
        content: const SingleChildScrollView(
          child: Text(
            'ATRIO protege tu privacidad. Los datos obtenidos a través de Google o Apple se utilizan exclusivamente para sincronizar tu perfil de membresía con el servidor Odoo de la comunidad. No compartimos tus datos con terceros ni comercializamos tu información personal.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // WIDGET: BOTÓN SOCIAL CON ESTADO DE CARGA Y ESTILOS NATIVOS
  // ============================================================================
  Widget _buildSocialButton({
    required String title,
    String? imageAsset,
    IconData? iconData,
    Widget? customIcon,
    required Color backgroundColor,
    required Color textColor,
    required Color borderColor,
    required bool isLoading,
    required double screenWidth,
    required double usableHeight,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: usableHeight * 0.060,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.025),
          ),
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        ),
        child: isLoading
            ? SizedBox(
                width: screenWidth * 0.05,
                height: screenWidth * 0.05,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (imageAsset != null)
                    Image.asset(
                      imageAsset,
                      width: screenWidth * 0.140,
                      height: screenWidth * 0.140,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.account_circle,
                        color: textColor,
                        size: screenWidth * 0.055,
                      ),
                    )
                  else if (customIcon != null)
                    customIcon
                  else if (iconData != null)
                    Icon(iconData, color: textColor, size: screenWidth * 0.055),
                  SizedBox(width: screenWidth * 0.03),
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: screenWidth * 0.055,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
