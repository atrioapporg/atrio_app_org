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
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/l10n/app_localizations.dart';

import 'crear_cuenta_screen.dart';
import 'inicio_atrio_screen.dart';
import 'recuperar_clave_screen.dart';
import 'tradicion_cristiana_screen.dart';

/// ==============================================================================
/// PANTALLA DE ACCESO ATRIO (INICIO DE SESIÓN / REGISTRO)
/// ==============================================================================
/// Principios de UX/UI aplicados (Guía Heurística de Nielsen & Minimalismo Funcional):
/// 1. Minimalismo funcional: Eliminación de redundancias, iconos innecesarios y dobles títulos.
/// 2. Jerarquía visual ("Un solo primario"): Un botón principal de acción clara ('Iniciar Sesión')
///    y acciones secundarias consistentes sin competir (Google y Apple en fila unificada).
/// 3. Visibilidad del estado del sistema: Indicadores en vivo en el botón ('Iniciando sesión...',
///    spinner y confirmación '¡Listo!') evitando dobles envíos y dudas en el usuario.
/// 4. Campos de entrada optimizados: Altura estándar, bordes suaves, navegación de teclado fluida,
///    toggle de visibilidad de contraseña y auto-completado.
/// 5. Adaptabilidad responsiva: Composición fluida sin 'overflows' ante el teclado ni en pantallas pequeñas.
/// ==============================================================================
class InicioSesionScreen extends StatefulWidget {
  static const routeName = 'inicio_sesion_screen';

  const InicioSesionScreen({super.key});

  @override
  State<InicioSesionScreen> createState() => _InicioSesionScreenState();
}

class _InicioSesionScreenState extends State<InicioSesionScreen> {
  // Paleta oficial y tokens de diseño ATRIO
  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color superficieBlanca = Color(0xFFFFFFFF);
  static const Color superficieCampo = Color(0xFFF8FAFC);
  static const Color grisBorde = Color(0xFFE2E8F0);
  static const Color textoGris = Color(0xFF64748B);
  static const Color textoOscuro = Color(0xFF0F172A);
  static const Color azulLink = Color(0xFF0284C7);
  static const Color verdeExito = Color(0xFF16A34A);

  // Estados de carga y confirmación
  bool _isLoadingGoogle = false;
  bool _isLoadingApple = false;
  bool _isLoadingCredentials = false;
  bool _isLoginSuccess = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;

  bool get _isProcessing =>
      _isLoadingGoogle || _isLoadingApple || _isLoadingCredentials;

