import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../atrio_api.dart';
import '../models/sermon_dto.dart';
import '../providers/admin_provider.dart';
import '../providers/user_provider.dart';
import '../utils/media_validator.dart';
import '../utils/youtube_helper.dart';

/// Pantalla responsiva para la publicación de Prédicas y Transmisiones en Vivo.
/// Exclusivo para administradores pastorales y líderes de iglesia (church_admin).
class CrearPredicaScreen extends StatefulWidget {
  static const routeName = 'crear_predica_screen';

  const CrearPredicaScreen({super.key});

  @override
  State<CrearPredicaScreen> createState() => _CrearPredicaScreenState();
}

class _CrearPredicaScreenState extends State<CrearPredicaScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  late final TextEditingController _tituloController;
  late final TextEditingController _predicadorController;
  late final TextEditingController _videoUrlController;
  late final TextEditingController _descripcionController;

  // Estado del streaming y contenido
  bool _esEnVivo = true;
  StreamingPlatform _plataforma = StreamingPlatform.youtube;
  String? _detectedYoutubeId;
  String? _detectedChannelHandle;
  String? _detectedChannelId;
  bool _isChannelLive = false;

  // Video local individual opcional (10s a 5 min)
  String? _videoLocalPath;
  String? _videoLocalName;
  Duration? _videoLocalDuration;
  double? _videoLocalSizeMB;

  String _categoria = 'Prédicas';
  bool _fijado = false;
  final DateTime _fecha = DateTime.now();

  // Banner personalizado opcional
  String? _imagenBase64;
  bool _isLoading = false;

  final List<String> _categoriasDisponibles = [
    'Prédicas',
    'En vivo',
    'Estudios',
    'Música',
    'Conferencias',
  ];

  @override
  void initState() {
    super.initState();
    _tituloController = TextEditingController();
    _predicadorController = TextEditingController();
    _videoUrlController = TextEditingController();
    _descripcionController = TextEditingController();

    // Listener reactivo en tiempo real para parseo de streaming de video y canales
    _videoUrlController.addListener(_onVideoUrlChanged);
  }

  void _onVideoUrlChanged() {
    final text = _videoUrlController.text.trim();
    if (_videoLocalPath != null && text != _videoLocalPath) {
      _videoLocalPath = null;
      _videoLocalName = null;
      _videoLocalDuration = null;
      _videoLocalSizeMB = null;
    }

    final detectedId = YoutubeHelper.extractId(text);
    final detectedHandle = YoutubeHelper.extractChannelHandle(text);
    final detectedChannelId = YoutubeHelper.extractChannelId(text);
    final isChannelLive = YoutubeHelper.isChannelLiveUrl(text);
    final detectedPlatform = YoutubeHelper.detectPlatform(text);

    if (_detectedYoutubeId != detectedId ||
        _detectedChannelHandle != detectedHandle ||
        _detectedChannelId != detectedChannelId ||
        _isChannelLive != isChannelLive ||
        _plataforma != detectedPlatform) {
      setState(() {
        _detectedYoutubeId = detectedId;
        _detectedChannelHandle = detectedHandle;
        _detectedChannelId = detectedChannelId;
        _isChannelLive = isChannelLive;
        _plataforma = detectedPlatform;
      });
    }
  }

  @override
  void dispose() {
    _videoUrlController.removeListener(_onVideoUrlChanged);
    _tituloController.dispose();
    _predicadorController.dispose();
    _videoUrlController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // CAPTURA Y COMPRESIÓN DE BANNERS (image_picker + Base64)
  // ===========================================================================

  Future<void> _seleccionarBannerPersonalizado(ImageSource source) async {
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
          await MediaValidator.showImageSizeExceededModal(
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
      debugPrint('[CrearPredicaScreen] Error seleccionando banner: $e');
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
  // SUBIDA Y VALIDACIÓN DE VIDEO INDIVIDUAL (10s a 5 min)
  // ===========================================================================

  Future<void> _seleccionarVideoIndividual(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        final validation = await MediaValidator.validateVideoFile(
          video,
          channelHandle: '@AtrioIglesia',
        );

        if (!mounted) return;

        // Caso 1: Video supera los 5 minutos -> Sugerir amigablemente YouTube
        if (validation.isTooLong && validation.duration != null) {
          await MediaValidator.showVideoDurationExceededModal(
            context,
            duration: validation.duration!,
            channelHandle: '@AtrioIglesia',
            onUseYoutubeStreaming: () {
              setState(() {
                _videoLocalPath = null;
                _videoLocalName = null;
                _videoLocalDuration = null;
                _videoLocalSizeMB = null;
                _videoUrlController.clear();
              });
            },
          );
          return;
        }

        // Caso 2: Video dura menos de 10 segundos
        if (validation.isTooShort && validation.duration != null) {
          await MediaValidator.showVideoTooShortModal(
            context,
            duration: validation.duration!,
          );
          return;
        }

        // Caso 3: Video dentro del rango permitido (10s a 5 min)
        if (validation.isValid) {
          setState(() {
            _videoLocalPath = video.path;
            _videoLocalName = video.name;
            _videoLocalDuration = validation.duration;
            _videoLocalSizeMB = validation.sizeInMB;
            _videoUrlController.text = video.path;
          });
        }
      }
    } catch (e) {
      debugPrint('[CrearPredicaScreen] Error seleccionando video individual: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo cargar el video: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  // ===========================================================================
  // GUARDAR Y TRANSMITIR
  // ===========================================================================

  Future<void> _guardarPredica() async {
    if (!_formKey.currentState!.validate()) return;

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
      final predicadorLimpio = _predicadorController.text.trim().isNotEmpty
          ? _predicadorController.text.trim()
          : (userProvider.currentUser?.nombre ?? 'Pastor de la Comunidad');

      final sermonDto = SermonDto(
        titulo: _tituloController.text.trim(),
        predicador: predicadorLimpio,
        fecha: _fecha,
        esEnVivo: _esEnVivo,
        plataforma: _plataforma,
        urlOIdVideo: _videoUrlController.text.trim(),
        descripcion: _descripcionController.text.trim().isNotEmpty
            ? _descripcionController.text.trim()
            : null,
        imagenPortadaBase64: _imagenBase64,
        categoria: _esEnVivo ? 'En vivo' : _categoria,
        fijado: _fijado,
        canalOIglesia: userProvider.currentUser?.iglesiaActual,
      );

      final success = await adminProvider.createSermon(sermonDto);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _esEnVivo
                        ? '¡Transmisión en vivo publicada con éxito en la congregación!'
                        : '¡Prédica grabada agregada al catálogo de la iglesia!',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF166534),
          ),
        );
        Navigator.pop(context, true);
      } else {
        final errorMsg = adminProvider.errorMessage ??
            'Error al publicar la prédica en el servidor Odoo.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } on AtrioApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de API (${e.code}): ${e.message}'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red.shade700,
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
    const Color rojoLive = Color(0xFFE53935);

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
                            _esEnVivo
                                ? 'Transmitir en Vivo'
                                : 'Publicar Prédica',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.056,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Difusión audiovisual congregacional',
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
                            // Selector de Tipo de Emisión (En Vivo vs Grabado)
                            _buildLiveToggle(screenWidth, usableHeight, rojoLive),
                            SizedBox(height: usableHeight * 0.022),

                            // Encabezado con acción rápida para subir video corto
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                _buildSectionLabel(
                                  'Video o Transmisión *',
                                  screenWidth,
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      _seleccionarVideoIndividual(ImageSource.gallery),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.025,
                                      vertical: usableHeight * 0.005,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          const Color(0xFF072B4F).withValues(alpha: 0.08),
                                      borderRadius:
                                          BorderRadius.circular(screenWidth * 0.02),
                                      border: Border.all(
                                        color: const Color(0xFF072B4F)
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.upload_file_rounded,
                                          size: screenWidth * 0.038,
                                          color: const Color(0xFF072B4F),
                                        ),
                                        SizedBox(width: screenWidth * 0.01),
                                        Text(
                                          'Subir video corto (10s-5m)',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.028,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF072B4F),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: usableHeight * 0.006),
                            TextFormField(
                              controller: _videoUrlController,
                              style: TextStyle(fontSize: screenWidth * 0.038),
                              decoration: _inputDecoration(
                                hint: 'https://youtube.com/live/... o archivo local',
                                icon: Icons.video_collection_rounded,
                                screenWidth: screenWidth,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Por favor ingresa la URL o selecciona un video corto';
                                }
                                if (_videoLocalPath != null ||
                                    YoutubeHelper.isDirectVideoFile(val)) {
                                  return null;
                                }
                                if (!YoutubeHelper.isValidYoutubeUrlOrId(val)) {
                                  return 'Ingresa un enlace de YouTube válido (video, canal o transmisión)';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: usableHeight * 0.012),

                            // Badge interactivo de detección y previsualización de miniatura
                            _buildStreamingPreview(screenWidth, usableHeight),
                            SizedBox(height: usableHeight * 0.018),

                            // Título de la Prédica o Culto
                            _buildSectionLabel(
                              'Título del Mensaje o Culto *',
                              screenWidth,
                            ),
                            SizedBox(height: usableHeight * 0.006),
                            TextFormField(
                              controller: _tituloController,
                              style: TextStyle(fontSize: screenWidth * 0.038),
                              decoration: _inputDecoration(
                                hint: 'Ej: Culto Dominical: La Fe que Vence al Mundo',
                                icon: Icons.title_rounded,
                                screenWidth: screenWidth,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Por favor ingresa el título del mensaje';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: usableHeight * 0.018),

                            // Predicador / Orador
                            _buildSectionLabel(
                              'Predicador / Ministro *',
                              screenWidth,
                            ),
                            SizedBox(height: usableHeight * 0.006),
                            TextFormField(
                              controller: _predicadorController,
                              style: TextStyle(fontSize: screenWidth * 0.038),
                              decoration: _inputDecoration(
                                hint: 'Pastor Andrés Gómez / Invitado Especial',
                                icon: Icons.person_rounded,
                                screenWidth: screenWidth,
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Por favor ingresa el nombre del predicador';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: usableHeight * 0.018),

                            // Categoría Temática
                            if (!_esEnVivo) ...[
                              _buildSectionLabel('Categoría Temática', screenWidth),
                              SizedBox(height: usableHeight * 0.008),
                              _buildCategorySelector(screenWidth, usableHeight),
                              SizedBox(height: usableHeight * 0.018),
                            ],

                            // Sinopsis / Descripción
                            _buildSectionLabel(
                              'Descripción / Pasajes Bíblicos',
                              screenWidth,
                            ),
                            SizedBox(height: usableHeight * 0.006),
                            TextFormField(
                              controller: _descripcionController,
                              maxLines: 3,
                              style: TextStyle(fontSize: screenWidth * 0.038),
                              decoration: _inputDecoration(
                                hint: 'Anota los pasajes centrales, citas clave y resumen del mensaje espiritual.',
                                screenWidth: screenWidth,
                              ),
                            ),
                            SizedBox(height: usableHeight * 0.018),

                            // Opción de Banner Manual Personalizado (Opcional)
                            _buildCustomBannerSection(screenWidth, usableHeight),
                            SizedBox(height: usableHeight * 0.015),

                            // Fijar al Inicio (Switch)
                            SwitchListTile(
                              value: _fijado,
                              onChanged: (val) => setState(() => _fijado = val),
                              title: Text(
                                'Fijar al inicio de la sección',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.038,
                                  fontWeight: FontWeight.bold,
                                  color: azulFondo,
                                ),
                              ),
                              subtitle: Text(
                                'Aparecerá en el primer lugar del catálogo de transmisiones.',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.030,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              activeThumbColor: amarilloOro,
                              contentPadding: EdgeInsets.zero,
                            ),
                            SizedBox(height: usableHeight * 0.025),

                            // Botón de Publicación
                            SizedBox(
                              width: screenWidth,
                              height: usableHeight * 0.062,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _esEnVivo ? rojoLive : amarilloOro,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(screenWidth * 0.03),
                                  ),
                                ),
                                onPressed: _isLoading ? null : _guardarPredica,
                                child: _isLoading
                                    ? SizedBox(
                                        width: screenWidth * 0.06,
                                        height: screenWidth * 0.06,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _esEnVivo
                                                ? Icons.sensors_rounded
                                                : Icons.cloud_upload_rounded,
                                            size: screenWidth * 0.052,
                                          ),
                                          SizedBox(width: screenWidth * 0.02),
                                          Flexible(
                                            child: Text(
                                              _esEnVivo
                                                  ? 'Publicar Transmisión en Vivo'
                                                  : 'Publicar Prédica',
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
  // WIDGETS AUXILIARES
  // ===========================================================================

  Widget _buildLiveToggle(double screenWidth, double usableHeight, Color rojoLive) {
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
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _esEnVivo = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: usableHeight * 0.012),
                decoration: BoxDecoration(
                  color: _esEnVivo ? rojoLive : Colors.transparent,
                  borderRadius: BorderRadius.circular(screenWidth * 0.022),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fiber_manual_record_rounded,
                      size: screenWidth * 0.035,
                      color: _esEnVivo ? Colors.white : rojoLive,
                    ),
                    SizedBox(width: screenWidth * 0.015),
                    Flexible(
                      child: Text(
                        'Culto en Vivo',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _esEnVivo ? Colors.white : Colors.grey.shade700,
                          fontSize: screenWidth * 0.034,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _esEnVivo = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: usableHeight * 0.012),
                decoration: BoxDecoration(
                  color: !_esEnVivo ? azulFondo : Colors.transparent,
                  borderRadius: BorderRadius.circular(screenWidth * 0.022),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_outline_rounded,
                      size: screenWidth * 0.040,
                      color: !_esEnVivo ? Colors.white : Colors.grey.shade600,
                    ),
                    SizedBox(width: screenWidth * 0.015),
                    Flexible(
                      child: Text(
                        'Prédica Grabada',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: !_esEnVivo ? Colors.white : Colors.grey.shade700,
                          fontSize: screenWidth * 0.034,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildStreamingPreview(double screenWidth, double usableHeight) {
    // Caso 0: Video individual local seleccionado (10s a 5 min)
    if (_videoLocalPath != null) {
      final minutos = (_videoLocalDuration?.inMinutes ?? 0);
      final segundos = (_videoLocalDuration?.inSeconds ?? 0) % 60;
      final duracionStr = '${minutos}m ${segundos.toString().padLeft(2, '0')}s';
      final sizeStr = _videoLocalSizeMB != null
          ? '${_videoLocalSizeMB!.toStringAsFixed(2)} MB'
          : '';

      return Container(
        padding: EdgeInsets.all(screenWidth * 0.03),
        decoration: BoxDecoration(
          color: const Color(0xFF072B4F).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          border: Border.all(
            color: const Color(0xFF072B4F).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: screenWidth * 0.16,
              height: usableHeight * 0.060,
              decoration: BoxDecoration(
                color: const Color(0xFF072B4F),
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.video_file_rounded,
                color: const Color(0xFFE5A023),
                size: screenWidth * 0.075,
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF166534),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Video Individual Válido',
                          style: TextStyle(
                            color: const Color(0xFF072B4F),
                            fontSize: screenWidth * 0.032,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.003),
                  Text(
                    _videoLocalName ?? 'video.mp4',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: screenWidth * 0.028,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    'Duración: $duracionStr · $sizeStr (10s - 5m)',
                    style: TextStyle(
                      fontSize: screenWidth * 0.026,
                      color: const Color(0xFF166534),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              color: Colors.grey.shade700,
              tooltip: 'Remover video',
              onPressed: () {
                setState(() {
                  _videoLocalPath = null;
                  _videoLocalName = null;
                  _videoLocalDuration = null;
                  _videoLocalSizeMB = null;
                  _videoUrlController.clear();
                });
              },
            ),
          ],
        ),
      );
    }

    if (_detectedYoutubeId == null && _detectedChannelHandle == null && _detectedChannelId == null) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: usableHeight * 0.010,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey.shade600),
            SizedBox(width: screenWidth * 0.02),
            Expanded(
              child: Text(
                'Pega el enlace de YouTube (@AtrioIglesia, live o video) para autodetectar.',
                style: TextStyle(
                  fontSize: screenWidth * 0.030,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Caso 1: Canal de YouTube detectado (@AtrioIglesia o UC...)
    if (_detectedYoutubeId == null && (_detectedChannelHandle != null || _detectedChannelId != null)) {
      final canalDisplay = _detectedChannelHandle ?? _detectedChannelId!;
      final esLiveCanal = _isChannelLive;

      return Container(
        padding: EdgeInsets.all(screenWidth * 0.03),
        decoration: BoxDecoration(
          color: const Color(0xFFC4302B).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          border: Border.all(
            color: const Color(0xFFC4302B).withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: screenWidth * 0.16,
              height: usableHeight * 0.060,
              decoration: BoxDecoration(
                color: const Color(0xFFC4302B),
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
              ),
              alignment: Alignment.center,
              child: Icon(
                esLiveCanal ? Icons.sensors_rounded : Icons.subscriptions_rounded,
                color: Colors.white,
                size: screenWidth * 0.075,
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFFC4302B),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          esLiveCanal
                              ? 'Transmisión Oficial de Canal'
                              : 'Canal de YouTube Reconocido',
                          style: TextStyle(
                            color: const Color(0xFFC4302B),
                            fontSize: screenWidth * 0.032,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.003),
                  Text(
                    'Canal: $canalDisplay',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: screenWidth * 0.028,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final thumbUrl = YoutubeHelper.buildThumbnailUrl(_detectedYoutubeId!);

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: const Color(0xFF166534).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        border: Border.all(
          color: const Color(0xFF166534).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            child: SizedBox(
              width: screenWidth * 0.22,
              height: usableHeight * 0.065,
              child: Image.network(
                thumbUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, error, stackTrace) => Container(
                  color: Colors.grey.shade300,
                  alignment: Alignment.center,
                  child: const Icon(Icons.videocam_rounded, color: Colors.grey),
                ),
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF166534),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Video de YouTube Reconocido',
                        style: TextStyle(
                          color: const Color(0xFF166534),
                          fontSize: screenWidth * 0.032,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: usableHeight * 0.003),
                Text(
                  'ID: $_detectedYoutubeId',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: screenWidth * 0.028,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(double screenWidth, double usableHeight) {
    const Color azulFondo = Color(0xFF072B4F);

    return SizedBox(
      height: usableHeight * 0.045,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categoriasDisponibles.length,
        separatorBuilder: (context, index) => SizedBox(width: screenWidth * 0.02),
        itemBuilder: (context, index) {
          final cat = _categoriasDisponibles[index];
          final isSelected = _categoria == cat;
          return ChoiceChip(
            label: Text(cat),
            selected: isSelected,
            onSelected: (val) {
              if (val) setState(() => _categoria = cat);
            },
            selectedColor: azulFondo,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : azulFondo,
              fontSize: screenWidth * 0.032,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              side: BorderSide(
                color: isSelected ? azulFondo : Colors.grey.shade300,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomBannerSection(double screenWidth, double usableHeight) {
    const Color azulFondo = Color(0xFF072B4F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(
          'Carátula Personalizada (Opcional)',
          screenWidth,
        ),
        SizedBox(height: usableHeight * 0.006),
        if (_imagenBase64 != null) ...[
          Container(
            width: screenWidth,
            height: usableHeight * 0.16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
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
            ),
          ),
        ] else ...[
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: azulFondo,
              side: BorderSide(color: Colors.grey.shade400),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
              ),
              padding: EdgeInsets.symmetric(
                vertical: usableHeight * 0.012,
                horizontal: screenWidth * 0.04,
              ),
            ),
            onPressed: () => _seleccionarBannerPersonalizado(ImageSource.gallery),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Subir banner específico desde la galería'),
          ),
        ],
      ],
    );
  }

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
}
