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

/// Pantalla OBSOLETA donde un usuario sin congregación vinculada seleccionaba su camino.
/// Reemplazada en el flujo principal por navegación directa a [SeleccionarIglesiaScreen]
/// junto con el modal de bienvenida [ChurchWelcomeModal].
@Deprecated(
  'Pantalla redundante omitida. Redirigir directamente a SeleccionarIglesiaScreen con ChurchWelcomeModal.',
)
class ElegirCaminoIglesiaScreen extends StatefulWidget {
  static const String routeName = 'elegir_camino_iglesia_screen';

  const ElegirCaminoIglesiaScreen({super.key});

  @override
  State<ElegirCaminoIglesiaScreen> createState() =>
      _ElegirCaminoIglesiaScreenState();
}

class _ElegirCaminoIglesiaScreenState extends State<ElegirCaminoIglesiaScreen> {
  static const Color azulFondo = Color(0xFF072B4F);
  static const Color azulOscuro = Color(0xFF03182E);
  static const Color azulMedio = Color(0xFF0F4C81);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFF8FAFC);
  static const Color grisBorde = Color(0xFFE2E8F0);
  static const Color textoOscuro = Color(0xFF0F172A);
  static const Color textoGris = Color(0xFF64748B);

  static const String webRegistroUrl = 'https://atrioapp.odoo19rd.com/#inicio';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _comprobarBypassIglesia();
    });
  }

  Future<void> _comprobarBypassIglesia() async {
    final userProvider = context.read<UserProvider>();
    // Regla estricta: Si ya tiene iglesia seleccionada o vinculada, bypass inmediato al HomeScreen
    if (userProvider.hasSelectedOrLinkedChurch) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, InicioAtrioScreen.routeName);
      }
      return;
    }

    final tienePrevia = await userProvider.verificarIglesiaPrevia();
    if (tienePrevia && mounted) {
      Navigator.pushReplacementNamed(context, InicioAtrioScreen.routeName);
    }
  }

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
          // Fondo superior degradado corporativo ATRIO
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.28,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [azulOscuro, azulFondo, azulMedio],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth > 600 ? 32 : screenWidth * 0.05,
                vertical: 10,
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
                          foregroundColor: Colors.white.withValues(alpha: 0.9),
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
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Elige cómo deseas participar en la comunidad:',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =========================================================
                  // ACCIÓN PRINCIPAL (HERO CARD): UNIRME A UNA IGLESIA
                  // =========================================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: grisBorde, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: azulFondo.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.diversity_3_rounded,
                                color: azulMedio,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Unirme a una iglesia',
                                    style: TextStyle(
                                      color: textoOscuro,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Para miembros y servidores',
                                    style: TextStyle(
                                      color: textoGris,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Conéctate a tu iglesia local para acceder a devocionales, eventos, oraciones y la vida de tu comunidad.',
                          style: TextStyle(
                            color: textoGris,
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: azulFondo,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                TradicionCristianaScreen.routeName,
                              );
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.church_rounded, size: 19),
                                SizedBox(width: 8),
                                Text(
                                  'Conectarme a mi iglesia',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Separador de opciones secundarias
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Otras opciones',
                      style: TextStyle(
                        color: textoOscuro.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // OPCIÓN SECUNDARIA 1: RECOMENDAR EN GOOGLE MAPS
                  _buildSecondaryOptionTile(
                    icon: Icons.add_location_alt_rounded,
                    iconBgColor: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFD97706),
                    title: 'Mi iglesia no está en Atrio',
                    subtitle: 'Búscala en Google Maps y recomiéndala para incorporarla.',
                    trailingIcon: Icons.arrow_forward_ios_rounded,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        RecomendarIglesiaMapaScreen.routeName,
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // OPCIÓN SECUNDARIA 2: REGISTRO WEB ODOO
                  _buildSecondaryOptionTile(
                    icon: Icons.domain_rounded,
                    iconBgColor: const Color(0xFFF1F5F9),
                    iconColor: const Color(0xFF475569),
                    title: 'Registrar una congregación',
                    subtitle: 'Portal web oficial para Pastores y Líderes de iglesia.',
                    trailingIcon: Icons.open_in_new_rounded,
                    onTap: () => _abrirPortalWeb(context),
                  ),

                  const SizedBox(height: 20),

                  // Opción alternativa: Explorar como invitado
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: azulFondo,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Footer de Asistencia
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          '¿Tienes dudas? ',
                          style: TextStyle(color: textoGris, fontSize: 12),
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
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryOptionTile({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required IconData trailingIcon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: grisBorde, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: textoOscuro,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: textoGris,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  trailingIcon,
                  color: textoGris.withValues(alpha: 0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
