import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../widgets/modal_restriccion_donacion.dart';
import 'seguimiento_solicitud_screen.dart';

class TiposSolicitudScreen extends StatelessWidget {
  static const routeName = 'tipos_solicitud_screen';
  const TiposSolicitudScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Métricas relativas dinámicas (Flutter 3.22+)
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    final l10n = AppLocalizations.of(context);

    // Paleta de diseño Atrio
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);
    const Color grisBorde = Color(0xFFE5E5E5);

    final List<Map<String, dynamic>> tiposSolicitud = [
      {
        'title': l10n?.peticionDeOracion ?? 'Petición de oración',
        'icon': Icons.pan_tool_alt_outlined,
        'iconColor': const Color(0xFF7A8B43),
        'route': 'nueva_solicitud_screen',
      },
      {
        'title': l10n?.orientacionPastoral ?? 'Orientación pastoral',
        'icon': Icons.church_outlined,
        'iconColor': const Color(0xFF0055A5),
        'route': 'nueva_solicitud_screen',
      },
      {
        'title': l10n?.consejeriaFamiliar ?? 'Consejería familiar',
        'icon': Icons.family_restroom_rounded,
        'iconColor': const Color(0xFF072B4F),
        'route': 'nueva_solicitud_screen',
      },
      {
        'title': l10n?.visitaAEnfermos ?? 'Visita a enfermos',
        'icon': Icons.favorite_border_rounded,
        'iconColor': const Color(0xFF7A8B43),
        'route': 'nueva_solicitud_screen',
      },
      {
        'title': l10n?.ayudaComunitaria ?? 'Ayuda comunitaria',
        'icon': Icons.groups_outlined,
        'iconColor': const Color(0xFF072B4F),
        'route': 'nueva_solicitud_screen',
      },
      {
        'title': l10n?.otraSolicitud ?? 'Otra solicitud',
        'icon': Icons.edit_document,
        'iconColor': const Color(0xFF0055A5),
        'route': 'nueva_solicitud_screen',
      },
    ];

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Expanded(
                      child: Text(
                        l10n?.comoPodemosAyudarte ?? '¿Cómo podemos\nayudarte?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.058,
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
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

              // 3. Contenedor Blanco Inferior con Lista de Opciones
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
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: usableHeight * 0.022,
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: tiposSolicitud.length,
                              separatorBuilder: (context, index) =>
                                  SizedBox(height: usableHeight * 0.014),
                              itemBuilder: (context, index) {
                                final item = tiposSolicitud[index];
                                return _buildOptionTile(
                                  icon: item['icon'] as IconData,
                                  iconColor: item['iconColor'] as Color,
                                  title: item['title'] as String,
                                  screenWidth: screenWidth,
                                  usableHeight: usableHeight,
                                  azulFondo: azulFondo,
                                  grisBorde: grisBorde,
                                  onTap: () {
                                    if (!ModalRestriccionDonacion.verificarAutenticacion(
                                      context: context,
                                      mensaje: l10n?.solicitudRequiereSesion,
                                    )) {
                                      return;
                                    }
                                    if (item['route'] != null) {
                                      Navigator.pushNamed(
                                        context,
                                        item['route'] as String,
                                        arguments: {'tipo': item['title']},
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.015),
                          SizedBox(
                            width: screenWidth,
                            height: usableHeight * 0.062,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: amarilloOro,
                                foregroundColor: azulFondo,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.035,
                                  ),
                                ),
                              ),
                              icon: Icon(
                                Icons.history_rounded,
                                size: screenWidth * 0.055,
                              ),
                              label: Text(
                                'Historial de solicitudes',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.042,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  SeguimientoSolicitudScreen.routeName,
                                );
                              },
                            ),
                          ),
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

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.045),
        child: Row(
          children: [
            Container(
              width: screenWidth * 0.11,
              height: screenWidth * 0.11,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
              ),
              child: Icon(icon, color: iconColor, size: screenWidth * 0.06),
            ),
            SizedBox(width: screenWidth * 0.040),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.042,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: screenWidth * 0.060,
            ),
          ],
        ),
      ),
    );
  }
}
