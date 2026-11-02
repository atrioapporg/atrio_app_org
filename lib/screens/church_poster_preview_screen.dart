import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/providers/iglesia_provider.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/servicios/join_church_service.dart';

/// Pantalla de Previsualización y Descarga del Afiche Oficial de Vinculación QR.
/// Permite al Administrador de Iglesia / Pastor visualizar el cartel oficial con
/// el código QR real de su parroquia e imprimirlo o descargarlo en formato PDF A4.
class ChurchPosterPreviewScreen extends StatefulWidget {
  static const String routeName = '/church-poster-preview';

  const ChurchPosterPreviewScreen({super.key});

  @override
  State<ChurchPosterPreviewScreen> createState() => _ChurchPosterPreviewScreenState();
}

class _ChurchPosterPreviewScreenState extends State<ChurchPosterPreviewScreen> {
  final JoinChurchService _joinService = JoinChurchService();
  String? _joinUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveChurchUrl();
    });
  }

  Future<void> _resolveChurchUrl() async {
    final userProv = context.read<UserProvider>();
    final churchId = userProv.currentUser?.iglesiaId ?? 18;
    final token = await userProv.storageService.getAccessToken();

    final url = await _joinService.resolveChurchJoinUrl(
      churchId: churchId,
      accessToken: token,
    );

    if (mounted) {
      setState(() {
        _joinUrl = url;
        _isLoading = false;
      });
    }
  }

  Future<void> _generateAndPrintPdf(String churchName, String joinUrl) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context pdfContext) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('072B4F'), width: 3),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
            ),
            padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // 1. Encabezado ATRIO
                pw.Column(
                  children: [
                    pw.Text(
                      'ATRIO',
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('072B4F'),
                        fontSize: 36,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'APP CRISTIANA - VIVE TU FE EN COMUNIDAD',
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('E5A023'),
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Text(
                      '¡Agrégate a la familia ATRIO!',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('072B4F'),
                        fontSize: 26,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('F0F4F8'),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Text(
                        churchName,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('072B4F'),
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // 2. Código QR Vectorial Nítido
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
                    border: pw.Border.all(
                      color: PdfColor.fromHex('E5A023'),
                      width: 4,
                    ),
                  ),
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(
                      errorCorrectLevel: pw.BarcodeQRCorrectionLevel.high,
                    ),
                    data: joinUrl,
                    width: 200,
                    height: 200,
                  ),
                ),

                // 3. Botón / Call To Action
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('E5A023'),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(24)),
                  ),
                  child: pw.Text(
                    'Escanea aquí y conéctate con nuestra congregación',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      color: PdfColor.fromHex('072B4F'),
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),

                // 4. Beneficios del Feligrés
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    _pdfPillarItem('Eventos', 'Mis actividades y cultos'),
                    _pdfPillarItem('Comunidad', 'Peticiones y comunión'),
                    _pdfPillarItem('Avisos', 'Notificaciones pastorales'),
                  ],
                ),

                // 5. Enlace canónico en texto para respaldo
                pw.Text(
                  'Enlace oficial: $joinUrl',
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('64748B'),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Afiche_QR_${churchName.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.Widget _pdfPillarItem(String title, String subtitle) {
    return pw.Column(
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            color: PdfColor.fromHex('072B4F'),
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          subtitle,
          style: pw.TextStyle(
            color: PdfColor.fromHex('64748B'),
            fontSize: 8,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final userProv = context.watch<UserProvider>();
    final iglesiaProv = context.watch<IglesiaProvider>();

    final churchName = iglesiaProv.iglesiaActual?.nombre.isNotEmpty == true
        ? iglesiaProv.iglesiaActual!.nombre
        : (userProv.currentUser?.iglesiaActual.isNotEmpty == true &&
                userProv.currentUser!.iglesiaActual != 'Sin iglesia seleccionada')
            ? userProv.currentUser!.iglesiaActual
            : 'Parroquia San Pedro Nolasco';

    return Scaffold(
      backgroundColor: const Color(0xFF04182C),
      appBar: AppBar(
        title: Text(
          l10n?.aficheQrOficial ?? 'Afiche y QR Oficial',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF072B4F),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading && _joinUrl != null)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: l10n?.compartirEnlaceIglesia ?? 'Compartir Enlace',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _joinUrl!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enlace copiado al portapapeles.'),
                    backgroundColor: Color(0xFF072B4F),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE5A023)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsetsDirectional.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Tarjeta gráfica del afiche que recrea la plantilla visual
                  PosterGraphicCard(
                    churchName: churchName,
                    joinUrl: _joinUrl ?? 'https://atrioapp.odoo19rd.com',
                  ),
                  const SizedBox(height: 24),

                  // Texto instructivo pastoral
                  Container(
                    padding: const EdgeInsetsDirectional.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF072B4F).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFE5A023),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n?.imprimeColocaAfiche ??
                                'Imprime este cartel y colócalo en la entrada o boletín de tu iglesia para que los feligreses se unan escaneando el código QR.',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón principal de impresión / guardado PDF
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5A023), // Oro ATRIO
                        foregroundColor: const Color(0xFF072B4F),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 22),
                      label: Text(
                        l10n?.descargarAfichePdf ?? 'Descargar / Imprimir Afiche (PDF)',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _generateAndPrintPdf(
                        churchName,
                        _joinUrl ?? 'https://atrioapp.odoo19rd.com',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

/// Tarjeta que reproduce visualmente el afiche oficial de ATRIO
class PosterGraphicCard extends StatelessWidget {
  final String churchName;
  final String joinUrl;

  const PosterGraphicCard({
    super.key,
    required this.churchName,
    required this.joinUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // 1. Cabecera con degradado y branding
            Container(
              width: double.infinity,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF072B4F), Color(0xFF0F3E6C)],
                ),
              ),
              child: Column(
                children: [
                  // Logo ATRIO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/logo_encabezado_sinfondo.png',
                        height: 38,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.church,
                          color: Color(0xFFE5A023),
                          size: 34,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'APP CRISTIANA',
                    style: TextStyle(
                      color: Color(0xFFE5A023),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '¡Agrégate a la\nfamilia ATRIO!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Nombre de la Parroquia
                  Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      churchName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Código QR Central con Marco Dorado
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsetsDirectional.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE5A023), // Oro ATRIO
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE5A023).withValues(alpha: 0.25),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: joinUrl,
                      version: QrVersions.auto,
                      size: 210,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF072B4F),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF072B4F),
                      ),
                      errorCorrectionLevel: QrErrorCorrectLevel.Q,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Call To Action Dorado
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5A023),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE5A023).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Color(0xFF072B4F),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Escanea aquí y conéctate con nuestra iglesia',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF072B4F),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. Pie con Iconos de la Comunidad (Eventos, Comunidad, Avisos)
            Container(
              width: double.infinity,
              padding: const EdgeInsetsDirectional.symmetric(vertical: 16, horizontal: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF072B4F),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  PosterPillarItem(
                    icon: Icons.calendar_month_rounded,
                    label: 'Eventos',
                  ),
                  PosterPillarItem(
                    icon: Icons.groups_rounded,
                    label: 'Comunidad',
                  ),
                  PosterPillarItem(
                    icon: Icons.notifications_active_rounded,
                    label: 'Avisos',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Elemento del pie del afiche
class PosterPillarItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const PosterPillarItem({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFE5A023), size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
