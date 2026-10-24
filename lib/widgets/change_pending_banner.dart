import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';

/// Banner persistente que informa al usuario cuando ha solicitado un cambio de iglesia
/// y la solicitud está actualmente en revisión por la administración de la nueva congregación.
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
              'Has solicitado cambio de iglesia. Tu solicitud está en revisión por la nueva congregación.',
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
