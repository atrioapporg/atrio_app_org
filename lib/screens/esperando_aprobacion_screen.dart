import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../modelos/app_stage.dart';
import '../providers/iglesia_provider.dart';
import '../providers/user_provider.dart';
import 'elegir_camino_iglesia_screen.dart';
import 'inicio_atrio_screen.dart';
import 'inicio_sesion_screen.dart';

/// Pantalla donde un usuario espera que el administrador/pastor de la iglesia apruebe su solicitud de ingreso.
/// (membership_status == 'membership_pending').
class EsperandoAprobacionScreen extends StatefulWidget {
  static const String routeName = 'esperando_aprobacion_screen';

  const EsperandoAprobacionScreen({super.key});

  @override
  State<EsperandoAprobacionScreen> createState() =>
      _EsperandoAprobacionScreenState();
}

class _EsperandoAprobacionScreenState extends State<EsperandoAprobacionScreen>
    with WidgetsBindingObserver {
  bool _isRefreshing = false;

  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFE2E8F0);
  static const Color textoOscuro = Color(0xFF0F172A);
  static const Color textoGris = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Cada vez que la app vuelve a primer plano, consultamos /me
  /// para ver si el pastor ya aprobó el ingreso mientras la app estaba en segundo plano.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _comprobarEstado(silencioso: true);
    }
  }

  Future<void> _comprobarEstado({bool silencioso = false}) async {
    if (_isRefreshing) return;
    if (!silencioso) {
      setState(() => _isRefreshing = true);
    }

    final userProvider = context.read<UserProvider>();

    try {
      final nuevoStage = await userProvider.checkCurrentStage();

      if (!mounted) return;

      if (nuevoStage == AppStage.memberHome ||
          nuevoStage == AppStage.adminHome) {
        // Solicitud aprobada con éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('¡Tu solicitud ha sido aprobada! Bienvenido.'),
                ),
              ],
            ),
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          InicioAtrioScreen.routeName,
          (route) => false,
        );
      } else if (nuevoStage == AppStage.chooseChurch &&
          userProvider.membershipStatus == 'none') {
        // La solicitud fue rechazada por el administrador
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Solicitud no aprobada'),
            content: const Text(
              'Tu solicitud de ingreso no fue aprobada por la administración de la congregación. Puedes elegir otra iglesia para unirte.',
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulFondo,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            ElegirCaminoIglesiaScreen.routeName,
            (route) => false,
          );
        }
      } else if (!silencioso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tu solicitud aún está pendiente de revisión.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[EsperandoAprobacionScreen] Error comprobando estado: $e');
      if (!silencioso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo verificar el estado con el servidor.'),
          ),
        );
      }
    } finally {
      if (mounted && !silencioso) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final l10n = AppLocalizations.of(context);
    final userProvider = context.watch<UserProvider>();
    IglesiaProvider? iglesiaProvider;
    try {
      iglesiaProvider = Provider.of<IglesiaProvider>(context, listen: false);
    } catch (_) {
      iglesiaProvider = null;
    }

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
                    : 'Congregación seleccionada')));

    final logoUrl =
        (userProvider.requestedChurchData?['logo_url'] as String?) ??
        (userProvider.currentUser?.requestedChurchData?['logo_url'] as String?);

    return Scaffold(
      backgroundColor: blancoFondo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 110,
        leading: TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: azulFondo,
            padding: const EdgeInsets.only(left: 10),
          ),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              InicioAtrioScreen.routeName,
              (route) => false,
            );
          },
          icon: const Icon(Icons.home_rounded, size: 20),
          label: const Text(
            'Inicio',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: textoGris),
            onPressed: () async {
              await userProvider.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  InicioSesionScreen.routeName,
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(
              l10n?.cerrarSesion ?? 'Cerrar sesión',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.07,
                    vertical: 12,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      // Icono animado o reloj de espera
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: amarilloOro.withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.hourglass_top_rounded,
                          color: Color(0xFFB45309),
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Título
                      const Text(
                        'Solicitud en Revisión',
                        style: TextStyle(
                          color: textoOscuro,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Explicación
                      const Text(
                        'Tu petición de ingreso ha sido enviada con éxito. El pastor o administrador debe validar tu acceso a la congregación:',
                        style: TextStyle(
                          color: textoGris,
                          fontSize: 14.5,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Tarjeta de la iglesia pedida
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: grisBorde),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: logoUrl != null && logoUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        logoUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            const Icon(
                                          Icons.church_rounded,
                                          color: Color(0xFF0284C7),
                                          size: 28,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.church_rounded,
                                      color: Color(0xFF0284C7),
                                      size: 28,
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Iglesia solicitada',
                                    style: TextStyle(
                                      color: textoGris,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    iglesiaNombre,
                                    style: const TextStyle(
                                      color: textoOscuro,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Pendiente',
                                style: TextStyle(
                                  color: Color(0xFFB45309),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tarjeta informativa: Atrio está disponible mientras tanto
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF1D4ED8),
                              size: 19,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Mientras se revisa tu solicitud, puedes entrar al Inicio de Atrio para leer la Biblia, explorar devocionales y usar la app con normalidad.',
                                style: TextStyle(
                                  color: Color(0xFF1E3A8A),
                                  fontSize: 12.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Botón principal: "Ir al Inicio de Atrio"
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: azulFondo,
                            foregroundColor: Colors.white,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              InicioAtrioScreen.routeName,
                              (route) => false,
                            );
                          },
                          icon: const Icon(Icons.home_rounded, size: 20),
                          label: const Text(
                            'Ir al Inicio de Atrio',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Botón secundario: "Comprobar estado"
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: azulFondo, width: 1.3),
                            foregroundColor: azulFondo,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _isRefreshing ? null : () => _comprobarEstado(),
                          icon: _isRefreshing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: azulFondo,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, size: 19),
                          label: Text(
                            _isRefreshing ? 'Comprobando...' : 'Comprobar estado',
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Botón terciario para cambiar de iglesia si se equivocó
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: textoGris),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            ElegirCaminoIglesiaScreen.routeName,
                          );
                        },
                        child: const Text(
                          '¿Deseas elegir otra iglesia?',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
