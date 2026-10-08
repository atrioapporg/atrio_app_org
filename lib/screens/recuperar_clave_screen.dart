import 'package:flutter/material.dart';

class RecuperarClaveScreen extends StatefulWidget {
  static const routeName = 'recuperar_clave_screen';

  const RecuperarClaveScreen({super.key});

  @override
  State<RecuperarClaveScreen> createState() => _RecuperarClaveScreenState();
}

class _RecuperarClaveScreenState extends State<RecuperarClaveScreen> {
  final TextEditingController _identifierController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Métricas relativas dinámicas (Flutter 3.22+)
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
              // 2. Encabezado Superior (Botón Volver + Logo + Selector de Idioma)
              Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  children: [
                    SizedBox(height: usableHeight * 0.01),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Botón Volver (<-)
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
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white,
                                size: screenWidth * 0.04,
                              ),
                            ],
                          ),
                        ),
                      ],
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
                        horizontal: screenWidth * 0.055,
                        vertical: usableHeight * 0.03,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Ícono de Candado con Corazón
                          _buildLockHeartIcon(
                            screenWidth,
                            amarilloOro,
                            azulFondo,
                          ),
                          SizedBox(height: usableHeight * 0.025),

                          // Título
                          Text(
                            '¿Olvidaste tu\ncontraseña?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.068,
                              fontWeight: FontWeight.bold,
                              height: 1.15,
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.015),

                          // Subtítulo descriptivo
                          Text(
                            'No te preocupes. Escribe el correo electrónico o número de teléfono asociado a tu cuenta y te enviaremos instrucciones para recuperar el acceso.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: screenWidth * 0.034,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.03),

                          // Campo Correo o número de teléfono
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Correo o número de teléfono',
                              style: TextStyle(
                                color: azulFondo,
                                fontSize: screenWidth * 0.036,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.008),
                          Container(
                            height: usableHeight * 0.058,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.03,
                              ),
                              border: Border.all(color: grisBorde),
                            ),
                            child: TextField(
                              controller: _identifierController,
                              style: TextStyle(
                                fontSize: screenWidth * 0.036,
                                color: azulFondo,
                              ),
                              decoration: InputDecoration(
                                hintText: 'tu@correo.com',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: screenWidth * 0.035,
                                ),
                                prefixIcon: Icon(
                                  Icons.mail_outline_rounded,
                                  color: azulFondo,
                                  size: screenWidth * 0.055,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: usableHeight * 0.016,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.03),

                          // Botón Enviar instrucciones
                          SizedBox(
                            width: screenWidth,
                            height: usableHeight * 0.062,
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
                              onPressed: () {},
                              child: Text(
                                'Enviar instrucciones',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.025),

                          // Link Volver a iniciar sesión
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Volver a iniciar sesión',
                              style: TextStyle(
                                color: azulLink,
                                fontSize: screenWidth * 0.034,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.04),

                          // Divisor tenue
                          Divider(color: grisBorde, thickness: 1),
                          SizedBox(height: usableHeight * 0.02),

                          // Link Soporte
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '¿Necesitas ayuda? ',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: screenWidth * 0.032,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {},
                                child: Text(
                                  'Contactar soporte',
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

  // Componente: Ícono decorativo del candado con corazón
  Widget _buildLockHeartIcon(
    double screenWidth,
    Color amarilloOro,
    Color azulFondo,
  ) {
    final double iconBoxWidth = screenWidth * 0.16;
    final double iconBoxHeight = screenWidth * 0.20;

    return SizedBox(
      width: iconBoxWidth,
      height: iconBoxHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arco superior del candado (grillete)
          Positioned(
            top: 0,
            child: Container(
              width: iconBoxWidth * 0.58,
              height: iconBoxHeight * 0.45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(iconBoxWidth * 0.3),
                  topRight: Radius.circular(iconBoxWidth * 0.3),
                ),
                border: Border.all(
                  color: amarilloOro,
                  width: screenWidth * 0.012,
                ),
              ),
            ),
          ),
          // Cuerpo rectangular inferior del candado
          Positioned(
            bottom: 0,
            child: Container(
              width: iconBoxWidth,
              height: iconBoxHeight * 0.62,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                border: Border.all(
                  color: amarilloOro,
                  width: screenWidth * 0.012,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.favorite_rounded,
                  color: azulFondo,
                  size: iconBoxWidth * 0.42,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
