import 'package:atrio/widgets/odoo_pago_dialog.dart';
import 'package:flutter/material.dart';

class ConfirmarDonacionScreen extends StatelessWidget {
  static const routeName = 'confirmar_donacion_screen';
  const ConfirmarDonacionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Recepción dinámica de datos desde RealizarAporteScreen
    final Map donacionData =
        (ModalRoute.of(context)?.settings.arguments as Map?) ??
        {
          'comunidad': 'Comunidad de Esperanza',
          'concepto': 'Ofrenda',
          'monto': 'RD\$1,000.00',
          'frecuencia': 'Una sola vez',
          'metodoPago': 'Visa •••• 1234',
        };

    final String comunidad = donacionData['comunidad'];
    final String concepto = donacionData['concepto'];
    final String monto = donacionData['monto'];
    final String frecuencia = donacionData['frecuencia'];
    final String metodoPago = donacionData['metodoPago'];

    // 2. Métricas relativas dinámicas (Flutter 3.22+)
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    // Paleta de diseño Atrio
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);
    const Color grisBorde = Color(0xFFE8ECEF);
    const Color textoGris = Color(0xFF6C757D);

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: true,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight,
          child: Column(
            children: [
              // 3. Encabezado Superior (Botón Volver + Título + Campana)
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
                        'Revisa tu donación',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.058,
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
                          padding: EdgeInsets.all(screenWidth * 0.018),
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

              // 4. Contenedor Blanco Inferior con Resumen y Confirmación
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
                        horizontal: screenWidth * 0.045,
                        vertical: usableHeight * 0.025,
                      ),
                      child: Column(
                        children: [
                          // Tarjeta de Resumen Detallado
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.04,
                              ),
                              border: Border.all(color: grisBorde),
                            ),
                            padding: EdgeInsets.all(screenWidth * 0.04),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Resumen de tu donación',
                                  style: TextStyle(
                                    color: azulFondo,
                                    fontSize: screenWidth * 0.052,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: usableHeight * 0.02),
                                // 1. Para
                                _buildSummaryRow(
                                  label: 'Para',
                                  valueWidget: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(
                                          screenWidth * 0.012,
                                        ),
                                        decoration: BoxDecoration(
                                          color: azulFondo,
                                          borderRadius: BorderRadius.circular(
                                            screenWidth * 0.015,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.church_rounded,
                                          color: Colors.white,
                                          size: screenWidth * 0.045,
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Text(
                                        comunidad,
                                        style: TextStyle(
                                          color: azulFondo,
                                          fontSize: screenWidth * 0.035,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  screenWidth: screenWidth,
                                  usableHeight: usableHeight,
                                  textoGris: textoGris,
                                ),
                                Divider(
                                  height: usableHeight * 0.025,
                                  color: grisBorde,
                                ),
                                // 2. Concepto
                                _buildSummaryRow(
                                  label: 'Concepto',
                                  valueWidget: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.favorite_border_rounded,
                                        color: amarilloOro,
                                        size: screenWidth * 0.05,
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Text(
                                        concepto,
                                        style: TextStyle(
                                          color: azulFondo,
                                          fontSize: screenWidth * 0.035,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  screenWidth: screenWidth,
                                  usableHeight: usableHeight,
                                  textoGris: textoGris,
                                ),
                                Divider(
                                  height: usableHeight * 0.025,
                                  color: grisBorde,
                                ),
                                // 3. Monto
                                _buildSummaryRow(
                                  label: 'Monto',
                                  valueWidget: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: screenWidth * 0.05,
                                        height: screenWidth * 0.055,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF5A7D5A),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '\$',
                                            style: TextStyle(
                                              color: const Color(0xFF5A7D5A),
                                              fontSize: screenWidth * 0.028,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Text(
                                        monto,
                                        style: TextStyle(
                                          color: azulFondo,
                                          fontSize: screenWidth * 0.035,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  screenWidth: screenWidth,
                                  usableHeight: usableHeight,
                                  textoGris: textoGris,
                                ),
                                Divider(
                                  height: usableHeight * 0.025,
                                  color: grisBorde,
                                ),
                                // 4. Frecuencia
                                _buildSummaryRow(
                                  label: 'Frecuencia',
                                  valueWidget: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.event_outlined,
                                        color: const Color(0xFF0055A5),
                                        size: screenWidth * 0.05,
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Text(
                                        frecuencia,
                                        style: TextStyle(
                                          color: azulFondo,
                                          fontSize: screenWidth * 0.035,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  screenWidth: screenWidth,
                                  usableHeight: usableHeight,
                                  textoGris: textoGris,
                                ),
                                Divider(
                                  height: usableHeight * 0.025,
                                  color: grisBorde,
                                ),
                                // 5. Método de pago
                                _buildSummaryRow(
                                  label: 'Método de pago',
                                  valueWidget: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.credit_card_rounded,
                                        color: azulFondo,
                                        size: screenWidth * 0.05,
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      Text(
                                        metodoPago,
                                        style: TextStyle(
                                          color: azulFondo,
                                          fontSize: screenWidth * 0.035,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  screenWidth: screenWidth,
                                  usableHeight: usableHeight,
                                  textoGris: textoGris,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.03),
                          // Escudo de Seguridad
                          Icon(
                            Icons.shield_outlined,
                            color: azulFondo,
                            size: screenWidth * 0.12,
                          ),
                          SizedBox(height: usableHeight * 0.01),
                          Text(
                            'Tu donación es segura',
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.055,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.01),
                          Text(
                            'Usamos conexión cifrada para proteger\ntu información y tu aporte.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textoGris,
                              fontSize: screenWidth * 0.038,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.035),
                          // Botón Confirmar donación con candado
                          SizedBox(
                            width: screenWidth,
                            height: usableHeight * 0.062,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: amarilloOro,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.03,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                OdooPagoDialog.mostrarConfirmacionPago(
                                  context: context,
                                  concepto: '$concepto ($comunidad)',
                                  monto: monto,
                                  metodoPago: metodoPago,
                                  onConfirmado: () {
                                    Navigator.popUntil(
                                      context,
                                      ModalRoute.withName(
                                        'inicio_atrio_screen',
                                      ),
                                    );
                                  },
                                );
                              },
                              icon: Icon(
                                Icons.lock_outline_rounded,
                                color: Colors.white,
                                size: screenWidth * 0.05,
                              ),
                              label: Text(
                                'Confirmar donación',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.050,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
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

  // Widget auxiliar para filas con ícono y valor personalizado
  Widget _buildSummaryRow({
    required String label,
    required Widget valueWidget,
    required double screenWidth,
    required double usableHeight,
    required Color textoGris,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: textoGris,
              fontSize: screenWidth * 0.040,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.03),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: valueWidget,
          ),
        ),
      ],
    );
  }
}
