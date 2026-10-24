import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../modelos/app_stage.dart';
import '../providers/user_provider.dart';
import 'inicio_atrio_screen.dart';
import 'inicio_sesion_screen.dart';

/// Pantalla donde un administrador de iglesia creada recientemente espera la activación de la suscripción
/// por parte del equipo de ATRIO (role == 'church_admin' y church.has_active_subscription == false).
class IglesiaPendienteActivacionScreen extends StatefulWidget {
  static const String routeName = 'iglesia_pendiente_activacion_screen';

  const IglesiaPendienteActivacionScreen({super.key});

  @override
  State<IglesiaPendienteActivacionScreen> createState() =>
      _IglesiaPendienteActivacionScreenState();
}

class _IglesiaPendienteActivacionScreenState
    extends State<IglesiaPendienteActivacionScreen>
    with WidgetsBindingObserver {
  bool _isRefreshing = false;

  static const Color azulFondo = Color(0xFF072B4F);
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _comprobarActivacion(silencioso: true);
    }
  }

  Future<void> _abrirConsolaWeb() async {
    final Uri url = Uri.parse('https://atrioapp.odoo19rd.com/atrio/manage');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visita atrioapp.odoo19rd.com/atrio/manage desde tu navegador.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('[IglesiaPendienteActivacion] Error abriendo URL: $e');
    }
  }

  Future<void> _comprobarActivacion({bool silencioso = false}) async {
    if (_isRefreshing) return;
    if (!silencioso) {
      setState(() => _isRefreshing = true);
    }

    final userProvider = context.read<UserProvider>();

    try {
      final nuevoStage = await userProvider.checkCurrentStage();

      if (!mounted) return;

      if (nuevoStage == AppStage.adminHome) {
        // Iglesia activada por ATRIO
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF16A34A),
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('¡Tu iglesia ha sido activada! Bienvenido al panel de administración.'),
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
      } else if (!silencioso) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tu congregación sigue en proceso de validación y activación por ATRIO.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[IglesiaPendienteActivacion] Error comprobando estado: $e');
      if (!silencioso && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo verificar el estado de activación.'),
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

    final iglesiaNombre = userProvider.currentUser?.iglesiaActual != 'Sin iglesia seleccionada' &&
            userProvider.currentUser?.iglesiaActual != 'Iglesia Atrio'
        ? userProvider.currentUser!.iglesiaActual
        : 'Tu Nueva Congregación';

    return Scaffold(
      backgroundColor: blancoFondo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                    children: [
                      const Spacer(),

                      // Icono / Escudo de activación
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Color(0xFF0284C7),
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Título
                      const Text(
                        'Iglesia en Proceso de Activación',
                        style: TextStyle(
                          color: textoOscuro,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Explicación
                      const Text(
                        'Tu congregación ha sido registrada. El equipo de ATRIO está revisando los datos para asignar el plan de suscripción correspondiente a tu comunidad.',
                        style: TextStyle(
                          color: textoGris,
                          fontSize: 14.5,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Ficha de la iglesia creada
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
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.church_rounded,
                                color: Color(0xFFB45309),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Congregación registrada',
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
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Por activar',
                                style: TextStyle(
                                  color: Color(0xFF0284C7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Banner con sugerencia de consola web
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: grisBorde),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.laptop_chromebook_rounded,
                                  color: azulFondo,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Gestión desde la web',
                                  style: TextStyle(
                                    color: textoOscuro,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Mientras esperas, puedes completar los horarios de culto, ubicación e información desde la consola de gestión:',
                              style: TextStyle(
                                color: textoGris,
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            InkWell(
                              onTap: _abrirConsolaWeb,
                              child: const Text(
                                'Abrir atrioapp.odoo19rd.com/atrio/manage →',
                                style: TextStyle(
                                  color: Color(0xFF0284C7),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Botón para actualizar estado
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: azulFondo,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _isRefreshing ? null : () => _comprobarActivacion(),
                          icon: _isRefreshing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded),
                          label: Text(
                            _isRefreshing ? 'Verificando...' : 'Comprobar activación',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
