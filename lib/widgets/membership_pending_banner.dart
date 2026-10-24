import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/iglesia_provider.dart';
import '../providers/user_provider.dart';
import '../screens/esperando_aprobacion_screen.dart';

/// Banner persistente en el Home que informa al usuario que su solicitud
/// de ingreso a la iglesia está actualmente en revisión por el pastor o administrador.
/// Permite usar la aplicación libremente y consultar el estado con un toque.
class MembershipPendingBanner extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const MembershipPendingBanner({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    IglesiaProvider? iglesiaProvider;
    try {
      iglesiaProvider = Provider.of<IglesiaProvider>(context, listen: false);
    } catch (_) {
      iglesiaProvider = null;
    }

    final isMembershipPending = userProvider.isAuthenticated &&
        (userProvider.isWaitingApproval ||
            userProvider.currentUser?.isMembershipPending == true ||
            userProvider.membershipStatus == 'membership_pending');

    if (!isMembershipPending) return const SizedBox.shrink();

    final screenWidth = MediaQuery.sizeOf(context).width;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    final String? nombreRequested =
        userProvider.requestedChurchData?['name'] as String?;
    final String? nombreUserRequested =
        userProvider.currentUser?.requestedChurchData?['name'] as String?;
    final String? nombreUserActual =
        (userProvider.currentUser?.iglesiaActual != null &&
                userProvider.currentUser?.iglesiaActual !=
                    'Sin iglesia seleccionada' &&
                userProvider.currentUser?.iglesiaActual != 'Iglesia Atrio')
            ? userProvider.currentUser?.iglesiaActual
            : null;
    final String? nombreIglesiaProvider = iglesiaProvider?.iglesiaActual?.nombre;

    final iglesiaNombre = (nombreRequested != null &&
            nombreRequested.trim().isNotEmpty)
        ? nombreRequested.trim()
        : ((nombreUserRequested != null &&
                nombreUserRequested.trim().isNotEmpty)
            ? nombreUserRequested.trim()
            : ((nombreUserActual != null &&
                    nombreUserActual.trim().isNotEmpty)
                ? nombreUserActual.trim()
                : ((nombreIglesiaProvider != null &&
                        nombreIglesiaProvider.trim().isNotEmpty)
                    ? nombreIglesiaProvider.trim()
                    : 'tu congregación')));

    return Container(
      width: double.infinity,
      margin: margin ??
          EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 6),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.035,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: azulFondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: amarilloOro.withValues(alpha: 0.85),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.pushNamed(
              context,
              EsperandoAprobacionScreen.routeName,
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: amarilloOro.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_top_rounded,
                  color: amarilloOro,
                  size: screenWidth * 0.048,
                ),
              ),
              SizedBox(width: screenWidth * 0.025),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Solicitud en revisión',
                          style: TextStyle(
                            color: amarilloOro,
                            fontSize: screenWidth * 0.031,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Pendiente',
                            style: TextStyle(
                              color: Color(0xFFB45309),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tu ingreso a $iglesiaNombre está pendiente de aprobación pastoral. Toca para ver detalles.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: screenWidth * 0.0285,
                        fontWeight: FontWeight.w400,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white70,
                size: screenWidth * 0.05,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
