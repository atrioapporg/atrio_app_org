import 'dart:async';

import 'package:atrio/screens/mis_notas_screen.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importación de las pantallas para obtener sus static const routeName
import '../data/app_config.dart';
import '../data/atrio_database_helper.dart';
import '../l10n/app_localizations.dart';
import '../modelos/admin_models.dart';
import '../providers/admin_provider.dart';
import '../providers/ajustes_provider.dart';
import '../providers/iglesia_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/permission_guard.dart';
import '../widgets/read_only_banner.dart';
import 'ayuda_soporte_screen.dart';
import 'esperando_aprobacion_screen.dart';
import 'mis_donaciones_screen.dart';
import 'mis_pedidos_screen.dart';
import 'inicio_sesion_screen.dart';
import 'notificaciones_screen.dart';
import 'seguimiento_solicitud_screen.dart';
import 'terminos_privacidad_screen.dart';
import 'tradicion_cristiana_screen.dart';
import 'configuracion_screen.dart';

class PerfilScreen extends StatefulWidget {
  static const routeName = 'perfil_screen';

  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with WidgetsBindingObserver {
  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFEFEFEF);

  bool _isLoading = true;
  Map<String, dynamic>? _usuarioData;
  String _appVersion = '';
  Timer? _periodicStatusTimer;
  StreamSubscription<ChurchStatusChangeEvent>? _statusSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cargarDatosUsuario();
    _cargarVersionApp();
    _iniciarEscuchaEstadoIglesia();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodicStatusTimer?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.isAuthenticated) {
        userProvider.refreshUserProfile();
      }
    }
  }

  void _iniciarEscuchaEstadoIglesia() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Escuchar eventos reactivos de aprobación o cambio de estado
      _statusSub = userProvider.onChurchStatusChanged.listen((event) {
        if (!mounted) return;
        _mostrarNotificacionCambioEstado(event);
      });

      // Chequeo periódico preventivo cada 20s para usuarios en revisión
      _periodicStatusTimer?.cancel();
      _periodicStatusTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        if (!mounted) return;
        final p = Provider.of<UserProvider>(context, listen: false);
        if (p.isAuthenticated &&
            (p.isMembershipPending || p.isWaitingApproval)) {
          p.refreshUserProfile();
        }
      });
    });
  }

  void _mostrarNotificacionCambioEstado(ChurchStatusChangeEvent event) {
    if (!mounted) return;
    if (event.isApprovedNow) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const Icon(Icons.verified_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¡Tu iglesia ha sido aprobada!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Ya eres miembro activo de ${event.churchName}. Acceso completo desbloqueado.',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF0F172A),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'El estado de tu congregación (${event.churchName}) ha cambiado a: ${event.newStatus}.',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _cargarVersionApp() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = 'v${info.version}+${info.buildNumber}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _appVersion = 'v0.1.0+15';
        });
      }
    }
  }

  // Carga los datos directamente desde atrio.db
  Future<void> _cargarDatosUsuario() async {
    try {
      final data = await AtrioDatabaseHelper.instance.getUsuario();
      if (mounted) {
        setState(() {
          _usuarioData = data;
          _isLoading = false;
        });
        // Si el Provider aún no ha cargado la sesión reactiva, intentar auto-login desde secure storage
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        if (!userProvider.isAuthenticated && userProvider.currentUser == null) {
          userProvider.tryAutoLogin();
        }
      }
    } catch (e) {
      debugPrint(
        '[PerfilScreen] Error leyendo usuario de base de datos local: $e',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    if (_isLoading) {
      return Container(
        color: blancoFondo,
        child: const Center(
          child: CircularProgressIndicator(color: amarilloOro),
        ),
      );
    }

    // Escuchamos el estado reactivo de UserProvider, IglesiaProvider y AjustesProvider
    final userProvider = Provider.of<UserProvider>(context);
    final iglesiaProvider = Provider.of<IglesiaProvider>(context);
    final ajustesProvider = context.watch<AjustesProvider>();

    final l10n = AppLocalizations.of(context);
    final String sinIglesiaTexto =
        l10n?.sinIglesiaSeleccionada ?? 'Sin iglesia seleccionada';

    // Fuente de verdad: Si está autenticado, usar UserProvider (validado en Odoo o Social Session)
    // Si no está autenticado (Modo invitado), mostrar explícitamente "Usuario invitado"
    final bool estaAutenticado =
        userProvider.isAuthenticated || userProvider.currentUser != null;
    final currentUser = userProvider.currentUser;

    final String nombre = estaAutenticado
        ? (currentUser?.nombre.isNotEmpty == true
              ? currentUser!.nombre
              : (_usuarioData?['nombre'] ?? (l10n?.usuario ?? 'Usuario')))
        : (l10n?.usuarioInvitado ?? 'Usuario invitado');

    final String inicial = estaAutenticado
        ? (currentUser?.avatarIniciales.isNotEmpty == true
              ? currentUser!.avatarIniciales
              : (nombre.trim().isNotEmpty
                    ? nombre.trim()[0].toUpperCase()
                    : 'U'))
        : 'I';

    final String? nombreRequested =
        (userProvider.requestedChurchData?['name'] as String?)?.trim() ??
        (currentUser?.requestedChurchData?['name'] as String?)?.trim();

    final String? nombreProvider =
        (iglesiaProvider.tieneIglesiaGuardada &&
            iglesiaProvider.iglesiaActual != null)
        ? iglesiaProvider.iglesiaActual!.nombre.trim()
        : null;

    final String? nombreUserOdoo = currentUser?.iglesiaActual.trim();
    final String? nombreSqlite = (_usuarioData?['iglesia_nombre'] as String?)
        ?.trim();

    final String iglesia =
        (nombreRequested != null && nombreRequested.isNotEmpty)
        ? nombreRequested
        : ((nombreProvider != null && nombreProvider.isNotEmpty)
              ? nombreProvider
              : ((nombreUserOdoo != null &&
                        nombreUserOdoo.isNotEmpty &&
                        nombreUserOdoo != 'Sin iglesia seleccionada' &&
                        nombreUserOdoo != sinIglesiaTexto &&
                        nombreUserOdoo != 'Iglesia Atrio')
                    ? nombreUserOdoo
                    : ((nombreRequested != null && nombreRequested.isNotEmpty)
                          ? nombreRequested
                          : ((nombreSqlite != null &&
                                    nombreSqlite.isNotEmpty &&
                                    nombreSqlite !=
                                        'Sin iglesia seleccionada' &&
                                    nombreSqlite != sinIglesiaTexto &&
                                    nombreSqlite != 'Iglesia Atrio')
                                ? nombreSqlite
                                : sinIglesiaTexto))));

    final bool hasChurchSelected =
        estaAutenticado &&
        iglesia.isNotEmpty &&
        iglesia != sinIglesiaTexto &&
        iglesia != 'Sin iglesia seleccionada' &&
        iglesia != 'Sin congregación' &&
        iglesia != 'Iglesia Atrio';

    final bool isChangePending =
        estaAutenticado &&
        (userProvider.isChangePending ||
            currentUser?.isChangePending == true ||
            userProvider.membershipStatus == 'change_pending');

    final bool isChurchApproved =
        estaAutenticado &&
        userProvider.isChurchApproved &&
        !userProvider.isMembershipPending &&
        userProvider.membershipStatus != 'pending';

    final bool isMembershipPending =
        estaAutenticado &&
        !isChurchApproved &&
        !isChangePending &&
        (userProvider.isWaitingApproval ||
            currentUser?.isMembershipPending == true ||
            userProvider.isMembershipPending ||
            userProvider.membershipStatus == 'membership_pending' ||
            userProvider.membershipStatus == 'pending' ||
            userProvider.churchStatus == 'pending' ||
            userProvider.churchStatus == 'membership_pending' ||
            hasChurchSelected);

    final bool hasChurchAssigned =
        estaAutenticado &&
        (userProvider.hasChurchAssigned || hasChurchSelected) &&
        iglesia != sinIglesiaTexto &&
        iglesia.isNotEmpty;

    return Container(
      color: blancoFondo,
      child: RefreshIndicator(
        color: amarilloOro,
        onRefresh: () async {
          if (userProvider.isAuthenticated) {
            await userProvider.refreshUserProfile();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(
                context: context,
                screenWidth: screenWidth,
                usableHeight: usableHeight,
                nombre: nombre,
                iglesia: iglesia,
                iniciales: inicial,
                ajustesProvider: ajustesProvider,
                isMembershipPending: isMembershipPending,
                isChurchApproved: isChurchApproved,
                isChangePending: isChangePending,
                hasChurchAssigned: hasChurchAssigned,
              ),
              if (!estaAutenticado)
                Container(
                  margin: EdgeInsets.fromLTRB(
                    screenWidth * 0.05,
                    usableHeight * 0.015,
                    screenWidth * 0.05,
                    0,
                  ),
                  padding: EdgeInsets.all(screenWidth * 0.035),
                  decoration: BoxDecoration(
                    color: amarilloOro.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    border: Border.all(
                      color: amarilloOro.withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: const Color(0xFF8A5B00),
                        size: screenWidth * 0.055,
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: Text(
                          l10n?.perfilInvitadoDesc ?? 'Estás navegando en modo invitado. Inicia sesión para acceder a tu historial, peticiones y donaciones.',
                          style: TextStyle(
                            color: const Color(0xFF5D3E00),
                            fontSize: screenWidth * 0.032,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const ReadOnlyBanner(),
              _buildTarjetaEstadoIglesia(
                context: context,
                screenWidth: screenWidth,
                usableHeight: usableHeight,
                iglesia: iglesia,
                isChurchApproved: isChurchApproved,
                isMembershipPending: isMembershipPending,
                isChangePending: isChangePending,
                hasChurchAssigned: hasChurchAssigned,
                estaAutenticado: estaAutenticado,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: usableHeight * 0.025),
                    _sectionLabel(
                      l10n?.miActividad ?? 'Mi actividad',
                      screenWidth,
                      usableHeight,
                    ),
                    _buildMenuGroup(
                      context: context,
                      screenWidth: screenWidth,
                      usableHeight: usableHeight,
                      items: [
                        _MenuItemData(
                          icon: Icons.edit_note_outlined,
                          label: l10n?.misSolicitudes ?? 'Mis solicitudes',
                          badge: (!isChurchApproved && estaAutenticado)
                              ? 'Pendiente'
                              : null,
                          route: isChurchApproved
                              ? SeguimientoSolicitudScreen.routeName
                              : null,
                          onCustomTap: isChurchApproved
                              ? null
                              : () => _mostrarAvisoIglesiaPendiente(
                                  context: context,
                                  screenWidth: screenWidth,
                                  usableHeight: usableHeight,
                                  iglesiaNombre: iglesia,
                                ),
                        ),
                        _MenuItemData(
                          icon: Icons.favorite_border_rounded,
                          label: l10n?.misDonaciones ?? 'Mis donaciones',
                          route: MisDonacionesScreen.routeName,
                        ),
                        _MenuItemData(
                          icon: Icons.receipt_long_outlined,
                          label: l10n?.misPedidos ?? 'Mis pedidos',
                          route: MisPedidosScreen.routeName,
                        ),
                        _MenuItemData(
                          icon: Icons.menu_book_outlined,
                          label:
                              l10n?.misNotasDeLaBiblia ??
                              'Mis notas de la Biblia',
                          route: MisNotasScreen.routeName,
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.025),

                    // Sección Administrativa Pastoral (Odoo 19 /admin/*)
                    PermissionGuard(
                      requireChurchAdmin: true,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: usableHeight * 0.025),
                        child: _buildSeccionPastoralDestacada(
                          context: context,
                          screenWidth: screenWidth,
                          usableHeight: usableHeight,
                        ),
                      ),
                    ),

                    _sectionLabel(
                      l10n?.cuenta ?? 'Cuenta',
                      screenWidth,
                      usableHeight,
                    ),
                    _buildMenuGroup(
                      context: context,
                      screenWidth: screenWidth,
                      usableHeight: usableHeight,
                      items: [
                        _MenuItemData(
                          icon: Icons.person_outline_rounded,
                          label: l10n?.misDatos ?? 'Mis datos',
                          route: null,
                          onCustomTap: () => _mostrarDialogoEditarDatos(
                            context,
                            screenWidth,
                            usableHeight,
                            iglesiaActual: iglesia,
                          ),
                        ),
                        _MenuItemData(
                          icon: Icons.church_outlined,
                          label: l10n?.cambiarDeIglesia ?? 'Cambiar de iglesia',
                          route: TradicionCristianaScreen.routeName,
                        ),
                        _MenuItemData(
                          icon: Icons.notifications_none_rounded,
                          label: l10n?.notificaciones ?? 'Notificaciones',
                          route: NotificacionesScreen.routeName,
                        ),
                        _MenuItemData(
                          icon: Icons.settings_outlined,
                          label: l10n?.ajustesDeLaApp ?? 'Ajustes de la app',
                          route: ConfiguracionScreen.routeName,
                        ),
                        if (AppConfig.appEnvironment != 'production')
                          _MenuItemData(
                            icon: Icons.sync_lock_rounded,
                            label: 'Diagnóstico Token Odoo',
                            customColor: Colors.deepPurple,
                            route: null,
                            onCustomTap: () => _probarRenovacionToken(context),
                          ),
                        _MenuItemData(
                          icon: Icons.delete_forever_outlined,
                          label:
                              l10n?.eliminarCuentaYDatos ??
                              'Eliminar cuenta y datos',
                          customColor: Colors.red.shade700,
                          route: null,
                          onCustomTap: () => _confirmarEliminarCuenta(context),
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.025),
                    _sectionLabel(
                      l10n?.soporte ?? 'Soporte',
                      screenWidth,
                      usableHeight,
                    ),
                    _buildMenuGroup(
                      context: context,
                      screenWidth: screenWidth,
                      usableHeight: usableHeight,
                      items: [
                        _MenuItemData(
                          icon: Icons.help_outline_rounded,
                          label: l10n?.ayudaYSoporte ?? 'Ayuda y soporte',
                          route: AyudaSoporteScreen.routeName,
                        ),
                        _MenuItemData(
                          icon: Icons.privacy_tip_outlined,
                          label:
                              l10n?.terminosYPrivacidad ??
                              'Términos y privacidad',
                          route: TerminosPrivacidadScreen.routeName,
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.03),
                    _buildLogoutButton(context, screenWidth, usableHeight),
                    SizedBox(height: usableHeight * 0.02),
                    Center(
                      child: Text(
                        _appVersion.isNotEmpty
                            ? 'Atrio · $_appVersion'
                            : 'Atrio',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: screenWidth * 0.03,
                        ),
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.03),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarAvisoIglesiaPendiente({
    required BuildContext context,
    required double screenWidth,
    required double usableHeight,
    String? iglesiaNombre,
  }) {
    final l10n = AppLocalizations.of(context);
    final String nombreMostrar =
        (iglesiaNombre != null &&
            iglesiaNombre.trim().isNotEmpty &&
            iglesiaNombre.trim() != 'Sin iglesia seleccionada' &&
            iglesiaNombre.trim() !=
                (l10n?.sinIglesiaSeleccionada ?? 'Sin iglesia seleccionada') &&
            iglesiaNombre.trim() != 'Sin congregación')
        ? iglesiaNombre.trim()
        : '';

    final String prefixAviso =
        (nombreMostrar.toLowerCase().startsWith('el ') ||
            nombreMostrar.toLowerCase().startsWith('templo '))
        ? 'al '
        : (nombreMostrar.toLowerCase().startsWith('la ') ? '' : 'a la ');

    final String mensajeAviso = nombreMostrar.isNotEmpty
        ? 'Perteneces $prefixAviso$nombreMostrar, pero tu aprobación se encuentra actualmente pendiente por parte de la administración. Tu iglesia se encuentra actualmente en proceso de revisión por parte de la administración. Una vez aprobada, podrás gestionar y ver el historial de tus solicitudes y peticiones pastorales.'
        : 'Tu iglesia se encuentra actualmente en proceso de revisión por parte de la administración. Una vez aprobada, podrás gestionar y ver el historial de tus solicitudes y peticiones pastorales.';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFCD34D),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      color: Color(0xFFD97706),
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Iglesia en revisión',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    mensajeAviso,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: azulFondo,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text(
                        'Ver estado de solicitud',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        Navigator.pushNamed(
                          context,
                          EsperandoAprobacionScreen.routeName,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    child: Text(
                      l10n?.entendido ?? 'Entendido',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _mostrarDialogoEditarDatos(
    BuildContext context,
    double screenWidth,
    double usableHeight, {
    String? iglesiaActual,
  }) {
    final l10n = AppLocalizations.of(context);
    final userProvider = context.read<UserProvider>();
    final bool estaAutenticado =
        userProvider.isAuthenticated || userProvider.currentUser != null;

    if (!estaAutenticado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.perfilInvitadoDesc ?? 'Estás navegando en modo invitado. Inicia sesión para acceder a tu perfil y datos.',
          ),
          backgroundColor: azulFondo,
          action: SnackBarAction(
            label: l10n?.iniciarSesion ?? 'Iniciar sesión',
            textColor: amarilloOro,
            onPressed: () {
              Navigator.pushNamed(context, InicioSesionScreen.routeName);
            },
          ),
        ),
      );
      return;
    }

    final currentUser = userProvider.currentUser;
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(
      text: currentUser?.nombre ?? (_usuarioData?['nombre'] ?? ''),
    );
    final emailCtrl = TextEditingController(
      text: currentUser?.email ?? (_usuarioData?['email'] ?? ''),
    );
    final telefonoCtrl = TextEditingController(
      text: currentUser?.telefono ?? (_usuarioData?['celular'] ?? ''),
    );
    final String defaultIglesia =
        (iglesiaActual != null &&
            iglesiaActual.isNotEmpty &&
            iglesiaActual != 'Sin iglesia seleccionada' &&
            iglesiaActual !=
                (l10n?.sinIglesiaSeleccionada ?? 'Sin iglesia seleccionada'))
        ? iglesiaActual
        : (currentUser?.iglesiaActual ??
              (_usuarioData?['iglesia_nombre'] ?? ''));

    final iglesiaCtrl = TextEditingController(text: defaultIglesia);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: usableHeight * 0.03,
          ),
          backgroundColor: blancoFondo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
          ),
          title: Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                color: azulFondo,
                size: screenWidth * 0.065,
              ),
              SizedBox(width: screenWidth * 0.02),
              Text(
                l10n?.misDatosDePerfil ?? 'Mis datos de perfil',
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: screenWidth * 0.90,
            height: usableHeight * 0.55,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFormField(
                      controller: nombreCtrl,
                      label: l10n?.nombreCompleto ?? 'Nombre completo',
                      icon: Icons.person_outline,
                      screenWidth: screenWidth,
                      usableHeight: usableHeight,
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? (l10n?.ingresaUnNombre ?? 'Ingresa un nombre')
                          : null,
                    ),
                    SizedBox(height: usableHeight * 0.025),
                    _buildFormField(
                      controller: emailCtrl,
                      label: l10n?.correoElectronico ?? 'Correo electrónico',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      screenWidth: screenWidth,
                      usableHeight: usableHeight,
                      validator: (val) => (val == null || !val.contains('@'))
                          ? (l10n?.ingresaUnCorreoValido ??
                                'Ingresa un correo válido')
                          : null,
                    ),
                    SizedBox(height: usableHeight * 0.025),
                    _buildFormField(
                      controller: telefonoCtrl,
                      label: l10n?.telefonoCelular ?? 'Teléfono celular',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      screenWidth: screenWidth,
                      usableHeight: usableHeight,
                    ),
                    SizedBox(height: usableHeight * 0.025),
                    _buildFormField(
                      controller: iglesiaCtrl,
                      label: l10n?.iglesiaActual ?? 'Iglesia actual',
                      icon: Icons.church_outlined,
                      screenWidth: screenWidth,
                      usableHeight: usableHeight,
                      readOnly: true,
                      helperText:
                          l10n?.helperCambiarIglesia ??
                          'Para cambiarla usa la opción "Cambiar de iglesia"',
                    ),
                  ],
                ),
              ),
            ),
          ),
          actionsPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: usableHeight * 0.015,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                l10n?.cancelar ?? 'Cancelar',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: amarilloOro,
                foregroundColor: azulFondo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.045,
                  vertical: usableHeight * 0.01,
                ),
              ),
              onPressed: () async {
                if (context.read<UserProvider>().isReadOnly) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n?.accionRestringidaSoloLectura ?? 'Acción restringida: Modo de solo lectura activado.',
                      ),
                      backgroundColor: Colors.red.shade700,
                    ),
                  );
                  return;
                }
                if (formKey.currentState!.validate()) {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(dialogCtx);
                  final String nuevaIglesia = iglesiaCtrl.text.trim();

                  // Guardamos en SQLite
                  await AtrioDatabaseHelper.instance.guardarUsuario({
                    if (_usuarioData != null && _usuarioData!['id'] != null)
                      'id': _usuarioData!['id'],
                    'nombre': nombreCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'celular': telefonoCtrl.text.trim(),
                    'iglesia_nombre': nuevaIglesia,
                    if (_usuarioData != null &&
                        _usuarioData!['fe_religiosa'] != null)
                      'fe_religiosa': _usuarioData!['fe_religiosa'],
                  });

                  if (nuevaIglesia.isNotEmpty) {
                    await AtrioDatabaseHelper.instance.guardarIglesiaNombre(
                      nuevaIglesia,
                    );
                  }

                  navigator.pop();

                  // Refrescamos la UI
                  await _cargarDatosUsuario();

                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      backgroundColor: azulFondo,
                      content: Text(
                        l10n?.datosActualizadosCorrectamente ??
                            'Datos actualizados correctamente',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text(
                l10n?.guardarCambios ?? 'Guardar cambios',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required double screenWidth,
    required double usableHeight,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: readOnly ? Colors.grey.shade700 : azulFondo,
        fontSize: screenWidth * 0.04,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontSize: screenWidth * 0.035,
        ),
        helperText: helperText,
        helperStyle: TextStyle(
          color: Colors.grey.shade600,
          fontSize: screenWidth * 0.028,
        ),
        prefixIcon: Icon(icon, color: azulFondo, size: screenWidth * 0.05),
        suffixIcon: readOnly
            ? Icon(
                Icons.lock_outline_rounded,
                color: Colors.grey.shade500,
                size: screenWidth * 0.045,
              )
            : null,
        filled: true,
        fillColor: readOnly ? const Color(0xFFF3F5F7) : Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: usableHeight * 0.018,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
          borderSide: const BorderSide(color: grisBorde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
          borderSide: BorderSide(
            color: readOnly ? grisBorde : azulFondo,
            width: readOnly ? 1.0 : 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required double screenWidth,
    required double usableHeight,
    required String nombre,
    required String iglesia,
    required String iniciales,
    required AjustesProvider ajustesProvider,
    bool isMembershipPending = false,
    bool isChurchApproved = false,
    bool isChangePending = false,
    bool hasChurchAssigned = false,
  }) {
    final l10n = AppLocalizations.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final bool estaAutenticado =
        userProvider.isAuthenticated || userProvider.currentUser != null;

    return Container(
      width: screenWidth,
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.05,
        usableHeight * 0.015,
        screenWidth * 0.05,
        usableHeight * 0.025,
      ),
      decoration: BoxDecoration(
        color: azulFondo,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(screenWidth * 0.07),
          bottomRight: Radius.circular(screenWidth * 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior: Título Perfil + Selector de Idioma
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                l10n?.perfil ?? 'Perfil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.052,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              _buildBotonSelectorIdioma(
                context: context,
                provider: ajustesProvider,
                screenWidth: screenWidth,
                usableHeight: usableHeight,
              ),
            ],
          ),
          SizedBox(height: usableHeight * 0.018),

          // Fila del Usuario (Avatar + Nombre e Iglesia + Botón Editar)
          Row(
            children: [
              CircleAvatar(
                radius: screenWidth * 0.09,
                backgroundColor: amarilloOro,
                child: Text(
                  iniciales,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.08,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.05,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: usableHeight * 0.005),
                    Row(
                      children: [
                        Icon(
                          Icons.church_rounded,
                          color: amarilloOro,
                          size: screenWidth * 0.04,
                        ),
                        SizedBox(width: screenWidth * 0.015),
                        Expanded(
                          child: Text(
                            iglesia,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: screenWidth * 0.033,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.005),
                    _buildHeaderChurchStatusBadge(
                      isChurchApproved: isChurchApproved,
                      isMembershipPending: isMembershipPending,
                      isChangePending: isChangePending,
                      hasChurchAssigned: hasChurchAssigned,
                    ),
                    SizedBox(height: usableHeight * 0.007),
                    // Badges de Rol y Estado de Lectura (RBAC Odoo 19)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: amarilloOro.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: amarilloOro.withValues(alpha: 0.7),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            estaAutenticado
                                ? userProvider.role.getLocalizedName(context)
                                : (l10n?.modoInvitado ?? 'Modo invitado'),
                            style: TextStyle(
                              color: amarilloOro,
                              fontSize: screenWidth * 0.027,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (estaAutenticado && userProvider.isReadOnly)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white38,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              l10n?.modoSoloLectura ?? 'Solo Lectura',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: screenWidth * 0.025,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  if (estaAutenticado) {
                    _mostrarDialogoEditarDatos(
                      context,
                      screenWidth,
                      usableHeight,
                      iglesiaActual: iglesia,
                    );
                  } else {
                    Navigator.pushNamed(context, InicioSesionScreen.routeName);
                  }
                },
                icon: Icon(
                  estaAutenticado ? Icons.edit_outlined : Icons.login_rounded,
                  color: Colors.white,
                  size: screenWidth * 0.055,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Badge compacto de alta visibilidad para el encabezado superior
  Widget _buildHeaderChurchStatusBadge({
    required bool isChurchApproved,
    required bool isMembershipPending,
    required bool isChangePending,
    required bool hasChurchAssigned,
  }) {
    Color bg;
    Color border;
    Color textCol;
    IconData icon;
    String label;

    if (isChurchApproved) {
      bg = const Color(0xFFDCFCE7);
      border = const Color(0xFF22C55E);
      textCol = const Color(0xFF15803D);
      icon = Icons.verified_rounded;
      label = 'Iglesia aprobada';
    } else if (isMembershipPending) {
      bg = const Color(0xFFFEF3C7);
      border = const Color(0xFFF59E0B);
      textCol = const Color(0xFFB45309);
      icon = Icons.hourglass_top_rounded;
      label = 'Pendiente de aprobación';
    } else if (isChangePending) {
      bg = const Color(0xFFE0E7FF);
      border = const Color(0xFF6366F1);
      textCol = const Color(0xFF4338CA);
      icon = Icons.swap_horiz_rounded;
      label = 'Cambio en revisión';
    } else {
      bg = Colors.white.withValues(alpha: 0.15);
      border = Colors.white.withValues(alpha: 0.35);
      textCol = Colors.white;
      icon = Icons.church_outlined;
      label = 'Sin congregación';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: textCol),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textCol,
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta de estatus de iglesia SIEMPRE visible a simple vista en el cuerpo de PerfilScreen
  Widget _buildTarjetaEstadoIglesia({
    required BuildContext context,
    required double screenWidth,
    required double usableHeight,
    required String iglesia,
    required bool isChurchApproved,
    required bool isMembershipPending,
    required bool isChangePending,
    required bool hasChurchAssigned,
    required bool estaAutenticado,
  }) {
    Color cardBorder;
    Color iconBg;
    Color iconColor;
    IconData iconData;
    String badgeText;
    Color badgeBg;
    Color badgeTextCol;
    String headerTitle;
    String description;
    final String buttonText;
    final IconData buttonIcon;
    final VoidCallback onButtonTap;

    if (isChurchApproved) {
      cardBorder = const Color(0xFFBBF7D0);
      iconBg = const Color(0xFFDCFCE7);
      iconColor = const Color(0xFF16A34A);
      iconData = Icons.verified_rounded;
      badgeText = 'Aprobada';
      badgeBg = const Color(0xFFDCFCE7);
      badgeTextCol = const Color(0xFF15803D);
      headerTitle = 'Congregación activa';
      description = 'Perteneces activamente a esta congregación. Tu membresía está verificada y tienes acceso pleno a peticiones pastorales, solicitudes y actividades.';
      buttonText = 'Ver detalles de iglesia';
      buttonIcon = Icons.info_outline_rounded;
      onButtonTap = () {
        _mostrarDetallesIglesiaAprobada(context, iglesia);
      };
    } else if (isMembershipPending) {
      cardBorder = const Color(0xFFFDE68A);
      iconBg = const Color(0xFFFEF3C7);
      iconColor = const Color(0xFFB45309);
      iconData = Icons.hourglass_top_rounded;
      badgeText = 'En revisión';
      badgeBg = const Color(0xFFFEF3C7);
      badgeTextCol = const Color(0xFFB45309);
      headerTitle = 'Solicitud de membresía';
      final String prefix =
          (iglesia.toLowerCase().startsWith('el ') ||
              iglesia.toLowerCase().startsWith('templo '))
          ? 'al '
          : (iglesia.toLowerCase().startsWith('la ') ? '' : 'a la ');
      description =
          'Perteneces $prefix$iglesia, pero tu aprobación se encuentra actualmente pendiente por parte de la administración.';
      buttonText = 'Ver estado de solicitud';
      buttonIcon = Icons.hourglass_top_rounded;
      onButtonTap = () {
        Navigator.pushNamed(context, EsperandoAprobacionScreen.routeName);
      };
    } else if (isChangePending) {
      cardBorder = const Color(0xFFC7D2FE);
      iconBg = const Color(0xFFE0E7FF);
      iconColor = const Color(0xFF4338CA);
      iconData = Icons.swap_horiz_rounded;
      badgeText = 'Traslado en curso';
      badgeBg = const Color(0xFFE0E7FF);
      badgeTextCol = const Color(0xFF4338CA);
      headerTitle = 'Cambio de congregación';
      description = 'Tu solicitud para trasladarte a una nueva congregación está en proceso de revisión por la administración.';
      buttonText = 'Consultar estado';
      buttonIcon = Icons.visibility_outlined;
      onButtonTap = () {
        Navigator.pushNamed(context, EsperandoAprobacionScreen.routeName);
      };
    } else {
      cardBorder = const Color(0xFFE2E8F0);
      iconBg = const Color(0xFFF1F5F9);
      iconColor = const Color(0xFF475569);
      iconData = Icons.church_outlined;
      badgeText = 'Sin vincular';
      badgeBg = const Color(0xFFF1F5F9);
      badgeTextCol = const Color(0xFF475569);
      headerTitle = 'Sin congregación';
      description = 'Aún no perteneces a una comunidad eclesial en ATRIO. Elige tu congregación para participar de las actividades y servicios pastorales.';
      buttonText = 'Buscar y unirse a una iglesia';
      buttonIcon = Icons.search_rounded;
      onButtonTap = () {
        Navigator.pushNamed(context, TradicionCristianaScreen.routeName);
      };
    }

    return Container(
      margin: EdgeInsets.fromLTRB(
        screenWidth * 0.05,
        usableHeight * 0.015,
        screenWidth * 0.05,
        0,
      ),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(iconData, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headerTitle,
                      style: TextStyle(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.036,
                      ),
                    ),
                    Text(
                      iglesia,
                      style: TextStyle(
                        color: isChurchApproved
                            ? azulFondo
                            : const Color(0xFF64748B),
                        fontSize: screenWidth * 0.033,
                        fontWeight: isChurchApproved
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeTextCol,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isChurchApproved ? const Color(0xFF16A34A) : azulFondo,
                  width: 1.2,
                ),
                foregroundColor: isChurchApproved
                    ? const Color(0xFF15803D)
                    : azulFondo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: onButtonTap,
              icon: Icon(buttonIcon, size: 16),
              label: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetallesIglesiaAprobada(
    BuildContext context,
    String iglesiaNombre,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF22C55E),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Color(0xFF16A34A),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  iglesiaNombre,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: azulFondo,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Estado: Membresía aprobada y activa',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Formas parte activa de esta congregación. Desde ATRIO puedes interactuar con tu pastor, realizar solicitudes y participar en eventos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: azulFondo,
                      side: const BorderSide(color: azulFondo, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text(
                      'Cambiar de congregación',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(
                        context,
                        TradicionCristianaScreen.routeName,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // GESTIÓN Y SELECTOR DE IDIOMA (flutter_localizations)
  // ============================================================================
  String _obtenerNombreIdioma(String codigo) {
    switch (codigo) {
      case 'en':
        return 'English';
      case 'es':
      default:
        return 'Español';
    }
  }

  Widget _buildBotonSelectorIdioma({
    required BuildContext context,
    required AjustesProvider provider,
    required double screenWidth,
    required double usableHeight,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        onTap: () => _mostrarSelectorIdioma(context, provider, screenWidth),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.025,
            vertical: usableHeight * 0.006,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            border: Border.all(color: Colors.white38),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language,
                color: Colors.white,
                size: screenWidth * 0.04,
              ),
              SizedBox(width: screenWidth * 0.015),
              Text(
                _obtenerNombreIdioma(provider.idiomaCodigo),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.03,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: screenWidth * 0.04,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarSelectorIdioma(
    BuildContext context,
    AjustesProvider provider,
    double screenWidth,
  ) {
    final l10n = AppLocalizations.of(context);
    final opciones = [
      {
        'codigo': 'es',
        'region': 'DO',
        'nombre': l10n?.idiomaEspanolLatino ?? 'Español (Latinoamérica)',
        'bandera': '🇩🇴',
      },
      {
        'codigo': 'en',
        'region': 'US',
        'nombre': l10n?.idiomaInglesUSA ?? 'English (United States)',
        'bandera': '🇺🇸',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.06),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenWidth * 0.04,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.translate_rounded, color: azulFondo),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    l10n?.seleccionarIdioma ?? 'Seleccionar Idioma',
                    style: TextStyle(
                      color: azulFondo,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              ...opciones.map((opcion) {
                final isSelected = provider.idiomaCodigo == opcion['codigo'];
                return ListTile(
                  leading: Text(
                    opcion['bandera']!,
                    style: TextStyle(fontSize: screenWidth * 0.06),
                  ),
                  title: Text(
                    opcion['nombre']!,
                    style: TextStyle(
                      color: isSelected ? azulFondo : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: screenWidth * 0.038,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: amarilloOro,
                        )
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                  ),
                  tileColor: isSelected
                      ? azulFondo.withValues(alpha: 0.05)
                      : Colors.transparent,
                  onTap: () {
                    provider.cambiarIdioma(
                      opcion['codigo']!,
                      region: opcion['region'],
                    );
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, double screenWidth, double usableHeight) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: usableHeight * 0.01,
        left: screenWidth * 0.01,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: azulFondo,
          fontSize: screenWidth * 0.050,
          fontWeight: FontWeight.bold,
          letterSpacing: screenWidth * 0.001,
        ),
      ),
    );
  }

  Widget _buildSeccionPastoralDestacada({
    required BuildContext context,
    required double screenWidth,
    required double usableHeight,
  }) {
    final l10n = AppLocalizations.of(context);

    final items = [
      (
        icon: Icons.campaign_rounded,
        title: l10n?.gestionAvisos ?? 'Avisos congregacionales',
        subtitle: 'Publicar comunicados y avisos clave',
        onTap: () => _mostrarGestionAvisos(context),
      ),
      (
        icon: Icons.groups_rounded,
        title: l10n?.gestionGrupos ?? 'Audiencias y grupos',
        subtitle: 'Segmentación de ministerios y membresía',
        onTap: () => _mostrarGruposAudiencia(context),
      ),
      (
        icon: Icons.volunteer_activism_rounded,
        title: l10n?.moderacionPeticiones ?? 'Moderación de peticiones',
        subtitle: 'Revisión y cuidado pastoral de oraciones',
        onTap: () => _mostrarModeracionPeticiones(context),
      ),
      (
        icon: Icons.insights_rounded,
        title: l10n?.metricasComunidad ?? 'Estadísticas de comunidad',
        subtitle: 'Métricas de crecimiento y participación',
        onTap: () => _mostrarMetricasComunidad(context),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [azulFondo, Color(0xFF0F3E6C)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: amarilloOro.withValues(alpha: 0.38),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: azulFondo.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Sutil decoración de fondo de agua
            Positioned(
              top: -15,
              right: -15,
              child: Icon(
                Icons.church_rounded,
                size: screenWidth * 0.38,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.045,
                vertical: usableHeight * 0.022,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabecera destacada de liderazgo pastoral
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: amarilloOro.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: amarilloOro.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: amarilloOro,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    l10n?.administracionPastoral ??
                                        'Administración Pastoral',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.044,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: amarilloOro,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'LÍDER',
                                    style: TextStyle(
                                      color: azulFondo,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Gestión y cuidado de la congregación',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: screenWidth * 0.03,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.018),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.09),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: List.generate(items.length, (idx) {
                        final item = items[idx];
                        final isLast = idx == items.length - 1;
                        return Column(
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.vertical(
                                  top: idx == 0
                                      ? const Radius.circular(14)
                                      : Radius.zero,
                                  bottom: isLast
                                      ? const Radius.circular(14)
                                      : Radius.zero,
                                ),
                                onTap: item.onTap,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.035,
                                    vertical: usableHeight * 0.014,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: amarilloOro.withValues(
                                            alpha: 0.16,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          item.icon,
                                          color: amarilloOro,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.title,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: screenWidth * 0.037,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.subtitle,
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.65,
                                                ),
                                                fontSize: screenWidth * 0.029,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: Colors.white.withValues(
                                          alpha: 0.38,
                                        ),
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (!isLast)
                              Divider(
                                color: Colors.white.withValues(alpha: 0.08),
                                height: 1,
                                thickness: 1,
                                indent: screenWidth * 0.14,
                                endIndent: screenWidth * 0.03,
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGroup({
    required BuildContext context,
    required List<_MenuItemData> items,
    required double screenWidth,
    required double usableHeight,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
        border: Border.all(color: grisBorde),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isLast = index == items.length - 1;
            return InkWell(
              onTap: () {
                if (item.onCustomTap != null) {
                  item.onCustomTap!();
                } else if (item.route != null) {
                  Navigator.pushNamed(context, item.route!);
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: usableHeight * 0.016,
                ),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(bottom: BorderSide(color: grisBorde)),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      color: item.customColor ?? azulFondo,
                      size: screenWidth * 0.055,
                    ),
                    SizedBox(width: screenWidth * 0.025),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: item.customColor ?? azulFondo,
                          fontSize: screenWidth * 0.050,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (item.badge != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFFFCD34D),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          item.badge!,
                          style: const TextStyle(
                            color: Color(0xFFB45309),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
                      size: screenWidth * 0.05,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(
    BuildContext context,
    double screenWidth,
    double usableHeight,
  ) {
    final l10n = AppLocalizations.of(context);
    final userProvider = context.watch<UserProvider>();
    final bool estaAutenticado =
        userProvider.isAuthenticated || userProvider.currentUser != null;

    if (!estaAutenticado) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, InicioSesionScreen.routeName);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: amarilloOro,
            foregroundColor: azulFondo,
            elevation: 0,
            padding: EdgeInsets.symmetric(vertical: usableHeight * 0.016),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
            ),
          ),
          icon: Icon(Icons.login_rounded, size: screenWidth * 0.05),
          label: Text(
            l10n?.iniciarSesion ?? 'Iniciar sesión',
            style: TextStyle(
              fontSize: screenWidth * 0.038,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFC0392B),
          side: const BorderSide(color: Color(0xFFC0392B)),
          padding: EdgeInsets.symmetric(vertical: usableHeight * 0.016),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
        ),
        icon: Icon(Icons.logout_rounded, size: screenWidth * 0.05),
        label: Text(
          l10n?.cerrarSesion ?? 'Cerrar sesión',
          style: TextStyle(
            fontSize: screenWidth * 0.038,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.cerrarSesion ?? 'Cerrar sesión'),
        content: Text(
          l10n?.seguroDeseasCerrarSesion ?? '¿Seguro que deseas cerrar sesión?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.cancelar ?? 'Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final userProvider = Provider.of<UserProvider>(
                context,
                listen: false,
              );
              Navigator.pop(ctx);
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);
              } catch (_) {}
              await userProvider.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  InicioSesionScreen.routeName,
                  (route) => false,
                );
              }
            },
            child: Text(
              l10n?.cerrarSesion ?? 'Cerrar sesión',
              style: const TextStyle(color: Color(0xFFC0392B)),
            ),
          ),
        ],
      ),
    );
  }

  /// Herramienta interactiva para verificar en vivo la recuperación ante error 401 y refresh de Odoo
  Future<void> _probarRenovacionToken(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final bool estaAutenticado =
        userProvider.isAuthenticated || userProvider.currentUser != null;
    if (!estaAutenticado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes tener una sesión activa para probar la renovación de tokens.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Modal de carga mientras se ejecuta el test
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Probando ciclo 401 -> Refresh -> 200...',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'Corrompiendo token y verificando rescate con Odoo ERP.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final res = await userProvider.testRefreshTokenFlow();
      if (!context.mounted) return;
      Navigator.pop(context); // Cerrar loader

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2E7D32),
                size: 28,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '¡Renovación Exitosa!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            '${res['message']}\n\n'
            'Detalles técnicos:\n'
            '• Se corrompió el Bearer Token en memoria.\n'
            '• Odoo respondió con HTTP 401 Unauthorized.\n'
            '• El interceptor envió el refresh_token a /auth/refresh.\n'
            '• Odoo emitió un nuevo token y la petición se completó sin desconectar al usuario.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF072B4F),
                foregroundColor: Colors.white,
              ),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Cerrar loader

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade700,
                size: 28,
              ),
              const SizedBox(width: 10),
              const Text('Fallo en Renovación'),
            ],
          ),
          content: Text(
            'No se pudo renovar la sesión: $e',
            style: const TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  /// Diálogo y flujo para eliminar cuenta de forma permanente
  /// (Cumplimiento de Apple App Store Guideline 5.1.1(v) y Google Play Console)
  void _confirmarEliminarCuenta(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade700,
              size: 28,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n?.eliminarCuenta ?? 'Eliminar cuenta',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n?.seguroEliminarCuenta ?? '¿Estás seguro de que deseas eliminar tu cuenta y todos tus datos personales de ATRIO?',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                l10n?.detalleEliminarCuenta ??
                    'Esta acción es definitiva e irreversible. Se eliminarán permanentemente:\n'
                        '• Tu perfil de usuario y vinculación comunitaria.\n'
                        '• Todas tus notas personales de la Biblia y favoritos guardados.\n'
                        '• Tu historial de solicitudes y aportes locales.\n'
                        '• Se solicitará la desactivación de tu registro en el backend Odoo ERP.',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.cancelar ?? 'Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);

              // ===============================================================
              // TODO: ODOO 19 BACKEND INTEGRATION - SOLICITUD DE BORRADO DE CUENTA
              // ===============================================================

              // 1. Purgar datos personales en la base de datos local SQLite
              await AtrioDatabaseHelper.instance.eliminarUsuarioYDatos();

              // 2. Limpiar estado en memoria de UserProvider
              if (context.mounted) {
                await Provider.of<UserProvider>(
                  context,
                  listen: false,
                ).logout();
              }

              // 3. Redirigir a la pantalla de Inicio de Sesión
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n?.cuentaEliminadaExito ?? 'Tu cuenta y datos personales han sido eliminados satisfactoriamente.',
                    ),
                    backgroundColor: const Color(0xFF072B4F),
                    duration: const Duration(seconds: 4),
                  ),
                );

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  InicioSesionScreen.routeName,
                  (route) => false,
                );
              }
            },
            child: Text(
              l10n?.eliminarDefinitivamente ?? 'Eliminar definitivamente',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // MÓDULO ADMINISTRATIVO PASTORAL (Odoo 19 /admin/* - ETAPA 3)
  // ============================================================================

  void _mostrarGestionAvisos(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final usableHeight = screenHeight - MediaQuery.of(context).padding.top;
    final l10n = AppLocalizations.of(context);
    final adminProvider = context.read<AdminProvider>();
    final userProvider = context.read<UserProvider>();

    adminProvider.loadAnnouncements();
    adminProvider.loadGroups();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: usableHeight * 0.85,
          decoration: BoxDecoration(
            color: blancoFondo,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(screenWidth * 0.06),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: usableHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: screenWidth * 0.12,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: usableHeight * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n?.gestionAvisos ?? 'Avisos congregacionales',
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.048,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (userProvider.canWrite)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: amarilloOro,
                        foregroundColor: azulFondo,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: usableHeight * 0.008,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        _mostrarDialogoCrearAviso(context);
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        l10n?.publicarAviso ?? 'Publicar aviso',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              SizedBox(height: usableHeight * 0.015),
              Expanded(
                child: Consumer<AdminProvider>(
                  builder: (context, prov, _) {
                    if (prov.isLoading && prov.announcements.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(color: amarilloOro),
                      );
                    }
                    if (prov.announcements.isEmpty) {
                      return Center(
                        child: Text(
                          l10n?.sinAvisosActivos ??
                              'No hay avisos congregacionales publicados',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: screenWidth * 0.036,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: prov.announcements.length,
                      separatorBuilder: (_, index) =>
                          SizedBox(height: usableHeight * 0.012),
                      itemBuilder: (context, index) {
                        final a = prov.announcements[index];
                        return Container(
                          padding: EdgeInsets.all(screenWidth * 0.035),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: grisBorde),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (a.isPinned)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 6),
                                      child: Icon(
                                        Icons.push_pin_rounded,
                                        size: 16,
                                        color: amarilloOro,
                                      ),
                                    ),
                                  Expanded(
                                    child: Text(
                                      a.title,
                                      style: TextStyle(
                                        color: azulFondo,
                                        fontSize: screenWidth * 0.038,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (userProvider.canWrite)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          prov.deleteAnnouncement(a.id),
                                    ),
                                ],
                              ),
                              SizedBox(height: usableHeight * 0.006),
                              Text(
                                a.plainContent,
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: screenWidth * 0.032,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarDialogoCrearAviso(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final usableHeight =
        MediaQuery.sizeOf(context).height - MediaQuery.of(context).padding.top;
    final l10n = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    bool pinned = false;
    int? selectedGroupId;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (dialogStateCtx, setDialogState) {
            final adminProv = dialogStateCtx.watch<AdminProvider>();
            final keyboardHeight = MediaQuery.of(dialogStateCtx)
                .viewInsets
                .bottom;

            return PopScope(
              canPop: !isSubmitting,
              child: Container(
                constraints: BoxConstraints(maxHeight: usableHeight * 0.92),
                decoration: BoxDecoration(
                  color: blancoFondo,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(screenWidth * 0.06),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(bottom: keyboardHeight),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Manija superior de arrastre
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 6),
                        child: Center(
                          child: Container(
                            width: 44,
                            height: 4.5,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),

                      // Cabecera estilizada del modal
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: amarilloOro.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.campaign_rounded,
                                color: azulFondo,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n?.publicarAviso ?? 'Publicar aviso',
                                    style: TextStyle(
                                      color: azulFondo,
                                      fontSize: screenWidth * 0.046,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Difunde comunicados clave a tu congregación',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: screenWidth * 0.03,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              color: Colors.grey.shade700,
                              tooltip: l10n?.cancelar ?? 'Cerrar',
                              onPressed: isSubmitting
                                  ? null
                                  : () => Navigator.of(sheetCtx).pop(),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1, thickness: 1),

                      // Formulario deslizable con uso óptimo del espacio
                      Flexible(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            screenWidth * 0.05,
                            usableHeight * 0.02,
                            screenWidth * 0.05,
                            usableHeight * 0.025,
                          ),
                          child: Form(
                            key: formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Título
                                Text(
                                  l10n?.tituloAviso ?? 'Título del aviso',
                                  style: TextStyle(
                                    color: azulFondo,
                                    fontSize: screenWidth * 0.034,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: titleCtrl,
                                  enabled: !isSubmitting,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.038,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Ej. Convocatoria a vigilia de oración',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: screenWidth * 0.033,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.title_rounded,
                                      color: azulFondo,
                                      size: 20,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: azulFondo,
                                        width: 1.6,
                                      ),
                                    ),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? (l10n?.campoRequerido ??
                                            'Este campo es requerido')
                                      : null,
                                ),
                                SizedBox(height: usableHeight * 0.018),

                                // Contenido
                                Text(
                                  l10n?.contenidoAviso ?? 'Contenido del aviso',
                                  style: TextStyle(
                                    color: azulFondo,
                                    fontSize: screenWidth * 0.034,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: contentCtrl,
                                  enabled: !isSubmitting,
                                  maxLines: 4,
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.038,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Describe fecha, hora, lugar y detalles del comunicado...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: screenWidth * 0.033,
                                    ),
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.only(bottom: 54),
                                      child: Icon(
                                        Icons.notes_rounded,
                                        color: azulFondo,
                                        size: 20,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: azulFondo,
                                        width: 1.6,
                                      ),
                                    ),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? (l10n?.campoRequerido ??
                                            'Este campo es requerido')
                                      : null,
                                ),
                                SizedBox(height: usableHeight * 0.018),

                                // Audiencia / Grupo
                                Text(
                                  l10n?.seleccionarAudiencia ??
                                      'Audiencia / Grupo',
                                  style: TextStyle(
                                    color: azulFondo,
                                    fontSize: screenWidth * 0.034,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<int?>(
                                  initialValue: selectedGroupId,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(
                                      Icons.groups_rounded,
                                      color: azulFondo,
                                      size: 20,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: azulFondo,
                                        width: 1.6,
                                      ),
                                    ),
                                  ),
                                  items: [
                                    DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text(
                                        l10n?.todasLasAudiencias ??
                                            'Toda la congregación',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.036,
                                        ),
                                      ),
                                    ),
                                    ...adminProv.groups.map(
                                      (g) => DropdownMenuItem<int?>(
                                        value: g.id,
                                        child: Text(
                                          '${g.name} (${g.memberCount})',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.036,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: isSubmitting
                                      ? null
                                      : (val) => setDialogState(
                                          () => selectedGroupId = val,
                                        ),
                                ),
                                SizedBox(height: usableHeight * 0.016),

                                // Fijar al inicio (Tarjeta con Switch y estilo distintivo)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: pinned
                                          ? amarilloOro.withValues(alpha: 0.6)
                                          : Colors.grey.shade300,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: SwitchListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 2,
                                    ),
                                    secondary: Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: pinned
                                            ? amarilloOro.withValues(alpha: 0.2)
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.push_pin_rounded,
                                        color: pinned
                                            ? azulFondo
                                            : Colors.grey.shade500,
                                        size: 18,
                                      ),
                                    ),
                                    title: Text(
                                      l10n?.fijarAviso ?? 'Fijar al inicio',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        fontWeight: FontWeight.w600,
                                        color: azulFondo,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Mantener en la parte superior del muro',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.029,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    value: pinned,
                                    activeThumbColor: amarilloOro,
                                    activeTrackColor: amarilloOro.withValues(
                                      alpha: 0.4,
                                    ),
                                    onChanged: isSubmitting
                                        ? null
                                        : (val) => setDialogState(
                                            () => pinned = val,
                                          ),
                                  ),
                                ),
                                SizedBox(height: usableHeight * 0.024),

                                // Botón principal de publicación a ancho completo
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: amarilloOro,
                                      foregroundColor: azulFondo,
                                      elevation: 2,
                                      shadowColor: amarilloOro.withValues(
                                        alpha: 0.4,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: isSubmitting
                                        ? null
                                        : () async {
                                            if (!formKey.currentState!
                                                .validate()) {
                                              return;
                                            }
                                            setDialogState(
                                              () => isSubmitting = true,
                                            );
                                            final nav = Navigator.of(sheetCtx);
                                            try {
                                              final ok = await dialogStateCtx
                                                  .read<AdminProvider>()
                                                  .createAnnouncement(
                                                    title: titleCtrl.text
                                                        .trim(),
                                                    content: contentCtrl.text
                                                        .trim(),
                                                    targetGroupIds:
                                                        selectedGroupId != null
                                                        ? [selectedGroupId!]
                                                        : null,
                                                    pinned: pinned,
                                                  );
                                              if (ok) {
                                                nav.pop();
                                                scaffoldMessenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      l10n?.avisoPublicadoExito ?? 'Aviso publicado con éxito',
                                                    ),
                                                    backgroundColor: azulFondo,
                                                  ),
                                                );
                                              } else {
                                                setDialogState(
                                                  () => isSubmitting = false,
                                                );
                                                final errorMsg =
                                                    adminProv.errorMessage ??
                                                    (l10n?.errorPublicarAviso ??
                                                        'No fue posible publicar el aviso');
                                                scaffoldMessenger.showSnackBar(
                                                  SnackBar(
                                                    content: Text(errorMsg),
                                                    backgroundColor:
                                                        Colors.red.shade700,
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              setDialogState(
                                                () => isSubmitting = false,
                                              );
                                              scaffoldMessenger.showSnackBar(
                                                SnackBar(
                                                  content: Text('Error: $e'),
                                                  backgroundColor:
                                                      Colors.red.shade700,
                                                ),
                                              );
                                            }
                                          },
                                    child: isSubmitting
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: azulFondo,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.send_rounded,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                l10n?.publicar ??
                                                    'Publicar aviso',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: screenWidth * 0.038,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarGruposAudiencia(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final usableHeight =
        MediaQuery.sizeOf(context).height - MediaQuery.of(context).padding.top;
    final l10n = AppLocalizations.of(context);
    final adminProv = context.read<AdminProvider>();
    adminProv.loadGroups();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: usableHeight * 0.6,
          decoration: BoxDecoration(
            color: blancoFondo,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(screenWidth * 0.06),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: usableHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: screenWidth * 0.12,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: usableHeight * 0.02),
              Text(
                l10n?.gestionGrupos ?? 'Audiencias y grupos',
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.048,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: usableHeight * 0.015),
              Expanded(
                child: Consumer<AdminProvider>(
                  builder: (context, prov, _) {
                    if (prov.groups.isEmpty) {
                      return Center(
                        child: Text(
                          'No hay grupos configurados',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: prov.groups.length,
                      separatorBuilder: (_, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final g = prov.groups[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: azulFondo.withValues(alpha: 0.1),
                            child: const Icon(Icons.group, color: azulFondo),
                          ),
                          title: Text(
                            g.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            g.description.isNotEmpty
                                ? g.description
                                : '${g.memberCount} miembros',
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: amarilloOro.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${g.memberCount}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9E6500),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarModeracionPeticiones(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final usableHeight =
        MediaQuery.sizeOf(context).height - MediaQuery.of(context).padding.top;
    final l10n = AppLocalizations.of(context);
    final adminProv = context.read<AdminProvider>();
    final userProvider = context.read<UserProvider>();
    adminProv.loadPrayerRequests(status: 'pending');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: usableHeight * 0.85,
          decoration: BoxDecoration(
            color: blancoFondo,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(screenWidth * 0.06),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: usableHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: screenWidth * 0.12,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: usableHeight * 0.02),
              Text(
                l10n?.moderacionPeticiones ?? 'Moderación de peticiones',
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.048,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: usableHeight * 0.015),
              Expanded(
                child: Consumer<AdminProvider>(
                  builder: (context, prov, _) {
                    if (prov.isLoading && prov.prayerRequests.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(color: amarilloOro),
                      );
                    }
                    if (prov.isPrayerRequestsWebOnly) {
                      return _buildWebOnlyNotice(
                        screenWidth: screenWidth,
                        usableHeight: usableHeight,
                        icon: Icons.laptop_chromebook_rounded,
                        titulo: 'Gestión en Consola Web',
                        descripcion: 'Las solicitudes pastorales y peticiones de oración de tu congregación se responden y administran centralizadamente a través de la consola web:',
                        url: 'https://atrioapp.odoo19rd.com/atrio/manage',
                      );
                    }
                    final pending = prov.prayerRequests
                        .where((r) => r.isPending)
                        .toList();
                    if (pending.isEmpty) {
                      return Center(
                        child: Text(
                          l10n?.sinPeticionesPendientes ??
                              'No hay peticiones pendientes de moderación',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: screenWidth * 0.036,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: pending.length,
                      separatorBuilder: (_, index) =>
                          SizedBox(height: usableHeight * 0.012),
                      itemBuilder: (context, index) {
                        final r = pending[index];
                        return Container(
                          padding: EdgeInsets.all(screenWidth * 0.035),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: grisBorde),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      r.title,
                                      style: TextStyle(
                                        color: azulFondo,
                                        fontSize: screenWidth * 0.038,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    r.applicantName,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: screenWidth * 0.03,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: usableHeight * 0.006),
                              Text(
                                r.description,
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: screenWidth * 0.032,
                                ),
                              ),
                              if (userProvider.canWrite) ...[
                                SizedBox(height: usableHeight * 0.012),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(
                                          color: Colors.red,
                                        ),
                                      ),
                                      onPressed: () async {
                                        final messenger = ScaffoldMessenger.of(
                                          context,
                                        );
                                        final ok = await prov
                                            .moderatePrayerRequest(
                                              requestId: r.id,
                                              approve: false,
                                              reason: 'Rechazado por moderador',
                                            );
                                        if (ok) {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                l10n?.peticionRechazada ??
                                                    'Petición rechazada',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      child: Text(l10n?.rechazar ?? 'Rechazar'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: amarilloOro,
                                        foregroundColor: azulFondo,
                                      ),
                                      onPressed: () async {
                                        final messenger = ScaffoldMessenger.of(
                                          context,
                                        );
                                        final ok = await prov
                                            .moderatePrayerRequest(
                                              requestId: r.id,
                                              approve: true,
                                            );
                                        if (ok) {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                l10n?.peticionAprobada ??
                                                    'Petición aprobada',
                                              ),
                                              backgroundColor: azulFondo,
                                            ),
                                          );
                                        }
                                      },
                                      child: Text(l10n?.aprobar ?? 'Aprobar'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarMetricasComunidad(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final usableHeight =
        MediaQuery.sizeOf(context).height - MediaQuery.of(context).padding.top;
    final l10n = AppLocalizations.of(context);
    final adminProv = context.read<AdminProvider>();
    adminProv.loadAnalytics();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: usableHeight * 0.75,
          decoration: BoxDecoration(
            color: blancoFondo,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(screenWidth * 0.06),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: usableHeight * 0.02,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: screenWidth * 0.12,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: usableHeight * 0.02),
              Text(
                l10n?.metricasComunidad ?? 'Estadísticas de comunidad',
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.048,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: usableHeight * 0.02),
              Expanded(
                child: Consumer<AdminProvider>(
                  builder: (context, prov, _) {
                    if (prov.isLoading && prov.analytics == null) {
                      return const Center(
                        child: CircularProgressIndicator(color: amarilloOro),
                      );
                    }
                    final m = prov.analytics ?? AdminAnalyticsModel();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (prov.isAnalyticsWebOnly)
                          Container(
                            margin: EdgeInsets.only(
                              bottom: usableHeight * 0.015,
                            ),
                            padding: EdgeInsets.all(screenWidth * 0.03),
                            decoration: BoxDecoration(
                              color: azulFondo.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: azulFondo.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: azulFondo,
                                  size: screenWidth * 0.045,
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                Expanded(
                                  child: Text(
                                    'Reportes de comunidad avanzados disponibles en la consola web (/atrio/manage).',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.028,
                                      color: azulFondo,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Expanded(
                          child: GridView.count(
                            crossAxisCount: 2,
                            crossAxisSpacing: screenWidth * 0.03,
                            mainAxisSpacing: usableHeight * 0.015,
                            childAspectRatio: 1.25,
                            children: [
                              _buildStatCard(
                                icon: Icons.people_outline,
                                label: l10n?.totalMiembros ?? 'Total miembros',
                                value: '${m.totalMembers}',
                                screenWidth: screenWidth,
                              ),
                              _buildStatCard(
                                icon: Icons.person_add_outlined,
                                label:
                                    l10n?.nuevosMiembrosMes ??
                                    'Nuevos este mes',
                                value: '+${m.newMembersThisMonth}',
                                screenWidth: screenWidth,
                              ),
                              _buildStatCard(
                                icon: Icons.event_available_outlined,
                                label: l10n?.inscripcionesEventos ?? 'Eventos',
                                value: '${m.eventRegistrationsCount}',
                                screenWidth: screenWidth,
                              ),
                              _buildStatCard(
                                icon: Icons.volunteer_activism_outlined,
                                label:
                                    l10n?.peticionesPendientes ??
                                    'Peticiones pend.',
                                value: '${m.pendingModerationCount}',
                                screenWidth: screenWidth,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWebOnlyNotice({
    required double screenWidth,
    required double usableHeight,
    required IconData icon,
    required String titulo,
    required String descripcion,
    required String url,
  }) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.05),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: azulFondo.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: screenWidth * 0.09, color: azulFondo),
            ),
            SizedBox(height: usableHeight * 0.02),
            Text(
              titulo,
              style: TextStyle(
                color: azulFondo,
                fontSize: screenWidth * 0.044,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: usableHeight * 0.01),
            Text(
              descripcion,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: screenWidth * 0.032,
                height: 1.35,
              ),
            ),
            SizedBox(height: usableHeight * 0.02),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.035,
                vertical: usableHeight * 0.01,
              ),
              decoration: BoxDecoration(
                color: amarilloOro.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: amarilloOro.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.link_rounded,
                    size: screenWidth * 0.04,
                    color: azulFondo,
                  ),
                  SizedBox(width: screenWidth * 0.015),
                  Text(
                    url,
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.029,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required double screenWidth,
  }) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: grisBorde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: azulFondo, size: screenWidth * 0.06),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.052,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: screenWidth * 0.028,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String label;
  final String? route;
  final VoidCallback? onCustomTap;
  final Color? customColor;
  final String? badge;

  const _MenuItemData({
    required this.icon,
    required this.label,
    this.route,
    this.onCustomTap,
    this.customColor,
    this.badge,
  });
}
