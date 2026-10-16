import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/providers/user_provider.dart';

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
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);
    const Color grisBorde = Color(0xFFE8ECEF);
    const Color verdeExito = Color(0xFF2E7D32);
    const Color rojoError = Color(0xFFD32F2F);

    final bool esPaypal = metodoPago.toLowerCase().contains('paypal');

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool procesando = false;
        bool completado = false;
        bool error = false;
        String errorMessage = '';
        String ordenOdoo = '';

        return StatefulBuilder(
          builder: (modalContext, setStateModal) {
            return Container(
              width: screenWidth,
              padding: EdgeInsets.fromLTRB(
                screenWidth * 0.06,
                usableHeight * 0.025,
                screenWidth * 0.06,
                usableHeight * 0.03 + safeAreaBottom,
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
                children: [
                  // Indicador superior de arrastre (Handle)
                  Container(
                    width: screenWidth * 0.12,
                    height: screenWidth * 0.012,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(screenWidth * 0.01),
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.025),

                  if (!procesando && !completado && !error) ...[
                    // Ícono de validación de pago
                    Container(
                      width: screenWidth * 0.16,
                      height: screenWidth * 0.16,
                      decoration: const BoxDecoration(
                        color: azulFondo,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        esPaypal
                            ? Icons.account_balance_wallet_rounded
                            : Icons.payment_rounded,
                        color: amarilloOro,
                        size: screenWidth * 0.08,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.015),
                    Text(
                      l10n?.confirmarTransaccion ?? 'Confirmar Transacción',
                      style: TextStyle(
                        color: azulFondo,
                        fontSize: screenWidth * 0.055,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.005),
                    Text(
                      l10n?.transaccionValidaraOdoo ??
                          'La transacción se validará mediante la pasarela segura de Odoo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.032,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.02),

                    // Tarjeta Resumen rápido protegido contra Overflows
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.035,
                        ),
                        border: Border.all(color: grisBorde),
                      ),
                      child: Column(
                        children: [
                          // Fila: Concepto
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n?.concepto ?? 'Concepto',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: screenWidth * 0.033,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Expanded(
                                child: Text(
                                  concepto,
                                  textAlign: TextAlign.end,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: azulFondo,
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.035,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Divider(
                            height: usableHeight * 0.02,
                            color: grisBorde,
                          ),

                          // Fila: Método de pago
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n?.metodoDePago ?? 'Método de pago',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: screenWidth * 0.033,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Flexible(
                                child: Text(
                                  metodoPago,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    color: azulFondo,
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.033,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Divider(
                            height: usableHeight * 0.02,
                            color: grisBorde,
                          ),

                          // Fila: Total a procesar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n?.totalAProcesar ?? 'Total a procesar',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: screenWidth * 0.033,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Flexible(
                                child: Text(
                                  monto,
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    color: amarilloOro,
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.042,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.03),

                    // Botón Procesar
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
                        onPressed: () async {
                          setStateModal(() {
                            procesando = true;
                            error = false;
                            errorMessage = '';
                          });

                          try {
                            final userProvider = Provider.of<UserProvider>(
                              context,
                              listen: false,
                            );
                            final user = userProvider.currentUser;

                            final effectiveName =
                                (donorName != null &&
                                    donorName.trim().isNotEmpty)
                                ? donorName.trim()
                                : ((user != null &&
                                          user.nombre.trim().isNotEmpty)
                                      ? user.nombre.trim()
                                      : 'Miembro Atrio');

                            final effectiveEmail =
                                (donorEmail != null &&
                                    donorEmail.trim().isNotEmpty)
                                ? donorEmail.trim()
                                : ((user != null &&
                                          user.email.trim().isNotEmpty)
                                      ? user.email.trim()
                                      : 'miembro@atrio.app');

                            final cleanStr = monto
                                .replaceAll(',', '')
                                .replaceAll(RegExp(r'[^0-9.]'), '');
                            final double amountVal =
                                montoNumerico ??
                                double.tryParse(cleanStr) ??
                                100.0;

                            if (esPaypal) {
                              final res = await userProvider.api
                                  .donateWithPaypal(
                                    name: effectiveName,
                                    email: effectiveEmail,
                                    amount: amountVal,
                                    notes: mensajeApoyo ?? concepto,
                                    publicConsent: !esAnonimo,
                                  );

                              final checkoutUrl =
                                  res['checkout_url'] as String?;
                              if (checkoutUrl != null &&
                                  checkoutUrl.isNotEmpty) {
                                final uri = Uri.parse(checkoutUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              }

                              final ref =
                                  res['reference'] ??
                                  (res['donation_id'] != null
                                      ? 'DON-${res['donation_id']}'
                                      : 'DON-PAYPAL');

                              setStateModal(() {
                                procesando = false;
                                completado = true;
                                ordenOdoo = ref.toString();
                              });
                            } else {
                              // Transferencia bancaria
                              final String b64 =
                                  (receiptBase64 != null &&
                                      receiptBase64.isNotEmpty)
                                  ? receiptBase64
                                  : base64Encode(
                                      utf8.encode(
                                        'COMPROBANTE-APP-$effectiveName-$amountVal',
                                      ),
                                    );
                              final String filename =
                                  receiptFilename ??
                                  'comprobante_transferencia.jpg';

                              final res = await userProvider.api
                                  .donateWithTransfer(
                                    name: effectiveName,
                                    email: effectiveEmail,
                                    amount: amountVal,
                                    receiptBase64: b64,
                                    receiptFilename: filename,
                                    reference:
                                        'APP-${DateTime.now().millisecondsSinceEpoch}',
                                    currency: 'DOP',
                                  );

                              final ref =
                                  res['reference'] ??
                                  (res['donation_id'] != null
                                      ? 'DON-${res['donation_id']}'
                                      : 'DON-Odoo');

                              setStateModal(() {
                                procesando = false;
                                completado = true;
                                ordenOdoo = ref.toString();
                              });
                            }
                          } catch (e) {
                            setStateModal(() {
                              procesando = false;
                              error = true;
                              errorMessage = e
                                  .toString()
                                  .replaceFirst('Exception: ', '');
                            });
                          }
                        },
                        child: Text(
                          l10n?.pagarYValidar ?? 'Pagar y Validar',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.01),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        l10n?.cancelar ?? 'Cancelar',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                    ),
                  ] else if (procesando) ...[
                    SizedBox(height: usableHeight * 0.03),
                    const CircularProgressIndicator(color: amarilloOro),
                    SizedBox(height: usableHeight * 0.03),
                    Text(
                      l10n?.validandoConOdoo ?? 'Validando con Odoo...',
                      style: TextStyle(
                        color: azulFondo,
                        fontSize: screenWidth * 0.048,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.005),
                    Text(
                      esPaypal
                          ? (l10n?.redirigiendoPaypal ??
                              'Redirigiendo a PayPal para completar tu donación...')
                          : (l10n?.registrandoOrdenConfirmandoPago ??
                              'Estamos registrando tu orden y confirmando el pago.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.032,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.04),
                  ] else if (error) ...[
                    // Estado de Error controlado
                    Container(
                      width: screenWidth * 0.16,
                      height: screenWidth * 0.16,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFEBEE),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: rojoError,
                        size: screenWidth * 0.1,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.015),
                    Text(
                      l10n?.errorProcesarDonacion(errorMessage) ??
                          'Ocurrió un error al procesar la donación: $errorMessage',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: azulFondo,
                        fontSize: screenWidth * 0.038,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.025),
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
                          setStateModal(() {
                            error = false;
                            procesando = false;
                          });
                        },
                        child: Text(
                          l10n?.reintentar ?? 'Reintentar',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.01),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        l10n?.cancelar ?? 'Cancelar',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                    ),
                  ] else if (completado) ...[
                    // Estado de Éxito
                    Container(
                      width: screenWidth * 0.16,
                      height: screenWidth * 0.16,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: verdeExito,
                        size: screenWidth * 0.1,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.015),
                    Text(
                      l10n?.aporteExitoso ?? '¡Aporte Exitoso!',
                      style: TextStyle(
                        color: azulFondo,
                        fontSize: screenWidth * 0.058,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.005),
                    Text(
                      l10n?.referenciaOdoo(ordenOdoo) ??
                          'Referencia Odoo: $ordenOdoo',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.032,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.01),
                    Text(
                      l10n?.donacionPendienteVerificacion ??
                          'Tu donación ha sido registrada en Odoo y está pendiente de verificación contable.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: screenWidth * 0.032,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.03),
                    SizedBox(
                      width: screenWidth,
                      height: usableHeight * 0.062,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: azulFondo,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.03,
                            ),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          onConfirmado();
                        },
                        child: Text(
                          l10n?.finalizar ?? 'Finalizar',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
