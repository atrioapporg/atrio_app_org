import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../modelos/ad_models.dart';
import '../providers/ads_provider.dart';

/// Tarjeta publicitaria patrocinada para el feed de inicio y secciones multimedia.
/// Cumple con los estándares de Material 3, soporte bidireccional (RTL/LTR),
/// internacionalización estricta y arquitectura StatelessWidget desacoplada.
class SponsoredAdCard extends StatelessWidget {
  final AdModel ad;
  final VoidCallback? onCustomTap;

  const SponsoredAdCard({
    super.key,
    required this.ad,
    this.onCustomTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoCard = Colors.white;
    const Color grisBorde = Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsetsDirectional.only(
        start: 16,
        end: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: blancoCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: grisBorde, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (onCustomTap != null) {
              onCustomTap!();
            } else {
              context.read<AdsProvider>().handleAdClick(context, ad);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Imagen del Anuncio con Badge de Patrocinado superpuesto
              if (ad.imageUrl != null && ad.imageUrl!.isNotEmpty)
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        ad.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(azulFondo),
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: azulFondo,
                          child: Center(
                            child: Icon(
                              Icons.campaign_rounded,
                              size: 48,
                              color: amarilloOro.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Badge: Patrocinado
                    PositionedDirectional(
                      top: 12,
                      start: 12,
                      child: Container(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: azulFondo.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: amarilloOro.withValues(alpha: 0.6),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              color: amarilloOro,
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              l10n?.patrocinado ?? 'Patrocinado',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Badge de la Iglesia anunciante (si está disponible)
                    if (ad.churchName != null && ad.churchName!.isNotEmpty)
                      PositionedDirectional(
                        bottom: 10,
                        start: 12,
                        child: Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ad.churchName!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

              // 2. Contenido Textual y Call to Action
              Padding(
                padding: const EdgeInsetsDirectional.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título del anuncio
                    Text(
                      ad.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: azulFondo,
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.042,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Descripción del anuncio si existe
                    if (ad.description != null && ad.description!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        ad.description!.trim(),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: screenWidth * 0.034,
                          height: 1.35,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    const SizedBox(height: 12),

                    // 3. Fila de Acción (CTA)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.public_rounded,
                              color: Colors.grey.shade500,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n?.anunciosYPublicidad ?? 'Publicidad',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (ad.hasInteractiveLink)
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: amarilloOro,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: amarilloOro.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n?.masInformacion ?? 'Más información',
                                  style: const TextStyle(
                                    color: azulFondo,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_outward_rounded,
                                  color: azulFondo,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
