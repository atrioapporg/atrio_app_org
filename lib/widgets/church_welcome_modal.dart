import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

/// Modal informativo de bienvenida que se muestra una única vez cuando el usuario
/// ingresa a la selección de iglesia por primera vez.
///
/// Utiliza [SharedPreferences] con la clave `has_seen_church_welcome_modal`
/// para garantizar persistencia estricta de visualización única.
class ChurchWelcomeModal {
  static const String prefsKey = 'has_seen_church_welcome_modal';

  /// Texto exacto corporativo requerido por la experiencia de usuario
  static const String mensajeBienvenida =
      'Conéctate a tu iglesia local para acceder a devocionales, eventos, oraciones y la vida de tu comunidad';

  // Paleta corporativa ATRIO
  static const Color azulFondo = Color(0xFF072B4F);
  static const Color azulOscuro = Color(0xFF03182E);
  static const Color azulMedio = Color(0xFF0F4C81);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFE2E8F0);
  static const Color textoOscuro = Color(0xFF0F172A);
  static const Color textoGris = Color(0xFF64748B);

  /// Consulta si el usuario ya ha visualizado el modal previamente.
  static Future<bool> haVistoModal({SharedPreferences? customPrefs}) async {
    try {
      final prefs = customPrefs ?? await SharedPreferences.getInstance();
      return prefs.getBool(prefsKey) ?? false;
    } catch (e) {
      debugPrint('[ChurchWelcomeModal] Error comprobando bandera: $e');
      return false;
    }
  }

  /// Marca la bandera como vista en persistencia local.
  static Future<void> marcarComoVisto({SharedPreferences? customPrefs}) async {
    try {
      final prefs = customPrefs ?? await SharedPreferences.getInstance();
      await prefs.setBool(prefsKey, true);
    } catch (e) {
      debugPrint('[ChurchWelcomeModal] Error guardando bandera: $e');
    }
  }

  /// Restablece la bandera para pruebas o reinicio de flujo.
  static Future<void> resetearBandera({SharedPreferences? customPrefs}) async {
    try {
      final prefs = customPrefs ?? await SharedPreferences.getInstance();
      await prefs.remove(prefsKey);
    } catch (e) {
      debugPrint('[ChurchWelcomeModal] Error al resetear bandera: $e');
    }
  }

  /// Verifica si el modal ya fue mostrado anteriormente.
  /// Si NO se ha mostrado, dispara el modal y guarda el estado (`true`) para evitar
  /// que vuelva a aparecer. Retorna `true` si el modal fue mostrado, o `false` si ya se había visto.
  static Future<bool> mostrarSiEsPrimeraVez(
    BuildContext context, {
    SharedPreferences? customPrefs,
  }) async {
    final yaVisto = await haVistoModal(customPrefs: customPrefs);
    if (yaVisto) return false;

    // Marcamos inmediatamente como visto para evitar aperturas concurrentes
    await marcarComoVisto(customPrefs: customPrefs);

    if (!context.mounted) return false;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => const ChurchWelcomeDialog(),
    );

    return true;
  }

  /// Despliega directamente el diálogo modal sin comprobar la bandera.
  static Future<void> mostrar(BuildContext context) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => const ChurchWelcomeDialog(),
    );
  }
}

/// Diálogo visual de bienvenida con estilo y paleta corporativa de ATRIO.
class ChurchWelcomeDialog extends StatelessWidget {
  const ChurchWelcomeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dialogWidth = size.width > 500 ? 420.0 : size.width * 0.88;

    final l10n = AppLocalizations.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      elevation: 0,
      child: Center(
        child: Container(
          width: dialogWidth,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: ChurchWelcomeModal.grisBorde,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: ChurchWelcomeModal.azulFondo.withValues(alpha: 0.16),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono central con diseño de aura dorada corporativa
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: ChurchWelcomeModal.amarilloOro.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ChurchWelcomeModal.amarilloOro.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.church_rounded,
                    color: ChurchWelcomeModal.amarilloOro,
                    size: 38,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Encabezado de bienvenida localizado
              Text(
                l10n?.bienvenidaAtrio ?? '¡Bienvenido a ATRIO!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ChurchWelcomeModal.textoOscuro,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 12),

              // Texto exacto requerido y localizado
              Text(
                l10n?.modalBienvenidaIglesiaMensaje ??
                    ChurchWelcomeModal.mensajeBienvenida,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ChurchWelcomeModal.textoGris,
                  fontSize: 14.5,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 26),

              // Botón de acción principal
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ChurchWelcomeModal.azulFondo,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n?.continuar ?? 'Continuar',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Transform.flip(
                        flipX: isRtl,
                        child: const Icon(Icons.arrow_forward_rounded, size: 18),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Opción secundaria rápida ("Entendido")
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: ChurchWelcomeModal.textoGris,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l10n?.entendido ?? 'Entendido',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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
