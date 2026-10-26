import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../atrio_api.dart';
import '../models/event_dto.dart';
import '../providers/admin_provider.dart';
import '../providers/user_provider.dart';
import '../utils/media_validator.dart';

/// Pantalla responsiva para la creación y publicación de eventos congregacionales.
/// Exclusivo para administradores de iglesia (church_admin).
class CrearEventoScreen extends StatefulWidget {
  static const routeName = 'crear_evento_screen';

  const CrearEventoScreen({super.key});

  @override
  State<CrearEventoScreen> createState() => _CrearEventoScreenState();
}

class _CrearEventoScreenState extends State<CrearEventoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final ScrollController _scrollController;

  // Controladores de texto
  late final TextEditingController _tituloController;
  late final TextEditingController _descripcionController;
  late final TextEditingController _organizadorController;
  late final TextEditingController _lugarController;
  late final TextEditingController _streamUrlController;
  late final TextEditingController _cupoController;
  late final TextEditingController _categoriaController;

  // Estado del formulario
  EventModality _modalidad = EventModality.presencial;
  DateTime _fechaInicio = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _horaInicio = const TimeOfDay(hour: 18, minute: 30);
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 1));
  bool _esDestacado = false;

  // Banner y compresión
  String? _imagenBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tituloController = TextEditingController();
    _descripcionController = TextEditingController();
    _organizadorController = TextEditingController();
    _lugarController = TextEditingController(text: 'Auditorio Principal ATRIO');
    _streamUrlController = TextEditingController();
    _cupoController = TextEditingController(text: '150');
    _categoriaController = TextEditingController(text: 'General');

    // Inicializar fechas coherentes
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _fechaInicio = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 18, 30);
    _fechaFin = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 20, 30);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tituloController.dispose();
    _descripcionController.dispose();
    _organizadorController.dispose();
    _lugarController.dispose();
    _streamUrlController.dispose();
    _cupoController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // SELECTORES DE FECHA Y HORA
  // ===========================================================================

  Future<void> _seleccionarFechaInicio(BuildContext context) async {
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: azulFondo,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: azulFondo,
            secondary: amarilloOro,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _fechaInicio = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _horaInicio.hour,
          _horaInicio.minute,
        );
        if (_fechaFin.isBefore(_fechaInicio)) {
          _fechaFin = _fechaInicio.add(const Duration(hours: 2));
        }
      });
    }
  }

  Future<void> _seleccionarHoraInicio(BuildContext context) async {
    const Color azulFondo = Color(0xFF072B4F);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _horaInicio,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: azulFondo,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: azulFondo,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _horaInicio = picked;
        _fechaInicio = DateTime(
          _fechaInicio.year,
          _fechaInicio.month,
          _fechaInicio.day,
          picked.hour,
          picked.minute,
        );
        if (_fechaFin.isBefore(_fechaInicio)) {
          _fechaFin = _fechaInicio.add(const Duration(hours: 2));
        }
      });
    }
  }

  // ===========================================================================
  // CAPTURA Y COMPRESIÓN DE BANNERS (image_picker + Base64)
  // ===========================================================================

  Future<void> _seleccionarImagen(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 720,
        imageQuality: 82,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final validation = MediaValidator.validateImageBytes(bytes);
        if (!validation.isValid) {
          if (!mounted) return;
          MediaValidator.showImageSizeExceededModal(
            context,
            sizeInMB: validation.sizeInMB,
          );
          return;
        }

        setState(() {
          _imagenBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      debugPrint('[CrearEventoScreen] Error seleccionando imagen: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cargar la imagen: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  // ===========================================================================
  // ENVÍO Y PERSISTENCIA
  // ===========================================================================

  Future<void> _guardarEvento() async {
    if (!_formKey.currentState!.validate()) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Por favor completa todos los campos requeridos marcados con asterisco (*).'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final userProvider = context.read<UserProvider>();
    final adminProvider = context.read<AdminProvider>();

    if (userProvider.isReadOnly) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acción denegada: cuenta en modo solo lectura.'),
          backgroundColor: Color(0xFF072B4F),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cupoParsed = int.tryParse(_cupoController.text.trim()) ?? 100;
      final organizadorDefecto = _organizadorController.text.trim().isNotEmpty
          ? _organizadorController.text.trim()
          : (userProvider.currentUser?.iglesiaActual ?? 'Iglesia ATRIO');

      final streamUrlLimpia = _streamUrlController.text.trim();
      final eventDto = EventDto(
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        modalidad: _modalidad,
        enlaceUbicacionOStream: streamUrlLimpia.isNotEmpty ? streamUrlLimpia : null,
        imagenPortadaBase64: _imagenBase64,
        cupoMaximo: cupoParsed,
        esDestacado: _esDestacado,
        organizador: organizadorDefecto,
        categoria: _categoriaController.text.trim().isNotEmpty
            ? _categoriaController.text.trim()
            : 'General',
        lugar: _lugarController.text.trim().isNotEmpty
            ? _lugarController.text.trim()
            : 'Auditorio Principal',
      );

      final success = await adminProvider.createEvent(eventDto);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('¡Evento publicado con éxito en Odoo 19!'),
                ),
              ],
            ),
            backgroundColor: Color(0xFF166534),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final errorMsg = adminProvider.errorMessage ??
            'Error al registrar el evento en el servidor Odoo.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMsg)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on AtrioApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error de API (${e.code}): ${e.message}')),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error inesperado: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Métricas relativas dinámicas (Flutter 3.22+)
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: true,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight,
          child: Column(
            children: [
              // 1. Barra Superior con retroceso y título responsivo
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nuevo Evento',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.056,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Publicación oficial en tu congregación',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: screenWidth * 0.030,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Contenedor Blanco Inferior Scrollable
              Expanded(
                child: Material(
                  color: blancoFondo,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(screenWidth * 0.08),
                    topRight: Radius.circular(screenWidth * 0.08),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: usableHeight * 0.025,
                    ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Selector de Banner / Imagen de Portada
                            _buildBannerPicker(screenWidth, usableHeight),
                            SizedBox(height: usableHeight * 0.022),

                            // Título del Evento
                            _buildSectionLabel('Título del Evento *', screenWidth),
                            SizedBox(height: usableHeight * 0.006),
                            TextFormField(
                              controller: _tituloController,
                              style: TextStyle(fontSize: screenWidth * 0.038),
                              decoration: _inputDecoration(
                                hint: 'Ej: Conferencia Anual de Liderazgo 2026',
                                icon: Icons.title_rounded,
                                screenWidth: screenWidth,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Por favor ingresa un título para el evento';
                                }
                                if (val.trim().length < 4) {
                                  return 'El título debe tener al menos 4 caracteres';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: usableHeight * 0.018),

                            // Selector de Modalidad (Presencial / Virtual / Híbrido)
                            _buildSectionLabel('Modalidad de Celebración', screenWidth),
                            SizedBox(height: usableHeight * 0.008),
                            _buildModalitySelector(screenWidth, usableHeight),
                            SizedBox(height: usableHeight * 0.018),

                            // Campo Dinámico de Transmisión o Streaming
                            if (_modalidad != EventModality.presencial) ...[
                              _buildSectionLabel(
                                'Enlace de Transmisión (YouTube Live / Stream) *',
                                screenWidth,
                              ),
                              SizedBox(height: usableHeight * 0.006),
                              TextFormField(
                                controller: _streamUrlController,
                                style: TextStyle(fontSize: screenWidth * 0.038),
                                decoration: _inputDecoration(
                                  hint: 'https://youtube.com/live/ID o https://youtu.be/ID',
                                  icon: Icons.live_tv_rounded,
                                  screenWidth: screenWidth,
                                ),
                                validator: (val) {
                                  if (_modalidad == EventModality.virtual &&
                                      (val == null || val.trim().isEmpty)) {
                                    return 'El enlace de streaming es requerido para modalidad virtual';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: usableHeight * 0.018),
                            ],

                            // Campo de Lugar / Ubicación Física
                            if (_modalidad != EventModality.virtual) ...[
                              _buildSectionLabel('Lugar / Dirección Física', screenWidth),
                              SizedBox(height: usableHeight * 0.006),
                              TextFormField(
                                controller: _lugarController,
                                style: TextStyle(fontSize: screenWidth * 0.038),
                                decoration: _inputDecoration(
                                  hint: 'Auditorio Principal, Calle Central 123',
                                  icon: Icons.location_on_rounded,
                                  screenWidth: screenWidth,
                                ),
                              ),
                              SizedBox(height: usableHeight * 0.018),
                            ],

                            // Selector de Fecha y Hora
                            _buildSectionLabel('Fecha y Horario de Inicio', screenWidth),
                            SizedBox(height: usableHeight * 0.008),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPickerButton(
                                    label:
                                        '${_fechaInicio.day.toString().padLeft(2, '0')}/${_fechaInicio.month.toString().padLeft(2, '0')}/${_fechaInicio.year}',
                                    icon: Icons.calendar_today_rounded,
                                    onTap: () => _seleccionarFechaInicio(context),
                                    screenWidth: screenWidth,
                                    usableHeight: usableHeight,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.03),
                                Expanded(
                                  child: _buildPickerButton(
                                    label: _horaInicio.format(context),
                                    icon: Icons.access_time_rounded,
                                    onTap: () => _seleccionarHoraInicio(context),
                                    screenWidth: screenWidth,
                                    usableHeight: usableHeight,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: usableHeight * 0.018),

                            // Cupo y Categoría
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionLabel('Cupo Máximo', screenWidth),
                                      SizedBox(height: usableHeight * 0.006),
                                      TextFormField(
                                        controller: _cupoController,
                                        keyboardType: TextInputType.number,
                                        style: TextStyle(fontSize: screenWidth * 0.038),
                                        decoration: _inputDecoration(
                                          hint: '150',
                                          icon: Icons.people_outline_rounded,
                                          screenWidth: screenWidth,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.03),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionLabel('Categoría', screenWidth),
                                      SizedBox(height: usableHeight * 0.006),
                                      TextFormField(
                                        controller: _categoriaController,
                                        style: TextStyle(fontSize: screenWidth * 0.038),
                                        decoration: _inputDecoration(
                                          hint: 'Adoración',
                                          icon: Icons.category_rounded,
                                          screenWidth: screenWidth,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: usableHeight * 0.018),

                            // Descripción Detallada
                            _buildSectionLabel('Descripción del Evento *', screenWidth),
                            SizedBox(height: usableHeight * 0.006),
                            TextFormField(
                              controller: _descripcionController,
                              maxLines: 4,
                              style: TextStyle(fontSize: screenWidth * 0.038),
                              decoration: _inputDecoration(
                                hint: 'Comparte con la congregación el propósito, invitados especiales y recomendaciones del culto.',
                                screenWidth: screenWidth,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Por favor ingresa una descripción para el evento';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: usableHeight * 0.015),

                            // Destacar en Portada (Switch)
                            SwitchListTile(
                              value: _esDestacado,
                              onChanged: (val) => setState(() => _esDestacado = val),
                              title: Text(
                                'Destacar evento en portada',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.038,
                                  fontWeight: FontWeight.bold,
                                  color: azulFondo,
                                ),
                              ),
                              subtitle: Text(
                                'Aparecerá en el banner principal superior de la app.',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.030,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              activeThumbColor: amarilloOro,
                              contentPadding: EdgeInsets.zero,
                            ),
                            SizedBox(height: usableHeight * 0.025),

                            // Botón de Envío / Guardado
                            SizedBox(
                              width: screenWidth,
                              height: usableHeight * 0.062,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: amarilloOro,
                                  foregroundColor: azulFondo,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(screenWidth * 0.03),
                                  ),
                                ),
                                onPressed: _isLoading ? null : _guardarEvento,
                                child: _isLoading
                                    ? SizedBox(
                                        width: screenWidth * 0.06,
                                        height: screenWidth * 0.06,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  azulFondo),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.cloud_upload_rounded,
                                            size: screenWidth * 0.052,
                                          ),
                                          SizedBox(width: screenWidth * 0.02),
                                          Flexible(
                                            child: Text(
                                              'Publicar Evento',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: screenWidth * 0.040,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            SizedBox(height: usableHeight * 0.03),
                          ],
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

  // ===========================================================================
  // WIDGETS AUXILIARES RESPONSIVOS
  // ===========================================================================

  Widget _buildSectionLabel(String text, double screenWidth) {
    return Text(
      text,
      style: TextStyle(
        fontSize: screenWidth * 0.036,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF072B4F),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    IconData? icon,
    required double screenWidth,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: screenWidth * 0.034,
      ),
      prefixIcon: icon != null
          ? Icon(
              icon,
              color: const Color(0xFF072B4F).withValues(alpha: 0.6),
              size: screenWidth * 0.05,
            )
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenWidth * 0.035,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        borderSide: const BorderSide(color: Color(0xFF072B4F), width: 1.5),
      ),
    );
  }

  Widget _buildModalitySelector(double screenWidth, double usableHeight) {
    const Color azulFondo = Color(0xFF072B4F);

    return Container(
      width: screenWidth,
      padding: EdgeInsets.all(screenWidth * 0.012),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: EventModality.values.map((mod) {
          final isSelected = _modalidad == mod;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _modalidad = mod),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  vertical: usableHeight * 0.012,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? azulFondo : Colors.transparent,
                  borderRadius: BorderRadius.circular(screenWidth * 0.022),
                ),
                alignment: Alignment.center,
                child: Text(
                  mod.label.split(' ').first,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontSize: screenWidth * 0.033,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPickerButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required double screenWidth,
    required double usableHeight,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(screenWidth * 0.03),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: usableHeight * 0.014,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: screenWidth * 0.045, color: const Color(0xFF072B4F)),
            SizedBox(width: screenWidth * 0.02),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: screenWidth * 0.034,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF072B4F),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerPicker(double screenWidth, double usableHeight) {
    const Color azulFondo = Color(0xFF072B4F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Banner o Portada del Evento', screenWidth),
        SizedBox(height: usableHeight * 0.008),
        Container(
          width: screenWidth,
          height: usableHeight * 0.20,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(screenWidth * 0.035),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _imagenBase64 != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.035),
                      child: Image.memory(
                        base64Decode(_imagenBase64!),
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _imagenBase64 = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: screenWidth * 0.12,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: usableHeight * 0.008),
                    Text(
                      'Toca para seleccionar carátula',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.032,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.012),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () => _seleccionarImagen(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: const Text('Galería'),
                          style: TextButton.styleFrom(foregroundColor: azulFondo),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        TextButton.icon(
                          onPressed: () => _seleccionarImagen(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('Cámara'),
                          style: TextButton.styleFrom(foregroundColor: azulFondo),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
