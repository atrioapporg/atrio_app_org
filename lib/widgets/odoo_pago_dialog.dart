import 'package:flutter/material.dart';
import 'package:atrio/l10n/app_localizations.dart';

/// Aviso temporal para la sección de Donaciones mientras se completa
/// la etapa de prueba y la verificación legal y técnica (KYC) de las iglesias.
///
/// Reemplaza temporalmente el modal "Confirmar Transacción" y oculta el modal
/// "¡Aporte Exitoso!" independientemente de que la iglesia esté registrada o verificada.
class OdooPagoDialog {
  static Future<void> mostrarConfirmacionPago({
    required BuildContext context,
    required String concepto,
    required String monto,
    required String metodoPago,
    required VoidCallback onConfirmado,
    double? montoNumerico,
    String? receiptBase64,
    String? receiptFilename,
    String? mensajeApoyo,
    bool esAnonimo = false,
    String? donorName,
    String? donorEmail,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DonacionDisponibleProximamenteSheet(),
    );
  }
}

class _DonacionDisponibleProximamenteSheet extends StatelessWidget {
  const _DonacionDisponibleProximamenteSheet();

  static const Color _azulFondo = Color(0xFF072B4F);
  static const Color _amarilloOro = Color(0xFFE5A023);
  static const Color _blancoFondo = Color(0xFFFAF7F0);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    return Container(
      width: screenWidth,
      padding: EdgeInsetsDirectional.fromSTEB(
        screenWidth * 0.06,
        usableHeight * 0.025,
        screenWidth * 0.06,
        usableHeight * 0.03 + safeAreaBottom,
      ),
      decoration: BoxDecoration(
        color: _blancoFondo,
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(screenWidth * 0.08),
          topEnd: Radius.circular(screenWidth * 0.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: screenWidth * 0.12,
            height: screenWidth * 0.012,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(screenWidth * 0.01),
            ),
          ),
          SizedBox(height: usableHeight * 0.025),
          Container(
            width: screenWidth * 0.16,
            height: screenWidth * 0.16,
            decoration: const BoxDecoration(
              color: _azulFondo,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.schedule_rounded,
              color: _amarilloOro,
              size: screenWidth * 0.08,
            ),
          ),
          SizedBox(height: usableHeight * 0.018),
          Text(
            l10n.donacionesDeshabilitadasKycTitulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _azulFondo,
              fontSize: screenWidth * 0.052,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: usableHeight * 0.01),
          Text(
            l10n.donacionesDeshabilitadasKycMensaje,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: screenWidth * 0.035,
              height: 1.38,
            ),
          ),
          SizedBox(height: usableHeight * 0.03),
          SizedBox(
            width: screenWidth,
            height: usableHeight * 0.062 < 50 ? 50 : usableHeight * 0.062,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _amarilloOro,
                foregroundColor: _azulFondo,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.entendido,
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
  }
}

/// Modal nativo de gratitud pastoral desplegado automáticamente cuando el usuario
/// retorna a la aplicación mediante el esquema `atrio://donation-completed?tx_id=...`
/// tras completarse y verificarse (`GET /donations/status`) la ofrenda en Odoo 19.
class DonationGratitudeModal extends StatelessWidget {
  final String txId;
  final String status;

  const DonationGratitudeModal({
    super.key,
    required this.txId,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final usableHeight =
        MediaQuery.sizeOf(context).height - MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);
    const Color verdeExito = Color(0xFF2E7D32);

    return Container(
      width: screenWidth,
      padding: EdgeInsetsDirectional.fromSTEB(
        screenWidth * 0.06,
        usableHeight * 0.025,
        screenWidth * 0.06,
        usableHeight * 0.03 + safeAreaBottom,
      ),
      decoration: BoxDecoration(
        color: blancoFondo,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: screenWidth * 0.12,
            height: screenWidth * 0.012,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(screenWidth * 0.01),
            ),
          ),
          SizedBox(height: usableHeight * 0.025),
          Container(
            width: screenWidth * 0.18,
            height: screenWidth * 0.18,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.volunteer_activism_rounded,
              color: verdeExito,
              size: screenWidth * 0.1,
            ),
          ),
          SizedBox(height: usableHeight * 0.018),
          Text(
            l10n?.gratitudPastoralTitulo ?? '¡Gracias por tu Generosidad!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: azulFondo,
              fontSize: screenWidth * 0.055,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: usableHeight * 0.008),
          Text(
            l10n?.gratitudPastoralSubtitulo ??
                'Tu ofrenda ha sido recibida y registrada exitosamente en el sistema ministerial de tu congregación.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: screenWidth * 0.034,
              height: 1.35,
            ),
          ),
          SizedBox(height: usableHeight * 0.018),
          Container(
            width: double.infinity,
            padding: EdgeInsetsDirectional.all(screenWidth * 0.035),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              border: Border.all(color: const Color(0xFFE8ECEF)),
            ),
            child: Column(
              children: [
                Text(
                  l10n?.referenciaOdoo(txId) ?? 'Referencia Odoo: $txId',
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.034,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n?.estadoVerificadoEnOdoo(status) ??
                      'Estado verificado en Odoo 19: $status',
                  style: TextStyle(
                    color: verdeExito,
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: usableHeight * 0.025),
          SizedBox(
            width: screenWidth,
            height: usableHeight * 0.06,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: amarilloOro,
                foregroundColor: azulFondo,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n?.aceptar ?? 'Aceptar',
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
  }
}
