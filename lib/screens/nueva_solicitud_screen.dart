import 'package:flutter/material.dart';

import '../data/atrio_database_helper.dart';
import '../l10n/app_localizations.dart';
import '../widgets/modal_confirmacion_solicitud.dart';

class NuevaSolicitudScreen extends StatefulWidget {
  static const routeName = 'nueva_solicitud_screen';
  const NuevaSolicitudScreen({super.key});

  @override
  State<NuevaSolicitudScreen> createState() => _NuevaSolicitudScreenState();
}

class _NuevaSolicitudScreenState extends State<NuevaSolicitudScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _asuntoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  String? _selectedTipoSolicitud;
  bool _isPrivate = false;

  @override
  void initState() {
    super.initState();
    _cargarTelefonoUsuario();
  }

  Future<void> _cargarTelefonoUsuario() async {
    try {
      final user = await AtrioDatabaseHelper.instance.getUsuario();
      if (user != null && mounted) {
        final cel = (user['celular'] as String?)?.trim();
        if (cel != null && cel.isNotEmpty && _telefonoController.text.isEmpty) {
          setState(() {
            _telefonoController.text = cel;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args.containsKey('tipo')) {
      _selectedTipoSolicitud = args['tipo'] as String;
    }
  }

  @override
  void dispose() {
    _asuntoController.dispose();
    _descripcionController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);
    const Color grisBorde = Color(0xFFE5E5E5);

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: true,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight,
          child: Column(
            children: [
              // Encabezado Superior (Botón Volver + Título + Campana)
              Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: usableHeight * 0.015,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white,
                          size: screenWidth * 0.07,
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Text(
                        l10n?.nuevaSolicitud ?? 'Nueva solicitud',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.058,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.02),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: screenWidth * 0.058,
                          ),
                        ),
                        Positioned(
                          top: screenWidth * 0.015,
                          right: screenWidth * 0.015,
                          child: Container(
                            width: screenWidth * 0.022,
                            height: screenWidth * 0.022,
                            decoration: const BoxDecoration(
                              color: amarilloOro,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Contenedor Blanco Inferior con Formulario
              Expanded(
                child: Container(
                  width: screenWidth,
                  decoration: BoxDecoration(
                    color: blancoFondo,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.08),
                      topRight: Radius.circular(screenWidth * 0.08),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.08),
                      topRight: Radius.circular(screenWidth * 0.08),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.055,
                        vertical: usableHeight * 0.025,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Selector Tipo de Solicitud
                            _buildFieldLabel(
                              l10n?.tipoSolicitudLabel ?? 'Tipo de solicitud',
                              screenWidth,
                              azulFondo,
                            ),
                            SizedBox(height: usableHeight * 0.008),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  'tipos_solicitud_screen',
                                );
                              },
                              child: Container(
                                height: usableHeight * 0.058,
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.03,
                                  ),
                                  border: Border.all(color: grisBorde),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedTipoSolicitud ??
                                          (l10n?.seleccionaUnaOpcion ??
                                              'Selecciona una opción'),
                                      style: TextStyle(
                                        color: _selectedTipoSolicitud != null
                                            ? azulFondo
                                            : Colors.grey.shade500,
                                        fontSize: screenWidth * 0.036,
                                        fontWeight:
                                            _selectedTipoSolicitud != null
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: Colors.grey.shade500,
                                      size: screenWidth * 0.055,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: usableHeight * 0.02),

                            // 2. Campo Asunto (Obligatorio)
                            _buildFieldLabel(
                              l10n?.asunto ?? 'Asunto',
                              screenWidth,
                              azulFondo,
                              isRequired: true,
                            ),
                            SizedBox(height: usableHeight * 0.008),
                            _buildInputField(
                              controller: _asuntoController,
                              hintText: l10n?.asuntoPlaceholder ??
                                  'Escribe un asunto breve',
                              screenWidth: screenWidth,
                              usableHeight: usableHeight,
                              grisBorde: grisBorde,
                              azulFondo: azulFondo,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return l10n?.asuntoObligatorio ??
                                      'El asunto es obligatorio';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: usableHeight * 0.02),

                            // 3. Campo Descripción (Obligatorio)
                            _buildFieldLabel(
                              l10n?.describeComoAyudarte ??
                                  'Describe cómo podemos ayudarte',
                              screenWidth,
                              azulFondo,
                              isRequired: true,
                            ),
                            SizedBox(height: usableHeight * 0.008),
                            TextFormField(
                              controller: _descripcionController,
                              minLines: 4,
                              maxLines: 6,
                              style: TextStyle(
                                color: azulFondo,
                                fontSize: screenWidth * 0.036,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return l10n?.descripcionObligatoria ??
                                      'La descripción es obligatoria';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: l10n?.detallesSolicitudPlaceholder ??
                                    'Cuéntanos los detalles de tu solicitud',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: screenWidth * 0.035,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                  vertical: usableHeight * 0.015,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.03,
                                  ),
                                  borderSide: BorderSide(color: grisBorde),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.03,
                                  ),
                                  borderSide: BorderSide(
                                    color: azulFondo,
                                    width: 1.5,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.03,
                                  ),
                                  borderSide: BorderSide(
                                    color: Colors.red.shade700,
                                    width: 1.2,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.03,
                                  ),
                                  borderSide: BorderSide(
                                    color: Colors.red.shade700,
                                    width: 1.5,
                                  ),
                                ),
                                errorStyle: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: screenWidth * 0.030,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(height: usableHeight * 0.02),

                            // 4. Campo Teléfono (Obligatorio)
                            _buildFieldLabel(
                              l10n?.telefono ?? 'Teléfono',
                              screenWidth,
                              azulFondo,
                              isRequired: true,
                            ),
                            SizedBox(height: usableHeight * 0.008),
                            _buildInputField(
                              controller: _telefonoController,
                              hintText: '(55) 1234 5678',
                              keyboardType: TextInputType.phone,
                              screenWidth: screenWidth,
                              usableHeight: usableHeight,
                              grisBorde: grisBorde,
                              azulFondo: azulFondo,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return l10n?.telefonoObligatorio ??
                                      'El teléfono es obligatorio';
                                }
                                final clean = val.replaceAll(
                                  RegExp(r'[^0-9]'),
                                  '',
                                );
                                if (clean.length < 7) {
                                  return l10n?.telefonoInvalido ??
                                      'Ingresa un número de teléfono válido';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: usableHeight * 0.025),

                            // 5. Switch Solicitud Privada
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n?.solicitudPrivada ??
                                            'Solicitud privada',
                                        style: TextStyle(
                                          color: azulFondo,
                                          fontSize: screenWidth * 0.042,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: usableHeight * 0.003),
                                      Text(
                                        l10n?.solicitudPrivadaDesc ??
                                            'Solo el equipo pastoral podrá verla',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: screenWidth * 0.033,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _isPrivate,
                                  activeThumbColor: Colors.white,
                                  activeTrackColor: amarilloOro,
                                  inactiveThumbColor: Colors.white,
                                  inactiveTrackColor: Colors.grey.shade300,
                                  onChanged: (val) =>
                                      setState(() => _isPrivate = val),
                                ),
                              ],
                            ),
                            SizedBox(height: usableHeight * 0.03),

                            // 6. Botón Enviar Solicitud
                            SizedBox(
                              width: double.infinity,
                              height: usableHeight * 0.058,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: amarilloOro,
                                  foregroundColor: azulFondo,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      screenWidth * 0.03,
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    ModalConfirmacionSolicitud.mostrar(
                                      context: context,
                                      tipoSolicitud:
                                          _selectedTipoSolicitud ??
                                              (l10n?.general ?? 'General'),
                                      asunto: _asuntoController.text.trim(),
                                      mensaje: _descripcionController.text.trim(),
                                      isPrivate: _isPrivate,
                                      onConfirmado: () {
                                        Navigator.pop(context);
                                      },
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: const Color(
                                          0xFFC0392B,
                                        ),
                                        content: Text(
                                          l10n?.completaCamposObligatorios ??
                                              'Por favor completa todos los campos obligatorios.',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        duration: const Duration(seconds: 3),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  l10n?.enviarSolicitud ?? 'Enviar solicitud',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.045,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: usableHeight * 0.02),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(
    String text,
    double screenWidth,
    Color azulFondo, {
    bool isRequired = false,
  }) {
    if (!isRequired) {
      return Text(
        text,
        style: TextStyle(
          color: azulFondo,
          fontSize: screenWidth * 0.040,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            color: azulFondo,
            fontSize: screenWidth * 0.040,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: screenWidth * 0.01),
        Text(
          '*',
          style: TextStyle(
            color: Colors.red.shade700,
            fontSize: screenWidth * 0.042,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required double screenWidth,
    required double usableHeight,
    required Color grisBorde,
    required Color azulFondo,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: azulFondo, fontSize: screenWidth * 0.036),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: screenWidth * 0.035,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: usableHeight * 0.015,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: BorderSide(color: grisBorde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: BorderSide(color: azulFondo, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: BorderSide(color: Colors.red.shade700, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
        ),
        errorStyle: TextStyle(
          color: Colors.red.shade700,
          fontSize: screenWidth * 0.030,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
