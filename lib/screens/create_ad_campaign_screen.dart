import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../modelos/ad_models.dart';
import '../providers/ads_provider.dart';

/// Pantalla para crear, segmentar, cotizar en vivo y enviar una campaña publicitaria a revisión.
/// Cumple estrictamente con la especificación técnica de Odoo 19 ERP:
/// - POST /admin/ads/quote (delivery, duration_weeks, target_scope, country_ids, cities, church_ids)
/// - GET /admin/ads/targets (kind: 'country' / 'church')
/// - POST /admin/ads (name, message, image, link_url, cta_label, delivery, target_scope, date_start...)
/// - Arquitectura sin métodos helper _buildX(), soporte RTL/LTR, i18n e intl 0.20.
class CreateAdCampaignScreen extends StatefulWidget {
  static const routeName = 'create_ad_campaign_screen';

  const CreateAdCampaignScreen({super.key});

  @override
  State<CreateAdCampaignScreen> createState() => _CreateAdCampaignScreenState();
}

class _CreateAdCampaignScreenState extends State<CreateAdCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _ctaController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  String? _imageBase64;

  // Parámetros de segmentación y cotización Odoo 19
  String _delivery = 'both'; // 'both', 'post', 'notification'
  String _targetScope = 'location'; // 'location' o 'church'
  int _durationWeeks = 2;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));

  int? _selectedCountryId;
  List<AdTargetModel> _availableCountries = [];
  bool _isLoadingCountries = false;

  final List<AdTargetModel> _selectedChurches = [];

  Timer? _quoteDebounce;

  @override
  void initState() {
    super.initState();
    _ctaController.text = 'Ver más';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCountries();
      _requestQuote();
    });
  }

  @override
  void dispose() {
    _quoteDebounce?.cancel();
    _nameController.dispose();
    _messageController.dispose();
    _urlController.dispose();
    _ctaController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    setState(() => _isLoadingCountries = true);
    final countries = await context.read<AdsProvider>().searchTargets(
          kind: 'country',
        );
    if (!mounted) return;
    setState(() {
      _availableCountries = countries;
      if (countries.isNotEmpty) {
        _selectedCountryId = countries.first.id;
      }
      _isLoadingCountries = false;
    });
    _triggerQuote();
  }

  void _triggerQuote() {
    _quoteDebounce?.cancel();
    _quoteDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) _requestQuote();
    });
  }

  Future<void> _requestQuote() async {
    final countryIds =
        _targetScope == 'location' && _selectedCountryId != null
            ? [_selectedCountryId!]
            : <int>[];
    final cities = _targetScope == 'location' &&
            _cityController.text.trim().isNotEmpty
        ? [_cityController.text.trim()]
        : <String>[];
    final churchIds = _targetScope == 'church'
        ? _selectedChurches.map((c) => c.id).toList()
        : <int>[];

    await context.read<AdsProvider>().calculateQuote(
          delivery: _delivery,
          durationWeeks: _durationWeeks,
          targetScope: _targetScope,
          countryIds: countryIds,
          cities: cities,
          churchIds: churchIds,
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

  Future<void> _selectStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;
      });
      _triggerQuote();
    }
  }

  Future<void> _submitForm() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    if (_imageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.seleccionarImagen ?? 'Por favor selecciona la imagen de la campaña',
          ),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    final countryIds =
        _targetScope == 'location' && _selectedCountryId != null
            ? [_selectedCountryId!]
            : <int>[];
    final cities = _targetScope == 'location' &&
            _cityController.text.trim().isNotEmpty
        ? [_cityController.text.trim()]
        : <String>[];
    final churchIds = _targetScope == 'church'
        ? _selectedChurches.map((c) => c.id).toList()
        : <int>[];

    final created = await context.read<AdsProvider>().createCampaign(
          name: _nameController.text.trim(),
          imageBase64: _imageBase64!,
          message: _messageController.text.trim().isNotEmpty
              ? _messageController.text.trim()
              : null,
          linkUrl: _urlController.text.trim().isNotEmpty
              ? _urlController.text.trim()
              : null,
          ctaLabel: _ctaController.text.trim().isNotEmpty
              ? _ctaController.text.trim()
              : null,
          delivery: _delivery,
          targetScope: _targetScope,
          countryIds: countryIds,
          cities: cities,
          churchIds: churchIds,
          durationWeeks: _durationWeeks,
          dateStart: _startDate,
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
    final adsProvider = context.watch<AdsProvider>();
    final isSubmitting = adsProvider.isAdminLoading;
    final currentQuote = adsProvider.currentQuote;
    final isQuoting = adsProvider.isQuoting;

    const Color azulFondo = Color(0xFF072B4F);
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
        padding: const EdgeInsetsDirectional.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Selector de Imagen / Banner
              _ImageSelectorCard(
                selectedImage: _selectedImage,
                onPickImage: _pickImage,
              ),
              const SizedBox(height: 16),

              // 2. Información General del Anuncio
              _GeneralInfoCard(
                nameController: _nameController,
                messageController: _messageController,
                urlController: _urlController,
                ctaController: _ctaController,
              ),
              const SizedBox(height: 16),

              // 3. Formato y Fecha de Inicio
              _DeliveryAndDateCard(
                delivery: _delivery,
                startDate: _startDate,
                onDeliveryChanged: (val) {
                  setState(() => _delivery = val);
                  _triggerQuote();
                },
                onSelectDate: _selectStartDate,
              ),
              const SizedBox(height: 16),

              // 4. Segmentación de Audiencia (Targets Odoo 19)
              _TargetingCard(
                targetScope: _targetScope,
                selectedCountryId: _selectedCountryId,
                availableCountries: _availableCountries,
                isLoadingCountries: _isLoadingCountries,
                cityController: _cityController,
                selectedChurches: _selectedChurches,
                onScopeChanged: (val) {
                  setState(() => _targetScope = val);
                  _triggerQuote();
                },
                onCountryChanged: (val) {
                  setState(() => _selectedCountryId = val);
                  _triggerQuote();
                },
                onCityChanged: (_) => _triggerQuote(),
                onAddChurch: (church) {
                  if (!_selectedChurches.any((c) => c.id == church.id)) {
                    setState(() => _selectedChurches.add(church));
                    _triggerQuote();
                  }
                },
                onRemoveChurch: (churchId) {
                  setState(() {
                    _selectedChurches.removeWhere((c) => c.id == churchId);
                  });
                  _triggerQuote();
                },
              ),
              const SizedBox(height: 16),

              // 5. Duración de la Campaña
              _DurationCard(
                durationWeeks: _durationWeeks,
                onWeeksChanged: (w) {
                  setState(() => _durationWeeks = w);
                  _triggerQuote();
                },
              ),
              const SizedBox(height: 16),

              // 6. Resumen de Cotización en Tiempo Real y Alcance
              _QuoteSummaryCard(
                quote: currentQuote,
                isQuoting: isQuoting,
              ),
              const SizedBox(height: 24),

              // 7. Botón de Envío a Revisión
              _SubmitButton(
                isSubmitting: isSubmitting,
                onSubmit: _submitForm,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SUB-WIDGETS DESACOPLADOS (STATELESSWIDGET CONSTRUCTORES CONST)
// =============================================================================

class _ImageSelectorCard extends StatelessWidget {
  final XFile? selectedImage;
  final VoidCallback onPickImage;

  const _ImageSelectorCard({
    required this.selectedImage,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color azulFondo = Color(0xFF072B4F);

    return Container(
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
          if (selectedImage != null)
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(selectedImage!.path),
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: onPickImage,
                  icon: const Icon(Icons.change_circle_rounded),
                  label: Text(l10n?.cambiarImagen ?? 'Cambiar Imagen'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: azulFondo,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
              ],
            )
          else
            GestureDetector(
              onTap: onPickImage,
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 40,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n?.seleccionarImagen ?? 'Seleccionar Imagen',
                      style: const TextStyle(
                        color: azulFondo,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JPG o PNG (Recomendado 1200x675)',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GeneralInfoCard extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController messageController;
  final TextEditingController urlController;
  final TextEditingController ctaController;

  const _GeneralInfoCard({
    required this.nameController,
    required this.messageController,
    required this.urlController,
    required this.ctaController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color azulFondo = Color(0xFF072B4F);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información General',
            style: TextStyle(
              color: azulFondo,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: '${l10n?.nombreCampana ?? 'Nombre de la Campaña'} *',
              hintText: l10n?.nombreCampanaHint ?? 'Ej. Conferencia Anual 2026',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'El nombre de la campaña es obligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: messageController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: l10n?.descripcionCampana ?? 'Mensaje / Copy',
              hintText: l10n?.descripcionCampanaHint ?? 'Texto que acompañará el anuncio',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: urlController,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: l10n?.urlDestino ?? 'URL de Destino',
              hintText: l10n?.urlDestinoHint ?? 'https://miiglesia.org/evento',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: ctaController,
            decoration: InputDecoration(
              labelText: l10n?.ctaLabel ?? 'Texto del Botón (CTA)',
              hintText: l10n?.ctaLabelHint ?? 'Ej. Ver más, Registrarme',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryAndDateCard extends StatelessWidget {
  final String delivery;
  final DateTime startDate;
  final ValueChanged<String> onDeliveryChanged;
  final VoidCallback onSelectDate;

  const _DeliveryAndDateCard({
    required this.delivery,
    required this.startDate,
    required this.onDeliveryChanged,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    const Color azulFondo = Color(0xFF072B4F);

    return Container(
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
            l10n?.formatoEntrega ?? 'Formato y Entrega',
            style: const TextStyle(
              color: azulFondo,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: delivery,
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
                value: 'both',
                child: Text(l10n?.formatoAmbos ?? 'Feed y Notificaciones'),
              ),
              DropdownMenuItem(
                value: 'post',
                child: Text(l10n?.formatoFeed ?? 'Solo Feed de inicio'),
              ),
              DropdownMenuItem(
                value: 'notification',
                child: Text(l10n?.formatoNotificaciones ?? 'Solo Notificaciones'),
              ),
            ],
            onChanged: (val) {
              if (val != null) onDeliveryChanged(val);
            },
          ),
          const SizedBox(height: 14),
          Text(
            l10n?.fechaInicio ?? 'Fecha de Inicio Deseada',
            style: const TextStyle(
              color: azulFondo,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onSelectDate,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_rounded, color: azulFondo, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat.yMMMd(locale).format(startDate),
                    style: const TextStyle(
                      color: azulFondo,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetingCard extends StatelessWidget {
  final String targetScope;
  final int? selectedCountryId;
  final List<AdTargetModel> availableCountries;
  final bool isLoadingCountries;
  final TextEditingController cityController;
  final List<AdTargetModel> selectedChurches;
  final ValueChanged<String> onScopeChanged;
  final ValueChanged<int?> onCountryChanged;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<AdTargetModel> onAddChurch;
  final ValueChanged<int> onRemoveChurch;

  const _TargetingCard({
    required this.targetScope,
    required this.selectedCountryId,
    required this.availableCountries,
    required this.isLoadingCountries,
    required this.cityController,
    required this.selectedChurches,
    required this.onScopeChanged,
    required this.onCountryChanged,
    required this.onCityChanged,
    required this.onAddChurch,
    required this.onRemoveChurch,
  });

  void _openChurchSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _SearchChurchDialog(onSelect: onAddChurch),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color azulFondo = Color(0xFF072B4F);

    return Container(
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
            l10n?.segmentacionAudiencia ?? 'Segmentación de Audiencia',
            style: const TextStyle(
              color: azulFondo,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: Text(l10n?.porUbicacion ?? 'Por Ubicación'),
                  selected: targetScope == 'location',
                  selectedColor: azulFondo,
                  labelStyle: TextStyle(
                    color: targetScope == 'location'
                        ? Colors.white
                        : Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (_) => onScopeChanged('location'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: Text(l10n?.porIglesiasEspecificas ?? 'Por Iglesia'),
                  selected: targetScope == 'church',
                  selectedColor: azulFondo,
                  labelStyle: TextStyle(
                    color: targetScope == 'church'
                        ? Colors.white
                        : Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (_) => onScopeChanged('church'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (targetScope == 'location') ...[
            if (isLoadingCountries)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (availableCountries.isNotEmpty) ...[
              DropdownButtonFormField<int>(
                value: selectedCountryId,
                decoration: InputDecoration(
                  labelText: l10n?.paisDestino ?? 'País Destino',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
                items: availableCountries
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(
                            c.hint != null ? '${c.label} (${c.hint})' : c.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: onCountryChanged,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: cityController,
                onChanged: onCityChanged,
                decoration: InputDecoration(
                  labelText: l10n?.ciudadDestino ?? 'Ciudad (opcional)',
                  hintText: l10n?.ciudadDestinoHint ?? 'Ej. Santo Domingo',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
              ),
            ] else
              Text(
                l10n?.errorCargarTargets ?? 'No se encontraron países disponibles.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
          ] else ...[
            OutlinedButton.icon(
              onPressed: () => _openChurchSearchDialog(context),
              icon: const Icon(Icons.add_location_alt_rounded),
              label: Text(l10n?.seleccionarIglesias ?? 'Agregar Iglesias'),
              style: OutlinedButton.styleFrom(
                foregroundColor: azulFondo,
                side: const BorderSide(color: azulFondo),
              ),
            ),
            if (selectedChurches.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: selectedChurches
                    .map(
                      (ch) => Chip(
                        label: Text(
                          ch.label,
                          style: const TextStyle(fontSize: 12),
                        ),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        onDeleted: () => onRemoveChurch(ch.id),
                        backgroundColor: const Color(0xFFF1F5F9),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SearchChurchDialog extends StatefulWidget {
  final ValueChanged<AdTargetModel> onSelect;

  const _SearchChurchDialog({required this.onSelect});

  @override
  State<_SearchChurchDialog> createState() => _SearchChurchDialogState();
}

class _SearchChurchDialogState extends State<_SearchChurchDialog> {
  final TextEditingController _queryController = TextEditingController();
  List<AdTargetModel> _results = [];
  bool _isSearching = false;
  Timer? _debounce;

  void _search(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isSearching = true);
      final list = await context.read<AdsProvider>().searchTargets(
            kind: 'church',
            q: query.trim(),
          );
      if (!mounted) return;
      setState(() {
        _results = list;
        _isSearching = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color azulFondo = Color(0xFF072B4F);

    return AlertDialog(
      title: const Text('Buscar Iglesias', style: TextStyle(fontSize: 16)),
      content: SizedBox(
        width: double.maxFinite,
        height: 320,
        child: Column(
          children: [
            TextField(
              controller: _queryController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Nombre de iglesia...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  : _results.isEmpty
                      ? const Center(
                          child: Text(
                            'No se encontraron iglesias',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _results.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (ctx, index) {
                            final target = _results[index];
                            return ListTile(
                              title: Text(target.label, style: const TextStyle(fontSize: 13)),
                              subtitle: target.hint != null
                                  ? Text(target.hint!, style: const TextStyle(fontSize: 11))
                                  : null,
                              trailing: const Icon(Icons.add_circle_outline_rounded, color: azulFondo),
                              onTap: () {
                                widget.onSelect(target);
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class _DurationCard extends StatelessWidget {
  final int durationWeeks;
  final ValueChanged<int> onWeeksChanged;

  const _DurationCard({
    required this.durationWeeks,
    required this.onWeeksChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color azulFondo = Color(0xFF072B4F);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.duracionSemanas ?? 'Duración de la Campaña',
                style: const TextStyle(
                  color: azulFondo,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: azulFondo.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n != null
                      ? l10n.semanasPlural(durationWeeks)
                      : '$durationWeeks semanas',
                  style: const TextStyle(
                    color: azulFondo,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Slider(
            value: durationWeeks.toDouble(),
            min: 1,
            max: 12,
            divisions: 11,
            activeColor: azulFondo,
            label: l10n != null
                ? l10n.semanasPlural(durationWeeks)
                : '$durationWeeks sem',
            onChanged: (val) => onWeeksChanged(val.round()),
          ),
        ],
      ),
    );
  }
}

class _QuoteSummaryCard extends StatelessWidget {
  final AdQuoteModel? quote;
  final bool isQuoting;

  const _QuoteSummaryCard({
    required this.quote,
    required this.isQuoting,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: amarilloOro.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.resumenCotizacion ?? 'Resumen de Cotización',
                style: const TextStyle(
                  color: azulFondo,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isQuoting)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const Divider(height: 20),
          if (quote != null) ...[
            // Desglose de Precios Odoo 19
            _PriceRow(
              label: l10n?.precioBase ?? 'Precio Base del Formato',
              value: NumberFormat.simpleCurrency(
                locale: locale,
                name: quote!.currency,
              ).format(quote!.quote.base),
            ),
            const SizedBox(height: 6),
            _PriceRow(
              label: '${l10n?.precioPorIglesia ?? 'Por Iglesia'}:',
              value: NumberFormat.simpleCurrency(
                locale: locale,
                name: quote!.currency,
              ).format(quote!.quote.perChurch),
            ),
            const SizedBox(height: 6),
            _PriceRow(
              label: '${l10n?.precioPorSemana ?? 'Por Semana'}:',
              value: NumberFormat.simpleCurrency(
                locale: locale,
                name: quote!.currency,
              ).format(quote!.quote.perWeek),
            ),
            if (quote!.minApplied) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: amarilloOro),
                  const SizedBox(width: 6),
                  Text(
                    l10n?.minimoAplicado ?? 'Tarifa mínima aplicada',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 16),
            _PriceRow(
              label: l10n?.costoTotal ?? 'Costo Total Estimado',
              value: NumberFormat.simpleCurrency(
                locale: locale,
                name: quote!.currency,
              ).format(quote!.totalPrice),
              isTotal: true,
            ),

            // Alcance Estimado Odoo 19 (reach)
            if (quote!.reach != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsetsDirectional.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.alcanceEstimado ?? 'Alcance Estimado',
                      style: const TextStyle(
                        color: azulFondo,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.church_rounded,
                            size: 15, color: azulFondo),
                        const SizedBox(width: 6),
                        Text(
                          l10n != null
                              ? l10n.iglesiasPlural(quote!.reach!.churches)
                              : '${quote!.reach!.churches} iglesias',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 14),
                        const Icon(Icons.groups_rounded,
                            size: 15, color: azulFondo),
                        const SizedBox(width: 6),
                        Text(
                          l10n != null
                              ? l10n.miembrosPlural(quote!.reach!.members)
                              : '${quote!.reach!.members} miembros',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    if (quote!.reach!.sample.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${l10n?.muestraIglesias ?? 'Muestra'}: ${quote!.reach!.sample.join(", ")}',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 11),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  l10n?.cotizando ?? 'Calculando cotización con Odoo 19...',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    const Color azulFondo = Color(0xFF072B4F);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? azulFondo : Colors.grey.shade700,
            fontSize: isTotal ? 15 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? azulFondo : Colors.grey.shade800,
            fontSize: isTotal ? 17 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _SubmitButton({
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: amarilloOro,
          foregroundColor: azulFondo,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isSubmitting
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(azulFondo),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.send_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n?.enviarARevision ?? 'Enviar a Revisión',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
