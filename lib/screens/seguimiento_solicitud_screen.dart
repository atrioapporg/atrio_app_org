import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/user_provider.dart';
import '../widgets/modal_restriccion_donacion.dart';
import 'inicio_sesion_screen.dart';

class SeguimientoSolicitudScreen extends StatefulWidget {
  static const routeName = 'seguimiento_solicitud_screen';

  const SeguimientoSolicitudScreen({super.key});

  @override
  State<SeguimientoSolicitudScreen> createState() => _SeguimientoSolicitudScreenState();
}

class _SeguimientoSolicitudScreenState extends State<SeguimientoSolicitudScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _solicitudesApi = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarSolicitudes();
    });
  }

  /// Consulta las solicitudes del usuario en Odoo (GET /requests)
  Future<void> _cargarSolicitudes() async {
    if (!mounted) return;
    final userProvider = context.read<UserProvider>();
    if (!userProvider.isAuthenticated) {
      if (mounted) {
        setState(() {
          _solicitudesApi = [];
          _isLoading = false;
        });
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = userProvider.api;
      final data = await api.requests();
      final dynamic raw = data['requests'] ?? data['items'] ?? data['data'];

      if (raw is List && raw.isNotEmpty && mounted) {
        setState(() {
          _solicitudesApi = raw.map((r) {
            final m = r as Map<String, dynamic>;
            final state = (m['state'] ?? m['status'] ?? 'draft').toString().toLowerCase();
            final type = (m['type'] ?? m['request_type'] ?? '').toString().toLowerCase();

            // Determinar color y texto de estado
            Color statusColor = const Color(0xFFE5A023);
            String statusText = 'En revisión';
            if (state == 'done' ||
                state == 'completed' ||
                state == 'confirmed' ||
                state == 'approved' ||
                state == 'resuelta' ||
                state == 'atendida' ||
                state == 'respondida') {
              statusColor = const Color(0xFF2E7D32);
              statusText = state == 'respondida' ? 'Respondida' : 'Completada';
            } else if (state == 'pending' ||
                state == 'draft' ||
                state == 'received' ||
                state == 'nueva' ||
                state == 'new' ||
                state == 'recibida') {
              statusColor = const Color(0xFF0055A5);
              statusText = 'Recibida';
            } else if (state == 'in_progress' ||
                state == 'scheduled' ||
                state == 'proceso' ||
                state == 'en_proceso' ||
                state == 'en_progreso') {
              statusColor = const Color(0xFFE5A023);
              statusText = 'En proceso';
            } else if (state == 'cancelled' ||
                state == 'canceled' ||
                state == 'rejected' ||
                state == 'cancelada') {
              statusColor = const Color(0xFFC62828);
              statusText = 'Cancelada';
            }

            // Icono y color según tipo
            IconData icon = Icons.assignment_outlined;
            Color iconColor = const Color(0xFF0055A5);
            if (type.contains('pastoral') || type.contains('consej')) {
              icon = Icons.church_outlined;
              iconColor = const Color(0xFF0055A5);
            } else if (type.contains('oracion') || type.contains('prayer')) {
              icon = Icons.pan_tool_alt_outlined;
              iconColor = const Color(0xFF7A8B43);
            } else if (type.contains('comunitaria') || type.contains('social') || type.contains('ayuda')) {
              icon = Icons.groups_outlined;
              iconColor = const Color(0xFF072B4F);
            } else if (type.contains('familiar') || type.contains('family')) {
              icon = Icons.family_restroom_rounded;
              iconColor = const Color(0xFF072B4F);
            } else if (type.contains('enfermo') || type.contains('salud')) {
              icon = Icons.favorite_border_rounded;
              iconColor = const Color(0xFF7A8B43);
            } else if (type.contains('info')) {
              icon = Icons.info_outline_rounded;
              iconColor = const Color(0xFF0055A5);
            }

            final rawDate = m['created_at'] ?? m['date'] ?? m['create_date'];
            String dateFormatted = 'Reciente';
            if (rawDate != null) {
              dateFormatted = rawDate.toString().split('T').first;
            }

            return {
              'title': m['title'] ?? m['name'] ?? 'Solicitud Ministerial',
              'status': m['status_label'] ?? statusText,
              'statusColor': statusColor,
              'dateInfo': dateFormatted,
              'icon': icon,
              'iconColor': iconColor,
              'referencia': m['reference'] ?? 'REQ-${m['id'] ?? '0000'}',
              'detalle': m['message'] ?? m['description'] ?? 'Solicitud registrada y asignada.',
              'respuesta': m['response'] ?? m['pastoral_notes'] ?? m['admin_notes'],
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('[SOLICITUDES] Fallback local activo: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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

    // En modo invitado NO se muestran solicitudes de prueba ni datos de otros usuarios
    final userProvider = context.watch<UserProvider>();
    final bool esInvitado = !userProvider.isAuthenticated;
    final List<Map<String, dynamic>> solicitudes = esInvitado
        ? const []
        : (_solicitudesApi.isNotEmpty
            ? _solicitudesApi
            : const []);

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
                          if (_isLoading)
                            Padding(
                              padding: EdgeInsets.only(bottom: usableHeight * 0.01),
                              child: const LinearProgressIndicator(
                                color: amarilloOro,
                                backgroundColor: Colors.transparent,
                              ),
                            ),
                          // Lista de Solicitudes Desplazable o Estado Vacío
                          Expanded(
                            child: solicitudes.isEmpty
                                ? Center(
                                    child: SingleChildScrollView(
                                      physics: const AlwaysScrollableScrollPhysics(
                                        parent: BouncingScrollPhysics(),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.06,
                                          vertical: usableHeight * 0.02,
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: screenWidth * 0.18,
                                              height: screenWidth * 0.18,
                                              decoration: BoxDecoration(
                                                color: azulFondo.withValues(alpha: 0.08),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                esInvitado
                                                    ? Icons.account_circle_outlined
                                                    : Icons.inbox_outlined,
                                                color: azulFondo,
                                                size: screenWidth * 0.09,
                                              ),
                                            ),
                                            SizedBox(height: usableHeight * 0.02),
                                            Text(
                                              esInvitado
                                                  ? (l10n?.modoInvitado ?? 'Modo invitado')
                                                  : (l10n?.sinSolicitudesRegistradas ??
                                                      'No tienes solicitudes registradas'),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: azulFondo,
                                                fontSize: screenWidth * 0.045,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: usableHeight * 0.01),
                                            Text(
                                              esInvitado
                                                  ? (l10n?.solicitudesInvitadoDesc ??
                                                      'En modo invitado no se registran ni muestran solicitudes. Inicia sesión para crear peticiones y darles seguimiento.')
                                                  : (l10n?.sinSolicitudesRegistradas ??
                                                      'Tus peticiones pastorales aparecerán aquí.'),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: screenWidth * 0.034,
                                                height: 1.35,
                                              ),
                                            ),
                                            if (esInvitado) ...[
                                              SizedBox(height: usableHeight * 0.025),
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  Navigator.pushNamed(
                                                    context,
                                                    InicioSesionScreen.routeName,
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: amarilloOro,
                                                  foregroundColor: azulFondo,
                                                  elevation: 0,
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: screenWidth * 0.06,
                                                    vertical: usableHeight * 0.014,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(
                                                      screenWidth * 0.03,
                                                    ),
                                                  ),
                                                ),
                                                icon: Icon(
                                                  Icons.login_rounded,
                                                  size: screenWidth * 0.045,
                                                ),
                                                label: Text(
                                                  l10n?.iniciarSesion ?? 'Iniciar sesión',
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.038,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _cargarSolicitudes,
                                    color: amarilloOro,
                                    child: ListView.separated(
                                      physics: const AlwaysScrollableScrollPhysics(
                                        parent: BouncingScrollPhysics(),
                                      ),
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
                              onPressed: () async {
                                if (!ModalRestriccionDonacion.verificarAutenticacion(
                                  context: context,
                                  mensaje: l10n?.solicitudRequiereSesion,
                                )) {
                                  return;
                                }
                                await Navigator.pushNamed(
                                  context,
                                  'tipos_solicitud_screen',
                                );
                                _cargarSolicitudes();
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
                    if (item['respuesta'] != null &&
                        item['respuesta'].toString().trim().isNotEmpty) ...[
                      Divider(height: usableHeight * 0.025, color: grisBorde),
                      Row(
                        children: [
                          Icon(
                            Icons.mark_chat_read_rounded,
                            size: screenWidth * 0.042,
                            color: const Color(0xFF2E7D32),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            'Respuesta pastoral:',
                            style: TextStyle(
                              color: const Color(0xFF2E7D32),
                              fontSize: screenWidth * 0.032,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: usableHeight * 0.008),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.025),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: Text(
                          item['respuesta'].toString(),
                          style: TextStyle(
                            color: const Color(0xFF1B5E20),
                            fontSize: screenWidth * 0.034,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
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
