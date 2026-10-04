import 'package:atrio/providers/iglesia_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

//

class InicioSesionScreen extends StatefulWidget {
  static const routeName = 'inicio_sesion_screen';
  const InicioSesionScreen({super.key});

  @override
  State createState() => _InicioSesionScreenState();
}

class _InicioSesionScreenState extends State {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoginTab = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Métricas dinámicas relativas (Flutter 3.22+)
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    // Paleta de diseño Atrio
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);
    const Color grisBorde = Color(0xFFE0E0E0);
    const Color textoGris = Color(0xFF757575);
    const Color azulLink = Color(0xFF0055A5);

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: true,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight,
          child: Column(
            children: [
              // 2. Top Header (Logo Horizontal + Selector de Idioma + Título)
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
                        // Nuevo Logo Horizontal Atrio
                        Image.asset(
                          'assets/images/logo_encabezado_sinfondo.png',
                          height: usableHeight * 0.060,
                          fit: BoxFit.contain,
                        ),
                        // FIN Nuevo Logo Horizontal Atrio
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
                          fontSize: screenWidth * 0.044,
                        ),
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.015),
                  ],
                ),
              ),
              // 3. Contenedor Blanco Inferior
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
                        vertical: usableHeight * 0.025,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Selector de Tabs: Iniciar sesión / Crear cuenta
                          Container(
                            height: usableHeight * 0.055,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.025,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: azulFondo,
                                      borderRadius: BorderRadius.circular(
                                        screenWidth * 0.025,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Iniciar sesión',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenWidth * 0.045,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        'crear_cuenta_screen',
                                      );
                                    },
                                    child: Container(
                                      color: Colors.transparent,
                                      child: Center(
                                        child: Text(
                                          'Crear cuenta',
                                          style: TextStyle(
                                            color: textoGris,
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenWidth * 0.045,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.02),
                          // Campo Correo electrónico
                          Text(
                            'Correo electrónico',
                            style: TextStyle(
                              color: azulFondo,
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.008),
                          _buildInputField(
                            controller: _emailController,
                            hintText: 'tu@correo.com',
                            prefixIcon: Icons.mail_outline_rounded,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            grisBorde: grisBorde,
                            azulFondo: azulFondo,
                          ),
                          SizedBox(height: usableHeight * 0.015),
                          // Campo Contraseña
                          Text(
                            'Contraseña',
                            style: TextStyle(
                              color: azulFondo,
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth * 0.035,
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.008),
                          _buildInputField(
                            controller: _passwordController,
                            hintText: '••••••••••',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                            isPasswordVisible: _isPasswordVisible,
                            onToggleVisibility: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            grisBorde: grisBorde,
                            azulFondo: azulFondo,
                          ),
                          SizedBox(height: usableHeight * 0.008),
                          // Enlace "¿Olvidaste tu contraseña?"
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  'recuperar_clave_screen',
                                );
                              },
                              child: Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(
                                  color: azulLink,
                                  fontSize: screenWidth * 0.032,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.030),
                          // Botón Iniciar sesión Principal
                          SizedBox(
                            width: screenWidth,
                            height: usableHeight * 0.058,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: amarilloOro,
                                foregroundColor: azulFondo,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.025,
                                  ),
                                ),
                              ),
                              onPressed: () async {
                                if (_isLoginTab) {
                                  // Opción recomendada (más limpia y evita inferir dynamic):
                                  final iglesiaProvider = context
                                      .read<IglesiaProvider>();
                                  // ✅ Correcto

                                  bool tieneIglesia = await iglesiaProvider
                                      .verificarIglesiaGuardada();
                                  if (!context.mounted) return;

                                  if (tieneIglesia) {
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      'inicio_atrio_screen',
                                      (route) => false,
                                    );
                                  } else {
                                    Navigator.pushNamed(
                                      context,
                                      'tradicion_cristiana_screen',
                                    );
                                  }
                                } else {
                                  Navigator.pushNamed(
                                    context,
                                    'crear_cuenta_screen',
                                  );
                                }
                              },
                              child: Text(
                                'Iniciar sesión',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.055,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.015),
                          // Enlace para usuarios sin cuenta
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '¿No tienes una cuenta? ',
                                  style: TextStyle(
                                    color: textoGris,
                                    fontSize: screenWidth * 0.032,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      'crear_cuenta_screen',
                                    );
                                  },
                                  child: Text(
                                    'Crear cuenta',
                                    style: TextStyle(
                                      color: azulLink,
                                      fontSize: screenWidth * 0.032,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.02),
                          // Divisor "o continuar con"
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.02,
                                ),
                                child: Text(
                                  'o continuar con',
                                  style: TextStyle(
                                    color: textoGris,
                                    fontSize: screenWidth * 0.03,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          SizedBox(height: usableHeight * 0.015),
                          // Botones de Acceso Social
                          _buildSocialButton(
                            title: 'Continuar con Google',
                            icon: Icons.g_mobiledata_rounded,
                            iconColor: Colors.red,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            grisBorde: grisBorde,
                            azulFondo: azulFondo,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                'tradicion_cristiana_screen',
                              );
                            },
                          ),
                          SizedBox(height: usableHeight * 0.01),
                          _buildSocialButton(
                            title: 'Continuar con Facebook',
                            icon: Icons.facebook_rounded,
                            iconColor: Colors.blue.shade800,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            grisBorde: grisBorde,
                            azulFondo: azulFondo,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                'tradicion_cristiana_screen',
                              );
                            },
                          ),
                          SizedBox(height: usableHeight * 0.01),
                          _buildSocialButton(
                            title: 'Número de teléfono',
                            icon: Icons.phone_android_rounded,
                            iconColor: azulFondo,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            grisBorde: grisBorde,
                            azulFondo: azulFondo,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                'tradicion_cristiana_screen',
                              );
                            },
                          ),
                          SizedBox(height: usableHeight * 0.025),
                          // Enlaces de Pie (Términos y Privacidad)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Términos de uso',
                                style: TextStyle(
                                  color: azulFondo,
                                  fontSize: screenWidth * 0.03,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.02,
                                ),
                                child: Text(
                                  '|',
                                  style: TextStyle(
                                    color: textoGris,
                                    fontSize: screenWidth * 0.03,
                                  ),
                                ),
                              ),
                              Text(
                                'Política de privacidad',
                                style: TextStyle(
                                  color: azulFondo,
                                  fontSize: screenWidth * 0.03,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
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

  // Componente Input Field Relativo
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required double screenWidth,
    required double usableHeight,
    required Color grisBorde,
    required Color azulFondo,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      height: usableHeight * 0.055,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.025),
        border: Border.all(color: grisBorde),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && !isPasswordVisible,
        style: TextStyle(fontSize: screenWidth * 0.036, color: azulFondo),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: screenWidth * 0.035,
            color: Colors.black38,
          ),
          prefixIcon: Icon(
            prefixIcon,
            size: screenWidth * 0.05,
            color: Colors.black54,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: screenWidth * 0.05,
                    color: Colors.black54,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
          contentPadding: EdgeInsets.symmetric(vertical: usableHeight * 0.015),
        ),
      ),
    );
  }

  // Componente Botón Social Relativo
  Widget _buildSocialButton({
    required String title,
    required IconData icon,
    required Color iconColor,
    required double screenWidth,
    required double usableHeight,
    required Color grisBorde,
    required Color azulFondo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: usableHeight * 0.052,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
          border: Border.all(color: grisBorde),
        ),
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: screenWidth * 0.065),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.050,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.055),
          ],
        ),
      ),
    );
  }
}
