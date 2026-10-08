import 'package:flutter/material.dart';

class HeroBannerCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final VoidCallback? onTap;
  final String? backgroundImage;
  final List<Color>? gradientColors;
  final Color backgroundColor;
  final Widget? topLeading;
  final IconData? watermarkIcon;
  final double? heightFactor;

  const HeroBannerCard({
    super.key,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
    this.onTap,
    this.backgroundImage,
    this.gradientColors,
    this.backgroundColor = const Color(0xFF0F1E2E),
    this.topLeading,
    this.watermarkIcon,
    this.heightFactor = 0.22,
  });

  @override
  Widget build(BuildContext context) {
    // Métricas dinámicas relativas (Flutter 3.22+)
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: screenWidth,
        height: usableHeight * (heightFactor ?? 0.21),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(screenWidth * 0.045),
          gradient: gradientColors != null
              ? LinearGradient(
                  colors: gradientColors!,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(screenWidth * 0.045),
          child: Stack(
            children: [
              // Imagen de fondo con superposición oscura (si existe)
              if (backgroundImage != null) ...[
                Positioned.fill(
                  child: Image.asset(
                    backgroundImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.75),
                          Colors.black.withValues(alpha: 0.40),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ],

              // Ícono de marca de agua de fondo (opcional)
              if (watermarkIcon != null)
                Positioned(
                  right: screenWidth * 0.04,
                  top: usableHeight * 0.02,
                  child: Icon(
                    watermarkIcon,
                    size: screenWidth * 0.18,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),

              // Contenido principal (Textos y Botón de Acción)
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.045),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (topLeading != null) ...[
                          topLeading!,
                          SizedBox(height: usableHeight * 0.008),
                        ],
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.055,
                            fontWeight: FontWeight.bold,
                            height: 1.15,
                          ),
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: usableHeight * 0.005),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: screenWidth * 0.033,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (buttonText != null)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: amarilloOro,
                          foregroundColor: azulFondo,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.025,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.055,
                            vertical: usableHeight * 0.01,
                          ),
                        ),
                        onPressed: onButtonPressed ?? onTap,
                        child: Text(
                          buttonText!,
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
