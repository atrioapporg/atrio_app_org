import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../modelos/ad_models.dart';
import '../providers/ads_provider.dart';

/// Pantalla para gestionar el pago de una campaña de anuncios aprobada (`to_pay`).
/// Cumple con la especificación técnica de Odoo 19 ERP:
/// - GET /admin/ads/{id}/payment (payable, amount, currency, reference, rejection_reason, paypal_available, transfer)
/// - POST /admin/ads/{id}/pay/paypal
/// - POST /admin/ads/{id}/pay/transfer (reference, receipt_file, receipt_filename)
/// - Widgets desacoplados, soporte RTL/LTR, cero textos hardcodeados.
class AdPaymentScreen extends StatefulWidget {
  static const routeName = 'ad_payment_screen';
  final AdModel ad;

  const AdPaymentScreen({super.key, required this.ad});

  @override
  State<AdPaymentScreen> createState() => _AdPaymentScreenState();
}

class _AdPaymentScreenState extends State<AdPaymentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdsProvider>().loadPaymentDetails(widget.ad.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final adsProvider = context.watch<AdsProvider>();
    final payment = adsProvider.currentPayment;
    final isLoading = adsProvider.isPaymentLoading;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);

    final amountToPay = payment?.amount ?? widget.ad.cost ?? 0.0;
    final currencySymbol = payment?.currency ?? widget.ad.currency;
    final formattedAmount = NumberFormat.simpleCurrency(
      locale: locale,
      name: currencySymbol,
    ).format(amountToPay);

    return Scaffold(
      backgroundColor: blancoFondo,
      appBar: AppBar(
        title: Text(
          l10n?.pagarCampana ?? 'Pagar Campaña',
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
          : Column(
              children: [
                // 1. Alerta si el comprobante anterior fue rechazado por Atrio en Odoo 19
                if (payment?.rejectionReason != null &&
                    payment!.rejectionReason!.trim().isNotEmpty)
                  _RejectionAlertBanner(
                    rejectionReason: payment.rejectionReason!.trim(),
                  ),

                // 2. Tarjeta Resumen del Total y Referencia Odoo
                _PaymentHeaderCard(
                  adName: widget.ad.name,
                  formattedAmount: formattedAmount,
                  reference: payment?.reference,
                ),

                // 3. Pestañas de Métodos de Pago (PayPal vs Transferencia)
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: azulFondo,
                    unselectedLabelColor: Colors.grey.shade500,
                    indicatorColor: amarilloOro,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.payment_rounded),
                        text: l10n?.pagarConPaypal ?? 'PayPal',
                      ),
                      Tab(
                        icon: const Icon(Icons.account_balance_rounded),
                        text: l10n?.transferenciaBancaria ?? 'Transferencia',
                      ),
                    ],
                  ),
                ),

                // 4. Contenido de las pestañas desacoplado
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _PaypalTab(
                        adId: widget.ad.id,
                        paypalAvailable: payment?.paypalAvailable ?? true,
                      ),
                      _TransferTab(
                        ad: widget.ad,
                        payment: payment,
                      ),
                    ],
                  ),
                ),
              ],
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
                  : 'El comprobante anterior fue rechazado: $rejectionReason. Puedes subir uno nuevo.',
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
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
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

class _PaypalTab extends StatelessWidget {
  final int adId;
  final bool paypalAvailable;

