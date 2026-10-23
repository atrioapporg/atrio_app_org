import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/main.dart';
import 'package:atrio/modelos/auth_permissions.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/inicio_sesion_screen.dart';

/// Diálogo modal estilizado para informar de forma proactiva al usuario
/// cuando no cumple con los requisitos de autenticación (modo invitado),
/// membresía o permisos para realizar acciones en la aplicación.
class ModalRestriccionDonacion {
  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFE8ECEF);

  /// Evalúa si el usuario actual está autenticado. Si está autenticado, retorna `true`.
  /// Si está en modo invitado (no autenticado), muestra el diálogo modal
  /// "Inicio de sesión requerido" con las opciones "Iniciar sesión" y "Cancelar",
  /// y retorna `false`.
  static bool verificarAutenticacion({
    required BuildContext context,
    String? titulo,
    String? mensaje,
  }) {
    final effectiveContext = context.mounted
        ? context
        : (MyApp.navigatorKey.currentContext?.mounted == true
              ? MyApp.navigatorKey.currentContext!
              : context);
    if (!effectiveContext.mounted) return false;
    final userProvider = effectiveContext.read<UserProvider>();
    if (userProvider.isAuthenticated) {
      return true;
    }

    mostrar(
      context: effectiveContext,
      tituloPersonalizado: titulo,
      mensajePersonalizado: mensaje,
      forzarModoInvitado: true,
    );
    return false;
  }

  /// Evalúa si el usuario actual puede realizar una donación general a la plataforma ATRIO.
  /// Conforme a Odoo 19 (Pablo Oliveros Págs. 2 y 6), las donaciones por PayPal y transferencia
  /// están permitidas tanto para miembros como para invitados sin sesión.
  /// Se bloquea exclusivamente si la sesión opera en modo solo lectura (Super Admin: isReadOnly == true).
  static bool verificarDonacionGeneral({
    required BuildContext context,
    String? titulo,
    String? mensaje,
  }) {
    final effectiveContext = context.mounted
        ? context
        : (MyApp.navigatorKey.currentContext?.mounted == true
              ? MyApp.navigatorKey.currentContext!
              : context);
    if (!effectiveContext.mounted) return true;
    final userProvider = effectiveContext.read<UserProvider>();
    if (userProvider.isReadOnly) {
      mostrar(
        context: effectiveContext,
        tituloPersonalizado: titulo,
        mensajePersonalizado: mensaje,
      );
      return false;
    }
    return true;
  }

  /// Evalúa si el usuario actual puede donar ofrendas congregacionales locales.
  /// Si no puede, despliega el diálogo informativo con la acción adecuada y retorna `false`.
  static bool verificarYMostrar({
    required BuildContext context,
    String? titulo,
    String? mensaje,
  }) {
    final effectiveContext = context.mounted
        ? context
        : (MyApp.navigatorKey.currentContext?.mounted == true
              ? MyApp.navigatorKey.currentContext!
              : context);
    if (!effectiveContext.mounted) return false;
    final userProvider = effectiveContext.read<UserProvider>();
    if (userProvider.canDonate) {
      return true;
    }

    mostrar(
      context: effectiveContext,
      tituloPersonalizado: titulo,
      mensajePersonalizado: mensaje,
    );
    return false;
  }

  /// Muestra el modal explicativo con el motivo específico de restricción.
  static void mostrar({
    required BuildContext context,
    String? tituloPersonalizado,
    String? mensajePersonalizado,
    bool forzarModoInvitado = false,
  }) {
    final effectiveContext = context.mounted
        ? context
        : (MyApp.navigatorKey.currentContext?.mounted == true
              ? MyApp.navigatorKey.currentContext!
              : context);
    if (!effectiveContext.mounted) return;

    final l10n = AppLocalizations.of(effectiveContext);
    final userProvider = effectiveContext.read<UserProvider>();
    final screenWidth = MediaQuery.sizeOf(effectiveContext).width;
    final usableHeight =
        MediaQuery.sizeOf(effectiveContext).height -
        MediaQuery.of(effectiveContext).padding.top;

    final bool esInvitado = !userProvider.isAuthenticated || forzarModoInvitado;
    final bool esReadOnly = userProvider.isReadOnly;
    final bool sinIglesia = !userProvider.hasChurchAssigned;
    final bool membresiaPendiente =
        userProvider.role == UserRole.user ||
        (!userProvider.isMember && !userProvider.isChurchAdmin);

    IconData icono = Icons.lock_person_outlined;
    Color colorIcono = amarilloOro;
    String titulo =
        tituloPersonalizado ??
        l10n?.inicioSesionRequerido ??
        'Inicio de sesión requerido';
    String mensaje =
        mensajePersonalizado ??
        l10n?.sesionRequeridaGenerica ??
        'Debes iniciar sesión con tu cuenta para acceder a esta función.';
    bool mostrarBotonLogin = false;

    if (esInvitado) {
      icono = Icons.account_circle_outlined;
      colorIcono = amarilloOro;
      titulo =
          tituloPersonalizado ??
          l10n?.inicioSesionRequerido ??
          'Inicio de sesión requerido';
      mensaje =
          mensajePersonalizado ??
          l10n?.sesionRequeridaGenerica ??
          'Debes iniciar sesión con tu cuenta para acceder a esta función.';
      mostrarBotonLogin = true;
    } else if (esReadOnly) {
      icono = Icons.lock_clock_outlined;
      colorIcono = Colors.amber.shade800;
      titulo = tituloPersonalizado ?? l10n?.modoSoloLectura ?? 'Solo lectura';
      mensaje =
          mensajePersonalizado ??
          l10n?.accionRestringidaSoloLectura ??
          'Acción no disponible en modo solo lectura.';
    } else if (membresiaPendiente) {
      icono = Icons.hourglass_top_rounded;
      colorIcono = amarilloOro;
      titulo =
          tituloPersonalizado ??
          l10n?.membresiaPendiente ??
          'Membresía pendiente de aprobación';
      mensaje = mensajePersonalizado ?? l10n?.donacionRequiereMembresia ?? 'Tu cuenta está registrada pero aún está pendiente de asignación o aprobación de membresía por parte de tu congregación. Solo miembros activos pueden realizar donaciones.';
    } else if (sinIglesia) {
      icono = Icons.church_outlined;
      colorIcono = amarilloOro;
      titulo = tituloPersonalizado ?? l10n?.iglesia ?? 'Congregación requerida';
      mensaje = mensajePersonalizado ?? l10n?.donacionRequiereIglesia ?? 'Debes pertenecer a una congregación asignada para realizar donaciones.';
    }

    showDialog(
      context: effectiveContext,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: blancoFondo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
          ),
          contentPadding: EdgeInsets.all(screenWidth * 0.05),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: screenWidth * 0.16,
                height: screenWidth * 0.16,
                decoration: BoxDecoration(
                  color: colorIcono.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icono, color: colorIcono, size: screenWidth * 0.09),
              ),
              SizedBox(height: usableHeight * 0.02),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.046,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: usableHeight * 0.012),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: screenWidth * 0.034,
                  height: 1.35,
                ),
              ),
              SizedBox(height: usableHeight * 0.025),
              if (mostrarBotonLogin) ...[
                SizedBox(
                  width: double.infinity,
                  height: usableHeight * 0.055,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: amarilloOro,
                      foregroundColor: azulFondo,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.025,
                        ),
                      ),
                    ),
                    onPressed: () {
                      // 1. Obtener el Navigator de forma segura ANTES de cerrar el diálogo.
                      // Priorizar MyApp.navigatorKey.currentState (global, inmune a contextos desactivados).
                      // Si no está disponible (ej. pruebas unitarias), verificar context.mounted antes de acceder.
                      final nav =
                          MyApp.navigatorKey.currentState ??
                          (effectiveContext.mounted
                              ? Navigator.maybeOf(effectiveContext)
                              : null) ??
                          (dialogCtx.mounted
                              ? Navigator.maybeOf(dialogCtx)
                              : null);

                      // 2. Cerrar el diálogo usando dialogCtx si sigue montado
                      if (dialogCtx.mounted) {
                        Navigator.of(dialogCtx).pop();
                      }

                      // 3. Navegar a la pantalla de inicio de sesión de forma segura
                      nav?.pushNamed(InicioSesionScreen.routeName);
                    },
                    child: Text(
                      l10n?.iniciarSesion ?? 'Iniciar sesión',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(height: usableHeight * 0.01),
                TextButton(
                  onPressed: () {
                    if (dialogCtx.mounted) {
                      Navigator.of(dialogCtx).pop();
                    }
                  },
                  child: Text(
                    l10n?.cancelar ?? 'Cancelar',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: usableHeight * 0.055,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azulFondo,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.025,
                        ),
                      ),
                    ),
                    onPressed: () {
                      if (dialogCtx.mounted) {
                        Navigator.of(dialogCtx).pop();
                      }
                    },
                    child: Text(
                      l10n?.entendido ?? 'Entendido',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
