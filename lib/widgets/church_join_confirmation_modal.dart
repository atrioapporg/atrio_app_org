import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:atrio/data/app_config.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/modelos/join_church_models.dart';
import 'package:atrio/providers/join_church_provider.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/inicio_atrio_screen.dart';

/// Hoja modal inferior que presenta los datos de la iglesia escaneada
/// y permite confirmar la solicitud de membresía.
class ChurchJoinConfirmationModal extends StatelessWidget {
  const ChurchJoinConfirmationModal({super.key});

  @override
  Widget build(BuildContext context) {
    final joinProvider = context.watch<JoinChurchProvider>();
    final preview = joinProvider.currentPreview;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsetsDirectional.only(
        top: 24,
        start: 24,
        end: 24,
        bottom: MediaQuery.paddingOf(context).bottom + 20,
      ),
      child: preview == null
          ? const SizedBox(
              height: 180,
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF072B4F),
                ),
              ),
            )
          : joinProvider.step == JoinChurchStep.success
              ? const JoinSuccessView()
              : joinProvider.step == JoinChurchStep.alreadyMember
                  ? const AlreadyMemberView()
                  : JoinPromptView(preview: preview),
    );
  }
}

/// Vista de confirmación previa al envío de la solicitud.
class JoinPromptView extends StatelessWidget {
  final JoinChurchPreview preview;

  const JoinPromptView({
    super.key,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final joinProvider = context.watch<JoinChurchProvider>();
    final userProvider = context.read<UserProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Indicador de arrastre superior
        Container(
          width: 44,
          height: 4,
          margin: const EdgeInsetsDirectional.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Logo o escudo de la congregación
        ChurchAvatarBadge(logoUrl: preview.church.logoUrl),
        const SizedBox(height: 16),

        // Etiqueta de verificación eclesial
        Container(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF072B4F).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            l10n?.congregacionOficial ?? 'Congregación Oficial',
            style: const TextStyle(
              color: Color(0xFF072B4F),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Nombre de la Parroquia / Iglesia
        Text(
          preview.church.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),

        // Subtítulo explicativo
        Text(
          l10n?.deseasUnirteIglesia ??
              '¿Deseas solicitar tu vinculación a esta congregación?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),

        // Botón principal de acción: "Unirme a esta congregación"
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF072B4F), // Azul Principal ATRIO
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: joinProvider.isLoading
                ? null
                : () async {
                    await joinProvider.confirmJoinMembership(
                      userProvider: userProvider,
                    );
                  },
            child: joinProvider.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    l10n?.unirseCongregacion ?? 'Unirme a esta congregación',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),

        // Botón secundario: Cancelar
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton(
            onPressed: joinProvider.isLoading
                ? null
                : () => Navigator.of(context).pop(),
            child: Text(
              l10n?.cancelar ?? 'Cancelar',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Avatar con imagen de la iglesia o icono eclesial por defecto.
class ChurchAvatarBadge extends StatelessWidget {
  final String logoUrl;

  const ChurchAvatarBadge({
    super.key,
    required this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final String fullUrl = logoUrl.startsWith('http')
        ? logoUrl
        : '${AppConfig.odooBaseUrl}$logoUrl';

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFE5A023), // Oro ATRIO
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: logoUrl.isNotEmpty
            ? Image.network(
                fullUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.church,
                  size: 44,
                  color: Color(0xFF072B4F),
                ),
              )
            : const Icon(
                Icons.church,
                size: 44,
                color: Color(0xFF072B4F),
              ),
      ),
    );
  }
}

/// Estado visual tras recibir confirmación exitosa de Odoo 19.
class JoinSuccessView extends StatelessWidget {
  const JoinSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFFDCFCE7),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF16A34A),
            size: 48,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n?.solicitudEnviadaTitulo ?? '¡Solicitud Enviada con Éxito!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n?.solicitudEnviadaDesc ??
              'Tu solicitud fue registrada en Odoo y está pendiente de aprobación por el equipo pastoral.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF072B4F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                InicioAtrioScreen.routeName,
                (route) => false,
              );
            },
            child: Text(
              l10n?.entendido ?? 'Entendido',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Estado visual si el feligrés ya cuenta con membresía en la congregación.
class AlreadyMemberView extends StatelessWidget {
  const AlreadyMemberView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final joinProvider = context.watch<JoinChurchProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFFFEF3C7),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFD97706),
            size: 44,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n?.yaEresMiembroTitulo ?? 'Membresía Activa',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          joinProvider.errorMessage ??
              l10n?.yaEresMiembroDesc ??
              'Ya perteneces a esta congregación.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF072B4F),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n?.cerrar ?? 'Cerrar',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
