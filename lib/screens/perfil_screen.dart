import 'dart:async';

import 'package:atrio/screens/mis_notas_screen.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importación de las pantallas para obtener sus static const routeName
import '../data/atrio_database_helper.dart';
import '../l10n/app_localizations.dart';
import '../modelos/auth_permissions.dart';
import '../providers/admin_provider.dart';
import '../providers/ajustes_provider.dart';
import '../providers/iglesia_provider.dart';
import '../providers/recomendacion_iglesia_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/atrio_connectivity_alert.dart';
import '../widgets/change_pending_banner.dart';
import '../widgets/daily_verse_notification_settings_card.dart';
import '../widgets/permission_guard.dart';
import '../widgets/read_only_banner.dart';
import 'ayuda_soporte_screen.dart';
import 'configuracion_screen.dart';
import 'esperando_aprobacion_screen.dart';
import 'inicio_sesion_screen.dart';
import 'mis_donaciones_screen.dart';
import 'mis_pedidos_screen.dart';
import 'moderation_screen.dart';
import 'moderation_words_screen.dart';
import 'notificaciones_screen.dart';
import 'seguimiento_solicitud_screen.dart';
import 'terminos_privacidad_screen.dart';
import 'tradicion_cristiana_screen.dart';

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
      _cargarDatosUsuario();
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
    final l10n = AppLocalizations.of(context);
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
                    Text(
                      l10n?.iglesiaAprobadaTitulo ??
                          '¡Tu iglesia ha sido aprobada!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      l10n?.iglesiaAprobadaMensaje(event.churchName) ??
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
                  l10n?.estadoCongregacionCambiado(
                        event.churchName,
                        event.newStatus,
                      ) ??
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

    final bool tieneIglesiaActiva =
        (nombreUserOdoo != null &&
            nombreUserOdoo.isNotEmpty &&
            nombreUserOdoo != 'Sin iglesia seleccionada' &&
            nombreUserOdoo != sinIglesiaTexto &&
            nombreUserOdoo != 'Iglesia Atrio') ||
        (nombreProvider != null &&
            nombreProvider.isNotEmpty &&
            nombreProvider != 'Sin iglesia seleccionada' &&
            nombreProvider != sinIglesiaTexto &&
            nombreProvider != 'Iglesia Atrio');

    final String iglesia = tieneIglesiaActiva
        ? ((nombreUserOdoo != null &&
                  nombreUserOdoo.isNotEmpty &&
                  nombreUserOdoo != 'Sin iglesia seleccionada' &&
                  nombreUserOdoo != sinIglesiaTexto &&
                  nombreUserOdoo != 'Iglesia Atrio')
              ? nombreUserOdoo
              : (nombreProvider ?? sinIglesiaTexto))
        : ((nombreRequested != null && nombreRequested.isNotEmpty)
              ? nombreRequested
              : ((nombreSqlite != null &&
                        nombreSqlite.isNotEmpty &&
                        nombreSqlite != 'Sin iglesia seleccionada' &&
                        nombreSqlite != sinIglesiaTexto &&
                        nombreSqlite != 'Iglesia Atrio')
                    ? nombreSqlite
                    : sinIglesiaTexto));

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

    // Validación offline de respaldo: si el usuario está autenticado localmente,
    // cuenta con congregación legítima seleccionada/asignada (SQLite o Provider),
    // no tiene solicitudes pendientes de membresía/cambio, y está verificado como miembro
    // o registrado con su iglesia previa, se confirma su membresía aprobada.
    final bool isOfflineApproved =
        estaAutenticado &&
        hasChurchSelected &&
        !isChangePending &&
        (currentUser?.isMember == true ||
            currentUser?.esMiembroVerificado == true ||
            currentUser?.membershipStatus == 'approved' ||
            ((currentUser?.membershipStatus.isEmpty ?? true) &&
                currentUser?.role == UserRole.member &&
                _usuarioData != null &&
                (_usuarioData!['iglesia_nombre'] as String?)?.isNotEmpty ==
                    true));

    final bool isChurchApproved =
        estaAutenticado &&
        userProvider.membershipStatus != 'pending' &&
        userProvider.membershipStatus != 'membership_pending' &&
        (userProvider.isChurchApproved || isOfflineApproved);

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
            (hasChurchSelected &&
                currentUser?.role == UserRole.user &&
                currentUser?.esMiembroVerificado != true));

    final bool hasChurchAssigned =
        estaAutenticado &&
        (userProvider.hasChurchAssigned || hasChurchSelected) &&
        iglesia != sinIglesiaTexto &&
        iglesia.isNotEmpty;

    final bool canPop = Navigator.canPop(context);
    final Widget content = Container(
      color: blancoFondo,
      child: RefreshIndicator(
        color: amarilloOro,
        onRefresh: () async {
          if (!userProvider.isAuthenticated) return;
          final bool hasInternet = await AtrioConnectivityAlert.checkAndNotify(
            context,
            onRetry: () => userProvider.refreshUserProfile(),
          );
          if (!hasInternet) return;
          await userProvider.refreshUserProfile();
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
              const ChangePendingBanner(),
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
                              ? (l10n?.estadoDonacionPendiente ?? 'Pendiente')
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

                    // Panel de Moderación de Plataforma (Super Admin - Odoo 19 /platform/moderation/*)
                    PermissionGuard(
                      requirePlatformAdmin: true,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: usableHeight * 0.025),
                        child: _buildSeccionSuperAdminModeracion(
                          context: context,
                          screenWidth: screenWidth,
                          usableHeight: usableHeight,
                        ),
                      ),
                    ),

                    // Sección de Recordatorios del Versículo del Día (Doble Notificación)
                    _sectionLabel(
                      l10n?.notificacionesVersiculoDiario ??
                          'Versículo del Día',
                      screenWidth,
                      usableHeight,
                    ),
                    const DailyVerseNotificationSettingsCard(),
                    SizedBox(height: usableHeight * 0.025),

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

    if (canPop) {
      return Scaffold(
        backgroundColor: azulFondo,
        body: SafeArea(bottom: false, child: content),
      );
    }
    return content;
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

    final String mensajeAviso = nombreMostrar.isNotEmpty
        ? (l10n?.pertenecesAIglesiaEnRevisionDesc(nombreMostrar) ??
              'Perteneces a $nombreMostrar, pero tu aprobación se encuentra actualmente pendiente por parte de la administración. Tu iglesia se encuentra actualmente en proceso de revisión por parte de la administración. Una vez aprobada, podrás gestionar y ver el historial de tus solicitudes y peticiones pastorales.')
        : (l10n?.iglesiaEnRevisionDesc ??
              'Tu iglesia se encuentra actualmente en proceso de revisión por parte de la administración. Una vez aprobada, podrás gestionar y ver el historial de tus solicitudes y peticiones pastorales.');

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
            padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 20),
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
                    l10n?.iglesiaEnRevision ?? 'Iglesia en revisión',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
                      label: Text(
                        l10n?.verEstadoSolicitud ?? 'Ver estado de solicitud',
                        style: const TextStyle(
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
    String? iniciales,
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
      padding: EdgeInsetsDirectional.fromSTEB(
        screenWidth * 0.05,
        usableHeight * 0.015,
        screenWidth * 0.05,
        usableHeight * 0.02,
      ),
      decoration: BoxDecoration(
        color: azulFondo,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(screenWidth * 0.06),
          bottomRight: Radius.circular(screenWidth * 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila superior: Botón atrás (si fue empujada) + Título Perfil + Selector de Idioma
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (Navigator.canPop(context)) ...[
                    IconButton(
                      padding: EdgeInsetsDirectional.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: l10n?.volver ?? 'Volver',
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: screenWidth * 0.025),
                  ],
                  Text(
                    l10n?.perfil ?? 'Perfil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.052,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              _buildBotonSelectorIdioma(
                context: context,
                provider: ajustesProvider,
                screenWidth: screenWidth,
                usableHeight: usableHeight,
              ),
            ],
          ),
          SizedBox(height: usableHeight * 0.016),

          // Fila del Usuario (Nombre + Badges de Rol/Estado + Botón Editar/Login)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nombre,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.048,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: usableHeight * 0.006),
                    // Badges de Rol y Estado de Iglesia juntos en una misma fila (RBAC Odoo 19)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsetsDirectional.symmetric(
                            horizontal: 8,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: amarilloOro.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
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
                        if (estaAutenticado)
                          _buildHeaderChurchStatusBadge(
                            context: context,
                            isChurchApproved: isChurchApproved,
                            isMembershipPending: isMembershipPending,
                            isChangePending: isChangePending,
                            hasChurchAssigned: hasChurchAssigned,
                          ),
                        if (estaAutenticado && userProvider.isReadOnly)
                          Container(
                            padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 8,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(8),
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
              Material(
                color: Colors.white.withValues(alpha: 0.12),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  tooltip: estaAutenticado
                      ? (l10n?.perfilBotonEditarDatosTooltip ??
                            'Editar mis datos personales')
                      : (l10n?.perfilBotonIniciarSesionTooltip ??
                            'Iniciar sesión en ATRIO'),
                  onPressed: () {
                    if (estaAutenticado) {
                      _mostrarDialogoEditarDatos(
                        context,
                        screenWidth,
                        usableHeight,
                        iglesiaActual: iglesia,
                      );
                    } else {
                      Navigator.pushNamed(
                        context,
                        InicioSesionScreen.routeName,
                      );
                    }
                  },
                  icon: Icon(
                    estaAutenticado ? Icons.edit_outlined : Icons.login_rounded,
                    color: Colors.white,
                    size: screenWidth * 0.05,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: usableHeight * 0.014),

          // Cápsula horizontal de información de la Iglesia (nombre completo en hasta dos líneas)
          Container(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: screenWidth * 0.035,
              vertical: usableHeight * 0.012,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(screenWidth * 0.028),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.14),
                width: 0.8,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: amarilloOro.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(screenWidth * 0.018),
                  ),
                  child: Icon(
                    Icons.church_rounded,
                    color: amarilloOro,
                    size: screenWidth * 0.046,
                  ),
                ),
                SizedBox(width: screenWidth * 0.028),
                Expanded(
                  child: Text(
                    iglesia,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.034,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      height: 1.25,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Badge compacto de alta visibilidad para el encabezado superior
  Widget _buildHeaderChurchStatusBadge({
    required BuildContext context,
    required bool isChurchApproved,
    required bool isMembershipPending,
    required bool isChangePending,
    required bool hasChurchAssigned,
  }) {
    final l10n = AppLocalizations.of(context);
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
      label = l10n?.perfilIglesiaAprobada ?? 'Iglesia aprobada';
    } else if (isMembershipPending) {
      bg = const Color(0xFFFEF3C7);
      border = const Color(0xFFF59E0B);
      textCol = const Color(0xFFB45309);
      icon = Icons.hourglass_top_rounded;
      label = l10n?.perfilPendienteAprobacion ?? 'Pendiente de aprobación';
    } else if (isChangePending) {
      bg = const Color(0xFFE0E7FF);
      border = const Color(0xFF6366F1);
      textCol = const Color(0xFF4338CA);
      icon = Icons.swap_horiz_rounded;
      label = l10n?.perfilCambioEnRevision ?? 'Cambio en revisión';
    } else {
      bg = Colors.white.withValues(alpha: 0.15);
      border = Colors.white.withValues(alpha: 0.35);
      textCol = Colors.white;
      icon = Icons.church_outlined;
      label = l10n?.perfilSinCongregacion ?? 'Sin congregación';
    }

    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 8,
        vertical: 2.5,
      ),
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
    final l10n = AppLocalizations.of(context);
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
      badgeText = l10n?.perfilBadgeAprobada ?? 'Aprobada';
      badgeBg = const Color(0xFFDCFCE7);
      badgeTextCol = const Color(0xFF15803D);
      headerTitle = l10n?.perfilCongregacionActiva ?? 'Congregación activa';
      description = l10n?.perfilCongregacionActivaDesc ?? 'Perteneces activamente a esta congregación. Tu membresía está verificada y tienes acceso pleno a peticiones pastorales, solicitudes y actividades.';
      buttonText = l10n?.perfilVerDetallesIglesia ?? 'Ver detalles de iglesia';
      buttonIcon = Icons.info_outline_rounded;
      onButtonTap = () {
        _mostrarDetallesIglesiaAprobada(context, iglesia);
      };
    } else if (isMembershipPending) {
      cardBorder = const Color(0xFFFDE68A);
      iconBg = const Color(0xFFFEF3C7);
      iconColor = const Color(0xFFB45309);
      iconData = Icons.hourglass_top_rounded;
      badgeText = l10n?.perfilBadgeEnRevision ?? 'En revisión';
      badgeBg = const Color(0xFFFEF3C7);
      badgeTextCol = const Color(0xFFB45309);
      headerTitle = l10n?.perfilSolicitudMembresia ?? 'Solicitud de membresía';
      final String prefix =
          (iglesia.toLowerCase().startsWith('la ') ||
              iglesia.toLowerCase().startsWith('el ') ||
              iglesia.toLowerCase().startsWith('templo '))
          ? ''
          : 'la ';
      final String iglesiaFormateada = '$prefix$iglesia';
      description =
          l10n?.perfilMembresiaPendienteDesc(iglesiaFormateada) ??
          'Perteneces a $iglesiaFormateada, pero tu aprobación se encuentra actualmente pendiente por parte de la administración.';
      buttonText = l10n?.perfilVerEstadoSolicitud ?? 'Ver estado de solicitud';
      buttonIcon = Icons.hourglass_top_rounded;
      onButtonTap = () {
        Navigator.pushNamed(context, EsperandoAprobacionScreen.routeName);
      };
    } else if (isChangePending) {
      cardBorder = const Color(0xFFC7D2FE);
      iconBg = const Color(0xFFE0E7FF);
      iconColor = const Color(0xFF4338CA);
      iconData = Icons.swap_horiz_rounded;
      badgeText = l10n?.perfilBadgeTrasladoEnCurso ?? 'Traslado en curso';
      badgeBg = const Color(0xFFE0E7FF);
      badgeTextCol = const Color(0xFF4338CA);
      headerTitle = l10n?.perfilCambioCongregacion ?? 'Cambio de congregación';
      description = l10n?.perfilCambioCongregacionDesc ?? 'Tu solicitud para trasladarte a una nueva congregación está en proceso de revisión por la administración.';
      buttonText = l10n?.perfilConsultarEstado ?? 'Consultar estado';
      buttonIcon = Icons.visibility_outlined;
      onButtonTap = () {
        Navigator.pushNamed(context, EsperandoAprobacionScreen.routeName);
      };
    } else {
      cardBorder = const Color(0xFFE2E8F0);
      iconBg = const Color(0xFFF1F5F9);
      iconColor = const Color(0xFF475569);
      iconData = Icons.church_outlined;
      badgeText = l10n?.perfilBadgeSinVincular ?? 'Sin vincular';
      badgeBg = const Color(0xFFF1F5F9);
      badgeTextCol = const Color(0xFF475569);
      headerTitle = l10n?.perfilSinCongregacion ?? 'Sin congregación';
      description = l10n?.perfilSinCongregacionDesc ?? 'Aún no perteneces a una comunidad eclesial en ATRIO. Elige tu congregación para participar de las actividades y servicios pastorales.';
      buttonText =
          l10n?.perfilBuscarUnirseIglesia ?? 'Buscar y unirse a una iglesia';
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
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isChurchApproved ? const Color(0xFF16A34A) : azulFondo,
                  width: 1.4,
                ),
                foregroundColor: isChurchApproved
                    ? const Color(0xFF15803D)
                    : azulFondo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onPressed: onButtonTap,
              icon: Icon(buttonIcon, size: 18),
              label: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (isChangePending) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFC62828),
                ),
                onPressed: () =>
                    _confirmarCancelarCambioIglesia(context, iglesia),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: Text(
                  l10n?.cancelarSolicitudCambio ??
                      'Cancelar solicitud de cambio',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmarCancelarCambioIglesia(
    BuildContext context,
    String iglesiaActual,
  ) async {
    final l10n = AppLocalizations.of(context);
    final userProvider = context.read<UserProvider>();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            child: Text(l10n?.continuarConCambio ?? 'Continuar con el cambio'),
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
      final exito = await userProvider.cancelarSolicitudCambioIglesia();
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

  void _mostrarDetallesIglesiaAprobada(
    BuildContext context,
    String iglesiaNombre,
  ) {
    final l10n = AppLocalizations.of(context);
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
          padding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 20),
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
                Text(
                  l10n?.perfilEstadoMembresiaAprobadaActiva ??
                      'Estado: Membresía aprobada y activa',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n?.perfilDetalleMembresiaModal ?? 'Formas parte activa de esta congregación. Desde ATRIO puedes interactuar con tu pastor, realizar solicitudes y participar en eventos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
                if (Provider.of<UserProvider>(
                  context,
                  listen: false,
                ).isChangePending) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E7FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF6366F1),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.swap_horiz_rounded,
                          color: Color(0xFF4338CA),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n?.perfilCambioCongregacionDesc ?? 'Tu solicitud para trasladarte a una nueva congregación está en proceso de revisión por la administración.',
                            style: const TextStyle(
                              color: Color(0xFF4338CA),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: azulFondo,
                      side: const BorderSide(color: azulFondo, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: Text(
                      l10n?.cambiarDeIglesia ?? 'Cambiar de congregación',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
                  child: Text(
                    l10n?.cerrar ?? 'Cerrar',
                    style: const TextStyle(fontWeight: FontWeight.w600),
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

  Widget _buildSeccionSuperAdminModeracion({
    required BuildContext context,
    required double screenWidth,
    required double usableHeight,
  }) {
    final l10n = AppLocalizations.of(context);

    final items = [
      (
        icon: Icons.shield_rounded,
        title: l10n?.centroModeracion ?? 'Centro de Moderación',
        subtitle:
            l10n?.perfilSubtituloCentroModeracion ??
            'Auditar contenidos marcados y bloqueados',
        onTap: () => Navigator.pushNamed(context, ModerationScreen.routeName),
      ),
      (
        icon: Icons.rule_rounded,
        title: l10n?.palabrasRestringidas ?? 'Palabras Restringidas',
        subtitle:
            l10n?.perfilSubtituloPalabrasRestringidas ??
            'Reglas automáticas flag y block',
        onTap: () =>
            Navigator.pushNamed(context, ModerationWordsScreen.routeName),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF818CF8).withValues(alpha: 0.5),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              top: -15,
              right: -15,
              child: Icon(
                Icons.security_rounded,
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF818CF8).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF818CF8)
                                .withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.gavel_rounded,
                          color: Color(0xFFC7D2FE),
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
                                    l10n?.moderacionPlataforma ??
                                        'Moderación de Plataforma',
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
                                    color: const Color(0xFF818CF8),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'SUPER ADMIN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n?.subtituloModeracion ??
                                  'Audita y modera contenido público',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.88),
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
                                          color: const Color(0xFF818CF8)
                                              .withValues(alpha: 0.16),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Icon(
                                          item.icon,
                                          color: const Color(0xFFC7D2FE),
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
                                                  alpha: 0.88,
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
              final bool hasInternet =
                  await AtrioConnectivityAlert.checkAndNotify(
                    context,
                    onRetry: () => _confirmarEliminarCuenta(context),
                  );
              if (!hasInternet || !context.mounted) return;

              Navigator.pop(ctx);

              final userProvider = Provider.of<UserProvider>(
                context,
                listen: false,
              );

              // Modal de progreso no cancelable para evitar interrupciones o doble tap
              if (context.mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (loadingCtx) => PopScope(
                    canPop: false,
                    child: AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      content: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 8,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFC0392B),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              l10n?.eliminandoCuentaYDatos ??
                                  'Eliminando cuenta y datos personales...',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n?.eliminandoCuentaSubtitulo ?? 'Notificando a Odoo, revocando Google Sign-In y restableciendo estado virgen...',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              // ===============================================================
              // EJECUCIÓN INTEGRAL POR ETAPAS (1, 2 y 3)
              // ===============================================================
              await userProvider.eliminarCuentaDefinitiva();

              // Reseteo complementario de Providers en memoria
              if (context.mounted) {
                try {
                  context.read<IglesiaProvider>().limpiarIglesia();
                } catch (_) {}
                try {
                  context.read<AdminProvider>().reset();
                } catch (_) {}
                try {
                  context.read<RecomendacionIglesiaProvider>().clearSelection();
                } catch (_) {}

                // Cerrar modal de progreso
                Navigator.of(context, rootNavigator: true).pop();

                // SnackBar de confirmación
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n?.cuentaEliminadaExito ?? 'Tu cuenta y datos personales han sido eliminados satisfactoriamente. Se ha enviado una confirmación a tu correo.',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF072B4F),
                    duration: const Duration(seconds: 4),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );

                // ===============================================================
                // ETAPA 4: REINICIO DE RUTA RAÍZ (Navigator.pushAndRemoveUntil)
                // ===============================================================
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
