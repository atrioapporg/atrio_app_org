import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:atrio/atrio_api.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/widgets/modal_restriccion_donacion.dart';

/// Diálogo de redirección controlada al navegador seguro (SFSafariViewController en iOS /
/// Chrome Custom Tabs en Android) para procesar ofrendas y donaciones en el portal web de Odoo 19.
///
/// Cumple estrictamente con Apple Guideline 3.2.1(vi) y Google Play Payments Policy:
/// la app no recolecta ni procesa fondos de donación de forma nativa.
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

    if (!ModalRestriccionDonacion.verificarDonacionGeneral(context: context)) {
      return Future.value();
    }

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
              padding: EdgeInsetsDirectional.fromSTEB(
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
                    Container(
                      width: screenWidth * 0.16,
                      height: screenWidth * 0.16,
                      decoration: const BoxDecoration(
                        color: azulFondo,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.open_in_browser_rounded,
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
                    SizedBox(height: usableHeight * 0.006),
                    Text(
                      l10n?.avisoRedireccionWebDonacion ??
                          'En cumplimiento con las normativas de seguridad, tu ofrenda o donación se completará íntegramente en el portal web seguro de tu congregación (vía navegador seguro del sistema) con 0% de retención.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.031,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.02),

                    // Tarjeta Resumen rápido protegido contra Overflows
                    Container(
                      padding: EdgeInsetsDirectional.all(screenWidth * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.035,
                        ),
                        border: Border.all(color: grisBorde),
                      ),
                      child: Column(
                        children: [
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
                                  l10n?.portalWebExternoOdoo ??
                                      'Portal Web Oficial (SFSafariViewController / Chrome Tabs)',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    color: azulFondo,
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.031,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Divider(
                            height: usableHeight * 0.02,
                            color: grisBorde,
                          ),
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

                    // Botón Abrir Portal Web Seguro (Browser Redirect)
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
                              screenWidth * 0.03,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 19),
                        onPressed: () async {
                          final userProvider = Provider.of<UserProvider>(
                            context,
                            listen: false,
                          );
                          if (!userProvider.canDonateToPlatform) {
                            Navigator.of(modalContext).pop();
                            ModalRestriccionDonacion.mostrar(
                              context: context,
                            );
                            return;
                          }

                          setStateModal(() {
                            procesando = true;
                            error = false;
                            errorMessage = '';
                          });

                          try {
                            final user = userProvider.currentUser;

                            final effectiveName =
                                (donorName != null &&
                                        donorName.trim().isNotEmpty)
                                    ? donorName.trim()
                                    : ((user != null &&
                                              user.nombre.trim().isNotEmpty)
                                          ? user.nombre.trim()
                                          : 'Donante Atrio');

                            final effectiveEmail =
                                (donorEmail != null &&
                                        donorEmail.trim().isNotEmpty)
                                    ? donorEmail.trim()
                                    : ((user != null &&
                                              user.email.trim().isNotEmpty)
                                          ? user.email.trim()
                                          : 'donaciones@atrio.app');

                            final cleanStr = monto
                                .replaceAll(',', '')
                                .replaceAll(RegExp(r'[^0-9.]'), '');
                            final double amountVal =
                                montoNumerico ??
                                double.tryParse(cleanStr) ??
                                100.0;

                            final res = await userProvider.api
                                .createDonationWebCheckoutUrl(
                                  name: effectiveName,
                                  email: effectiveEmail,
                                  amount: amountVal,
                                  notes: mensajeApoyo ?? concepto,
                                  publicConsent: !esAnonimo,
                                  paymentMethod: metodoPago,
                                );

                            final checkoutUrl = res['checkout_url'] as String?;
                            if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
                              final uri = Uri.parse(checkoutUrl);
                              // Apertura controlada mediante SFSafariViewController (iOS)
                              // y Chrome Custom Tabs (Android) según Apple Guideline 3.2.1(vi)
                              bool launched = false;
                              try {
                                launched = await launchUrl(
                                  uri,
                                  mode: LaunchMode.inAppBrowserView,
                                );
                              } catch (_) {
                                launched = await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                              if (!launched) {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            }

                            final ref = res['reference'] ??
                                (res['donation_id'] != null
                                    ? 'DON-${res['donation_id']}'
                                    : 'DON-WEB');

                            setStateModal(() {
                              procesando = false;
                              completado = true;
                              ordenOdoo = ref.toString();
                            });
                          } catch (e) {
                            String msg =
                                e.toString().replaceFirst('Exception: ', '');
                            if (e is AtrioApiException) {
                              msg = e.message;
                            }
                            setStateModal(() {
                              procesando = false;
                              error = true;
                              errorMessage = msg;
                            });
                          }
                        },
                        label: Text(
                          l10n?.abrirPortalWebSeguro ??
                              'Abrir Portal Web Seguro',
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
                      l10n?.abriendoPortalSeguroOdoo ??
                          'Abriendo portal web seguro...',
                      style: TextStyle(
                        color: azulFondo,
                        fontSize: screenWidth * 0.048,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.005),
                    Text(
                      l10n?.completarAporteEnNavegadorDesc ??
                          'Completa tu aporte en la ventana segura del navegador. Al finalizar regresarás automáticamente a ATRIO.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.032,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.04),
                  ] else if (error) ...[
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
                      l10n?.completarAporteEnNavegadorDesc ??
                          'Completa tu aporte en la ventana segura del navegador. Al finalizar regresarás automáticamente a ATRIO.',
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
