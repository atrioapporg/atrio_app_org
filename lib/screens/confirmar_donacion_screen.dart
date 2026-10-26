import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/utils/media_validator.dart';
import 'package:atrio/widgets/modal_restriccion_donacion.dart';
import 'package:atrio/widgets/odoo_pago_dialog.dart';
import 'package:atrio/widgets/read_only_banner.dart';

class ConfirmarDonacionScreen extends StatefulWidget {
  static const routeName = 'confirmar_donacion_screen';
  const ConfirmarDonacionScreen({super.key});

  @override
  State<ConfirmarDonacionScreen> createState() =>
      _ConfirmarDonacionScreenState();
}

class _ConfirmarDonacionScreenState extends State<ConfirmarDonacionScreen> {
  XFile? _comprobanteFile;
  String? _receiptBase64;
  String? _receiptFilename;

  Future<void> _seleccionarComprobante(
    ImageSource source,
    AppLocalizations? l10n,
  ) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        final validation = MediaValidator.validateImageBytes(bytes);
        if (!validation.isValid) {
          if (!mounted) return;
          await MediaValidator.showImageSizeExceededModal(
            context,
            sizeInMB: validation.sizeInMB,
          );
          return;
        }

        setState(() {
          _comprobanteFile = image;
          _receiptFilename = image.name;
          _receiptBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      debugPrint('[ConfirmarDonacionScreen] Error seleccionando imagen: $e');
    }
  }

