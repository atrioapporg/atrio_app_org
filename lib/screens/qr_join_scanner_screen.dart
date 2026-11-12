import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/providers/join_church_provider.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/inicio_sesion_screen.dart';
import 'package:atrio/widgets/church_join_confirmation_modal.dart';

/// Pantalla in-app para la captura visual de códigos QR de vinculación a iglesias.
class QrJoinScannerScreen extends StatefulWidget {
  static const String routeName = 'qr_join_scanner_screen';

  const QrJoinScannerScreen({super.key});

  @override
  State<QrJoinScannerScreen> createState() => _QrJoinScannerScreenState();
}

class _QrJoinScannerScreenState extends State<QrJoinScannerScreen> with WidgetsBindingObserver {
  late final MobileScannerController _scannerController;
  bool _isProcessingCode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: const [BarcodeFormat.qrCode],
      returnImage: false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_scannerController.value.isInitialized) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _scannerController.stop();
    } else if (state == AppLifecycleState.resumed) {
      final joinProvider = context.read<JoinChurchProvider>();
      if (joinProvider.isScannerActive) {
        _scannerController.start();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessingCode) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    setState(() => _isProcessingCode = true);

    // 1. Detener sensor óptico inmediatamente para economizar recursos y evitar reintentos concurrentes
    await _scannerController.stop();

    if (!mounted) return;
    final joinProvider = context.read<JoinChurchProvider>();
    final userProvider = context.read<UserProvider>();

    // 2. Procesar el token en el Provider
    final bool success = await joinProvider.handleJoinToken(
      rawInput: rawValue,
      userProvider: userProvider,
    );

    if (!mounted) return;

    if (success) {
      if (joinProvider.step == JoinChurchStep.requiresLogin) {
        // Redirigir al inicio de sesión conservando el deferred token guardado
        Navigator.pushReplacementNamed(context, InicioSesionScreen.routeName);
      } else if (joinProvider.step == JoinChurchStep.previewReady) {
        // Desplegar modal reactivo de confirmación
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (modalContext) => const ChurchJoinConfirmationModal(),
        );

        // Si el usuario cierra el modal sin confirmar, reactivar el escáner
        if (mounted) {
          joinProvider.reset();
          await _scannerController.start();
          setState(() => _isProcessingCode = false);
        }
      }
    } else {
      // Notificar error al usuario y reactivar el escáner
      final l10n = AppLocalizations.of(context);
      final String mensajeError = joinProvider.errorCode == 'outdated_qr'
          ? (l10n?.errorQrDesactualizado ??
              'El código QR escaneado está desactualizado. Por favor, regenera o vuelve a abrir el código en la pantalla de la iglesia.')
          : (joinProvider.errorMessage ??
              l10n?.errorQrInvalido ??
              'Código QR no válido para ATRIO');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeError),
          backgroundColor: Colors.redAccent,
        ),
      );
      joinProvider.reset();
      if (mounted) {
        await _scannerController.start();
        setState(() => _isProcessingCode = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final joinProvider = context.watch<JoinChurchProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Capa de visualización del visor de cámara con control de error integrado
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcodeDetected,
            errorBuilder: (context, error) {
              return ScannerErrorCard(
                error: error,
                onRetry: () => _scannerController.start(),
              );
            },
          ),

          // 2. Overlay visual con marco de encuadre y efecto semitransparente
          const ScannerTargetOverlay(),

          // 3. Barra superior con título y botón de cierre
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: ScannerTopBar(
              title: l10n?.escanearQrIglesia ?? 'Escanear QR de Iglesia',
              onClosePressed: () => Navigator.of(context).pop(),
            ),
          ),

          // 4. Instrucción inferior para guiar al feligrés
          PositionedDirectional(
            bottom: 48,
            start: 24,
            end: 24,
            child: ScannerInstructionCard(
              message: l10n?.apuntaCamaraQr ??
                  'Enfoca el código QR oficial de tu congregación en el recuadro',
              controller: _scannerController,
            ),
          ),

          // 5. Indicador de carga si se está resolviendo el token con Odoo 19
          if (joinProvider.isLoading || _isProcessingCode)
            const Positioned.fill(
              child: ScannerLoadingIndicator(),
            ),
        ],
      ),
    );
  }
}

