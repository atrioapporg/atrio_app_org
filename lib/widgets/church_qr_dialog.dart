import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/user_provider.dart';
import '../servicios/join_church_service.dart';

/// Gestor y caché centralizado del código QR oficial de la iglesia.
/// Permite precargar y abrir el diálogo modal de QR desde cualquier pantalla
/// de la aplicación (ej. `IglesiaScreen`, `InicioAtrioScreen`) reutilizando
/// las respuestas descargadas de Odoo 19.
class ChurchQrManager {
  ChurchQrManager._();

  static final Map<int, ({Uint8List bytes, String? joinUrl})> _cache = {};

  /// Limpia la caché en memoria de códigos QR (ej. al cerrar o expirar la sesión).
  static void clearCache() => _cache.clear();

  /// Obtiene o descarga los bytes PNG del código QR de la congregación especificada.
  /// Endpoint: `GET /atrio/portal/api/church/qr.png?download=1` con `Authorization: Bearer <token>`.
  static Future<({Uint8List bytes, String? joinUrl})?> obtenerQr({
    required BuildContext context,
    required int churchId,
  }) async {
    final cached = _cache[churchId];
    if (cached != null) {
      return cached;
    }

    final userProvider = context.read<UserProvider>();
    final api = userProvider.api;

    await api.ensureInitialized();

    if (!api.isAuthenticated && api.refreshToken == null) {
      return null;
    }

    try {
      final res = await api.getChurchQr(download: true);
      String? joinUrl = res.joinUrl;

      // Respaldo de URL canónica de vinculación si Odoo no envió el encabezado
      if ((joinUrl == null || joinUrl.isEmpty) && context.mounted) {
        final validToken = await api.getValidAccessToken();
        joinUrl = await JoinChurchService().resolveChurchJoinUrl(
          churchId: churchId,
          accessToken: validToken,
        );
      }

      final data = (bytes: res.bytes, joinUrl: joinUrl);
      _cache[churchId] = data;
      return data;
    } catch (e) {
      debugPrint('ℹ️ [ChurchQrManager] No se pudo obtener QR de iglesia: $e');
      return null;
    }
  }

  /// Despliega el diálogo modal con el código QR ampliado y marco dorado.
  /// Si los datos ya se encuentran en memoria, se abre instantáneamente.
  /// De lo contrario, solicita los datos a Odoo antes de presentarlo.
  static Future<void> mostrarModal({
    required BuildContext context,
    required String churchName,
    required String denomination,
    required int churchId,
    Color azulFondo = const Color(0xFF072B4F),
    Color amarilloOro = const Color(0xFFE5A023),
  }) async {
    HapticFeedback.lightImpact();

    // 1. Apertura instantánea si ya está en caché
    final cached = _cache[churchId];
    if (cached != null) {
      _mostrarDialogo(
        context: context,
        churchName: churchName,
        denomination: denomination,
        qrBytes: cached.bytes,
        joinUrl: cached.joinUrl,
        azulFondo: azulFondo,
        amarilloOro: amarilloOro,
      );
      return;
    }

    // 2. Consulta en segundo plano con notificación de error si falla
    final l10n = AppLocalizations.of(context);
    final data = await obtenerQr(context: context, churchId: churchId);
    if (!context.mounted) return;

    if (data != null) {
      _mostrarDialogo(
        context: context,
        churchName: churchName,
        denomination: denomination,
        qrBytes: data.bytes,
        joinUrl: data.joinUrl,
        azulFondo: azulFondo,
        amarilloOro: amarilloOro,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.errorCargarQrIglesia ??
                'No se pudo cargar el código QR de la congregación.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  static void _mostrarDialogo({
    required BuildContext context,
    required String churchName,
    required String denomination,
    required Uint8List qrBytes,
    required String? joinUrl,
    required Color azulFondo,
    required Color amarilloOro,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => ChurchQrDialog(
        churchName: churchName,
        denomination: denomination,
        qrBytes: qrBytes,
        joinUrl: joinUrl,
        azulFondo: azulFondo,
        amarilloOro: amarilloOro,
      ),
    );
  }
}

/// Diálogo modal interactivo para visualizar el código QR oficial de la iglesia
/// en alta resolución y permitir copiar/compartir el enlace canónico de vinculación.
class ChurchQrDialog extends StatelessWidget {
  final String churchName;
  final String denomination;
  final Uint8List qrBytes;
  final String? joinUrl;
  final Color azulFondo;
  final Color amarilloOro;

  const ChurchQrDialog({
    super.key,
    required this.churchName,
    required this.denomination,
    required this.qrBytes,
    required this.joinUrl,
    required this.azulFondo,
    required this.amarilloOro,
  });

  Future<void> _copiarEnlace(BuildContext context) async {
    if (joinUrl == null || joinUrl!.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: joinUrl!));
    if (!context.mounted) return;
    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n?.enlaceInvitacionCopiado ??
                    '¡Enlace de invitación copiado al portapapeles!',
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final qrBoxSize = (size.width * 0.62).clamp(180.0, 260.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Badge de encabezado
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: azulFondo.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_2_rounded, size: 18, color: azulFondo),
                    const SizedBox(width: 6),
                    Text(
                      l10n?.qrOficialIglesiaTitulo ?? 'Código QR Oficial',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: azulFondo,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Nombre de la iglesia
              Text(
                churchName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF072B4F),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (denomination.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  denomination,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Contenedor del QR en alta resolución con marco dorado
              Container(
                width: qrBoxSize,
                height: qrBoxSize,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: amarilloOro.withValues(alpha: 0.7),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    qrBytes,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Subtítulo explicativo
              Text(
                l10n?.qrOficialIglesiaSubtitulo ??
                    'Muestra este código para que otros feligreses o visitantes se unan a esta iglesia en ATRIO.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey.shade700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              // Botón de copiar enlace si está disponible
              if (joinUrl != null && joinUrl!.isNotEmpty) ...[
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azulFondo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Text(
                      l10n?.copiarEnlaceInvitacion ??
                          'Copiar enlace de invitación',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    onPressed: () => _copiarEnlace(context),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              // Botón de cerrar
              SizedBox(
                width: double.infinity,
                height: 42,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    l10n?.cerrar ?? 'Cerrar',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
