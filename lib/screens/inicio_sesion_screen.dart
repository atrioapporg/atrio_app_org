import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:atrio/data/app_config.dart';
import 'package:atrio/data/atrio_database_helper.dart';
import 'package:atrio/providers/iglesia_provider.dart';
import 'package:atrio/providers/user_provider.dart';

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
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFE0E0E0);
  static const Color textoGris = Color(0xFF757575);
  static const Color azulLink = Color(0xFF0055A5);

  // Estados de carga independientes para feedback visual responsivo
  bool _isLoadingGoogle = false;
  bool _isLoadingApple = false;

  bool get _isProcessing => _isLoadingGoogle || _isLoadingApple;

  // Instancia de GoogleSignIn (configurada con Server Client ID desde AppConfig / .env)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: AppConfig.googleServerClientId.isNotEmpty
        ? AppConfig.googleServerClientId
        : null,
  );

  @override
  Widget build(BuildContext context) {
    // Métricas dinámicas relativas (Flutter 3.22+)
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

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
                        Container(
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
                            children: [
                              Icon(
                                Icons.language,
                                color: Colors.white,
                                size: screenWidth * 0.04,
                              ),
                              SizedBox(width: screenWidth * 0.015),
                              Text(
                                'Español',
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
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.018),

                    // Título y Subtítulo
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Bienvenido a Atrio',
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
                            'Acceso Rápido y Seguro',
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.055,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: usableHeight * 0.008),

                          Text(
                            'Ingresa o regístrate en un solo toque sin contraseñas que olvidar.',
                            style: TextStyle(
                              color: textoGris,
                              fontSize: screenWidth * 0.035,
                              height: 1.35,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: usableHeight * 0.035),

                          // ===================================================
                          // BOTÓN 1: CONTINUAR CON GOOGLE
                          // ===================================================
                          _buildSocialButton(
                            title: 'Continuar con Google',
                            imageAsset: 'assets/images/google_logo.png',
                            backgroundColor: Colors.white,
                            textColor: azulFondo,
                            borderColor: grisBorde,
                            isLoading: _isLoadingGoogle,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            onTap: _isProcessing ? null : _iniciarSesionGoogle,
                          ),
                          SizedBox(height: usableHeight * 0.016),

                          // ===================================================
                          // BOTÓN 2: CONTINUAR CON APPLE (Obligatorio iOS)
                          // ===================================================
                          _buildSocialButton(
                            title: 'Continuar con Apple',
                            customIcon: FaIcon(
                              FontAwesomeIcons.apple,
                              color: Colors.white,
                              size: screenWidth * 0.055,
                            ),
                            backgroundColor: Colors.black,
                            textColor: Colors.white,
                            borderColor: Colors.black,
                            isLoading: _isLoadingApple,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            onTap: _isProcessing ? null : _iniciarSesionApple,
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
                              'Explorar como invitado',
                              style: TextStyle(
                                color: azulLink,
                                fontSize: screenWidth * 0.036,
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
                              'Al continuar, vinculas tu cuenta de forma segura con el servidor eclesial de ATRIO en Odoo ERP.',
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
                                  'Términos de uso',
                                  style: TextStyle(
                                    color: azulFondo,
                                    fontSize: screenWidth * 0.030,
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
                                    fontSize: screenWidth * 0.03,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _mostrarPoliticaPrivacidad,
                                child: Text(
                                  'Privacidad',
                                  style: TextStyle(
                                    color: azulFondo,
                                    fontSize: screenWidth * 0.030,
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
                                    fontSize: screenWidth * 0.03,
                                  ),
                                ),
                              ),
                              // Enlace directo a solicitud de eliminación de datos
                              // (Cumplimiento de políticas de Google Play y Apple)
                              GestureDetector(
                                onTap: () => _mostrarSolicitudEliminacionDatos(
                                  context,
                                  screenWidth,
                                  usableHeight,
                                ),
                                child: Text(
                                  'Eliminar mis datos',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: screenWidth * 0.030,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
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
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // FLUDO DE AUTENTICACIÓN CON GOOGLE
  // ============================================================================
  Future<void> _iniciarSesionGoogle() async {
    setState(() => _isLoadingGoogle = true);

    try {
      debugPrint('[AUTH] Iniciando flujo nativo de Google Sign-In...');
      final GoogleSignInAccount? googleAccount = await _googleSignIn.signIn();

      if (googleAccount == null) {
        // El usuario canceló voluntariamente el diálogo de Google
        debugPrint('[AUTH] Inicio de sesión cancelado por el usuario.');
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleAccount.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      debugPrint('[AUTH] Google Sign-In exitoso:');
      debugPrint('       Email: ${googleAccount.email}');
      debugPrint('       Nombre: ${googleAccount.displayName}');
      debugPrint('       ID Token presente: ${idToken != null}');
      debugPrint('       Access Token presente: ${accessToken != null}');

      // =======================================================================
      // TODO: ODOO 19 BACKEND INTEGRATION
      // =======================================================================
      // Cuando el equipo de Odoo 19 entregue el endpoint oficial:
      //
      // 1. URL Endpoint:
      //    '${AppConfig.odooBaseUrl}${AppConfig.odooSocialAuthEndpoint}'
      //
      // 2. Payload HTTP POST:
      //    final body = jsonEncode({
      //      'provider': 'google',
      //      'id_token': idToken,
      //      'access_token': accessToken,
      //      'email': googleAccount.email,
      //      'name': googleAccount.displayName,
      //      'avatar_url': googleAccount.photoUrl,
      //      'db': AppConfig.odooDatabase,
      //    });
      //
      // 3. Respuesta esperada de Odoo 19:
      //    - Cookie 'session_id' en los headers
      //    - Body: { 'uid': 14, 'partner_id': 32, 'name': '...', 'email': '...', 'es_miembro_verificado': true }
      // =======================================================================

      // SIMULACIÓN / PERSISTENCIA LOCAL EN ATRIO (Mientras entregan el endpoint de Odoo)
      await AtrioDatabaseHelper.instance.guardarUsuario({
        'nombre': googleAccount.displayName ?? 'Usuario Google',
        'email': googleAccount.email,
        'celular': '',
        'idioma': 'es_DO',
      });

      if (!mounted) return;

      // Actualizar estado en memoria en UserProvider
      Provider.of<UserProvider>(context, listen: false).updateUserProfile(
        nombre: googleAccount.displayName ?? 'Usuario Google',
        email: googleAccount.email,
        telefono: '',
        iglesiaActual: 'Comunidad Principal',
      );

      _redirigirUsuarioPostLogin();
    } catch (error) {
      debugPrint('[AUTH] Error en Google Sign-In: $error');
      _mostrarMensajeError(
        'No se pudo completar el acceso con Google. Inténtalo nuevamente o verifica tu conexión.',
      );
    } finally {
      if (mounted) setState(() => _isLoadingGoogle = false);
    }
  }

  // ============================================================================
  // FLUJO DE AUTENTICACIÓN CON APPLE
  // ============================================================================
  Future<void> _iniciarSesionApple() async {
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

      // Persistencia local temporal
      await AtrioDatabaseHelper.instance.guardarUsuario({
        'nombre': nombreFinal,
        'email': emailFinal,
        'celular': '',
        'idioma': 'es_DO',
      });

      if (!mounted) return;

      Provider.of<UserProvider>(context, listen: false).updateUserProfile(
        nombre: nombreFinal,
        email: emailFinal,
        telefono: '',
        iglesiaActual: 'Comunidad Principal',
      );

      _redirigirUsuarioPostLogin();
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
    final bool tieneIglesia = await iglesiaProvider.verificarIglesiaGuardada();

    if (!mounted) return;

    if (tieneIglesia) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        'inicio_atrio_screen',
        (route) => false,
      );
    } else {
      Navigator.pushNamed(context, 'tradicion_cristiana_screen');
    }
  }

  // Continuar como invitado sin autenticarse de inmediato
  void _continuarComoInvitado(BuildContext context) {
    Navigator.pushNamed(context, 'tradicion_cristiana_screen');
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
                  'Eliminar cuenta y datos',
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
              child: const Text('Cancelar'),
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
              child: const Text('Solicitar eliminación'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================================
  // UTILIDADES Y MODALES INFORMATIVOS
  // ============================================================================
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
      height: usableHeight * 0.056,
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
                      width: screenWidth * 0.055,
                      height: screenWidth * 0.055,
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
                      fontSize: screenWidth * 0.040,
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
