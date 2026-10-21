import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/user_provider.dart';

/// Banner persistente y accesible que informa al usuario cuando su sesión o cuenta
/// opera bajo el modo de solo lectura (RBAC Odoo 19: `read_only == true`).
class ReadOnlyBanner extends StatelessWidget {
  /// Margen exterior opcional para adaptarse a diferentes pantallas o listas.
  final EdgeInsetsGeometry? margin;

  const ReadOnlyBanner({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    final isReadOnly = context.select<UserProvider, bool>((p) => p.isReadOnly);
    if (!isReadOnly) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    return Container(
      width: double.infinity,
      margin: margin ?? EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 6),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.035,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: azulFondo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: amarilloOro.withValues(alpha: 0.6),
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
            Icons.lock_clock_outlined,
            color: amarilloOro,
            size: screenWidth * 0.05,
          ),
          SizedBox(width: screenWidth * 0.025),
          Expanded(
            child: Text(
              l10n?.bannerModoSoloLectura ??
                  'Modo de solo lectura activado. Las funciones de publicación y registro están deshabilitadas.',
              style: TextStyle(
                color: Colors.white,
                fontSize: screenWidth * 0.03,
                fontWeight: FontWeight.w500,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
