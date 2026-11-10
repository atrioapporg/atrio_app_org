import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/user_provider.dart';

/// Banner persistente que informa al usuario cuando ha solicitado un cambio de iglesia
/// y la solicitud está actualmente en revisión por la administración de la nueva congregación.
/// Incluye botón directo para cancelar el cambio de congregación y permanecer en la iglesia actual.
class ChangePendingBanner extends StatelessWidget {
  /// Margen exterior opcional para adaptarse a diferentes pantallas o listas.
  final EdgeInsetsGeometry? margin;

  const ChangePendingBanner({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    final isChangePending = context.select<UserProvider, bool>(
      (p) => p.currentUser?.isChangePending ?? false,
    );
    if (!isChangePending) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    return Container(
      width: double.infinity,
      margin: margin ??
          EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 6),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.035,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: azulFondo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: amarilloOro.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.swap_horiz_rounded,
            color: amarilloOro,
            size: screenWidth * 0.052,
          ),
          SizedBox(width: screenWidth * 0.025),
          Expanded(
            child: Text(
              l10n?.perfilCambioCongregacionDesc ??
                  'Tu solicitud para trasladarte a una nueva congregación está en proceso de revisión por la administración.',
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.03,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          InkWell(
            onTap: () => _confirmarCancelarCambio(context),
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.025,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                border: Border.all(
                  color: amarilloOro.withValues(alpha: 0.7),
                  width: 0.9,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.close_rounded,
                    color: amarilloOro,
                    size: screenWidth * 0.035,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    l10n?.cancelar ?? 'Cancelar',
                    style: TextStyle(
                      color: amarilloOro,
                      fontSize: screenWidth * 0.027,
                      fontWeight: FontWeight.bold,
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

  Future<void> _confirmarCancelarCambio(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final userProvider = context.read<UserProvider>();
    final iglesiaActual =
        userProvider.currentUser?.iglesiaActual ?? 'tu congregación actual';

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          l10n?.cancelarSolicitudCambio ?? '¿Cancelar solicitud de cambio?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n?.cancelarSolicitudCambioDesc ??
              '¿Deseas cancelar la solicitud de cambio? Permanecerás como miembro activo en tu congregación actual ($iglesiaActual).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              l10n?.continuarConCambio ?? 'Continuar con el cambio',
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n?.permanecerEnMiIglesia ?? 'Permanecer en mi iglesia',
            ),
          ),
        ],
      ),
    );

    if (confirmado == true && context.mounted) {
      final exito =
          await context.read<UserProvider>().cancelarSolicitudCambioIglesia();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Text(
              exito
                  ? (l10n?.solicitudCambioCanceladaExito ??
                      'Solicitud de cambio cancelada. Permaneces en tu congregación.')
                  : (l10n?.noSePudoCancelar ??
                      'No se pudo cancelar la solicitud. Intenta nuevamente.'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
