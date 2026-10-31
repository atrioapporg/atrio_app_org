import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/ads_provider.dart';

/// Formulario para crear, segmentar, cotizar en vivo y enviar una campaña de publicidad a revisión.
class CreateAdCampaignScreen extends StatefulWidget {
  static const routeName = 'create_ad_campaign_screen';

  const CreateAdCampaignScreen({super.key});

  @override
  State<CreateAdCampaignScreen> createState() => _CreateAdCampaignScreenState();
}

class _CreateAdCampaignScreenState extends State<CreateAdCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  String? _imageBase64;

  String _placement = 'all';
  int _weeks = 2;
  int _targetChurches = 5;

  Timer? _quoteDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestQuote();
    });
  }

  @override
  void dispose() {
    _quoteDebounce?.cancel();
    _nameController.dispose();
    _descController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _onQuoteParamsChanged() {
    _quoteDebounce?.cancel();
    _quoteDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _requestQuote();
    });
  }

  Future<void> _requestQuote() async {
    await context.read<AdsProvider>().calculateQuote(
          targetChurchesCount: _targetChurches,
          weeks: _weeks,
          placement: _placement,
        );
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImage = picked;
          _imageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      debugPrint('[CreateAdCampaignScreen] Error seleccionando imagen: $e');
    }
  }

  Future<void> _submitForm() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    if (_imageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.seleccionarImagen ?? 'Por favor selecciona la imagen para tu campaña',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final created = await context.read<AdsProvider>().createCampaign(
          name: _nameController.text.trim(),
          imageBase64: _imageBase64!,
          description: _descController.text.trim().isNotEmpty
              ? _descController.text.trim()
              : null,
          redirectUrl: _urlController.text.trim().isNotEmpty
              ? _urlController.text.trim()
              : null,
          placement: _placement,
          weeks: _weeks,
        );

    if (!mounted) return;

    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.campanaCreadaExito ?? '¡Campaña enviada a revisión con éxito!',
          ),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.pop(context, true);
    } else {
      final errorMsg = context.read<AdsProvider>().adminError;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg ?? 'No se pudo crear la campaña'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final adsProvider = context.watch<AdsProvider>();
    final isSubmitting = adsProvider.isAdminLoading;
    final currentQuote = adsProvider.currentQuote;
    final isQuoting = adsProvider.isQuoting;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);

    return Scaffold(
      backgroundColor: blancoFondo,
      appBar: AppBar(
        title: Text(
          l10n?.nuevaCampana ?? 'Nueva Campaña',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: azulFondo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Selector de Imagen / Banner
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsetsDirectional.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.imagenCampana ?? 'Imagen o Banner de la Campaña',
                      style: const TextStyle(
                        color: azulFondo,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedImage != null)
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(_selectedImage!.path),
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.cached_rounded, size: 16),
                            label: Text(l10n?.cambiarImagen ?? 'Cambiar imagen'),
                          ),
                        ],
                      )
                    else
                      InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 140,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: amarilloOro.withValues(alpha: 0.6),
                              style: BorderStyle.solid,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: amarilloOro.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_photo_alternate_rounded,
                                    color: azulFondo,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n?.seleccionarImagen ?? 'Seleccionar imagen de la galería',
                                  style: const TextStyle(
                                    color: azulFondo,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
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

              const SizedBox(height: 16),

              // 2. Nombre de la Campaña
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n?.nombreCampana ?? 'Nombre de la Campaña',
                  hintText: l10n?.nombreCampanaHint ?? 'Ej. Conferencia de Jóvenes 2026',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              // 3. Descripción opcional
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n?.descripcionCampana ?? 'Descripción (opcional)',
                  hintText: l10n?.descripcionCampanaHint ?? 'Breve mensaje informativo',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 4. URL de Destino opcional
              TextFormField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l10n?.urlDestino ?? 'URL de Destino (opcional)',
                  hintText: l10n?.urlDestinoHint ?? 'https://mi-iglesia.org/evento',
                  prefixIcon: const Icon(Icons.link_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 5. Segmentación y Duración
              Container(
                padding: const EdgeInsetsDirectional.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ubicación / Placement
                    Text(
                      l10n?.ubicacionAnuncio ?? 'Ubicación del Anuncio',
                      style: const TextStyle(
                        color: azulFondo,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _placement,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text(l10n?.ubicacionTodas ?? 'Todas las ubicaciones'),
                        ),
                        DropdownMenuItem(
                          value: 'post',
                          child: Text(l10n?.ubicacionFeed ?? 'Feed de inicio'),
                        ),
                        DropdownMenuItem(
                          value: 'notification',
                          child: Text(l10n?.ubicacionNotificaciones ?? 'Notificaciones'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _placement = val);
                          _onQuoteParamsChanged();
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Slider: Duración en Semanas
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n?.duracionSemanas ?? 'Duración de la Campaña',
                          style: const TextStyle(
                            color: azulFondo,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n?.semanasPlural(_weeks) ?? '$_weeks semanas',
                          style: const TextStyle(
                            color: azulFondo,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _weeks.toDouble(),
                      min: 1,
                      max: 12,
                      divisions: 11,
                      activeColor: amarilloOro,
                      inactiveColor: const Color(0xFFE2E8F0),
                      onChanged: (val) {
                        setState(() => _weeks = val.toInt());
                        _onQuoteParamsChanged();
                      },
                    ),

                    const SizedBox(height: 10),

                    // Slider: Alcance de Iglesias
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n?.alcanceIglesias ?? 'Alcance de Iglesias',
                          style: const TextStyle(
                            color: azulFondo,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n?.iglesiasPlural(_targetChurches) ??
                              '$_targetChurches iglesias',
                          style: const TextStyle(
                            color: azulFondo,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _targetChurches.toDouble(),
                      min: 1,
                      max: 50,
                      divisions: 49,
                      activeColor: const Color(0xFF2563EB),
                      inactiveColor: const Color(0xFFE2E8F0),
                      onChanged: (val) {
                        setState(() => _targetChurches = val.toInt());
                        _onQuoteParamsChanged();
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 6. Tarjeta de Cotización en Tiempo Real
              Container(
                padding: const EdgeInsetsDirectional.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [azulFondo, Color(0xFF0F3E6C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: azulFondo.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n?.resumenCotizacion ?? 'Resumen de Cotización',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isQuoting)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(amarilloOro),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n?.precioBase ?? 'Precio base',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          currentQuote != null
                              ? NumberFormat.simpleCurrency(
                                  locale: locale,
                                  name: currentQuote.currency,
                                ).format(currentQuote.basePrice)
                              : '\$10.00',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${l10n?.alcanceIglesias ?? 'Alcance'}: $_targetChurches · $_weeks sem.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'x${_targetChurches * _weeks}',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n?.costoTotal ?? 'Costo Total Estimado',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          currentQuote != null
                              ? NumberFormat.simpleCurrency(
                                  locale: locale,
                                  name: currentQuote.currency,
                                ).format(currentQuote.totalPrice)
                              : NumberFormat.simpleCurrency(locale: locale).format(
                                  10.0 * _targetChurches * _weeks,
                                ),
                          style: const TextStyle(
                            color: amarilloOro,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 7. Botón Enviar a Revisión
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: amarilloOro,
                    foregroundColor: azulFondo,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: isSubmitting ? null : _submitForm,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(azulFondo),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              l10n?.enviarARevision ?? 'Enviar a Revisión',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
