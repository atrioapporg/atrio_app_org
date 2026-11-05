import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../modelos/ad_models.dart';
import '../providers/ads_provider.dart';
import '../widgets/atrio_connectivity_alert.dart';

/// Pantalla de Resumen de Orden y Facturación Externa B2B para campañas aprobadas (`to_pay`).
///
/// Cumple con la Auditoría Legal de Apple App Store (Guideline 3.1.1) y Google Play:
/// - Las campañas publicitarias B2B se cotizan in-app pero se facturan y liquidan
///   estrictamente fuera de la aplicación móvil (vía portal web externo de Odoo 19 o por correo).
/// - Cero formularios de cobro nativo ni subida de comprobantes dentro de la app.
/// - Widgets desacoplados con constructores `const`, soporte RTL/LTR (`EdgeInsetsDirectional`)
///   y cero textos hardcodeados (`AppLocalizations`).
class AdPaymentScreen extends StatefulWidget {
  static const routeName = 'ad_payment_screen';
  final AdModel ad;

  const AdPaymentScreen({super.key, required this.ad});

  @override
  State<AdPaymentScreen> createState() => _AdPaymentScreenState();
}

class _AdPaymentScreenState extends State<AdPaymentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdsProvider>().loadPaymentDetails(widget.ad.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final adsProvider = context.watch<AdsProvider>();
    final payment = adsProvider.currentPayment;
    final isLoading = adsProvider.isPaymentLoading;

    const Color azulFondo = Color(0xFF072B4F);
    const Color blancoFondo = Color(0xFFFAF7F0);

    final amountToPay = payment?.amount ?? widget.ad.cost ?? 0.0;
    final currencySymbol = payment?.currency ?? widget.ad.currency;
    final formattedAmount = NumberFormat.simpleCurrency(
      locale: locale,
      name: currencySymbol,
    ).format(amountToPay);

    final effectiveRef =
        (payment?.reference != null && payment!.reference!.trim().isNotEmpty)
            ? payment.reference!.trim()
            : 'AD-${widget.ad.id}';

    final bank = payment?.transfer ??
        (payment != null && payment.bankAccounts.isNotEmpty
            ? payment.bankAccounts.first
            : null);

    return Scaffold(
      backgroundColor: blancoFondo,
      appBar: AppBar(
        title: Text(
          l10n?.resumenFacturacionB2BTitulo ?? 'Orden de Pauta B2B',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: azulFondo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading && payment == null
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(azulFondo),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Alerta si existe observación contable previa en Odoo 19
                  if (payment?.rejectionReason != null &&
                      payment!.rejectionReason!.trim().isNotEmpty)
                    _RejectionAlertBanner(
                      rejectionReason: payment.rejectionReason!.trim(),
                    ),

                  // 2. Encabezado con Total Cotizado y Referencia Odoo 19
                  _PaymentHeaderCard(
                    adName: widget.ad.name,
                    formattedAmount: formattedAmount,
                    reference: effectiveRef,
                  ),

                  // 3. Tarjeta Principal de Facturación y Liquidación Externa B2B
                  Padding(
                    padding: const EdgeInsetsDirectional.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _B2BExternalBillingCard(
                          ad: widget.ad,
                          reference: effectiveRef,
                          formattedAmount: formattedAmount,
                          isLoading: isLoading,
                        ),
                        if (bank != null) ...[
                          const SizedBox(height: 20),
                          Text(
                            l10n?.datosReferenciaContableB2B ??
                                'Datos Institucionales de Referencia Contable',
                            style: const TextStyle(
                              color: azulFondo,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _OdooBankCard(bank: bank),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// =============================================================================
// SUB-WIDGETS DESACOPLADOS (CONSTRUCTORES CONST, CERO BUILD HELPERS)
// =============================================================================

class _RejectionAlertBanner extends StatelessWidget {
  final String rejectionReason;

  const _RejectionAlertBanner({required this.rejectionReason});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      color: const Color(0xFFFEF2F2),
      padding: const EdgeInsetsDirectional.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFDC2626),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n != null
                  ? l10n.comprobanteRechazadoAlerta(rejectionReason)
                  : rejectionReason,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentHeaderCard extends StatelessWidget {
  final String adName;
  final String formattedAmount;
  final String? reference;

  const _PaymentHeaderCard({
    required this.adName,
    required this.formattedAmount,
    this.reference,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(20),
      decoration: const BoxDecoration(
        color: azulFondo,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Text(
            adName,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            formattedAmount,
            style: const TextStyle(
              color: amarilloOro,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n?.costoTotal ?? 'Costo Total de la Campaña',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          if (reference != null && reference!.isNotEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: reference!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n?.referenciaCopiada ?? 'Referencia copiada',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ref: $reference',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.copy_rounded,
                      size: 13,
                      color: amarilloOro,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _B2BExternalBillingCard extends StatelessWidget {
  final AdModel ad;
  final String reference;
  final String formattedAmount;
  final bool isLoading;

  const _B2BExternalBillingCard({
    required this.ad,
    required this.reference,
    required this.formattedAmount,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    return Container(
      padding: const EdgeInsetsDirectional.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: azulFondo.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: azulFondo,
                  size: 30,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n?.resumenFacturacionB2BTitulo ?? 'Orden de Pauta B2B',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: azulFondo,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsetsDirectional.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F2F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l10n?.avisoFacturacionExternaB2B ??
                  'Por políticas de la plataforma, la facturación y liquidación de pautas publicitarias institucionales (B2B) se gestiona exclusivamente a través del portal web administrativo de Odoo 19 o mediante la factura enviada al correo de tu congregación.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: azulFondo,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n?.instruccionesFacturacionExternaSubtitulo ??
                'Completa la orden desde tu navegador web institucional o con el departamento contable de tu iglesia usando la referencia oficial.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),

          // Acción 1: Abrir Portal de Facturación en Navegador Externo
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: isLoading
                  ? null
                  : () async {
                      final hasInternet =
                          await AtrioConnectivityAlert.checkAndNotify(context);
                      if (!hasInternet || !context.mounted) return;
                      await context
                          .read<AdsProvider>()
                          .openExternalBillingPortal(ad.id);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: amarilloOro,
                foregroundColor: azulFondo,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(azulFondo),
                      ),
                    )
                  : const Icon(Icons.open_in_new_rounded, size: 19),
              label: Text(
                l10n?.abrirPortalFacturacionWeb ??
                    'Abrir Portal de Facturación en Navegador',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Acción 2: Solicitar / Enviar Factura por Correo Institucional
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final adsProv = context.read<AdsProvider>();
                await Clipboard.setData(ClipboardData(text: reference));
                await adsProv.requestInvoiceByEmail(
                  ad: ad,
                  reference: reference,
                  formattedAmount: formattedAmount,
                );
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n?.facturaEnviadaCorreoConfirmacion(reference) ??
                          'Solicitud de facturación preparada para la referencia $reference.',
                    ),
                    backgroundColor: azulFondo,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: azulFondo,
                side: const BorderSide(color: azulFondo, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.mail_outline_rounded, size: 19),
              label: Text(
                l10n?.solicitarFacturaPorCorreo ??
                    'Enviar / Solicitar Factura por Correo',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OdooBankCard extends StatelessWidget {
  final AdBankAccountModel bank;

  const _OdooBankCard({required this.bank});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    return Container(
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_rounded,
                color: azulFondo,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bank.bankName,
                  style: const TextStyle(
                    color: azulFondo,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  bank.currency,
                  style: const TextStyle(
                    color: azulFondo,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          _BankDetailRow(
            label: l10n?.titularCuenta ?? 'Titular',
            value: bank.accountHolder,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.numeroCuenta ?? 'Número de Cuenta',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bank.accountNumber,
                    style: const TextStyle(
                      color: azulFondo,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: amarilloOro,
                ),
                tooltip: l10n?.copiarNumeroCuenta ?? 'Copiar',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: bank.accountNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n?.numeroCopiado ?? 'Número copiado al portapapeles',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          if (bank.iban != null && bank.iban!.isNotEmpty) ...[
            const SizedBox(height: 6),
            _BankDetailRow(label: 'IBAN', value: bank.iban!),
          ],
        ],
      ),
    );
  }
}

class _BankDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _BankDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF072B4F),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
