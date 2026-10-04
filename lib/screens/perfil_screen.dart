import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importación de las pantallas para obtener sus static const routeName
import '../data/atrio_database_helper.dart';
import '../providers/user_provider.dart';
import 'biblia_screen.dart';
import 'donaciones_screen.dart';
import 'inicio_sesion_screen.dart';
import 'seguimiento_solicitud_screen.dart';
import 'seleccionar_iglesia_screen.dart';

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
    setState(() => _isLoading = true);
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

    // Extracción segura de los datos de SQLite
    final String nombre = _usuarioData?['nombre'] ?? 'Usuario';
    final String inicial = nombre.trim().isNotEmpty
        ? nombre.trim()[0].toUpperCase()
        : 'U';
    final String iglesia =
        _usuarioData?['iglesia_nombre'] ?? 'Sin iglesia seleccionada';

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
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: usableHeight * 0.025),
                  _sectionLabel('Mi actividad', screenWidth, usableHeight),
                  _buildMenuGroup(
                    context: context,
                    screenWidth: screenWidth,
                    usableHeight: usableHeight,
                    items: const [
                      _MenuItemData(
                        icon: Icons.edit_note_outlined,
                        label: 'Mis solicitudes',
                        route: SeguimientoSolicitudScreen.routeName,
                      ),
                      _MenuItemData(
                        icon: Icons.favorite_border_rounded,
                        label: 'Mis donaciones',
                        route: DonacionesScreen.routeName,
                      ),
                      _MenuItemData(
                        icon: Icons.menu_book_outlined,
                        label: 'Mis notas de la Biblia',
                        route: BibliaScreen.routeName,
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.025),
                  _sectionLabel('Cuenta', screenWidth, usableHeight),
                  _buildMenuGroup(
                    context: context,
                    screenWidth: screenWidth,
                    usableHeight: usableHeight,
                    items: [
                      _MenuItemData(
                        icon: Icons.person_outline_rounded,
                        label: 'Mis datos',
                        route: null,
                        onCustomTap: () => _mostrarDialogoEditarDatos(
                          context,
                          screenWidth,
                          usableHeight,
                        ),
                      ),
                      const _MenuItemData(
                        icon: Icons.church_outlined,
                        label: 'Cambiar de iglesia',
                        route: SeleccionarIglesiaScreen.routeName,
                      ),
                      const _MenuItemData(
                        icon: Icons.notifications_none_rounded,
                        label: 'Notificaciones',
                        route: null,
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.025),
                  _sectionLabel('Soporte', screenWidth, usableHeight),
                  _buildMenuGroup(
                    context: context,
                    screenWidth: screenWidth,
                    usableHeight: usableHeight,
                    items: const [
                      _MenuItemData(
                        icon: Icons.help_outline_rounded,
                        label: 'Ayuda y soporte',
                        route: null,
                      ),
                      _MenuItemData(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Términos y privacidad',
                        route: null,
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
    double usableHeight,
  ) {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(
      text: _usuarioData?['nombre'] ?? '',
    );
    final emailCtrl = TextEditingController(text: _usuarioData?['email'] ?? '');
    final telefonoCtrl = TextEditingController(
      text: _usuarioData?['celular'] ?? '',
    );
    final iglesiaCtrl = TextEditingController(
      text: _usuarioData?['iglesia_nombre'] ?? '',
    );

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
                'Mis datos de perfil',
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
                      label: 'Nombre completo',
                      icon: Icons.person_outline,
                      screenWidth: screenWidth,
                      usableHeight: usableHeight,
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Ingresa un nombre'
                          : null,
                    ),
                    SizedBox(height: usableHeight * 0.025),
                    _buildFormField(
                      controller: emailCtrl,
                      label: 'Correo electrónico',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      screenWidth: screenWidth,
                      usableHeight: usableHeight,
                      validator: (val) => (val == null || !val.contains('@'))
                          ? 'Ingresa un correo válido'
                          : null,
                    ),
                    SizedBox(height: usableHeight * 0.025),
                    _buildFormField(
                      controller: telefonoCtrl,
                      label: 'Teléfono celular',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      screenWidth: screenWidth,
                      usableHeight: usableHeight,
                    ),
                    SizedBox(height: usableHeight * 0.025),
                    _buildFormField(
                      controller: iglesiaCtrl,
                      label: 'Iglesia actual',
                      icon: Icons.church_outlined,
                      screenWidth: screenWidth,
                      usableHeight: usableHeight,
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Ingresa una comunidad'
                          : null,
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
                'Cancelar',
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
                if (formKey.currentState!.validate()) {
                  // Guardamos en SQLite
                  await AtrioDatabaseHelper.instance.guardarUsuario({
                    if (_usuarioData != null && _usuarioData!['id'] != null)
                      'id': _usuarioData!['id'],
                    'nombre': nombreCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'celular': telefonoCtrl.text.trim(),
                    'iglesia_nombre': iglesiaCtrl.text.trim(),
                    if (_usuarioData != null &&
                        _usuarioData!['fe_religiosa'] != null)
                      'fe_religiosa': _usuarioData!['fe_religiosa'],
                  });

                  if (!mounted) return;
                  Navigator.pop(dialogCtx);

                  // Refrescamos la UI
                  await _cargarDatosUsuario();

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: azulFondo,
                      content: Text(
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
                'Guardar cambios',
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: azulFondo, fontSize: screenWidth * 0.04),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey.shade600,
          fontSize: screenWidth * 0.035,
        ),
        prefixIcon: Icon(icon, color: azulFondo, size: screenWidth * 0.05),
        filled: true,
        fillColor: Colors.white,
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
          borderSide: const BorderSide(color: azulFondo, width: 1.5),
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
  }) {
    return Container(
      width: screenWidth,
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.05,
        usableHeight * 0.02,
        screenWidth * 0.05,
        usableHeight * 0.03,
      ),
      decoration: BoxDecoration(
        color: azulFondo,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(screenWidth * 0.07),
          bottomRight: Radius.circular(screenWidth * 0.07),
        ),
      ),
      child: Row(
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
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                _mostrarDialogoEditarDatos(context, screenWidth, usableHeight),
            icon: Icon(
              Icons.edit_outlined,
              color: Colors.white,
              size: screenWidth * 0.055,
            ),
          ),
        ],
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
          fontSize: screenWidth * 0.035,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
        border: Border.all(color: grisBorde),
      ),
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
                  Icon(item.icon, color: azulFondo, size: screenWidth * 0.055),
                  SizedBox(width: screenWidth * 0.035),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: azulFondo,
                        fontSize: screenWidth * 0.036,
                        fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildLogoutButton(
    BuildContext context,
    double screenWidth,
    double usableHeight,
  ) {
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
          'Cerrar sesión',
          style: TextStyle(
            fontSize: screenWidth * 0.038,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Conservamos el llamado a UserProvider SOLO para el limpiado de sesión
              Provider.of<UserProvider>(context, listen: false).clearSession();
              Navigator.pushNamedAndRemoveUntil(
                context,
                InicioSesionScreen.routeName,
                (route) => false,
              );
            },
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Color(0xFFC0392B)),
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

  const _MenuItemData({
    required this.icon,
    required this.label,
    this.route,
    this.onCustomTap,
  });
}
