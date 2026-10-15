import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/user_provider.dart';
import 'donaciones_screen.dart';

class MisDonacionesScreen extends StatefulWidget {
  static const routeName = 'mis_donaciones_screen';

  const MisDonacionesScreen({super.key});

  @override
  State<MisDonacionesScreen> createState() => _MisDonacionesScreenState();
}

class _MisDonacionesScreenState extends State<MisDonacionesScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _donacionesApi = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDonaciones();
    });
  }

  /// Consulta el historial real de donaciones del usuario en Odoo (GET /donations/mine)
  Future<void> _cargarDonaciones() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final api = context.read<UserProvider>().api;
      final data = await api.myDonations();
      final dynamic raw = data['donations'] ?? data['items'] ?? data['data'];

      if (raw is List && raw.isNotEmpty && mounted) {
        setState(() {
          _donacionesApi = raw.map((d) {
            final m = d as Map<String, dynamic>;
            final amount = m['amount'] ?? m['monto'] ?? '0.00';
            final currency = m['currency'] ?? 'DOP';
            final state = (m['state'] ?? m['status'] ?? 'completed').toString().toLowerCase();
            final isDone = state == 'completed' || state == 'done' || state == 'approved';

            return {
              'title': m['name'] ?? m['title'] ?? 'Aporte Ministerial',
              'monto': '\$ $amount $currency',
              'status': isDone ? 'Completada' : 'En proceso',
              'statusColor': isDone ? const Color(0xFF2E7D32) : const Color(0xFF0055A5),
              'dateInfo': m['date'] ?? m['create_date'] ?? 'Reciente',
              'icon': Icons.favorite_border_rounded,
              'iconColor': const Color(0xFFE5A023),
              'referencia': m['reference'] ?? 'DON-${m['id'] ?? '0000'}',
              'metodoPago': m['payment_method'] ?? 'Transferencia / Online',
              'destino': m['church_name'] ?? 'Comunidad ATRIO',
              'detalle': m['notes'] ?? 'Aporte voluntario para sostenimiento de la obra.',
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('[DONACIONES] Fallback local activo: $e');
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
    const Color verdeIcono = Color(0xFF5A7D5A);

    // Si la API devolvió donaciones reales las usamos; si no, mostramos el listado base
    final List<Map<String, dynamic>> donaciones = _donacionesApi.isNotEmpty
        ? _donacionesApi
        : [
            {
              'title': l10n?.diezmo ?? 'Diezmo',
              'monto': '\$ 75.00 USD',
              'status': l10n?.estadoCompletada ?? 'Completada',
              'statusColor': const Color(0xFF2E7D32),
              'dateInfo': l10n?.fechaDiezmoMock ?? '15 Oct 2026 · 10:30 a. m.',
              'icon': Icons.church_outlined,
              'iconColor': amarilloOro,
              'referencia': 'DON-2026-0104',
              'metodoPago':
                  l10n?.metodoTarjetaDebitoVisa ?? 'Tarjeta de débito (Visa)',
              'destino':
                  l10n?.destinoFondoGeneralMinisterial ?? 'Fondo General Ministerial',
              'detalle':
                  l10n?.detalleDiezmoMock ??
                  'Aporte de diezmo mensual para el sostenimiento del templo y ministerio pastoral.',
            },
            {
              'title': l10n?.ofrenda ?? 'Ofrenda',
              'monto': '\$ 25.00 USD',
              'status': l10n?.estadoCompletada ?? 'Completada',
              'statusColor': const Color(0xFF2E7D32),
              'dateInfo': l10n?.fechaOfrendaMock ?? '08 Oct 2026 · 7:15 p. m.',
              'icon': Icons.favorite_border_rounded,
              'iconColor': amarilloOro,
              'referencia': 'DON-2026-0092',
              'metodoPago': l10n?.metodoTransferenciaACH ?? 'Transferencia ACH',
              'destino':
                  l10n?.destinoCultoAdoracionDominical ??
                  'Culto de Adoración Dominical',
              'detalle':
                  l10n?.detalleOfrendaMock ??
                  'Ofrenda voluntaria de gratitud y adoración durante el servicio de alabanza.',
            },
            {
              'title': l10n?.campanaEspecial ?? 'Campaña especial',
              'monto': '\$ 100.00 USD',
              'status': l10n?.estadoEnProceso ?? 'En proceso',
              'statusColor': const Color(0xFF0055A5),
              'dateInfo': l10n?.fechaCampanaMock ?? '28 Sep 2026 · 4:20 p. m.',
              'icon': Icons.campaign_outlined,
              'iconColor': verdeIcono,
              'referencia': 'DON-2026-0081',
              'metodoPago':
                  l10n?.metodoTarjetaCreditoMastercard ??
                  'Tarjeta de crédito (Mastercard)',
              'destino':
                  l10n?.destinoCampanaMock ?? 'Campaña "Construyendo Esperanza 2026"',
              'detalle':
                  l10n?.detalleCampanaMock ??
                  'Aporte especial voluntario destinado a las obras de remodelación y mantenimiento del templo.',
            },
            {
              'title': l10n?.ayudaComunitaria ?? 'Ayuda comunitaria',
              'monto': '\$ 40.00 USD',
              'status': l10n?.estadoCompletada ?? 'Completada',
              'statusColor': const Color(0xFF2E7D32),
              'dateInfo': l10n?.fechaAyudaMock ?? '14 Sep 2026 · 11:00 a. m.',
              'icon': Icons.volunteer_activism_outlined,
              'iconColor': verdeIcono,
              'referencia': 'DON-2026-0065',
              'metodoPago':
                  l10n?.metodoPayPalSaldoDigital ?? 'PayPal / Saldo digital',
              'destino':
                  l10n?.destinoProgramaManosQueBendicen ??
                  'Programa "Manos que Bendicen"',
              'detalle':
                  l10n?.detalleAyudaMock ??
                  'Donación benéfica para canastas de alimentos básicos y medicinas para familias vulnerables.',
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
                        SizedBox(width: screenWidth * 0.035),
                        Text(
                          l10n?.misDonaciones ?? 'Mis donaciones',
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

              // 3. Contenedor Blanco Inferior con Lista de Donaciones y Botón
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
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: LinearProgressIndicator(
                                color: azulFondo,
                                minHeight: 2,
                              ),
                            ),
                          // Lista de Donaciones Desplazable
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: _cargarDonaciones,
                              color: azulFondo,
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                itemCount: donaciones.length,
                                separatorBuilder: (context, index) =>
                                    SizedBox(height: usableHeight * 0.014),
                              itemBuilder: (context, index) {
                                final item = donaciones[index];
                                return _buildDonationCard(
                                  title: item['title'] as String,
                                  monto: item['monto'] as String,
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
                                    _mostrarDetalleDonacion(
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

                          // Botón Inferior "Nueva donación"
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
                                  DonacionesScreen.routeName,
                                );
                              },
                              child: Text(
                                l10n?.nuevaDonacion ?? 'Nueva donación',
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

  // Componente: Tarjeta de Donación Individual
  Widget _buildDonationCard({
    required String title,
    required String monto,
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
            // Icono del tipo de donación
            Container(
              padding: EdgeInsets.all(screenWidth * 0.025),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: screenWidth * 0.075),
            ),
            SizedBox(width: screenWidth * 0.035),

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
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.022,
                          vertical: usableHeight * 0.002,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.015,
                          ),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: screenWidth * 0.030,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (dateInfo != null) ...[
                        SizedBox(width: screenWidth * 0.02),
                        Flexible(
                          child: Text(
                            dateInfo,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: screenWidth * 0.028,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Monto destacado a la derecha
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  monto,
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.042,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: usableHeight * 0.002),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: screenWidth * 0.055,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Modal con el detalle completo de la donación (preparado para Odoo 19)
  void _mostrarDetalleDonacion({
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
                          l10n?.idOdoo(item['referencia'] as String? ?? 'DON-2026-0001') ??
                              'ID Odoo: ${item['referencia'] ?? 'DON-2026-0001'}',
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
                    // Monto destacado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n?.montoAportado ?? 'Monto aportado:',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: screenWidth * 0.034,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          item['monto'] as String,
                          style: TextStyle(
                            color: azulFondo,
                            fontSize: screenWidth * 0.048,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Divider(height: usableHeight * 0.025, color: grisBorde),

                    if (item['dateInfo'] != null) ...[
                      _buildDetailRow(
                        icon: Icons.calendar_today_rounded,
                        label: l10n?.fechaYHora ?? 'Fecha y hora:',
                        value: item['dateInfo'] as String,
                        screenWidth: screenWidth,
                        azulFondo: azulFondo,
                      ),
                      SizedBox(height: usableHeight * 0.012),
                    ],

                    if (item['metodoPago'] != null) ...[
                      _buildDetailRow(
                        icon: Icons.credit_card_rounded,
                        label: l10n?.metodo ?? 'Método:',
                        value: item['metodoPago'] as String,
                        screenWidth: screenWidth,
                        azulFondo: azulFondo,
                      ),
                      SizedBox(height: usableHeight * 0.012),
                    ],

                    if (item['destino'] != null) ...[
                      _buildDetailRow(
                        icon: Icons.flag_outlined,
                        label: l10n?.destino ?? 'Destino:',
                        value: item['destino'] as String,
                        screenWidth: screenWidth,
                        azulFondo: azulFondo,
                      ),
                      SizedBox(height: usableHeight * 0.012),
                    ],

                    Divider(height: usableHeight * 0.020, color: grisBorde),

                    Text(
                      l10n?.detalleDelAporte ?? 'Detalle del aporte:',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.032,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.006),
                    Text(
                      item['detalle'] as String? ??
                          (l10n?.aporteVoluntarioRegistrado ??
                              'Aporte voluntario registrado en ATRIO.'),
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

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required double screenWidth,
    required Color azulFondo,
  }) {
    return Row(
      children: [
        Icon(icon, size: screenWidth * 0.042, color: azulFondo),
        SizedBox(width: screenWidth * 0.02),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: screenWidth * 0.033,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: screenWidth * 0.02),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: azulFondo,
              fontSize: screenWidth * 0.034,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
