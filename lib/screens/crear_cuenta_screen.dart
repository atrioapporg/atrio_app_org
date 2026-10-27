import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../atrio_api.dart';
import '../l10n/app_localizations.dart';
import '../modelos/user_model.dart';
import '../providers/ajustes_provider.dart';
import '../providers/iglesia_provider.dart';
import '../providers/user_provider.dart';
import 'elegir_camino_iglesia_screen.dart';
import 'iglesia_pendiente_activacion_screen.dart';
import 'inicio_atrio_screen.dart';
import 'inicio_sesion_screen.dart';
import 'terminos_privacidad_screen.dart';

class CrearCuentaScreen extends StatefulWidget {
  static const routeName = 'crear_cuenta_screen';
  const CrearCuentaScreen({super.key});

  @override
  State<CrearCuentaScreen> createState() => _CrearCuentaScreenState();
}

class _CrearCuentaScreenState extends State<CrearCuentaScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _mostrarSelectorIdioma(
    BuildContext context,
    AjustesProvider provider,
    double screenWidth,
  ) {
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
                  Icon(
                    Icons.language_rounded,
                    color: const Color(0xFF072B4F),
                    size: screenWidth * 0.06,
                  ),
                  SizedBox(width: screenWidth * 0.025),
                  Text(
                    l10n?.seleccionarIdioma ?? 'Seleccionar idioma',
                    style: TextStyle(
                      fontSize: screenWidth * 0.044,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF072B4F),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.03),
              ...opciones.map((op) {
                final esSeleccionado =
                    provider.locale.languageCode == op['codigo'];
                return ListTile(
                  leading: Text(
                    op['bandera']!,
                    style: TextStyle(fontSize: screenWidth * 0.06),
                  ),
                  title: Text(
                    op['nombre']!,
                    style: TextStyle(
                      fontSize: screenWidth * 0.038,
                      fontWeight: esSeleccionado
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: esSeleccionado
                          ? const Color(0xFF072B4F)
                          : Colors.black87,
                    ),
                  ),
                  trailing: esSeleccionado
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: const Color(0xFFE5A023),
                          size: screenWidth * 0.055,
                        )
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  tileColor: esSeleccionado
                      ? const Color(0xFF072B4F).withValues(alpha: 0.06)
                      : null,
                  onTap: () {
                    provider.cambiarIdioma(
                      op['codigo']!,
                      region: op['region'],
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

  Future<void> _ejecutarRegistro() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final nombre = _nombreController.text.trim();
    final correo = _correoController.text.trim();
    final telefono = _telefonoController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // 1. Validaciones
    if (nombre.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n?.errorNombreRequerido ?? 'Por favor ingresa tu nombre completo.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (correo.isEmpty || !emailRegExp.hasMatch(correo)) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n?.errorCorreoValido ?? 'Ingresa un correo electrónico válido.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (telefono.isEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n?.errorTelefonoRequerido ??
                'Por favor ingresa tu número de teléfono.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (password.length < 8) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n?.errorContrasenaMinima ??
                'La contraseña debe tener al menos 8 caracteres.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n?.errorContrasenasNoCoinciden ??
                'Las contraseñas no coinciden.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    if (!_acceptTerms) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n?.errorAceptarTerminos ??
                'Debes aceptar los Términos de uso y la Política de privacidad.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    // 2. Determinar iglesia vinculada (argumentos de ruta opcionales o provider)
    int? churchId;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is int && args > 0) {
      churchId = args;
    } else if (args is Map && args['church_id'] != null) {
      churchId = int.tryParse(args['church_id'].toString());
    }
    if (churchId == null || churchId <= 0) {
      final iglesiaProvider = context.read<IglesiaProvider>();
      churchId = iglesiaProvider.iglesiaActual?.id;
    }

    setState(() => _isLoading = true);

    try {
      final userProvider = context.read<UserProvider>();
      final payload = <String, dynamic>{
        'name': nombre,
        'email': correo,
        'phone': telefono,
        'password': password,
      };
      if (churchId != null && churchId > 0) {
        payload['church_id'] = churchId;
      }

      final res = await userProvider.api.registerMember(payload);

      if (!mounted) return;

      final success = res['success'] == true;
      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF2E7D32),
              size: 56,
            ),
            title: Text(
              l10n?.registroExitosoTitulo ?? '¡Cuenta Registrada!',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              churchId != null && churchId > 0
                  ? (l10n?.registroExitosoMensaje ??
                      'Tu cuenta ha sido creada exitosamente. Tu solicitud de membresía está en revisión por la congregación.')
                  : 'Tu cuenta ha sido creada exitosamente. Elige el camino de tu iglesia para comenzar.',
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF072B4F),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  // Iniciar sesión automáticamente
                  final loginOk =
                      await userProvider.login(correo, password);
                  if (!mounted) return;
                  if (loginOk) {
                    if (userProvider.hasSelectedOrLinkedChurch) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        InicioAtrioScreen.routeName,
                        (route) => false,
                      );
                      return;
                    }
                    final stage = userProvider.currentStage;
                    switch (stage) {
                      case AppStage.chooseChurch:
                        userProvider.verificarIglesiaPrevia().then((tienePrevia) {
                          if (!mounted) return;
                          if (tienePrevia) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              InicioAtrioScreen.routeName,
                              (route) => false,
                            );
                          } else {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              ElegirCaminoIglesiaScreen.routeName,
                              (route) => false,
                            );
                          }
                        });
                        break;
                      case AppStage.waitingApproval:
                        // Redirigir de inmediato al HomeScreen
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          InicioAtrioScreen.routeName,
                          (route) => false,
                        );
                        break;
                      case AppStage.churchPendingActivation:
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          IglesiaPendienteActivacionScreen.routeName,
                          (route) => false,
                        );
                        break;
                      case AppStage.welcome:
                      case AppStage.memberHome:
                      case AppStage.adminHome:
                      case AppStage.platformAdmin:
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          InicioAtrioScreen.routeName,
                          (route) => false,
                        );
                        break;
                    }
                  } else {
                    Navigator.pushReplacementNamed(
                      context,
                      InicioSesionScreen.routeName,
                    );
                  }
                },
                child: Text(
                  l10n?.iniciarSesionAhora ?? 'Iniciar sesión ahora',
                ),
              ),
            ],
          ),
        );
      }
    } on AtrioApiException catch (e) {
      if (!mounted) return;
      String errorMsg = e.message;
      if (e.code == 'email_taken') {
        errorMsg =
            'Ese correo ya tiene una cuenta registrada. Inicia sesión o recupera tu contraseña.';
      } else if (e.code == 'weak_password') {
        errorMsg = 'La contraseña debe tener un mínimo de 8 caracteres.';
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n?.errorConexionInternet ??
                'Error de conexión. Verifica tu internet.',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ajustesProvider = context.watch<AjustesProvider>();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);
    const Color grisBorde = Color(0xFFE5E5E5);

    final langCode =
        ajustesProvider.locale.languageCode.toUpperCase();

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: true,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight,
          child: Column(
            children: [
              // 2. Encabezado Superior (Botón Volver + Título + Selector de Idioma)
              Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: usableHeight * 0.015,
                ),
                child: Row(
                  children: [
                    // Botón Volver estilizado
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white,
                          size: screenWidth * 0.07,
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    // Título en el encabezado
                    Expanded(
                      child: Text(
                        l10n?.registroTitulo ?? 'Registro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.058,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    // Selector de Idioma estilizado
                    GestureDetector(
                      onTap: () => _mostrarSelectorIdioma(
                        context,
                        ajustesProvider,
                        screenWidth,
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.028,
                          vertical: usableHeight * 0.007,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.04),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.language_rounded,
                              color: Colors.white,
                              size: screenWidth * 0.042,
                            ),
                            SizedBox(width: screenWidth * 0.015),
                            Text(
                              langCode,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.032,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white70,
                              size: screenWidth * 0.04,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Contenedor Blanco Inferior con Formulario
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
                        horizontal: screenWidth * 0.055,
                        vertical: usableHeight * 0.025,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título y Subtítulo
                          Text(
                            l10n?.creaTuCuenta ?? 'Crea tu cuenta',
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.068,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.004),
                          Text(
                            l10n?.creaTuCuentaSubtitulo ??
                                'Únete a una comunidad para vivir y compartir tu fe.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: screenWidth * 0.034,
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.02),

                          // 1. Campo Nombre completo
                          _buildFieldLabel(
                            l10n?.nombreCompleto ?? 'Nombre completo',
                            screenWidth,
                            azulFondo,
                          ),
                          SizedBox(height: usableHeight * 0.006),
                          _buildInputField(
                            controller: _nombreController,
                            hintText: l10n?.escribeTuNombre ??
                                'Escribe tu nombre',
                            prefixIcon: Icons.person_outline_rounded,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            grisBorde: grisBorde,
                            azulFondo: azulFondo,
                          ),
                          SizedBox(height: usableHeight * 0.015),

                          // 2. Campo Correo electrónico
                          _buildFieldLabel(
                            l10n?.correoElectronico ?? 'Correo electrónico',
                            screenWidth,
                            azulFondo,
                          ),
                          SizedBox(height: usableHeight * 0.006),
                          _buildInputField(
                            controller: _correoController,
                            hintText: 'tu@correo.com',
                            prefixIcon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            grisBorde: grisBorde,
                            azulFondo: azulFondo,
                          ),
                          SizedBox(height: usableHeight * 0.015),

                          // 3. Campo Número de teléfono
                          _buildFieldLabel(
                            l10n?.numeroTelefonoLabel ?? 'Número de teléfono',
                            screenWidth,
                            azulFondo,
                          ),
                          SizedBox(height: usableHeight * 0.006),
                          _buildInputField(
                            controller: _telefonoController,
                            hintText: '(809) 000-0000',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            grisBorde: grisBorde,
                            azulFondo: azulFondo,
                          ),
                          SizedBox(height: usableHeight * 0.015),

                          // 4. Campo Contraseña
                          _buildFieldLabel(
                            l10n?.contrasenaLabel ?? 'Contraseña',
                            screenWidth,
                            azulFondo,
                          ),
                          SizedBox(height: usableHeight * 0.006),
                          _buildInputField(
                            controller: _passwordController,
                            hintText: '••••••••••',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                            obscureText: _obscurePassword,
                            onToggleVisibility: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            grisBorde: grisBorde,
                            azulFondo: azulFondo,
                          ),
                          SizedBox(height: usableHeight * 0.015),

                          // 5. Campo Confirmar contraseña
                          _buildFieldLabel(
                            l10n?.confirmarContrasenaLabel ??
                                'Confirmar contraseña',
                            screenWidth,
                            azulFondo,
                          ),
                          SizedBox(height: usableHeight * 0.006),
                          _buildInputField(
                            controller: _confirmPasswordController,
                            hintText: '••••••••••',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                            obscureText: _obscureConfirmPassword,
                            onToggleVisibility: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            grisBorde: grisBorde,
                            azulFondo: azulFondo,
                          ),
                          SizedBox(height: usableHeight * 0.015),

                          // 6. Checkbox Términos y Políticas
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: screenWidth * 0.06,
                                height: screenWidth * 0.06,
                                child: Checkbox(
                                  value: _acceptTerms,
                                  activeColor: azulFondo,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      screenWidth * 0.01,
                                    ),
                                  ),
                                  side: BorderSide(
                                    color: Colors.grey.shade400,
                                    width: 1.5,
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      _acceptTerms = val ?? false;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.025),
                              Expanded(
                                child: Wrap(
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      l10n?.aceptoLos ?? 'Acepto los ',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: screenWidth * 0.03,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          TerminosPrivacidadScreen.routeName,
                                        );
                                      },
                                      child: Text(
                                        l10n?.terminosDeUso ??
                                            'Términos de uso',
                                        style: TextStyle(
                                          color: const Color(0xFF0055A5),
                                          fontSize: screenWidth * 0.03,
                                          fontWeight: FontWeight.bold,
                                          decoration:
                                              TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      l10n?.yLa ?? ' y la ',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: screenWidth * 0.03,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          TerminosPrivacidadScreen.routeName,
                                        );
                                      },
                                      child: Text(
                                        l10n?.politicaDePrivacidad ??
                                            'Política de privacidad',
                                        style: TextStyle(
                                          color: const Color(0xFF0055A5),
                                          fontSize: screenWidth * 0.03,
                                          fontWeight: FontWeight.bold,
                                          decoration:
                                              TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: usableHeight * 0.025),

                          // 7. Botón Crear cuenta con indicador de carga
                          SizedBox(
                            width: double.infinity,
                            height: usableHeight * 0.058,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: amarilloOro,
                                foregroundColor: azulFondo,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.03,
                                  ),
                                ),
                              ),
                              onPressed:
                                  _isLoading ? null : _ejecutarRegistro,
                              child: _isLoading
                                  ? SizedBox(
                                      width: screenWidth * 0.05,
                                      height: screenWidth * 0.05,
                                      child: const CircularProgressIndicator(
                                        color: azulFondo,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      l10n?.crearCuentaBoton ??
                                          'Crear cuenta',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.050,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.02),

                          // 8. Link ¿Ya tienes una cuenta? Iniciar sesión
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  l10n?.yaTienesCuenta ??
                                      '¿Ya tienes una cuenta? ',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: screenWidth * 0.032,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      InicioSesionScreen.routeName,
                                    );
                                  },
                                  child: Text(
                                    l10n?.iniciarSesionEnlace ??
                                        'Iniciar sesión',
                                    style: TextStyle(
                                      color: const Color(0xFF0055A5),
                                      fontSize: screenWidth * 0.032,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.015),
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

  // Label para los campos
  Widget _buildFieldLabel(
    String text,
    double screenWidth,
    Color azulFondo,
  ) {
    return Text(
      text,
      style: TextStyle(
        color: azulFondo,
        fontSize: screenWidth * 0.040,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // Campo de texto con icono prefijo y sufijo opcional
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required double screenWidth,
    required double usableHeight,
    required Color grisBorde,
    required Color azulFondo,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      height: usableHeight * 0.055,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        border: Border.all(color: grisBorde),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: TextStyle(fontSize: screenWidth * 0.036, color: azulFondo),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: screenWidth * 0.035,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: azulFondo,
            size: screenWidth * 0.055,
          ),
          suffixIcon: isPassword
              ? GestureDetector(
                  onTap: onToggleVisibility,
                  child: Icon(
                    obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: azulFondo,
                    size: screenWidth * 0.055,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(vertical: usableHeight * 0.014),
        ),
      ),
    );
  }
}