/// Widget dedicado para presentar fallos de hardware o permisos denegados de cámara
class ScannerErrorCard extends StatelessWidget {
  final MobileScannerException error;
  final VoidCallback onRetry;

  const ScannerErrorCard({
    super.key,
    required this.error,
    required this.onRetry,
  });

  Future<void> _abrirAjustes() async {
    final uri = Uri.parse('app-settings:');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isPermissionError =
        error.errorCode == MobileScannerErrorCode.permissionDenied;

    final String mensaje = isPermissionError
        ? (l10n?.errorPermisoCamara ??
            'Se necesita permiso de acceso a la cámara para escanear el código QR.')
        : (l10n?.errorHardwareCamara ??
            'No se pudo acceder a la cámara en este dispositivo.');

    return Center(
      child: Container(
        margin: const EdgeInsetsDirectional.symmetric(horizontal: 32),
        padding: const EdgeInsetsDirectional.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF072B4F).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE5A023),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPermissionError
                  ? Icons.no_photography_rounded
                  : Icons.videocam_off_rounded,
              size: 56,
              color: const Color(0xFFE5A023),
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isPermissionError) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5A023),
                      foregroundColor: const Color(0xFF072B4F),
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.settings, size: 18),
                    label: Text(
                      l10n?.abrirAjustesDispositivo ?? 'Abrir Ajustes',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _abrirAjustes,
                  ),
                  const SizedBox(width: 12),
                ],
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(l10n?.reintentar ?? 'Reintentar'),
                  onPressed: onRetry,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra superior flotante con gradiente oscuro para legibilidad.
class ScannerTopBar extends StatelessWidget {
  final String title;
  final VoidCallback onClosePressed;

  const ScannerTopBar({
    super.key,
    required this.title,
    required this.onClosePressed,
  });

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsetsDirectional.only(
        top: topPadding + 8,
        bottom: 16,
        start: 16,
        end: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: onClosePressed,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance visual con el IconButton inicial
        ],
      ),
    );
  }
}

/// Marco central que recorta visualmente el área focal de escaneo.
class ScannerTargetOverlay extends StatelessWidget {
  const ScannerTargetOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final double scanArea = size.width * 0.72;

    return Center(
      child: Container(
        width: scanArea,
        height: scanArea,
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFE5A023), // Amarillo Oro ATRIO
            width: 2.5,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE5A023).withValues(alpha: 0.25),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta inferior con controles de cámara (flash y toggle) y texto guía.
class ScannerInstructionCard extends StatelessWidget {
  final String message;
  final MobileScannerController controller;

  const ScannerInstructionCard({
    super.key,
    required this.message,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF072B4F).withValues(alpha: 0.88), // Azul Noche ATRIO
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón de Linterna (Torch)
              ValueListenableBuilder<MobileScannerState>(
                valueListenable: controller,
                builder: (context, state, child) {
                  final bool isOn = state.torchState == TorchState.on;
                  return IconButton(
                    icon: Icon(
                      isOn ? Icons.flash_on : Icons.flash_off,
                      color: isOn ? const Color(0xFFE5A023) : Colors.white70,
                    ),
                    onPressed: () => controller.toggleTorch(),
                  );
                },
              ),

              const SizedBox(width: 24),
              // Botón para Alternar Cámara (Frontal / Trasera)
              IconButton(
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white70),
                onPressed: () => controller.switchCamera(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pantalla semitransparente de bloqueo y spinner mientras la API responde.
class ScannerLoadingIndicator extends StatelessWidget {
  const ScannerLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE5A023)),
        ),
      ),
    );
  }
}
