import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../providers/user_provider.dart';
import 'ayuda_soporte_screen.dart';
import 'inicio_atrio_screen.dart';
import 'inicio_sesion_screen.dart';
import 'recomendar_iglesia_mapa_screen.dart';
import 'tradicion_cristiana_screen.dart';

/// Pantalla donde un usuario autenticado sin congregación vinculada
/// selecciona su camino de participación en la plataforma ATRIO:
/// 1. Unirme a una iglesia (Búsqueda in-app por tradición / mapa local)
/// 2. Mi iglesia no está en Atrio (Recomendación in-app mediante Google Maps)
/// 3. Registrar una congregación (Delegada exclusivamente al portal web de Odoo)
class ElegirCaminoIglesiaScreen extends StatelessWidget {
  static const String routeName = 'elegir_camino_iglesia_screen';

  const ElegirCaminoIglesiaScreen({super.key});

  static const Color azulFondo = Color(0xFF072B4F);
  static const Color azulOscuro = Color(0xFF03182E);
  static const Color azulMedio = Color(0xFF0F4C81);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFF8FAFC);
  static const Color grisBorde = Color(0xFFE2E8F0);
  static const Color textoOscuro = Color(0xFF0F172A);
  static const Color textoGris = Color(0xFF64748B);

  static const String webRegistroUrl = 'https://atrioapp.odoo19rd.com/#inicio';

  Future<void> _abrirPortalWeb(BuildContext context) async {
    final uri = Uri.parse(webRegistroUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo abrir el navegador. Visita: $webRegistroUrl',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enlace web: $webRegistroUrl')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final screenHeight = size.height;
    final l10n = AppLocalizations.of(context);
    final userProvider = context.watch<UserProvider>();
    final userName = userProvider.currentUser?.nombre ?? 'Hermano(a)';

    return Scaffold(
      backgroundColor: blancoFondo,
      body: Stack(
        children: [
          // Fondo superior con degradado corporativo ATRIO
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.32,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [azulOscuro, azulFondo, azulMedio],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barra superior: Identificador ATRIO + Cerrar sesión
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.church_rounded,
                                  color: amarilloOro,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'ATRIO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white.withValues(
                                alpha: 0.9,
                              ),
                            ),
                            onPressed: () async {
                              await userProvider.logout();
                              if (context.mounted) {
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  InicioSesionScreen.routeName,
                                  (route) => false,
                                );
                              }
                            },
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: Text(
                              l10n?.cerrarSesion ?? 'Cerrar sesión',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Encabezado de Bienvenida
                      Center(
                        child: Column(
                          children: [
                            Text(
                              '¡Bienvenido a Atrio, $userName!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'Para comenzar a personalizar tu experiencia, selecciona cómo deseas participar en la plataforma:',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // =======================================================
                      // TARJETA 1: UNIRME A UNA IGLESIA (MIEMBROS & SERVIDORES)
                      // =======================================================
                      _buildPathCard(
                        context: context,
                        badgeText: 'MIEMBROS & SERVIDORES',
                        badgeIcon: Icons.people_alt_rounded,
                        badgeBgColor: const Color(0xFFEFF6FF),
                        badgeTextColor: const Color(0xFF1D4ED8),
                        iconData: Icons.diversity_3_rounded,
                        iconGradientColors: const [
                          Color(0xFFDBEAFE),
                          Color(0xFFBFDBFE),
                        ],
                        iconColor: const Color(0xFF1D4ED8),
                        title: 'Unirme a una iglesia',
                        description: 'Busca y conéctate a tu congregación para acceder a noticias, eventos, grupos de discipulado, oraciones y ofrendas.',
                        bulletPoints: const [
                          'Conexión directa con tu congregación',
                          'Contenidos y devocionales exclusivos',
                        ],
                        buttonText: 'Conectarme a mi iglesia',
                        buttonColor: Colors.white,
                        buttonTextColor: azulFondo,
                        isButtonOutlined: true,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            TradicionCristianaScreen.routeName,
                          );
                        },
                      ),

                      const SizedBox(height: 18),

                      // =======================================================
                      // TARJETA 2: MI IGLESIA NO ESTÁ EN ATRIO (GOOGLE MAPS)
                      // =======================================================
                      _buildPathCard(
                        context: context,
                        isHighlighted: true,
                        badgeText: 'GOOGLE MAPS',
                        badgeIcon: Icons.location_on_rounded,
                        badgeBgColor: const Color(0xFFFEF3C7),
                        badgeTextColor: const Color(0xFFB45309),
                        iconData: Icons.place_rounded,
                        iconGradientColors: const [
                          Color(0xFFFEF3C7),
                          Color(0xFFFDE68A),
                        ],
                        iconColor: const Color(0xFFD97706),
                        title: 'Mi iglesia no está en Atrio',
                        description: 'Buscala en el mapa y recomendala. Atrio la contacta para sumarla y tu pedido de ingreso queda listo.',
                        bulletPoints: const [
                          'Elegí tu iglesia en Google Maps',
                          'Te avisamos cuando se inscriba (plazo 30 días)',
                        ],
                        buttonText: 'Recomendar mi iglesia',
                        buttonColor: azulFondo,
                        buttonTextColor: Colors.white,
                        isButtonOutlined: false,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            RecomendarIglesiaMapaScreen.routeName,
                          );
                        },
                      ),

                      const SizedBox(height: 18),

                      // =======================================================
                      // TARJETA 3: REGISTRAR UNA IGLESIA (DELEGADA A WEB ODOO)
                      // =======================================================
                      _buildPathCard(
                        context: context,
                        badgeText: 'REGISTRO WEB (ODOO)',
                        badgeIcon: Icons.open_in_browser_rounded,
                        badgeBgColor: const Color(0xFFF1F5F9),
                        badgeTextColor: const Color(0xFF475569),
                        iconData: Icons.domain_rounded,
                        iconGradientColors: const [
                          Color(0xFFF1F5F9),
                          Color(0xFFE2E8F0),
                        ],
                        iconColor: const Color(0xFF334155),
                        title: 'Registrar una congregación',
                        description: 'Crea la ficha de tu iglesia. Para Pastores, Líderes y Administradores: el alta y gestión de módulos se realiza exclusivamente en nuestro portal web.',
                        bulletPoints: const [
                          'Gestión completa de miembros, eventos y tienda',
                          'Registro habilitado exclusivamente en web oficial',
                        ],
                        buttonText: 'Ir al portal web oficial',
                        buttonTrailingIcon: Icons.arrow_outward_rounded,
                        buttonColor: Colors.white,
                        buttonTextColor: const Color(0xFF334155),
                        isButtonOutlined: true,
                        onTap: () => _abrirPortalWeb(context),
                      ),

                      const SizedBox(height: 24),

                      // Opción alternativa: Explorar como invitado
                      Center(
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: azulFondo,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              InicioAtrioScreen.routeName,
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.explore_outlined, size: 18),
                          label: const Text(
                            'Explorar contenido público por ahora',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Footer de Asistencia
                      Center(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              '¿Tienes dudas? ',
                              style: TextStyle(
                                color: textoGris,
                                fontSize: 12.5,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AyudaSoporteScreen.routeName,
                                );
                              },
                              child: const Text(
                                'Contacta a soporte',
                                style: TextStyle(
                                  color: azulMedio,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const Text(
                              ' o consulta nuestras Preguntas Frecuentes',
                              style: TextStyle(
                                color: textoGris,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathCard({
    required BuildContext context,
    required String badgeText,
    required IconData badgeIcon,
    required Color badgeBgColor,
    required Color badgeTextColor,
    required IconData iconData,
    required List<Color> iconGradientColors,
    required Color iconColor,
    required String title,
    required String description,
    required List<String> bulletPoints,
    required String buttonText,
    required Color buttonColor,
    required Color buttonTextColor,
    required bool isButtonOutlined,
    required VoidCallback onTap,
    IconData buttonTrailingIcon = Icons.arrow_forward_rounded,
    bool isHighlighted = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isHighlighted ? amarilloOro : grisBorde,
          width: isHighlighted ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? amarilloOro.withValues(alpha: 0.12)
                : azulFondo.withValues(alpha: 0.05),
            blurRadius: isHighlighted ? 18 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge Superior
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, color: badgeTextColor, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeTextColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: iconGradientColors),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconData, color: iconColor, size: 18),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Título
          Text(
            title,
            style: const TextStyle(
              color: textoOscuro,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 6),

          // Descripción
          Text(
            description,
            style: const TextStyle(
              color: textoGris,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          // Puntos clave / Checkmarks
          ...bulletPoints.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF10B981),
                      size: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Botón CTA
          SizedBox(
            width: double.infinity,
            height: 46,
            child: isButtonOutlined
                ? OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: buttonTextColor,
                      side: BorderSide(color: grisBorde, width: 1.3),
                      backgroundColor: buttonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onTap,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          buttonText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(buttonTrailingIcon, size: 16),
                      ],
                    ),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: buttonTextColor,
                      elevation: 2,
                      shadowColor: buttonColor.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onTap,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          buttonText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(buttonTrailingIcon, size: 16),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
