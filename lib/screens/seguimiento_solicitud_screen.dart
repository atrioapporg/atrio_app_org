import 'package:flutter/material.dart';

class SeguimientoSolicitudScreen extends StatelessWidget {
  static const routeName = 'seguimiento_solicitud_screen';

  const SeguimientoSolicitudScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

    // Listado de solicitudes con su estado según 15_seguimiento_solicitudes.png
    final List<Map<String, dynamic>> solicitudes = [
      {
        'title': 'Orientación pastoral',
        'status': 'Programada',
        'statusColor': amarilloOro,
        'dateInfo': 'Martes · 4:00 p. m.',
        'icon': Icons.church_outlined,
        'iconColor': const Color(0xFF0055A5),
      },
      {
        'title': 'Petición de oración',
        'status': 'Recibida',
        'statusColor': const Color(0xFF0055A5),
        'dateInfo': null,
        'icon': Icons.pan_tool_alt_outlined,
        'iconColor': const Color(0xFF7A8B43),
      },
      {
        'title': 'Ayuda comunitaria',
        'status': 'En revisión',
        'statusColor': amarilloOro,
        'dateInfo': null,
        'icon': Icons.groups_outlined,
        'iconColor': azulFondo,
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
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: screenWidth * 0.085,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        Text(
                          'Mis solicitudes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.068,
                            fontWeight: FontWeight.bold,
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
                        vertical: usableHeight * 0.025,
                      ),
                      child: Column(
                        children: [
                          // Lista de Solicitudes Desplazable
                          Expanded(
                            child: ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              itemCount: solicitudes.length,
                              separatorBuilder: (context, index) =>
                                  SizedBox(height: usableHeight * 0.015),
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
                                  onTap: () {},
                                );
                              },
                            ),
                          ),

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
                                    screenWidth * 0.03,
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
                                'Nueva solicitud',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.055,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.01),
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

  // Componente: Tarjeta de Solicitud Individual
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
          vertical: usableHeight * 0.018,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          border: Border.all(color: grisBorde),
        ),
        child: Row(
          children: [
            // Icono del tipo de solicitud
            Icon(icon, color: iconColor, size: screenWidth * 0.095),
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
                      fontSize: screenWidth * 0.060,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.003),
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: screenWidth * 0.038,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (dateInfo != null) ...[
                    SizedBox(height: usableHeight * 0.002),
                    Text(
                      dateInfo,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.03,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Flecha indicadora derecha
            Icon(
              Icons.chevron_right_rounded,
              color: azulFondo,
              size: screenWidth * 0.06,
            ),
          ],
        ),
      ),
    );
  }
}
