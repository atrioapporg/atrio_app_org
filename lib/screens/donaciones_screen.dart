import 'package:atrio/screens/realizar_aporte_screen.dart';
import 'package:flutter/material.dart';

class DonacionesScreen extends StatelessWidget {
  static const routeName = 'donaciones_screen';
  const DonacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Obtención de métricas dinámicas relativas (Flutter 3.22+)
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    // Paleta de colores oficial Atrio
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);
    const Color grisBorde = Color(0xFFE8ECEF);
    const Color verdeIcono = Color(0xFF5A7D5A);
    const Color azulBadge = Color(0xFF00386C);
    const Color celesteCard = Color(0xFFE8F2F8);

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: true,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight,
          child: Column(
            children: [
              // 2. Encabezado Superior (Botón Volver + Título + Campana)
              Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: usableHeight * 0.015,
                ),
                child: Row(
                  children: [
                    // Botón de retroceso circular estilizado
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
                    // Título de la pantalla
                    Expanded(
                      child: Text(
                        'Donaciones',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.062,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    // Campana de notificaciones con punto de alerta
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.02),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: screenWidth * 0.058,
                          ),
                        ),
                        Positioned(
                          top: screenWidth * 0.015,
                          right: screenWidth * 0.015,
                          child: Container(
                            width: screenWidth * 0.022,
                            height: screenWidth * 0.022,
                            decoration: const BoxDecoration(
                              color: amarilloOro,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
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
                        horizontal: screenWidth * 0.05,
                        vertical: usableHeight * 0.022,
                      ),
                      child: Column(
                        children: [
                          // Tarjeta de la Iglesia Verificada
                          _buildVerifiedChurchCard(
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            azulBadge: azulBadge,
                            grisBorde: grisBorde,
                          ),
                          SizedBox(height: usableHeight * 0.02),

                          // 1. Diezmo
                          _buildDonationCategoryTile(
                            title: 'Diezmo',
                            icon: Icons.church_outlined,
                            iconColor: amarilloOro,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            grisBorde: grisBorde,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                RealizarAporteScreen.routeName,
                                arguments: 'Diezmo',
                              );
                            },
                          ),
                          SizedBox(height: usableHeight * 0.012),

                          // 2. Ofrenda
                          _buildDonationCategoryTile(
                            title: 'Ofrenda',
                            icon: Icons.favorite_border_rounded,
                            iconColor: amarilloOro,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            grisBorde: grisBorde,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                RealizarAporteScreen.routeName,
                                arguments: 'Ofrenda',
                              );
                            },
                          ),
                          SizedBox(height: usableHeight * 0.012),

                          // 3. Campaña especial
                          _buildDonationCategoryTile(
                            title: 'Campaña especial',
                            icon: Icons.campaign_outlined,
                            iconColor: verdeIcono,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            grisBorde: grisBorde,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                RealizarAporteScreen.routeName,
                                arguments: 'Campaña especial',
                              );
                            },
                          ),
                          SizedBox(height: usableHeight * 0.012),

                          // 4. Ayuda comunitaria
                          _buildDonationCategoryTile(
                            title: 'Ayuda comunitaria',
                            icon: Icons.volunteer_activism_outlined,
                            iconColor: verdeIcono,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            grisBorde: grisBorde,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                RealizarAporteScreen.routeName,
                                arguments: 'Ayuda comunitaria',
                              );
                            },
                          ),
                          SizedBox(height: usableHeight * 0.012),

                          // 5. Otro aporte
                          _buildDonationCategoryTile(
                            title: 'Otro aporte',
                            icon: Icons.more_horiz_rounded,
                            iconColor: const Color(0xFF0055A5),
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            grisBorde: grisBorde,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                RealizarAporteScreen.routeName,
                                arguments: 'Otro aporte',
                              );
                            },
                          ),
                          SizedBox(height: usableHeight * 0.02),

                          // Tarjeta Destacada "Mis donaciones"
                          _buildHistoryCard(
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            celesteCard: celesteCard,
                            grisBorde: grisBorde,
                            onTap: () {},
                          ),
                          SizedBox(height: usableHeight * 0.02),
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

  Widget _buildVerifiedChurchCard({
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color azulBadge,
    required Color grisBorde,
  }) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.035),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
        border: Border.all(color: grisBorde),
      ),
      child: Row(
        children: [
          Container(
            width: screenWidth * 0.12,
            height: screenWidth * 0.12,
            decoration: BoxDecoration(
              color: azulFondo,
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
            ),
            child: Icon(
              Icons.groups_2_outlined,
              color: Colors.white,
              size: screenWidth * 0.07,
            ),
          ),
          SizedBox(width: screenWidth * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Comunidad de Esperanza',
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.038,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.015),
                    Icon(
                      Icons.verified,
                      color: azulBadge,
                      size: screenWidth * 0.045,
                    ),
                  ],
                ),
                SizedBox(height: usableHeight * 0.002),
                Text(
                  'Comunidad verificada',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: screenWidth * 0.03,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonationCategoryTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color grisBorde,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: usableHeight * 0.075,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          border: Border.all(color: grisBorde),
        ),
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.045),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: screenWidth * 0.089),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.055,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: azulFondo,
              size: screenWidth * 0.055,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard({
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color celesteCard,
    required Color grisBorde,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: usableHeight * 0.085,
        decoration: BoxDecoration(
          color: celesteCard,
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          border: Border.all(color: grisBorde),
        ),
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.045),
        child: Row(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: azulFondo,
              size: screenWidth * 0.085,
            ),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mis donaciones',
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.055,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.002),
                  Text(
                    'Historial y recibos',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: screenWidth * 0.03,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: azulFondo,
              size: screenWidth * 0.055,
            ),
          ],
        ),
      ),
    );
  }
}
