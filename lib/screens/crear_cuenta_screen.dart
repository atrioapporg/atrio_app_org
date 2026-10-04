import 'package:flutter/material.dart';

class CrearCuentaScreen extends StatefulWidget {
  static const routeName = 'crear_cuenta_screen';
  const CrearCuentaScreen({super.key});

  @override
  State createState() => _CrearCuentaScreenState();
}

class _CrearCuentaScreenState extends State {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Obtención de métricas dinámicas relativas (Flutter 3.22+)
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    // Paleta de diseño Atrio
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);
    const Color grisBorde = Color(0xFFE5E5E5);

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
                        'Registro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.058,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    // Selector de Idioma estilizado
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.028,
                        vertical: usableHeight * 0.007,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(screenWidth * 0.04),
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
                            'ES',
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
                            'Crea tu cuenta',
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.068,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.004),
                          Text(
                            'Únete a una comunidad para vivir y compartir tu fe.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: screenWidth * 0.034,
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.02),

                          // 1. Campo Nombre completo
                          _buildFieldLabel(
                            'Nombre completo',
                            screenWidth,
                            azulFondo,
                          ),
                          SizedBox(height: usableHeight * 0.006),
                          _buildInputField(
                            controller: _nombreController,
                            hintText: 'Escribe tu nombre',
                            prefixIcon: Icons.person_outline_rounded,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            grisBorde: grisBorde,
                            azulFondo: azulFondo,
                          ),
                          SizedBox(height: usableHeight * 0.015),

                          // 2. Campo Correo electrónico
                          _buildFieldLabel(
                            'Correo electrónico',
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
                            'Número de teléfono',
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
                            'Contraseña',
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
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      'Acepto los ',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: screenWidth * 0.03,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {},
                                      child: Text(
                                        'Términos de uso',
                                        style: TextStyle(
                                          color: const Color(0xFF0055A5),
                                          fontSize: screenWidth * 0.03,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      ' y la ',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: screenWidth * 0.03,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {},
                                      child: Text(
                                        'Política de privacidad',
                                        style: TextStyle(
                                          color: const Color(0xFF0055A5),
                                          fontSize: screenWidth * 0.03,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: usableHeight * 0.025),

                          // 7. Botón Crear cuenta
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
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  'tradicion_cristiana_screen',
                                );
                              },
                              child: Text(
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
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
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
                                      'inicio_sesion_screen',
                                    );
                                  },
                                  child: Text(
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
  Widget _buildFieldLabel(String text, double screenWidth, Color azulFondo) {
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
          contentPadding: EdgeInsets.symmetric(vertical: usableHeight * 0.014),
        ),
      ),
    );
  }
}
