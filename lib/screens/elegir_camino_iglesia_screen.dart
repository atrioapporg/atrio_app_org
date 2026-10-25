import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/user_provider.dart';
import 'inicio_atrio_screen.dart';
import 'inicio_sesion_screen.dart';
import 'tradicion_cristiana_screen.dart';

/// Pantalla donde un usuario autenticado sin congregación vinculada (role: user, membership_status: none)
/// visualiza el paso para conectarse a una iglesia existente.
/// 
/// La creación y registro de nuevas congregaciones se realiza exclusivamente a través
/// de la plataforma web administrativa de ATRIO.
class ElegirCaminoIglesiaScreen extends StatelessWidget {
  static const String routeName = 'elegir_camino_iglesia_screen';

  const ElegirCaminoIglesiaScreen({super.key});

  static const Color azulFondo = Color(0xFF072B4F);
  static const Color azulOscuro = Color(0xFF03182E);
  static const Color azulMedio = Color(0xFF0F4C81);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFE2E8F0);
  static const Color textoOscuro = Color(0xFF0F172A);
  static const Color textoGris = Color(0xFF64748B);

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
            height: screenHeight * 0.36,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    azulOscuro,
                    azulFondo,
                    azulMedio,
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.06,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Barra superior: Identificador ATRIO + Cerrar sesión
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.15),
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
                                            color: Colors.white
                                                .withValues(alpha: 0.95),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          Colors.white.withValues(alpha: 0.9),
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
                                    icon: const Icon(Icons.logout_rounded,
                                        size: 18),
                                    label: Text(
                                      l10n?.cerrarSesion ?? 'Cerrar sesión',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.02),

                            // Encabezado de bienvenida
                            Text(
                              '¡Paz y bien, $userName!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Para vivir tu fe en comunión y acceder a actividades, peticiones y eventos, da el siguiente paso:',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14.5,
                                height: 1.45,
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.035),

                            // Tarjeta Hero Principal: Unirme a una iglesia
                            _buildHeroCard(
                              context: context,
                              screenWidth: screenWidth,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  TradicionCristianaScreen.routeName,
                                );
                              },
                            ),

                            SizedBox(height: screenHeight * 0.025),

                            // Nota informativa: Registro web de congregaciones
                            _buildWebRegistrationNotice(),

                            const Spacer(),

                            SizedBox(height: screenHeight * 0.02),

                            // Opción secundaria: Continuar como invitado
                            Center(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: azulFondo,
                                  side: BorderSide(
                                    color: azulFondo.withValues(alpha: 0.25),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.6),
                                ),
                                onPressed: () {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    InicioAtrioScreen.routeName,
                                    (route) => false,
                                  );
                                },
                                icon: const Icon(Icons.explore_outlined,
                                    size: 18),
                                label: const Text(
                                  'Explorar contenido público por ahora',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: screenHeight * 0.03),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard({
    required BuildContext context,
    required double screenWidth,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: grisBorde, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: azulFondo.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge superior
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: amarilloOro.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: amarilloOro,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'PASO PRINCIPAL',
                      style: TextStyle(
                        color: Color(0xFFB45309),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.place_outlined,
                  color: Color(0xFF0284C7),
                  size: 18,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Icono principal y Título
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE0F2FE),
                      Color(0xFFBAE6FD),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.church_rounded,
                  color: Color(0xFF0284C7),
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unirme a una iglesia',
                      style: TextStyle(
                        color: textoOscuro,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Comunión, eventos y ministerio',
                      style: TextStyle(
                        color: textoGris,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Text(
            'Explora congregaciones en el mapa interactivo por ubicación o denominación y solicita tu ingreso.',
            style: TextStyle(
              color: Color(0xFF475569),
              fontSize: 14,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 16),

          // Puntos clave / Beneficios
          _buildFeatureItem(
            icon: Icons.map_outlined,
            text: 'Encuentra tu congregación en el mapa interactivo',
          ),
          const SizedBox(height: 8),
          _buildFeatureItem(
            icon: Icons.people_outline_rounded,
            text: 'Conéctate con tus pastores, líderes y hermanos',
          ),
          const SizedBox(height: 8),
          _buildFeatureItem(
            icon: Icons.favorite_border_rounded,
            text: 'Participa en peticiones de oración y actividades',
          ),

          const SizedBox(height: 22),

          // Botón CTA de alto impacto
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: azulFondo,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: azulFondo.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onTap,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Buscar mi iglesia',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String text,
  }) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0284C7),
            size: 13,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: textoGris,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebRegistrationNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: grisBorde),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.language_rounded,
              color: Color(0xFFB45309),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Eres pastor o líder ministerial?',
                  style: TextStyle(
                    color: textoOscuro,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'El registro y gestión de nuevas congregaciones se realiza exclusivamente desde nuestro portal web oficial.',
                  style: TextStyle(
                    color: textoGris,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
