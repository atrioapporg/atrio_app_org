import 'package:atrio/screens/mis_notas_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importación de las pantallas para obtener sus static const routeName
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

class _PerfilScreenState extends State<PerfilScreen> {
  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFEFEFEF);

  bool _isLoading = true;
  Map<String, dynamic>? _usuarioData;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  // Carga los datos directamente desde atrio.db
  Future<void> _cargarDatosUsuario() async {
    final data = await AtrioDatabaseHelper.instance.getUsuario();
    if (mounted) {
      setState(() {
        _usuarioData = data;
        _isLoading = false;
      });
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

    // Fuente de verdad: Si está autenticado, usar UserProvider (validado en Odoo)
    // Si no está autenticado (Modo invitado), mostrar explícitamente "Usuario invitado"
    final bool estaAutenticado = userProvider.isAuthenticated;
    final currentUser = userProvider.currentUser;

    final String nombre = estaAutenticado
        ? (currentUser?.nombre.isNotEmpty == true
            ? currentUser!.nombre
            : (_usuarioData?['nombre'] ?? (l10n?.usuario ?? 'Usuario')))
        : (l10n?.usuarioInvitado ?? 'Usuario invitado');

    final String inicial = estaAutenticado
        ? (currentUser?.avatarIniciales.isNotEmpty == true
            ? currentUser!.avatarIniciales
            : (nombre.trim().isNotEmpty ? nombre.trim()[0].toUpperCase() : 'U'))
        : 'I';

    final String? nombreProvider =
        (iglesiaProvider.tieneIglesiaGuardada &&
            iglesiaProvider.iglesiaActual != null)
        ? iglesiaProvider.iglesiaActual!.nombre.trim()
        : null;

    final String? nombreUserOdoo = currentUser?.iglesiaActual.trim();
    final String? nombreSqlite = (_usuarioData?['iglesia_nombre'] as String?)
        ?.trim();

    final String iglesia = (nombreProvider != null && nombreProvider.isNotEmpty)
        ? nombreProvider
        : ((nombreUserOdoo != null &&
                  nombreUserOdoo.isNotEmpty &&
                  nombreUserOdoo != 'Sin iglesia seleccionada' &&
                  nombreUserOdoo != sinIglesiaTexto)
              ? nombreUserOdoo
              : ((nombreSqlite != null &&
                        nombreSqlite.isNotEmpty &&
                        nombreSqlite != 'Sin iglesia seleccionada' &&
                        nombreSqlite != sinIglesiaTexto)
                    ? nombreSqlite
                    : sinIglesiaTexto));

    return Container(
      color: blancoFondo,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
                        l10n?.perfilInvitadoDesc ??
                            'Estás navegando en modo invitado. Inicia sesión para acceder a tu historial, peticiones y donaciones.',
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
                        route: SeguimientoSolicitudScreen.routeName,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel(
                          l10n?.administracionPastoral ??
                              'Administración Pastoral',
                          screenWidth,
                          usableHeight,
                        ),
                        _buildMenuGroup(
                          context: context,
                          screenWidth: screenWidth,
                          usableHeight: usableHeight,
                          items: [
                            _MenuItemData(
                              icon: Icons.campaign_outlined,
                              label: l10n?.gestionAvisos ??
                                  'Avisos congregacionales',
                              route: null,
                              onCustomTap: () => _mostrarGestionAvisos(context),
                            ),
                            _MenuItemData(
                              icon: Icons.groups_outlined,
                              label: l10n?.gestionGrupos ??
                                  'Audiencias y grupos',
                              route: null,
                              onCustomTap: () =>
                                  _mostrarGruposAudiencia(context),
                            ),
                            _MenuItemData(
                              icon: Icons.volunteer_activism_outlined,
                              label: l10n?.moderacionPeticiones ??
                                  'Moderación de peticiones',
                              route: null,
                              onCustomTap: () =>
                                  _mostrarModeracionPeticiones(context),
                            ),
                            _MenuItemData(
                              icon: Icons.analytics_outlined,
                              label: l10n?.metricasComunidad ??
                                  'Estadísticas de comunidad',
                              route: null,
                              onCustomTap: () =>
                                  _mostrarMetricasComunidad(context),
                            ),
                          ],
                        ),
                        SizedBox(height: usableHeight * 0.025),
                      ],
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
                        icon: Icons.sync_lock_rounded,
                        label: 'Probar renovación de token (401)',
                        route: null,
                        onCustomTap: () => _probarRenovacionToken(context),
                      ),
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
                      'Atrio · v1.0.0',
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

    if (!userProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.perfilInvitadoDesc ??
                'Estás navegando en modo invitado. Inicia sesión para acceder a tu perfil y datos.',
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
        : (currentUser?.iglesiaActual ?? (_usuarioData?['iglesia_nombre'] ?? ''));

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
                        l10n?.accionRestringidaSoloLectura ??
                            'Acción restringida: Modo de solo lectura activado.',
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
  }) {
    final l10n = AppLocalizations.of(context);
    final userProvider = Provider.of<UserProvider>(context);

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
                            userProvider.isAuthenticated
                                ? userProvider.role.getLocalizedName(context)
                                : (l10n?.modoInvitado ?? 'Modo invitado'),
                            style: TextStyle(
                              color: amarilloOro,
                              fontSize: screenWidth * 0.027,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (userProvider.isAuthenticated && userProvider.isReadOnly)
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
                  if (userProvider.isAuthenticated) {
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
                  userProvider.isAuthenticated
                      ? Icons.edit_outlined
                      : Icons.login_rounded,
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

    if (!userProvider.isAuthenticated) {
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
    if (!userProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes tener una sesión activa para probar la renovación de tokens.'),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 28),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 28),
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
    final usableHeight = MediaQuery.sizeOf(context).height -
        MediaQuery.of(context).padding.top;
    final l10n = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    bool pinned = false;
    int? selectedGroupId;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (dialogStateCtx, setDialogState) {
            final adminProv = dialogStateCtx.watch<AdminProvider>();
            return AlertDialog(
              backgroundColor: blancoFondo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                l10n?.publicarAviso ?? 'Publicar aviso',
                style: const TextStyle(
                  color: azulFondo,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: screenWidth * 0.85,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleCtrl,
                          enabled: !isSubmitting,
                          decoration: InputDecoration(
                            labelText:
                                l10n?.tituloAviso ?? 'Título del aviso',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? (l10n?.campoRequerido ?? 'Este campo es requerido')
                              : null,
                        ),
                        SizedBox(height: usableHeight * 0.015),
                        TextFormField(
                          controller: contentCtrl,
                          enabled: !isSubmitting,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText:
                                l10n?.contenidoAviso ?? 'Contenido del aviso',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? (l10n?.campoRequerido ?? 'Este campo es requerido')
                              : null,
                        ),
                        SizedBox(height: usableHeight * 0.015),
                        DropdownButtonFormField<int?>(
                          initialValue: selectedGroupId,
                          decoration: InputDecoration(
                            labelText: l10n?.seleccionarAudiencia ??
                                'Audiencia / Grupo',
                            border: const OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(
                                l10n?.todasLasAudiencias ??
                                    'Toda la congregación',
                              ),
                            ),
                            ...adminProv.groups.map(
                              (g) => DropdownMenuItem<int?>(
                                value: g.id,
                                child: Text('${g.name} (${g.memberCount})'),
                              ),
                            ),
                          ],
                          onChanged: isSubmitting
                              ? null
                              : (val) =>
                                  setDialogState(() => selectedGroupId = val),
                        ),
                        SizedBox(height: usableHeight * 0.01),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            l10n?.fijarAviso ?? 'Fijar al inicio',
                            style: TextStyle(fontSize: screenWidth * 0.034),
                          ),
                          value: pinned,
                          activeThumbColor: amarilloOro,
                          onChanged: isSubmitting
                              ? null
                              : (val) =>
                                  setDialogState(() => pinned = val),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: Text(l10n?.cancelar ?? 'Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: amarilloOro,
                    foregroundColor: azulFondo,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSubmitting = true);
                          final nav = Navigator.of(dialogCtx);
                          try {
                            final ok = await dialogStateCtx
                                .read<AdminProvider>()
                                .createAnnouncement(
                                  title: titleCtrl.text.trim(),
                                  content: contentCtrl.text.trim(),
                                  targetGroupIds: selectedGroupId != null
                                      ? [selectedGroupId!]
                                      : null,
                                  pinned: pinned,
                                );
                            if (ok) {
                              nav.pop();
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n?.avisoPublicadoExito ??
                                        'Aviso publicado con éxito',
                                  ),
                                  backgroundColor: azulFondo,
                                ),
                              );
                            } else {
                              setDialogState(() => isSubmitting = false);
                              final errorMsg = adminProv.errorMessage ??
                                  (l10n?.errorPublicarAviso ??
                                      'No fue posible publicar el aviso');
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(errorMsg),
                                  backgroundColor: Colors.red.shade700,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red.shade700,
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: azulFondo,
                          ),
                        )
                      : Text(l10n?.publicar ?? 'Publicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarGruposAudiencia(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final usableHeight = MediaQuery.sizeOf(context).height -
        MediaQuery.of(context).padding.top;
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
                          subtitle: Text(g.description.isNotEmpty
                              ? g.description
                              : '${g.memberCount} miembros'),
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
    final usableHeight = MediaQuery.sizeOf(context).height -
        MediaQuery.of(context).padding.top;
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
                                        final messenger =
                                            ScaffoldMessenger.of(context);
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
                                      child: Text(
                                        l10n?.rechazar ?? 'Rechazar',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: amarilloOro,
                                        foregroundColor: azulFondo,
                                      ),
                                      onPressed: () async {
                                        final messenger =
                                            ScaffoldMessenger.of(context);
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
                                      child: Text(
                                        l10n?.aprobar ?? 'Aprobar',
                                      ),
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
    final usableHeight = MediaQuery.sizeOf(context).height -
        MediaQuery.of(context).padding.top;
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
                    return GridView.count(
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
                          label: l10n?.nuevosMiembrosMes ?? 'Nuevos este mes',
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
                          label: l10n?.peticionesPendientes ??
                              'Peticiones pend.',
                          value: '${m.pendingModerationCount}',
                          screenWidth: screenWidth,
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

  const _MenuItemData({
    required this.icon,
    required this.label,
    this.route,
    this.onCustomTap,
    this.customColor,
  });
}
