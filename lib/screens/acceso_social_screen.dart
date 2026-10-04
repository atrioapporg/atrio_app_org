import 'package:flutter/material.dart';

class AccesoSocialScreen extends StatelessWidget {
  static const routeName = 'acceso_social_screen';
  const AccesoSocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Obtención de métricas dinámicas relativas
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    // Paleta de diseño Atrio
    const Color azulFondo = Color(0xFF072B4F);
    const Color blancoFondo = Color(0xFFFAF7F0);
    const Color grisBorde = Color(0xFFE0E0E0);

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        child: SizedBox(
          width: screenWidth,
          height: usableHeight,
          child: Column(
            children: [
              // 2. Encabezado Superior (Logo Horizontal + Selector de Idioma + Título)
              Container(
                height: usableHeight * 0.18,
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
                          'assets/images/logo_encabezado.png',
                          height: usableHeight * 0.048,
                          fit: BoxFit.contain,
                        ),
                        // Selector de idioma simplificado
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
                              Text(
                                'ES',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.032,
                                  fontWeight: FontWeight.bold,
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
                    const Spacer(),
                    // Título Principal
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
                    SizedBox(height: usableHeight * 0.01),
                  ],
                ),
              ),

              // 3. Contenedor Blanco Inferior (Imagen + Botones)
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
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: usableHeight * 0.02,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Placeholder / Contenedor Ilustrativo de la Comunidad
                        Container(
                          width: screenWidth * 0.88,
                          height: usableHeight * 0.28,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.05,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.groups_rounded,
                              size: screenWidth * 0.22,
                              color: azulFondo,
                            ),
                          ),
                        ),

                        // Bloque de Accesos Sociales y Métodos de Entrada
                        Column(
                          children: [
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
                            SizedBox(height: usableHeight * 0.012),
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
                            SizedBox(height: usableHeight * 0.012),
                            _buildSocialButton(
                              title: 'Correo electrónico',
                              icon: Icons.mail_outline_rounded,
                              iconColor: azulFondo,
                              screenWidth: screenWidth,
                              usableHeight: usableHeight,
                              grisBorde: grisBorde,
                              azulFondo: azulFondo,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  'inicio_sesion_screen',
                                );
                              },
                            ),
                            SizedBox(height: usableHeight * 0.012),
                            _buildSocialButton(
                              title: 'Número de teléfono',
                              icon: Icons.phone_outlined,
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
                          ],
                        ),
                      ],
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

  // Componente de Botón de Opción Relativo
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
        height: usableHeight * 0.060,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          border: Border.all(color: grisBorde),
        ),
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: screenWidth * 0.06),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.06),
          ],
        ),
      ),
    );
  }
}
