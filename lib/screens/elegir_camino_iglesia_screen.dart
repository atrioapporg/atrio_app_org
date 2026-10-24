import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/user_provider.dart';
import 'crear_mi_iglesia_screen.dart';
import 'inicio_atrio_screen.dart';
import 'inicio_sesion_screen.dart';
import 'seleccionar_iglesia_screen.dart';

/// Pantalla donde un usuario autenticado sin congregación vinculada (role: user, membership_status: none)
/// decide entre unirse a una iglesia existente o registrar la suya propia.
class ElegirCaminoIglesiaScreen extends StatelessWidget {
  static const String routeName = 'elegir_camino_iglesia_screen';

  const ElegirCaminoIglesiaScreen({super.key});

  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFE2E8F0);
  static const Color textoOscuro = Color(0xFF0F172A);
  static const Color textoGris = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
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
                  colors: [
                    Color(0xFF03182E),
                    Color(0xFF072B4F),
                    Color(0xFF0F4C81),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Barra superior: Cerrar sesión
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              color: amarilloOro,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ATRIO Comunidad',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.85),
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
                ),

                // Contenido desplazable
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado de bienvenida
                        Text(
                          '¡Paz y bien, $userName!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Para vivir tu fe en comunión y acceder a actividades, peticiones y eventos, da el siguiente paso:',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.04),

                        // Opción 1: Unirme a una iglesia existente
                        _buildCardOpcion(
                          context: context,
                          icon: Icons.church_rounded,
                          iconColor: const Color(0xFF0284C7),
                          iconBgColor: const Color(0xFFE0F2FE),
                          titulo: 'Unirme a una iglesia',
                          descripcion:
                              'Explora congregaciones en el mapa interactivo por ubicación o denominación y solicita tu ingreso.',
                          botonTexto: 'Buscar mi iglesia',
                          esPrimario: true,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              SeleccionarIglesiaScreen.routeName,
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Opción 2: Registrar mi congregación
                        _buildCardOpcion(
                          context: context,
                          icon: Icons.domain_add_rounded,
                          iconColor: const Color(0xFFB45309),
                          iconBgColor: const Color(0xFFFEF3C7),
                          titulo: 'Registrar mi iglesia',
                          descripcion:
                              'Si eres pastor, obispo o líder ministerial, registra tu congregación en ATRIO para administrarla.',
                          botonTexto: 'Crear congregación',
                          esPrimario: false,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              CrearMiIglesiaScreen.routeName,
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Opción secundaria: Continuar como invitado
                        Center(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: textoGris,
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
                            child: const Text(
                              'Explorar contenido público por ahora',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardOpcion({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String titulo,
    required String descripcion,
    required String botonTexto,
    required bool esPrimario,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: grisBorde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: textoOscuro,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            descripcion,
            style: const TextStyle(
              color: textoGris,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: esPrimario ? azulFondo : amarilloOro,
                foregroundColor: esPrimario ? Colors.white : azulFondo,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    botonTexto,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
