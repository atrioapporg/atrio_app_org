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
/// Soporta pasarela PayPal (checkout_url externa) y Transferencia Bancaria con subida de comprobante Base64.
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
  final TextEditingController _referenceController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _receiptImage;
  String? _receiptBase64;
  String? _receiptFilename;

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
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _pickReceiptImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64String = base64Encode(bytes);
        setState(() {
          _receiptImage = picked;
          _receiptBase64 = base64String;
          _receiptFilename = picked.name;
        });
      }
    } catch (e) {
      debugPrint('[AdPaymentScreen] Error al seleccionar imagen: $e');
    }
  }

  Future<void> _enviarTransferencia() async {
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
            l10n?.comprobanteEnviadoExito ??
                'Comprobante enviado. Tu campaña pasará a revisión de pago.',
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
          content: Text(errorMsg ?? 'No se pudo procesar el comprobante'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
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
                // 1. Tarjeta Resumen del Total a Pagar
                Container(
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
                        widget.ad.name,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
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
                    ],
                  ),
                ),

                // 2. Tabs de Pasarela (PayPal vs Transferencia)
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

                // 3. Vistas de Contenido de los Tabs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // TAB A: PAYPAL
                      _buildPaypalTab(context, adsProvider, isLoading),

                      // TAB B: TRANSFERENCIA BANCARIA
                      _buildTransferTab(context, payment, adsProvider, isLoading),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPaypalTab(
    BuildContext context,
    AdsProvider adsProvider,
    bool isLoading,
  ) {
    final l10n = AppLocalizations.of(context);
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
                const Text(
                  'Pago Rápido y Seguro vía PayPal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Al presionar el botón serás redirigido al portal seguro de PayPal para completar tu transacción internacional.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC439),
                      foregroundColor: const Color(0xFF003087),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            final launched = await adsProvider.processPaypalPayment(
                              widget.ad.id,
                            );
                            if (launched && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Completando pago en el navegador seguro de PayPal...',
                                  ),
                                ),
                              );
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                l10n?.pagarConPaypal ?? 'Pagar con PayPal',
                                style: const TextStyle(
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

  Widget _buildTransferTab(
    BuildContext context,
    AdPaymentModel? payment,
    AdsProvider adsProvider,
    bool isLoading,
  ) {
    final l10n = AppLocalizations.of(context);
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    final accounts = payment?.bankAccounts ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Subtítulo de Cuentas
          Text(
            l10n?.cuentasBancariasDisponibles ?? 'Cuentas Bancarias Disponibles',
            style: const TextStyle(
              color: azulFondo,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          // Lista de cuentas o cuenta por defecto si no vinieron en la API
          if (accounts.isNotEmpty)
            ...accounts.map((acc) => _BankAccountCard(account: acc))
          else
            const _BankAccountCard(
              account: AdBankAccountModel(
                bankName: 'Banco Popular Dominicano',
                accountHolder: 'Fundación ATRIO Dominicana',
                accountNumber: '802-123456-7',
                accountType: 'Corriente en Pesos / USD',
                taxId: '4-01-12345-6',
              ),
            ),

          const SizedBox(height: 20),

          // Campo de Referencia Bancaria
          TextField(
            controller: _referenceController,
            decoration: InputDecoration(
              labelText: l10n?.referenciaBancaria ?? 'Referencia Bancaria',
              hintText: l10n?.referenciaBancariaHint ?? 'Ej. DEP-12345678',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Selector / Previsualización de Comprobante
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
                  l10n?.comprobanteTransferencia ?? 'Comprobante de Transferencia',
                  style: const TextStyle(
                    color: azulFondo,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                if (_receiptImage != null)
                  Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_receiptImage!.path),
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: _pickReceiptImage,
                        icon: const Icon(Icons.cached_rounded, size: 16),
                        label: Text(l10n?.cambiarImagen ?? 'Cambiar comprobante'),
                      ),
                    ],
                  )
                else
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: amarilloOro, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _pickReceiptImage,
                    icon: const Icon(Icons.upload_file_rounded, color: azulFondo),
                    label: Text(
                      l10n?.adjuntarComprobante ?? 'Adjuntar foto del comprobante',
                      style: const TextStyle(
                        color: azulFondo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Botón Enviar Comprobante
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: azulFondo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isLoading ? null : _enviarTransferencia,
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      l10n?.enviarComprobante ?? 'Enviar Comprobante a Revisión',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _BankAccountCard extends StatelessWidget {
  final AdBankAccountModel account;

  const _BankAccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color azulFondo = Color(0xFF072B4F);

    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: 12),
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                account.bankName,
                style: const TextStyle(
                  color: azulFondo,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  account.accountType,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n?.titularCuenta ?? 'Titular'}: ${account.accountHolder}',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          if (account.taxId != null) ...[
            const SizedBox(height: 2),
            Text(
              '${l10n?.rncCedula ?? 'RNC'}: ${account.taxId}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: account.accountNumber));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n?.numeroCopiado ?? 'Número de cuenta copiado al portapapeles',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.copy_rounded, size: 14, color: azulFondo),
                  const SizedBox(width: 6),
                  Text(
                    account.accountNumber,
                    style: const TextStyle(
                      color: azulFondo,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