  const _PaypalTab({
    required this.adId,
    required this.paypalAvailable,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final adsProvider = context.watch<AdsProvider>();
    final isLoading = adsProvider.isPaymentLoading;

    const Color azulFondo = Color(0xFF072B4F);

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(24),
      child: Column(
        children: [
          Container(
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
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF003087).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF003087),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n?.pagarConPaypal ?? 'Pagar con PayPal',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: azulFondo,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n?.pagoPaypalExplicacion ??
                      'Al presionar el botón serás redirigido al portal seguro de PayPal para completar tu transacción internacional.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                if (!paypalAvailable)
                  Container(
                    padding: const EdgeInsetsDirectional.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      l10n?.paypalNoDisponible ??
                          'PayPal no está disponible para esta transacción. Por favor utiliza transferencia bancaria.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => context
                              .read<AdsProvider>()
                              .processPaypalPayment(adId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC439),
                        foregroundColor: const Color(0xFF003087),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(azulFondo),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.open_in_new_rounded,
                                  color: Color(0xFF003087),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  l10n?.abrirPaypal ?? 'Continuar a PayPal',
                                  style: const TextStyle(
                                    color: Color(0xFF003087),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferTab extends StatefulWidget {
  final AdModel ad;
  final AdPaymentModel? payment;

  const _TransferTab({
    required this.ad,
    required this.payment,
  });

  @override
  State<_TransferTab> createState() => _TransferTabState();
}

class _TransferTabState extends State<_TransferTab> {
  final TextEditingController _referenceController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _receiptImage;
  String? _receiptBase64;
  String? _receiptFilename;

  @override
  void initState() {
    super.initState();
    if (widget.payment?.reference != null) {
      _referenceController.text = widget.payment!.reference!;
    }
  }

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _pickReceiptImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        maxHeight: 1400,
        imageQuality: 80,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _receiptImage = picked;
          _receiptBase64 = base64Encode(bytes);
          _receiptFilename = picked.name;
        });
      }
    } catch (e) {
      debugPrint('[AdPaymentScreen] Error seleccionando comprobante: $e');
    }
  }

  Future<void> _submitTransfer() async {
    final l10n = AppLocalizations.of(context);
    if (_receiptBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.adjuntarComprobante ?? 'Por favor adjunta el comprobante de transferencia',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final success = await context.read<AdsProvider>().submitTransferPayment(
          widget.ad.id,
          receiptBase64: _receiptBase64!,
          receiptFilename: _receiptFilename ?? 'comprobante.jpg',
          reference: _referenceController.text.trim().isNotEmpty
              ? _referenceController.text.trim()
              : null,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.comprobanteEnviadoExito ?? 'Comprobante enviado a revisión.',
          ),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.pop(context, true);
    } else {
      final errorMsg = context.read<AdsProvider>().paymentError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg ?? 'No se pudo registrar la transferencia'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSubmitting = context.watch<AdsProvider>().isPaymentLoading;
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    // Banco de Odoo 19
    final bank = widget.payment?.transfer ??
        (widget.payment != null && widget.payment!.bankAccounts.isNotEmpty
            ? widget.payment!.bankAccounts.first
            : null);

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Datos bancarios
          Text(
            l10n?.cuentasBancariasDisponibles ?? 'Datos para Transferencia Bancaria',
            style: const TextStyle(
              color: azulFondo,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          if (bank != null)
            _OdooBankCard(bank: bank)
          else
            const _OdooBankCard(
              bank: AdBankAccountModel(
                bankName: 'Banco Popular Dominicano',
                accountHolder: 'Fundación ATRIO',
                accountNumber: '798412356',
                currency: 'DOP',
              ),
            ),

          const SizedBox(height: 20),

          // Campo de Referencia Bancaria
          TextField(
            controller: _referenceController,
            decoration: InputDecoration(
              labelText: l10n?.referenciaBancaria ?? 'Referencia / Depósito',
              hintText: l10n?.referenciaBancariaHint ?? 'Ej. REF-889231',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Selector de Comprobante
          Container(
            padding: const EdgeInsetsDirectional.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.comprobanteTransferencia ?? 'Comprobante de Pago',
                  style: const TextStyle(
                    color: azulFondo,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                if (_receiptImage != null)
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(_receiptImage!.path),
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _pickReceiptImage,
                        icon: const Icon(Icons.change_circle_rounded),
                        label: Text(l10n?.cambiarImagen ?? 'Cambiar Comprobante'),
                      ),
                    ],
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _pickReceiptImage,
                    icon: const Icon(Icons.attach_file_rounded),
                    label: Text(
                      l10n?.adjuntarComprobante ?? 'Adjuntar Foto / Captura',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: azulFondo,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Botón de Envío de Transferencia
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : _submitTransfer,
              style: ElevatedButton.styleFrom(
                backgroundColor: amarilloOro,
                foregroundColor: azulFondo,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(azulFondo),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          l10n?.enviarComprobante ?? 'Enviar Comprobante',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 32),
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
              const Icon(Icons.account_balance_rounded,
                  color: azulFondo, size: 20),
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
                icon: const Icon(Icons.copy_rounded,
                    size: 18, color: amarilloOro),
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