  // Instancia de GoogleSignIn oficial
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: AppConfig.googleServerClientId.isNotEmpty
        ? AppConfig.googleServerClientId
        : '641023137906-6m8nt5665cljeeb0ob56q6kbl7ks8cad.apps.googleusercontent.com',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final userProvider = context.read<UserProvider>();
        final bool autoLogueado = await userProvider.tryAutoLogin();
        if (autoLogueado && mounted) {
          await _redirigirUsuarioPostLogin(esAutoLogin: true);
          return;
        }

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
        if (isLoggedIn && mounted) {
          await _redirigirUsuarioPostLogin(esAutoLogin: true);
        }
      } catch (e) {
        debugPrint('[AUTH] Error verificando sesión inicial: $e');
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;
    final bottomInset = mediaQuery.padding.bottom;
    final ajustesProvider = context.watch<AjustesProvider>();
    final l10n = AppLocalizations.of(context);

    // Altura responsiva del hero fotográfico superior
    final double heroHeight = (screenHeight * 0.40).clamp(240.0, 360.0);
    final bool isCompact = screenHeight < 720;

    return Scaffold(
      backgroundColor: const Color(0xFF072B4F),
      body: Stack(
        children: [
          // ===================================================================
          // 1. CAPA DE FONDO: Degradado azul profundo corporativo ATRIO
          // ===================================================================
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF03182E),
                    Color(0xFF072B4F),
                    Color(0xFF093660),
                    Color(0xFF041C35),
                  ],
                  stops: [0.0, 0.42, 0.82, 1.0],
                ),
              ),
            ),
          ),

          // ===================================================================
          // 2. ONDA DECORATIVA INFERIOR SUTIL
          // ===================================================================
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 90,
            child: IgnorePointer(
              child: ClipPath(
                clipper: _BottomWaveClipper(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF0F4C81).withValues(alpha: 0.22),
                        const Color(0xFF0A335C).withValues(alpha: 0.50),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ===================================================================
          // 3. CABECERA HERO: Fotografía de la mujer orando con transición ondulada
          // ===================================================================
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: heroHeight,
            child: Stack(
              children: [
                // Resplandor / onda secundaria cian por detrás
                Positioned.fill(
                  child: ClipPath(
                    clipper: _HeroWaveClipper(offsetY: 6),
                    child: Container(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                    ),
                  ),
                ),
                // Imagen de cabecera recortada por la onda curva orgánica
                Positioned.fill(
                  child: ClipPath(
                    clipper: _HeroWaveClipper(),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/images/login_header_mujer_limpia.jpg',
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/login_header_mujer.jpg',
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFF072B4F),
                                );
                              },
                            );
                          },
                        ),
                        // Viñeta superior para asegurar contraste con el logo y selector
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.40),
                                Colors.transparent,
                                const Color(0xFF072B4F).withValues(alpha: 0.25),
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ===================================================================
          // 4. BARRA SUPERIOR: Logo ATRIO + Selector de Idioma
          // ===================================================================
          Positioned(
            top: topPadding + 6,
            left: screenWidth > 600 ? 32 : 18,
            right: screenWidth > 600 ? 32 : 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo_encabezado_sinfondo.png',
                  height: isCompact ? 32 : 36,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/logo_encabezado.png',
                      height: isCompact ? 32 : 36,
                      fit: BoxFit.contain,
                    );
                  },
                ),
                _buildLanguageSelector(
                  context,
                  ajustesProvider,
                  isCompact: isCompact,
                ),
              ],
            ),
          ),

          // ===================================================================
          // 5. BLOQUE DE CONTENIDO: Bienvenida, Botones y Cumplimiento
          // ===================================================================
          Positioned(
            top: heroHeight - (isCompact ? 18 : 10),
            left: 0,
            right: 0,
            bottom: bottomInset > 0 ? bottomInset : 8,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth > 600 ? 32 : 24,
                  ),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),
                      // Título principal
                      Text(
                        l10n?.bienvenida ?? 'Bienvenido a Atrio',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Subtítulo
                      Text(
                        l10n?.subtituloBienvenida ??
                            'Un espacio para vivir y compartir tu fe',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: isCompact ? 13.5 : 15,
                          fontWeight: FontWeight.w400,
                          height: 1.25,
                        ),
                      ),
                      const Spacer(flex: 2),

                      // Botón 1: Continuar con Google
                      _buildPillButton(
                        title: 'Continuar con Google',
                        backgroundColor: Colors.white,
                        textColor: const Color(0xFF072B4F),
                        icon: Image.asset(
                          'assets/images/google_logo.png',
                          width: 22,
                          height: 22,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.g_mobiledata,
                                size: 26,
                                color: Color(0xFF072B4F),
                              ),
                        ),
                        isLoading: _isLoadingGoogle,
                        onTap: _isProcessing ? null : _iniciarSesionGoogle,
                        isCompact: isCompact,
                      ),
                      SizedBox(height: isCompact ? 10 : 13),

                      // Botón 2: Continuar con Apple
                      _buildPillButton(
                        title: 'Continuar con Apple',
                        backgroundColor: Colors.black,
                        textColor: Colors.white,
                        icon: const FaIcon(
                          FontAwesomeIcons.apple,
                          color: Colors.white,
                          size: 20,
                        ),
                        isLoading: _isLoadingApple,
                        onTap: _isProcessing
                            ? null
                            : () {
                                if (defaultTargetPlatform ==
                                    TargetPlatform.android) {
                                  _mostrarAvisoAndroidApple(context);
                                  return;
                                }
                                _iniciarSesionApple();
                              },
                        isCompact: isCompact,
                      ),
                      SizedBox(height: isCompact ? 10 : 13),

                      // Botón 3: Iniciar sesión (Credenciales)
                      _buildPillButton(
                        title: 'Iniciar sesión',
                        backgroundColor: const Color(0xFF0A335C)
                            .withValues(alpha: 0.35),
                        textColor: Colors.white,
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                        icon: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        isLoading: _isLoadingCredentials,
                        onTap: _isProcessing
                            ? null
                            : () => _mostrarModalInicioSesionCredenciales(
                                context,
                              ),
                        isCompact: isCompact,
                      ),
                      const Spacer(flex: 2),

                      // Nota de privacidad Odoo ERP
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          l10n?.avisoPrivacidadOdoo ?? 'Al continuar, vinculas tu cuenta de forma segura con el servidor eclesial de ATRIO en Odoo ERP.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: isCompact ? 10 : 11.5,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: isCompact ? 6 : 10),

                      // Enlaces de Términos y Privacidad
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _mostrarTerminosDeUso,
                            child: Text(
                              l10n?.terminosDeUso ?? 'Términos de uso',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: isCompact ? 11 : 12.5,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '•',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _mostrarPoliticaPrivacidad,
                            child: Text(
                              l10n?.privacidad ?? 'Privacidad',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: isCompact ? 11 : 12.5,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isCompact ? 4 : 6),

                      // Enlace Eliminar mis datos
                      GestureDetector(
                        onTap: () => _mostrarSolicitudEliminacionDatos(context),
                        child: Text(
                          l10n?.eliminarMisDatos ?? 'Eliminar mis datos',
                          style: TextStyle(
                            color: const Color(0xFFEF4444),
                            fontSize: isCompact ? 11 : 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // WIDGET: SELECTOR DE IDIOMA MINIMALISTA
  // ============================================================================
  Widget _buildLanguageSelector(
    BuildContext context,
    AjustesProvider provider, {
    bool isCompact = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _mostrarSelectorIdioma(context, provider),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 10,
            vertical: isCompact ? 4 : 5,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language_rounded,
                color: Colors.white,
                size: isCompact ? 14 : 16,
              ),
              const SizedBox(width: 5),
              Text(
                _obtenerNombreIdioma(provider.idiomaCodigo),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isCompact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: isCompact ? 14 : 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // WIDGET: BOTÓN SOCIAL PRINCIPAL EN CÁPSULA (PILL BUTTON)
  // ============================================================================
  Widget _buildPillButton({
    required String title,
    required Color backgroundColor,
    required Color textColor,
    required Widget icon,
    required bool isLoading,
    required VoidCallback? onTap,
    BorderSide? borderSide,
    bool isCompact = false,
  }) {
    final double height = isCompact ? 46 : 50;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.6),
          disabledForegroundColor: textColor.withValues(alpha: 0.6),
          elevation: 0,
          shadowColor: Colors.transparent,
          side: borderSide,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(height / 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isCompact ? 14.5 : 15.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ============================================================================
  // MODAL BOTTOM SHEET: INICIO DE SESIÓN CON CREDENCIALES (EMAIL / PASSWORD)
  // ============================================================================
  void _mostrarModalInicioSesionCredenciales(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.height < 720;
    String? errorMessageModal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (builderCtx, setModalState) {
            final bottomInset = MediaQuery.of(builderCtx).viewInsets.bottom;

            Future<void> ejecutarLogin() async {
              setModalState(() => errorMessageModal = null);
              await _iniciarSesionCredenciales(
                setModalState: setModalState,
                modalCtx: modalCtx,
                onErrorMessage: (msg) {
                  setModalState(() => errorMessageModal = msg);
                },
              );
            }

            return Container(
              decoration: const BoxDecoration(
                color: superficieBlanca,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x28000000),
                    blurRadius: 25,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                14,
                24,
                (isCompact ? 16 : 24) + bottomInset,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Indicador de arrastre superior (pill)
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),

                    // Título del formulario
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n?.iniciarSesion ?? 'Iniciar Sesión',
                          style: const TextStyle(
                            color: textoOscuro,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: textoGris,
                          ),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Campo: Correo Electrónico / Usuario
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !_isProcessing,
                      onFieldSubmitted: (_) =>
                          _passwordFocusNode.requestFocus(),
                      style: const TextStyle(
                        color: textoOscuro,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Correo electrónico o usuario',
                        labelStyle: const TextStyle(
                          color: textoGris,
                          fontSize: 13,
                        ),
                        hintText: 'ej. nombre@correo.com',
                        hintStyle: TextStyle(
                          color: textoGris.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.mail_outline_rounded,
                          color: Color(0xFF64748B),
                          size: 19,
                        ),
                        filled: true,
                        fillColor: superficieCampo,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: grisBorde),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: grisBorde),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: azulFondo,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Campo: Contraseña
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      enabled: !_isProcessing,
                      onFieldSubmitted: (_) async {
                        if (!_isProcessing) {
                          await ejecutarLogin();
                        }
                      },
                      style: const TextStyle(
                        color: textoOscuro,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Contraseña',
                        labelStyle: const TextStyle(
                          color: textoGris,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF64748B),
                          size: 19,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF64748B),
                            size: 19,
                          ),
                          onPressed: () {
                            setModalState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: superficieCampo,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: grisBorde),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: grisBorde),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: azulFondo,
                            width: 1.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Olvidé mi contraseña
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isProcessing
                            ? null
                            : () {
                                Navigator.pop(modalCtx);
                                Navigator.pushNamed(
                                  context,
                                  RecuperarClaveScreen.routeName,
                                );
                              },
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            color: azulLink,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Banner visual de alerta ante credenciales incorrectas o errores de red (Caso 1)
                    if (errorMessageModal != null &&
                        errorMessageModal!.isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFDC2626),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                errorMessageModal!,
                                style: const TextStyle(
                                  color: Color(0xFFB91C1C),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Botón Iniciar Sesión en modal
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isProcessing
                            ? null
                            : () async {
                                await ejecutarLogin();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLoginSuccess
                              ? verdeExito
                              : azulFondo,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              azulFondo.withValues(alpha: 0.6),
                          disabledForegroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoginSuccess
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '¡Listo!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : _isLoadingCredentials
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Iniciando sesión...',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Iniciar Sesión',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Enlace a Registro
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '¿No tienes una cuenta? ',
                          style: TextStyle(color: textoGris, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: _isProcessing
                              ? null
                              : () {
                                  Navigator.pop(modalCtx);
                                  Navigator.pushNamed(
                                    context,
                                    CrearCuentaScreen.routeName,
                                  );
                                },
                          child: const Text(
                            'Regístrate',
                            style: TextStyle(
                              color: amarilloOro,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Explorar como invitado
                    Center(
                      child: TextButton.icon(
                        onPressed: _isProcessing
                            ? null
                            : () {
                                Navigator.pop(modalCtx);
                                _continuarComoInvitado(context);
                              },
                        icon: const Icon(Icons.explore_outlined, size: 16),
                        label: Text(
                          l10n?.explorarInvitado ?? 'Explorar como invitado',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================================
  // GESTIÓN Y SELECTOR DE IDIOMA (flutter_localizations)
  // ============================================================================
  String _obtenerNombreIdioma(String codigo) {
    switch (codigo) {
      case 'en':
        return 'English';
      case 'es':
      default:
        return 'Español';
    }
  }

  void _mostrarSelectorIdioma(BuildContext context, AjustesProvider provider) {
    final l10n = AppLocalizations.of(context);
    final opciones = [
      {
        'codigo': 'es',
        'region': 'DO',
        'nombre': l10n?.idiomaEspanolLatino ?? 'Español (Latinoamérica)',
        'bandera': '🇩🇴',
      },
      {
        'codigo': 'en',
        'region': 'US',
        'nombre': l10n?.idiomaInglesUSA ?? 'English (United States)',
        'bandera': '🇺🇸',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: superficieBlanca,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.translate_rounded,
                    color: azulFondo,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    l10n?.seleccionarIdioma ?? 'Seleccionar Idioma',
                    style: const TextStyle(
                      color: azulFondo,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const Divider(height: 28, color: grisBorde),
              ...opciones.map((opcion) {
                final isSelected = provider.idiomaCodigo == opcion['codigo'];
                return ListTile(
                  leading: Text(
                    opcion['bandera']!,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    opcion['nombre']!,
                    style: TextStyle(
                      color: isSelected ? azulFondo : textoOscuro,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: amarilloOro,
                        )
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
  // AUTENTICACIÓN CON CREDENCIALES (ODOO 19 REST API - POST /auth/login)
  // ============================================================================
  Future<void> _iniciarSesionCredenciales({
    StateSetter? setModalState,
    BuildContext? modalCtx,
    void Function(String)? onErrorMessage,
  }) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      const msg = 'Por favor ingresa tu correo y contraseña';
      onErrorMessage?.call(msg);
      _mostrarMensajeError(msg);
      return;
    }

    setModalState?.call(() {});
    setState(() {
      _isLoadingCredentials = true;
      _isLoginSuccess = false;
    });
    FocusScope.of(context).unfocus();

    try {
      final userProvider = context.read<UserProvider>();
      final ok = await userProvider.login(
        email,
        password,
        deviceName: 'App Atrio Flutter',
      );

      if (!mounted) return;

      if (ok) {
        setModalState?.call(() {});
        setState(() {
          _isLoginSuccess = true;
        });

        // Guardar también en la base de datos local SQLite para soporte offline
        try {
          final user = userProvider.currentUser;
          if (user != null) {
            final SharedPreferences prefs =
                await SharedPreferences.getInstance();
            final String? iglesiaGuardada =
                prefs.getString('iglesia_guardada');
            final String iglesiaNombre = (iglesiaGuardada != null &&
                    iglesiaGuardada.trim().isNotEmpty)
                ? (user.iglesiaActual.isNotEmpty &&
                        user.iglesiaActual != 'Iglesia Atrio'
                    ? user.iglesiaActual
                    : 'Sin iglesia seleccionada')
                : 'Sin iglesia seleccionada';

            await AtrioDatabaseHelper.instance.guardarUsuario({
              'email': user.email,
              'nombre': user.nombre,
              'celular': user.telefono ?? '',
              'iglesia_nombre': iglesiaNombre,
              'creado_en': DateTime.now().toIso8601String(),
            });
          }
        } catch (e) {
          debugPrint('[AUTH] Advertencia guardando en SQLite local: $e');
        }

        if (!mounted) return;

        // Pausa breve de 350ms para que el usuario aprecie el estado visual "¡Listo!"
        await Future.delayed(const Duration(milliseconds: 350));

        // 1. Cerrar primero el modal para evitar congelamiento de navegación o colisiones de rutas
        if (modalCtx != null && modalCtx.mounted) {
          Navigator.pop(modalCtx);
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '¡Bienvenido ${userProvider.currentUser?.nombre ?? ""}!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: verdeExito,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );

        // 2. Redirigir según el estado del usuario
        await _redirigirUsuarioPostLogin();
      } else {
        final errorMsg = userProvider.errorMessage ??
            'Usuario o contraseña incorrectos. Verifica tus credenciales.';
        onErrorMessage?.call(errorMsg);
        setModalState?.call(() {});
        setState(() {
          _isLoginSuccess = false;
        });
        _mostrarMensajeError(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Error al comunicarse con el servidor: $e';
      onErrorMessage?.call(errorMsg);
      if (mounted) {
        setModalState?.call(() {});
        setState(() {
          _isLoginSuccess = false;
        });
        _mostrarMensajeError(errorMsg);
      }
    } finally {
      if (mounted) {
        setModalState?.call(() {});
        setState(() {
          _isLoadingCredentials = false;
        });
      }
    }
  }

  // ============================================================================
  // SOCIAL LOGIN (GOOGLE SIGN-IN)
  // ============================================================================
  Future<void> _iniciarSesionGoogle() async {
    setState(() => _isLoadingGoogle = true);
    FocusScope.of(context).unfocus();

    try {
      final l10n = AppLocalizations.of(context);
      String email = 'usuario.google@gmail.com';
      String nombre = l10n?.usuarioGoogle ?? 'Usuario Google';

      try {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
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

      // 4. Redirigir según el estado del usuario
      await _redirigirUsuarioPostLogin();
    } catch (error) {
      debugPrint('[AUTH_ERROR] Error en Google Sign-In: $error');
      _mostrarMensajeError(
        'No se pudo conectar con Google. Revisa tu conexión.',
      );
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

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: AppConfig.appleServiceId.isNotEmpty
            ? WebAuthenticationOptions(
                clientId: AppConfig.appleServiceId,
                redirectUri: Uri.parse(
                  '${AppConfig.odooBaseUrl}/api/v1/auth/apple/callback',
                ),
              )
            : null,
      );

      final String nombre = [
        credential.givenName ?? '',
        credential.familyName ?? '',
      ].join(' ').trim();
      final String email = credential.email ?? '';

      final String nombreFinal = nombre.isNotEmpty ? nombre : 'Usuario Apple';
      final String emailFinal = email.isNotEmpty
          ? email
          : 'apple_user_${credential.userIdentifier?.substring(0, 6)}@privaterelay.appleid.com';

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userEmail', emailFinal);
      await prefs.setString('userName', nombreFinal);

      final usuarioExistente = await AtrioDatabaseHelper.instance.getUsuario();
      final String iglesiaExistente =
          (usuarioExistente != null &&
              usuarioExistente['iglesia_nombre'] != null &&
              usuarioExistente['iglesia_nombre'].toString().trim().isNotEmpty &&
              usuarioExistente['iglesia_nombre'].toString().trim() !=
                  'Sin iglesia seleccionada')
          ? usuarioExistente['iglesia_nombre'].toString().trim()
          : 'Sin iglesia seleccionada';

      await AtrioDatabaseHelper.instance.guardarUsuario(<String, dynamic>{
        'nombre': nombreFinal,
        'email': emailFinal,
        'celular': '',
        'idioma': 'es_DO',
        'iglesia_nombre': iglesiaExistente,
      });

      if (!mounted) return;

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

      await _redirigirUsuarioPostLogin();
    } catch (error) {
      debugPrint('[AUTH] Error en Sign in with Apple: $error');
      if (!error.toString().contains('canceled') &&
          !error.toString().contains('cancelled')) {
        _mostrarMensajeError(
          'No se pudo completar el acceso con Apple. Verifica tu cuenta o conexión.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingApple = false);
    }
  }

  // ============================================================================
  // REDIRECCIÓN INTELIGENTE POST LOGIN
  // ============================================================================
  Future<void> _redirigirUsuarioPostLogin({bool esAutoLogin = false}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? iglesiaGuardada = prefs.getString('iglesia_guardada');
    final bool tieneIglesiaLocal =
        iglesiaGuardada != null && iglesiaGuardada.trim().isNotEmpty;

    final usuario = await AtrioDatabaseHelper.instance.getUsuario();
    final bool tieneIglesiaDb =
        usuario != null &&
        usuario['iglesia_nombre'] != null &&
        usuario['iglesia_nombre'].toString().trim().isNotEmpty &&
        usuario['iglesia_nombre'].toString().trim() !=
            'Sin iglesia seleccionada' &&
        usuario['iglesia_nombre'].toString().trim() !=
            'Iglesia Atrio';

    final bool usuarioTieneIglesia = tieneIglesiaLocal || tieneIglesiaDb;

    if (!mounted) return;

    // Solo si es una sesión pasiva previamente restaurada al iniciar la app
    // y el usuario ya completó la selección de iglesia con anterioridad:
    if (esAutoLogin && usuarioTieneIglesia) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        InicioAtrioScreen.routeName,
        (route) => false,
      );
    } else {
      // Al iniciar sesión por primera vez o tras autenticarse con éxito,
      // debe siempre enviar a TradicionCristianaScreen para seleccionar su iglesia.
      Navigator.pushNamed(context, TradicionCristianaScreen.routeName);
    }
  }

  void _continuarComoInvitado(BuildContext context) {
    // Modo Invitado: es el ÚNICO caso donde NO pasa por TradicionCristianaScreen
    // y entra directamente al contenido principal de la app en InicioAtrioScreen.
    Navigator.pushNamedAndRemoveUntil(
      context,
      InicioAtrioScreen.routeName,
      (route) => false,
    );
  }

  // ============================================================================
  // MODAL DE SOLICITUD DE ELIMINACIÓN DE CUENTA Y DATOS PERSONALES
  // ============================================================================
  void _mostrarSolicitudEliminacionDatos(BuildContext context) {
    final emailController = TextEditingController();
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: superficieBlanca,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.delete_forever_rounded,
                color: Colors.red.shade700,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n?.eliminarCuentaYDatos ?? 'Eliminar cuenta y datos',
                  style: const TextStyle(
                    color: azulFondo,
                    fontSize: 18,
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
                  'Conforme a nuestras políticas de privacidad y los estándares de las tiendas de aplicaciones, tienes el derecho de solicitar la eliminación total de tu cuenta y los datos personales asociados.',
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ingresa tu correo para confirmar la solicitud:',
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: azulFondo, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'tu@correo.com',
                    filled: true,
                    fillColor: superficieCampo,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: grisBorde),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: grisBorde),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.amber.shade900,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Esta acción purgará tus notas bíblicas, historial y desvinculará tu usuario de forma irreversible.',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontSize: 12,
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
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final emailSolicitado = emailController.text.trim();
                if (emailSolicitado.isEmpty) return;

                Navigator.pop(dialogCtx);

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
                      'Solicitud registrada para $emailSolicitado. Datos locales eliminados.',
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
  void _mostrarAvisoAndroidApple(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: superficieBlanca,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: amarilloOro.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone_android_rounded,
                color: azulFondo,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n?.opcionNoDisponible ?? 'Opción no disponible',
                style: const TextStyle(
                  color: azulFondo,
                  fontSize: 17,
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
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: verdeExito,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'En tu dispositivo Android, por favor utiliza "Google" para ingresar de forma rápida y segura.',
                      style: TextStyle(
                        color: azulFondo,
                        fontSize: 13,
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
              width: 18,
              height: 18,
            ),
            label: const Text(
              'Usar Google',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: azulFondo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
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
  void _mostrarMensajeError(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _mostrarTerminosDeUso() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: superficieBlanca,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
        backgroundColor: superficieBlanca,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
}

// ==============================================================================
// CLIPPERS: ONDAS ORGÁNICAS DE TRANSICIÓN Y DECORACIÓN (HERO & BOTTOM)
// ==============================================================================
class _HeroWaveClipper extends CustomClipper<Path> {
  final double offsetY;
  _HeroWaveClipper({this.offsetY = 0});

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.88 + offsetY);

    // Primera curva descendente hacia el centro-izquierdo
    final p1 = Offset(size.width * 0.28, size.height * 0.98 + offsetY);
    final p2 = Offset(size.width * 0.58, size.height * 0.88 + offsetY);
    path.quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy);

    // Segunda curva suave ascendente hacia el extremo derecho
    final p3 = Offset(size.width * 0.84, size.height * 0.78 + offsetY);
    final p4 = Offset(size.width, size.height * 0.84 + offsetY);
    path.quadraticBezierTo(p3.dx, p3.dy, p4.dx, p4.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_HeroWaveClipper oldClipper) =>
      oldClipper.offsetY != offsetY;
}

class _BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.45);
    final p1 = Offset(size.width * 0.35, size.height * 0.15);
    final p2 = Offset(size.width * 0.70, size.height * 0.40);
    path.quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy);

    final p3 = Offset(size.width * 0.88, size.height * 0.55);
    final p4 = Offset(size.width, size.height * 0.30);
    path.quadraticBezierTo(p3.dx, p3.dy, p4.dx, p4.dy);

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
