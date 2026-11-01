import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/mis_donaciones_screen.dart';
import 'package:atrio/screens/realizar_aporte_screen.dart';
import 'package:atrio/widgets/atrio_connectivity_alert.dart';
import 'package:atrio/widgets/modal_restriccion_donacion.dart';
import 'package:atrio/widgets/read_only_banner.dart';

import '../l10n/app_localizations.dart';

class DonacionesScreen extends StatelessWidget {
  static const routeName = 'donaciones_screen';
  const DonacionesScreen({super.key});

  // Paleta de colores oficial Atrio
  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFE8ECEF);
  static const Color verdeIcono = Color(0xFF5A7D5A);
  static const Color azulBadge = Color(0xFF00386C);
  static const Color celesteCard = Color(0xFFE8F2F8);

  @override
  Widget build(BuildContext context) {
    // 1. Obtención de métricas dinámicas relativas (Flutter 3.22+)
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    final l10n = AppLocalizations.of(context);
    final userProvider = context.watch<UserProvider>();
    final rawIglesia = userProvider.currentUser?.iglesiaActual.trim();
    final String nombreIglesia = (rawIglesia != null &&
            rawIglesia.isNotEmpty &&
            rawIglesia != 'Sin iglesia seleccionada')
        ? rawIglesia
        : (l10n?.miIglesia ?? 'Mi Iglesia');

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
                padding: EdgeInsetsDirectional.symmetric(
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
                          padding: EdgeInsetsDirectional.all(screenWidth * 0.02),
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
                            padding:
                                EdgeInsetsDirectional.all(screenWidth * 0.02),
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
                          PositionedDirectional(
                            top: screenWidth * 0.015,
                            end: screenWidth * 0.015,
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
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: usableHeight * 0.022,
                      ),
                      child: Column(
                        children: [
                          const ReadOnlyBanner(),
                          // Tarjeta de la Iglesia Verificada
                          _VerifiedChurchCard(
                            churchName: nombreIglesia,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            azulBadge: azulBadge,
                            grisBorde: grisBorde,
                            verifiedLabel:
                                l10n?.comunidadVerificada ?? 'Comunidad verificada',
                          ),
                          SizedBox(height: usableHeight * 0.02),

                          // 1. Diezmo
                          _DonationCategoryTile(
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
                          _DonationCategoryTile(
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
                          _DonationCategoryTile(
                            title: l10n?.campanaEspecial ?? 'Campaña especial',
                            icon: Icons.campaign_outlined,
                            iconColor: verdeIcono,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            grisBorde: grisBorde,
                            onTap: () =>
                                _iniciarAporte(context, 'Campaña especial'),
                          ),
                          SizedBox(height: usableHeight * 0.012),

                          // 4. Ayuda comunitaria
                          _DonationCategoryTile(
                            title: l10n?.ayudaComunitaria ?? 'Ayuda comunitaria',
                            icon: Icons.volunteer_activism_outlined,
                            iconColor: verdeIcono,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            grisBorde: grisBorde,
                            onTap: () =>
                                _iniciarAporte(context, 'Ayuda comunitaria'),
                          ),
                          SizedBox(height: usableHeight * 0.012),

                          // 5. Otro aporte
                          _DonationCategoryTile(
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
                          _HistoryCard(
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            celesteCard: celesteCard,
                            grisBorde: grisBorde,
                            title: l10n?.misDonaciones ?? 'Mis donaciones',
                            subtitle: l10n?.historialYRecibos ??
                                'Historial y recibos',
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

  Future<void> _iniciarAporte(BuildContext context, String concepto) async {
    final bool hasInternet = await AtrioConnectivityAlert.checkAndNotify(
      context,
      onRetry: () => _iniciarAporte(context, concepto),
    );
    if (!hasInternet || !context.mounted) return;

    if (!ModalRestriccionDonacion.verificarDonacionGeneral(context: context)) {
      return;
    }
    Navigator.pushNamed(
      context,
      RealizarAporteScreen.routeName,
      arguments: concepto,
    );
  }

  Future<void> _abrirMisDonaciones(BuildContext context) async {
    final userProvider = context.read<UserProvider>();
    if (!userProvider.isAuthenticated) {
      ModalRestriccionDonacion.mostrar(context: context);
      return;
    }

    final bool hasInternet = await AtrioConnectivityAlert.checkAndNotify(
      context,
      onRetry: () => _abrirMisDonaciones(context),
    );
    if (!hasInternet || !context.mounted) return;

    Navigator.pushNamed(
      context,
      MisDonacionesScreen.routeName,
    );
  }
}

class _VerifiedChurchCard extends StatelessWidget {
  final String churchName;
  final double screenWidth;
  final double usableHeight;
  final Color azulFondo;
  final Color azulBadge;
  final Color grisBorde;
  final String verifiedLabel;

  const _VerifiedChurchCard({
    required this.churchName,
    required this.screenWidth,
    required this.usableHeight,
    required this.azulFondo,
    required this.azulBadge,
    required this.grisBorde,
    required this.verifiedLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.all(screenWidth * 0.035),
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
                        churchName,
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
                  verifiedLabel,
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
}

class _DonationCategoryTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final double screenWidth;
  final double usableHeight;
  final Color azulFondo;
  final Color grisBorde;
  final VoidCallback onTap;

  const _DonationCategoryTile({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.screenWidth,
    required this.usableHeight,
    required this.azulFondo,
    required this.grisBorde,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: usableHeight * 0.075,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          border: Border.all(color: grisBorde),
        ),
        padding: EdgeInsetsDirectional.symmetric(horizontal: screenWidth * 0.045),
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
}

class _HistoryCard extends StatelessWidget {
  final double screenWidth;
  final double usableHeight;
  final Color azulFondo;
  final Color celesteCard;
  final Color grisBorde;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.screenWidth,
    required this.usableHeight,
    required this.azulFondo,
    required this.celesteCard,
    required this.grisBorde,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: usableHeight * 0.085,
        decoration: BoxDecoration(
          color: celesteCard,
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          border: Border.all(color: grisBorde),
        ),
        padding: EdgeInsetsDirectional.symmetric(horizontal: screenWidth * 0.045),
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
                    title,
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.055,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.002),
                  Text(
                    subtitle,
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