  void _mostrarOpcionesImagen(BuildContext context, AppLocalizations? l10n) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    const Color azulFondo = Color(0xFF072B4F);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.05),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: screenWidth * 0.04,
              horizontal: screenWidth * 0.05,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: screenWidth * 0.1,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: screenWidth * 0.04),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_rounded,
                    color: azulFondo,
                  ),
                  title: Text(
                    l10n?.tomarFoto ?? 'Tomar foto',
                    style: TextStyle(
                      color: azulFondo,
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _seleccionarComprobante(ImageSource.camera, l10n);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_rounded,
                    color: azulFondo,
                  ),
                  title: Text(
                    l10n?.galeria ?? 'Galería de fotos',
                    style: TextStyle(
                      color: azulFondo,
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _seleccionarComprobante(ImageSource.gallery, l10n);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 1. Recepción dinámica de datos desde RealizarAporteScreen o AportarAProyectoScreen
    final Map donacionData =
        (ModalRoute.of(context)?.settings.arguments as Map?) ??
        {
          'comunidad': 'Comunidad de Esperanza',
          'concepto': l10n?.ofrenda ?? 'Ofrenda',
          'monto': 'RD\$1,000.00',
          'frecuencia': l10n?.frecuenciaUnaSolaVez ?? 'Una sola vez',
          'metodoPago': 'Visa •••• 1234',
        };

    final String comunidad = donacionData['comunidad'] ?? 'Comunidad';
    final String concepto = donacionData['concepto'] ?? (l10n?.ofrenda ?? 'Ofrenda');
    final String monto = donacionData['monto'] ?? 'RD\$ 0.00';
    final String frecuencia =
        donacionData['frecuencia'] ?? (l10n?.frecuenciaUnaSolaVez ?? 'Una sola vez');
    final String metodoPago = donacionData['metodoPago'] ?? 'Transferencia';
    final bool esPaypal = metodoPago.toLowerCase().contains('paypal');

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
    const Color verdeExito = Color(0xFF2E7D32);

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
                        l10n?.revisaTuDonacion ?? 'Revisa tu donación',
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
                          const ReadOnlyBanner(),
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
                                  l10n?.resumenDeTuDonacion ??
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
                                  label: l10n?.para ?? 'Para',
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
                                  label: l10n?.concepto ?? 'Concepto',
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
                                  label: l10n?.monto ?? 'Monto',
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
                                  label: l10n?.frecuencia ?? 'Frecuencia',
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
                                  label: l10n?.metodoDePago ?? 'Método de pago',
                                  valueWidget: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        esPaypal
                                            ? Icons.account_balance_wallet_rounded
                                            : Icons.credit_card_rounded,
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

                          // Sección para adjuntar comprobante (si es Transferencia u otro método no-Paypal)
                          if (!esPaypal) ...[
                            SizedBox(height: usableHeight * 0.02),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  screenWidth * 0.04,
                                ),
                                border: Border.all(
                                  color: _comprobanteFile != null
                                      ? verdeExito
                                      : grisBorde,
                                  width: _comprobanteFile != null ? 1.5 : 1,
                                ),
                              ),
                              padding: EdgeInsets.all(screenWidth * 0.04),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _comprobanteFile != null
                                            ? Icons.check_circle_rounded
                                            : Icons.receipt_long_rounded,
                                        color: _comprobanteFile != null
                                            ? verdeExito
                                            : azulFondo,
                                        size: screenWidth * 0.055,
                                      ),
                                      SizedBox(width: screenWidth * 0.025),
                                      Expanded(
                                        child: Text(
                                          l10n?.comprobanteTransferencia ??
                                              'Comprobante de transferencia',
                                          style: TextStyle(
                                            color: azulFondo,
                                            fontSize: screenWidth * 0.04,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: usableHeight * 0.01),
                                  Text(
                                    _comprobanteFile != null
                                        ? (_receiptFilename ??
                                            (l10n?.comprobanteAdjuntado ??
                                                'Comprobante adjuntado con éxito'))
                                        : (l10n?.subirComprobanteDesc ??
                                            'Adjunta una foto o captura del comprobante bancario para validar tu aporte rápidamente.'),
                                    style: TextStyle(
                                      color: _comprobanteFile != null
                                          ? verdeExito
                                          : textoGris,
                                      fontSize: screenWidth * 0.032,
                                      fontWeight: _comprobanteFile != null
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  SizedBox(height: usableHeight * 0.015),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: azulFondo,
                                            side: BorderSide(
                                              color: azulFondo.withValues(
                                                alpha: 0.3,
                                              ),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    screenWidth * 0.025,
                                                  ),
                                            ),
                                          ),
                                          onPressed: () =>
                                              _mostrarOpcionesImagen(
                                                context,
                                                l10n,
                                              ),
                                          icon: Icon(
                                            _comprobanteFile != null
                                                ? Icons.refresh_rounded
                                                : Icons.camera_alt_outlined,
                                            size: screenWidth * 0.045,
                                          ),
                                          label: Text(
                                            _comprobanteFile != null
                                                ? (l10n?.cambiarComprobante ??
                                                    'Cambiar comprobante')
                                                : (l10n?.adjuntarComprobante ??
                                                    'Adjuntar comprobante'),
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.032,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (_comprobanteFile != null) ...[
                                        SizedBox(width: screenWidth * 0.02),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Color(0xFFD32F2F),
                                          ),
                                          tooltip:
                                              l10n?.eliminarComprobante ??
                                              'Quitar comprobante',
                                          onPressed: () {
                                            setState(() {
                                              _comprobanteFile = null;
                                              _receiptBase64 = null;
                                              _receiptFilename = null;
                                            });
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],

                          SizedBox(height: usableHeight * 0.03),
                          // Escudo de Seguridad
                          Icon(
                            Icons.shield_outlined,
                            color: azulFondo,
                            size: screenWidth * 0.12,
                          ),
                          SizedBox(height: usableHeight * 0.01),
                          Text(
                            l10n?.tuDonacionEsSegura ?? 'Tu donación es segura',
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.055,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.01),
                          Text(
                            l10n?.conexionCifradaProteccion ??
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
                                if (!ModalRestriccionDonacion.verificarDonacionGeneral(context: context)) {
                                  return;
                                }
                                final userProvider = Provider.of<UserProvider>(
                                  context,
                                  listen: false,
                                );
                                final user = userProvider.currentUser;

                                OdooPagoDialog.mostrarConfirmacionPago(
                                  context: context,
                                  concepto: '$concepto ($comunidad)',
                                  monto: monto,
                                  metodoPago: metodoPago,
                                  receiptBase64: _receiptBase64,
                                  receiptFilename: _receiptFilename,
                                  mensajeApoyo:
                                      donacionData['mensajeApoyo'] as String?,
                                  esAnonimo:
                                      donacionData['esAnonimo'] as bool? ??
                                      false,
                                  donorName: user?.nombre,
                                  donorEmail: user?.email,
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
                                l10n?.confirmarDonacion ?? 'Confirmar donación',
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
