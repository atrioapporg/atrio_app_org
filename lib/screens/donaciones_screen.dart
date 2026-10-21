import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/mis_donaciones_screen.dart';
import 'package:atrio/screens/realizar_aporte_screen.dart';
import 'package:atrio/widgets/modal_restriccion_donacion.dart';
import 'package:atrio/widgets/read_only_banner.dart';

import '../l10n/app_localizations.dart';

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

    final l10n = AppLocalizations.of(context);

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
                      child: Tooltip(
                        message: l10n?.volver ?? 'Volver',
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
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    // Título de la pantalla
                    Expanded(
                      child: Text(
                        l10n?.donaciones ?? 'Donaciones',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.062,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    // Campana de notificaciones con punto de alerta
                    Tooltip(
                      message: l10n?.notificaciones ?? 'Notificaciones',
                      child: Stack(
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
                          const ReadOnlyBanner(),
                          // Tarjeta de la Iglesia Verificada
                          _buildVerifiedChurchCard(
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            azulBadge: azulBadge,
                            grisBorde: grisBorde,
                            l10n: l10n,
                          ),
                          SizedBox(height: usableHeight * 0.02),

                          // 1. Diezmo
                          _buildDonationCategoryTile(
                            title: l10n?.diezmo ?? 'Diezmo',
                            icon: Icons.church_outlined,
                            iconColor: amarilloOro,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            grisBorde: grisBorde,
                            onTap: () => _iniciarAporte(context, 'Diezmo'),
                          ),
                          SizedBox(height: usableHeight * 0.012),

                          // 2. Ofrenda
                          _buildDonationCategoryTile(
                            title: l10n?.ofrenda ?? 'Ofrenda',
                            icon: Icons.favorite_border_rounded,
                            iconColor: amarilloOro,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            grisBorde: grisBorde,
                            onTap: () => _iniciarAporte(context, 'Ofrenda'),
                          ),
                          SizedBox(height: usableHeight * 0.012),

                          // 3. Campaña especial
                          _buildDonationCategoryTile(
                            title: l10n?.campanaEspecial ?? 'Campaña especial',
                            icon: Icons.campaign_outlined,
                            iconColor: verdeIcono,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            grisBorde: grisBorde,
                            onTap: () => _iniciarAporte(context, 'Campaña especial'),
                          ),
                          SizedBox(height: usableHeight * 0.012),

                          // 4. Ayuda comunitaria
                          _buildDonationCategoryTile(
                            title: l10n?.ayudaComunitaria ?? 'Ayuda comunitaria',
                            icon: Icons.volunteer_activism_outlined,
                            iconColor: verdeIcono,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            grisBorde: grisBorde,
                            onTap: () => _iniciarAporte(context, 'Ayuda comunitaria'),
                          ),
                          SizedBox(height: usableHeight * 0.012),

                          // 5. Otro aporte
                          _buildDonationCategoryTile(
                            title: l10n?.otroAporte ?? 'Otro aporte',
                            icon: Icons.more_horiz_rounded,
                            iconColor: const Color(0xFF0055A5),
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            grisBorde: grisBorde,
                            onTap: () => _iniciarAporte(context, 'Otro aporte'),
                          ),
                          SizedBox(height: usableHeight * 0.02),

                          // Tarjeta Destacada "Mis donaciones"
                          _buildHistoryCard(
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            celesteCard: celesteCard,
                            grisBorde: grisBorde,
                            l10n: l10n,
                            onTap: () => _abrirMisDonaciones(context),
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
    required AppLocalizations? l10n,
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
                  l10n?.comunidadVerificada ?? 'Comunidad verificada',
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
    required AppLocalizations? l10n,
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
                    l10n?.misDonaciones ?? 'Mis donaciones',
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.055,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.002),
                  Text(
                    l10n?.historialYRecibos ?? 'Historial y recibos',
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

  void _iniciarAporte(BuildContext context, String concepto) {
    if (!ModalRestriccionDonacion.verificarYMostrar(context: context)) {
      return;
    }
    Navigator.pushNamed(
      context,
      RealizarAporteScreen.routeName,
      arguments: concepto,
    );
  }

  void _abrirMisDonaciones(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    if (!userProvider.isAuthenticated) {
      ModalRestriccionDonacion.mostrar(context: context);
      return;
    }
    Navigator.pushNamed(
      context,
      MisDonacionesScreen.routeName,
    );
  }
}
