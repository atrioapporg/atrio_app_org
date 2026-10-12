import 'package:flutter/material.dart';
import 'package:atrio/l10n/app_localizations.dart';

class OdooPagoDialog {
  static Future<void> mostrarConfirmacionPago({
    required BuildContext context,
    required String concepto,
    required String monto,
    required String metodoPago,
    required VoidCallback onConfirmado,
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

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        bool procesando = false;
        bool completado = false;
        String ordenOdoo = 'SO-2026-0842'; // Simulación ID sale.order

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

                  if (!procesando && !completado) ...[
                    // Ícono de validación de pago
                    Container(
                      width: screenWidth * 0.16,
                      height: screenWidth * 0.16,
                      decoration: const BoxDecoration(
                        color: azulFondo,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.payment_rounded,
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
                          // Fila: Concepto (Corregida con Expanded)
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
                              //
                              SizedBox(width: screenWidth * 0.03),
                              //
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
                              //
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
                        onPressed: () {
                          setStateModal(() => procesando = true);
                          // Simula la llamada RPC de Odoo (action_confirm / payment.transaction)
                          Future.delayed(const Duration(seconds: 2), () {
                            setStateModal(() {
                              procesando = false;
                              completado = true;
                            });
                          });
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
                      l10n?.registrandoOrdenConfirmandoPago ??
                          'Estamos registrando tu orden y confirmando el pago.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.032,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.04),
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
                      l10n?.contribucionValidadaRecibo ??
                          'Tu contribución ha sido validada y el recibo digital fue enviado a tu correo.',
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
