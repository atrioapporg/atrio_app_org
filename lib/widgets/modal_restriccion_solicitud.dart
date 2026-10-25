import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../providers/user_provider.dart';
import '../screens/esperando_aprobacion_screen.dart';
import '../screens/tradicion_cristiana_screen.dart';
import 'modal_restriccion_donacion.dart';

/// Controlador y diálogo modal para restringir de forma preventiva y amigable
/// el acceso a las solicitudes pastorales cuando la iglesia del usuario
/// se encuentra pendiente de aprobación, no está asignada o la sesión es invitada.
class ModalRestriccionSolicitud {
  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFE8ECEF);

  /// Evalúa reactivamente si el usuario cuenta con los requisitos para acceder
  /// o diligenciar el formulario de solicitudes pastorales.
  ///
  /// Valida:
  /// 1. Autenticación (Modo invitado -> modal de inicio de sesión).
  /// 2. Modo solo lectura (Superadmin/Auditoría -> advertencia).
  /// 3. Estatus de iglesia pendiente de aprobación (`churchStatus == 'membership_pending'` o `isMembershipPending`).
  /// 4. Iglesia debidamente asignada y aprobada (`hasChurchAssigned` e `isChurchApproved`).
  ///
  /// Si alguna validación falla, muestra el diálogo restrictivo o alerta y ejecuta [onDenegado].
  /// Retorna `true` únicamente si el acceso está plenamente autorizado.
  static bool verificarAcceso({
    required BuildContext context,
    VoidCallback? onDenegado,
  }) {
    final effectiveContext = context.mounted
        ? context
        : (MyApp.navigatorKey.currentContext?.mounted == true
            ? MyApp.navigatorKey.currentContext!
            : context);
    if (!effectiveContext.mounted) return false;

    final userProvider = effectiveContext.read<UserProvider>();
    final l10n = AppLocalizations.of(effectiveContext);

    // 1. Modo invitado
    if (!userProvider.isAuthenticated) {
      ModalRestriccionDonacion.mostrar(
        context: effectiveContext,
        forzarModoInvitado: true,
        mensajePersonalizado: l10n?.solicitudRequiereSesion ??
            'Debes iniciar sesión con tu cuenta para enviar solicitudes o peticiones pastorales a tu congregación.',
      );
      onDenegado?.call();
      return false;
    }

    // 2. Modo solo lectura
    if (userProvider.isReadOnly) {
      ScaffoldMessenger.maybeOf(effectiveContext)?.showSnackBar(
        SnackBar(
          content: Text(
            l10n?.accionRestringidaSoloLectura ??
                'Acción no disponible en modo solo lectura',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      onDenegado?.call();
      return false;
    }

    // 3. Estatus de iglesia pendiente de aprobación en backend
    final bool tieneIglesiaPendiente = userProvider.isMembershipPending ||
        userProvider.churchStatus == 'membership_pending' ||
        userProvider.churchStatus == 'pending' ||
        (!userProvider.isChurchApproved &&
            (userProvider.hasChurchAssigned ||
                userProvider.requestedChurchId != null ||
                (userProvider.currentUser?.iglesiaActual != null &&
                    userProvider.currentUser?.iglesiaActual !=
                        'Sin iglesia seleccionada' &&
                    userProvider.currentUser?.iglesiaActual !=
                        'Iglesia Atrio')));

    if (tieneIglesiaPendiente) {
      mostrarIglesiaPendiente(
        context: effectiveContext,
        onCerrar: onDenegado,
      );
      return false;
    }

    // 4. Sin iglesia asignada o no aprobada
    if (!userProvider.hasChurchAssigned || !userProvider.isChurchApproved) {
      mostrarAlertaIglesiaRequerida(
        context: effectiveContext,
        duracion: const Duration(seconds: 7),
      );
      onDenegado?.call();
      return false;
    }

    return true;
  }

  /// Despliega un diálogo modal restrictivo cuando el usuario tiene una congregación
  /// cuya aprobación pastoral aún se encuentra en revisión.
  static void mostrarIglesiaPendiente({
    required BuildContext context,
    VoidCallback? onCerrar,
    VoidCallback? onRedirigir,
  }) {
    final effectiveContext = context.mounted
        ? context
        : (MyApp.navigatorKey.currentContext?.mounted == true
            ? MyApp.navigatorKey.currentContext!
            : context);
    if (!effectiveContext.mounted) return;

    final l10n = AppLocalizations.of(effectiveContext);
    final screenWidth = MediaQuery.sizeOf(effectiveContext).width;
    final userProvider =
        Provider.of<UserProvider>(effectiveContext, listen: false);

    final String? nombreReq =
        userProvider.requestedChurchData?['name'] as String? ??
        userProvider.currentUser?.requestedChurchData?['name'] as String?;
    final String? nombreAct =
        (userProvider.currentUser?.iglesiaActual != null &&
                userProvider.currentUser?.iglesiaActual !=
                    'Sin iglesia seleccionada' &&
                userProvider.currentUser?.iglesiaActual != 'Iglesia Atrio')
            ? userProvider.currentUser?.iglesiaActual
            : null;
    final String churchName = (nombreReq != null && nombreReq.isNotEmpty)
        ? nombreReq
        : (nombreAct ?? '');

    final String prefix = (churchName.toLowerCase().startsWith('el ') ||
            churchName.toLowerCase().startsWith('templo '))
        ? 'al '
        : (churchName.toLowerCase().startsWith('la ') ? '' : 'a la ');

    final String mensajeDesc = churchName.isNotEmpty
        ? 'Perteneces $prefix$churchName, pero tu aprobación se encuentra actualmente pendiente por parte de la administración. Una vez aprobada por el pastor o administrador, podrás enviar solicitudes y peticiones pastorales.'
        : (l10n?.solicitudRequiereMembresia ??
            'Tu cuenta está pendiente de asignación o aprobación de membresía por parte de tu congregación para enviar solicitudes.');

    showDialog(
      context: effectiveContext,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: blancoFondo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
          ),
          contentPadding: EdgeInsets.all(screenWidth * 0.05),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: amarilloOro.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    color: amarilloOro,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n?.membresiaPendiente ?? 'Membresía pendiente de aprobación',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: azulFondo,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  mensajeDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: amarilloOro,
                      foregroundColor: azulFondo,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.remove_red_eye_outlined),
                    label: const Text(
                      'Ver estado de solicitud',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      if (dialogCtx.mounted) {
                        Navigator.of(dialogCtx).pop();
                      }
                      if (onRedirigir != null) {
                        onRedirigir();
                      } else {
                        final nav = MyApp.navigatorKey.currentState ??
                            (effectiveContext.mounted
                                ? Navigator.maybeOf(effectiveContext)
                                : null);
                        nav?.pushNamed(EsperandoAprobacionScreen.routeName);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () {
                    if (dialogCtx.mounted) {
                      Navigator.of(dialogCtx).pop();
                    }
                    onCerrar?.call();
                  },
                  child: Text(
                    l10n?.entendido ?? 'Entendido',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Muestra la advertencia visual con auto-dismiss garantizado
  /// para evitar que permanezca invasivamente en pantalla.
  ///
  /// Soporta un tiempo configurable (por defecto 7 segundos, rango recomendado 5 - 10 s).
  /// Utiliza `Future.delayed` para desvanecer y cerrar automáticamente el aviso.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
      mostrarAlertaIglesiaRequerida({
    required BuildContext context,
    Duration duracion = const Duration(seconds: 7),
    String? mensaje,
    VoidCallback? onSeleccionarIglesia,
  }) {
    final effectiveContext = context.mounted
        ? context
        : (MyApp.navigatorKey.currentContext?.mounted == true
            ? MyApp.navigatorKey.currentContext!
            : context);
    if (!effectiveContext.mounted) return null;

    final l10n = AppLocalizations.of(effectiveContext);
    final messenger = ScaffoldMessenger.maybeOf(effectiveContext);
    if (messenger == null) return null;

    final texto = mensaje ??
        l10n?.iglesiaRequeridaParaSolicitud ??
        'Debes tener una iglesia asignada para enviar solicitudes o peticiones pastorales.';

    // Ocultar snackbar previo para evitar acumulación invasiva
    messenger.hideCurrentSnackBar();

    final snackBarController = messenger.showSnackBar(
      SnackBar(
        duration: duracion,
        backgroundColor: azulFondo,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: amarilloOro.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        content: Row(
          children: [
            const Icon(
              Icons.church_outlined,
              color: amarilloOro,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                texto,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: l10n?.seleccionarIglesiaAccion ?? 'Seleccionar iglesia',
          textColor: amarilloOro,
          onPressed: () {
            if (onSeleccionarIglesia != null) {
              onSeleccionarIglesia();
            } else {
              final nav = MyApp.navigatorKey.currentState ??
                  (effectiveContext.mounted
                      ? Navigator.maybeOf(effectiveContext)
                      : null);
              nav?.pushNamed(TradicionCristianaScreen.routeName);
            }
          },
        ),
      ),
    );

    // Auto-dismiss programado de forma no invasiva con temporizador
    Future.delayed(duracion, () {
      try {
        snackBarController.close();
      } catch (_) {}
    });

    return snackBarController;
  }
}
