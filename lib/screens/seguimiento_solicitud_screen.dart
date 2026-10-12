import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class SeguimientoSolicitudScreen extends StatelessWidget {
  static const routeName = 'seguimiento_solicitud_screen';

  const SeguimientoSolicitudScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 1. Obtención de métricas dinámicas relativas (Flutter 3.22+)
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

    // Listado de 5 solicitudes de relleno (mock) según los tipos de solicitud disponibles
    final List<Map<String, dynamic>> solicitudes = [
      {
        'title': l10n?.orientacionPastoral ?? 'Orientación pastoral',
        'status': l10n?.estadoProgramada ?? 'Programada',
        'statusColor': amarilloOro,
        'dateInfo': l10n?.fechaMartesHora ?? 'Martes · 4:00 p. m.',
        'icon': Icons.church_outlined,
        'iconColor': const Color(0xFF0055A5),
        'referencia': 'REQ-2026-0041',
        'detalle':
            l10n?.detalleOrientacionPastoral ??
            'Cita de acompañamiento espiritual y orientación pastoral presencial con el pastor titular.',
      },
      {
        'title': l10n?.peticionDeOracion ?? 'Petición de oración',
        'status': l10n?.estadoRecibida ?? 'Recibida',
        'statusColor': const Color(0xFF0055A5),
        'dateInfo': null,
        'icon': Icons.pan_tool_alt_outlined,
        'iconColor': const Color(0xFF7A8B43),
        'referencia': 'REQ-2026-0038',
        'detalle':
            l10n?.detallePeticionOracion ??
            'Petición de intercesión por pronta recuperación de salud y bienestar familiar en el culto de oración.',
      },
      {
        'title': l10n?.ayudaComunitaria ?? 'Ayuda comunitaria',
        'status': l10n?.estadoEnRevision ?? 'En revisión',
        'statusColor': amarilloOro,
        'dateInfo': null,
        'icon': Icons.groups_outlined,
        'iconColor': azulFondo,
        'referencia': 'REQ-2026-0035',
        'detalle':
            l10n?.detalleAyudaComunitaria ??
            'Solicitud de canasta de alimentos básicos y apoyo solidario para una familia en situación de necesidad.',
      },
      {
        'title': l10n?.consejeriaFamiliar ?? 'Consejería familiar',
        'status': l10n?.estadoConfirmada ?? 'Confirmada',
        'statusColor': const Color(0xFF2E7D32),
        'dateInfo': l10n?.fechaJuevesHora ?? 'Jueves · 5:30 p. m.',
        'icon': Icons.family_restroom_rounded,
        'iconColor': azulFondo,
        'referencia': 'REQ-2026-0029',
        'detalle':
            l10n?.detalleConsejeriaFamiliar ??
            'Sesión de consejería familiar y diálogo guiado por el equipo ministerial de la iglesia.',
      },
      {
        'title': l10n?.visitaAEnfermos ?? 'Visita a enfermos',
        'status': l10n?.estadoEnProceso ?? 'En proceso',
        'statusColor': const Color(0xFF0055A5),
        'dateInfo': l10n?.fechaViernesHora ?? 'Viernes · 10:00 a. m.',
        'icon': Icons.favorite_border_rounded,
        'iconColor': const Color(0xFF7A8B43),
        'referencia': 'REQ-2026-0022',
        'detalle':
            l10n?.detalleVisitaEnfermos ??
            'Visita domiciliaria del equipo de visitación pastoral para ministración y oración por sanidad.',
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
              // 2. Encabezado Superior (Título con Botón Volver)
              Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: usableHeight * 0.015),
                    // Título con botón de retroceso (Back <-)
                    Row(
                      children: [
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
                        // Fin botón de retroceso (Back <-)
                        SizedBox(width: screenWidth * 0.035),
                        Text(
                          l10n?.misSolicitudes ?? 'Mis solicitudes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.065,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.02),
                  ],
                ),
              ),

              // 3. Contenedor Blanco Inferior con Lista de Solicitudes y Botón
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
                          // Lista de Solicitudes Desplazable
                          Expanded(
                            child: ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: solicitudes.length,
                              separatorBuilder: (context, index) =>
                                  SizedBox(height: usableHeight * 0.014),
                              itemBuilder: (context, index) {
                                final item = solicitudes[index];
                                return _buildRequestCard(
                                  title: item['title'] as String,
                                  status: item['status'] as String,
                                  statusColor: item['statusColor'] as Color,
                                  dateInfo: item['dateInfo'] as String?,
                                  icon: item['icon'] as IconData,
                                  iconColor: item['iconColor'] as Color,
                                  screenWidth: screenWidth,
                                  usableHeight: usableHeight,
                                  azulFondo: azulFondo,
                                  grisBorde: grisBorde,
                                  onTap: () {
                                    _mostrarDetalleSolicitud(
                                      context: context,
                                      item: item,
                                      screenWidth: screenWidth,
                                      usableHeight: usableHeight,
                                      azulFondo: azulFondo,
                                      blancoFondo: blancoFondo,
                                      grisBorde: grisBorde,
                                      amarilloOro: amarilloOro,
                                      l10n: l10n,
                                    );
                                  },
                                );
                              },
                            ),
                          ),

                          SizedBox(height: usableHeight * 0.015),

                          // Botón Inferior "Nueva solicitud"
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
                                    screenWidth * 0.035,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  'tipos_solicitud_screen',
                                );
                              },
                              child: Text(
                                l10n?.nuevaSolicitud ?? 'Nueva solicitud',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.048,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.008),
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

  // Componente: Tarjeta de Solicitud Individual (Fiel a Foto 2)
  Widget _buildRequestCard({
    required String title,
    required String status,
    required Color statusColor,
    required String? dateInfo,
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
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.045,
          vertical: usableHeight * 0.016,
        ),
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
        child: Row(
          children: [
            // Icono del tipo de solicitud
            Icon(icon, color: iconColor, size: screenWidth * 0.090),
            SizedBox(width: screenWidth * 0.04),

            // Textos de información (Título, Estado, Fecha)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.003),
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (dateInfo != null) ...[
                    SizedBox(height: usableHeight * 0.002),
                    Text(
                      dateInfo,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.030,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Flecha indicadora derecha
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: screenWidth * 0.06,
            ),
          ],
        ),
      ),
    );
  }

  // Modal con el detalle completo de la solicitud (preparado para Odoo 19)
  void _mostrarDetalleSolicitud({
    required BuildContext context,
    required Map<String, dynamic> item,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color blancoFondo,
    required Color grisBorde,
    required Color amarilloOro,
    AppLocalizations? l10n,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final safeBottom = MediaQuery.of(ctx).padding.bottom;
        return Container(
          padding: EdgeInsets.fromLTRB(
            screenWidth * 0.06,
            usableHeight * 0.02,
            screenWidth * 0.06,
            usableHeight * 0.03 + safeBottom,
          ),
          decoration: BoxDecoration(
            color: blancoFondo,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(screenWidth * 0.08),
              topRight: Radius.circular(screenWidth * 0.08),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra indicadora de arrastre
              Center(
                child: Container(
                  width: screenWidth * 0.12,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: usableHeight * 0.02),

              // Encabezado del modal: Icono + Título + Referencia
              Row(
                children: [
                  Container(
                    width: screenWidth * 0.13,
                    height: screenWidth * 0.13,
                    decoration: BoxDecoration(
                      color: (item['iconColor'] as Color).withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: item['iconColor'] as Color,
                      size: screenWidth * 0.075,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.035),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            color: azulFondo,
                            fontSize: screenWidth * 0.048,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: usableHeight * 0.003),
                        Text(
                          l10n?.idOdoo(item['referencia'] as String? ?? 'REQ-2026-0001') ??
                              'ID Odoo: ${item['referencia'] ?? 'REQ-2026-0001'}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: screenWidth * 0.030,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: usableHeight * 0.006,
                    ),
                    decoration: BoxDecoration(
                      color: (item['statusColor'] as Color).withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                    child: Text(
                      item['status'] as String,
                      style: TextStyle(
                        color: item['statusColor'] as Color,
                        fontSize: screenWidth * 0.032,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: usableHeight * 0.025),

              // Contenedor de Detalles
              Container(
                width: screenWidth,
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  border: Border.all(color: grisBorde),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item['dateInfo'] != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: screenWidth * 0.042,
                            color: azulFondo,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            item['dateInfo'] as String,
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.036,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Divider(height: usableHeight * 0.025, color: grisBorde),
                    ],
                    Text(
                      l10n?.detalleDeLaSolicitud ?? 'Detalle de la solicitud:',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.032,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.006),
                    Text(
                      item['detalle'] as String? ??
                          (l10n?.solicitudRegistradaAsignada ??
                              'Solicitud registrada y asignada al equipo ministerial.'),
                      style: TextStyle(
                        color: azulFondo,
                        fontSize: screenWidth * 0.035,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: usableHeight * 0.025),

              // Botón de cerrar
              SizedBox(
                width: screenWidth,
                height: usableHeight * 0.055,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azulFondo,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    l10n?.entendido ?? 'Entendido',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
