import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../atrio_api.dart';
import '../modelos/church_recommendation_model.dart';
import '../providers/ajustes_provider.dart';
import '../providers/recomendacion_iglesia_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/modal_ayuda_maps.dart';
import 'exito_recomendacion_screen.dart';

/// Pantalla interactiva «Mi iglesia no está en Atrio» (Imagen 1):
/// - Buscador con autocompletado en Google Places con debounce
/// - Google Map interactivo con marcador en la ubicación del lugar elegido
/// - Banner «¿Tu iglesia no aparece en el mapa? Solicitá ayuda»
/// - Ficha de la iglesia seleccionada con botón «Cambiar»
/// - Formulario de contacto opcional (Nombre y teléfono de pastor/líder)
/// - Botón contextual según el estado canónico de Odoo 19 (`by-place`)
class RecomendarIglesiaMapaScreen extends StatefulWidget {
  static const String routeName = 'recomendar_iglesia_mapa_screen';

  const RecomendarIglesiaMapaScreen({super.key});

  @override
  State<RecomendarIglesiaMapaScreen> createState() =>
      _RecomendarIglesiaMapaScreenState();
}

class _RecomendarIglesiaMapaScreenState
    extends State<RecomendarIglesiaMapaScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();

  GoogleMapController? _mapController;

  static const Color azulFondo = Color(0xFF072B4F);
  static const Color azulOscuro = Color(0xFF03182E);
  static const Color azulMedio = Color(0xFF0F4C81);
  static const Color amarilloClaro = Color(0xFFFEF3C7);
  static const Color grisBorde = Color(0xFFE2E8F0);
  static const Color textoOscuro = Color(0xFF0F172A);
  static const Color textoGris = Color(0xFF64748B);

  // Coordenadas canónicas de referencia por país (fase de pruebas: RD y Honduras)
  static const LatLng _coordSantoDomingo = LatLng(18.4812, -69.9158);
  static const LatLng _coordTegucigalpa = LatLng(14.0818, -87.2068);

  static LatLng _obtenerCoordenadasIniciales(BuildContext context) {
    try {
      final ajustes = context.read<AjustesProvider>();
      if (ajustes.paisRegion.toUpperCase() == 'HN') {
        return _coordTegucigalpa;
      }
      if (ajustes.paisRegion.toUpperCase() == 'DO') {
        return _coordSantoDomingo;
      }
    } catch (_) {}

    final deviceCountry =
        PlatformDispatcher.instance.locale.countryCode?.toUpperCase();
    if (deviceCountry == 'HN') {
      return _coordTegucigalpa;
    }

    return _coordSantoDomingo;
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {});
    });
    _determinarUbicacionGPS();
  }

  Future<void> _determinarUbicacionGPS() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      // 1. Detección ultrarrápida desde la última ubicación conocida del sistema operativo
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        _animarCamara(LatLng(lastPos.latitude, lastPos.longitude));
      }

      // 2. Refinamiento en tiempo real vía GPS de alta precisión
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      );

      if (mounted) {
        _animarCamara(LatLng(pos.latitude, pos.longitude));
      }
    } catch (e) {
      debugPrint('[RecomendarIglesiaMapaScreen] Error geolocalización GPS: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _animarCamara(LatLng pos) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: pos,
          zoom: 16.5,
        ),
      ),
    );
  }

  void _abrirModalAyudaMaps(BuildContext context) {
    ModalAyudaMaps.show(
      context,
      onSuccess: (ticketId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Text(
              'Solicitud #$ticketId recibida. Atrio te contactará pronto.',
            ),
          ),
        );
      },
    );
  }

  Future<void> _enviarRecomendacion(
    BuildContext context,
    RecomendacionIglesiaProvider provider,
  ) async {
    try {
      final rec = await provider.submitRecommendation(
        contactName: _contactNameController.text.trim(),
        contactPhone: _contactPhoneController.text.trim(),
      );

      // Refrescar perfil del usuario en segundo plano para sincronizar GET /me
      if (context.mounted) {
        context.read<UserProvider>().refreshUserProfile();
        Navigator.pushReplacementNamed(
          context,
          ExitoRecomendacionScreen.routeName,
          arguments: rec,
        );
      }
    } on AtrioApiException catch (e) {
      if (!context.mounted) return;
      if (e.isChurchInAtrio) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF0284C7),
            content: Text(
              'Esta iglesia ya está en Atrio. Puedes solicitar tu ingreso directo.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(e.message),
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Error al enviar recomendación. Revisa tu conexión.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final screenWidth = size.width;
    final provider = context.watch<RecomendacionIglesiaProvider>();

    final selectedLoc = provider.selectedLocation;
    final markers = <Marker>{};
    if (selectedLoc != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('selected_church_pin'),
          position: selectedLoc,
          infoWindow: InfoWindow(
            title: provider.selectedPlaceName ?? 'Iglesia elegida',
            snippet: provider.selectedPlaceAddress,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: azulOscuro,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: screenWidth > 640 ? 20 : 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // =====================================================
                        // 1. ENCABEZADO SUPERIOR: Ícono + Título + Botón Volver
                        // =====================================================
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.church_rounded,
                                color: azulMedio,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Mi iglesia no está en Atrio',
                                style: TextStyle(
                                  color: textoOscuro,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textoOscuro,
                                side: BorderSide(
                                  color: grisBorde,
                                  width: 1.2,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                size: 14,
                              ),
                              label: const Text(
                                'Volver',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // =====================================================
                        // 2. TEXTO EXPLICATIVO (PLAZO 30 DÍAS)
                        // =====================================================
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              color: textoGris,
                              fontSize: 13.5,
                              height: 1.45,
                            ),
                            children: [
                              TextSpan(
                                text: 'Buscá tu iglesia en el mapa y elegila. Atrio tiene ',
                              ),
                              TextSpan(
                                text: '30 días',
                                style: TextStyle(
                                  color: textoOscuro,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text:
                                    ' para contactarla e inscribirla; cuando se inscriba, tu pedido de ingreso ya estará enviado.',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // =====================================================
                        // 3. BARRA DE BÚSQUEDA GOOGLE PLACES
                        // =====================================================
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _searchFocusNode.hasFocus
                                  ? azulMedio
                                  : const Color(0xFFCBD5E1),
                              width: 1.4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            style: const TextStyle(
                              color: textoOscuro,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: InputBorder.none,
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: Color(0xFF64748B),
                                size: 20,
                              ),
                              hintText: 'Buscar por nombre o ciudad...',
                              hintStyle: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13.5,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.cancel_rounded,
                                        size: 18,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        provider.onSearchQueryChanged('');
                                        provider.clearSelection();
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (text) {
                              provider.onSearchQueryChanged(text);
                            },
                          ),
                        ),

                        // =====================================================
                        // 3.1 SUGERENCIAS / PREDICCIONES AUTOCOMPLETE
                        // =====================================================
                        if (provider.isSearching)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: azulMedio,
                                ),
                              ),
                            ),
                          )
                        else if (provider.predictions.isNotEmpty &&
                            _searchFocusNode.hasFocus)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            constraints: const BoxConstraints(maxHeight: 220),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: grisBorde),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: provider.predictions.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1, color: grisBorde),
                              itemBuilder: (context, index) {
                                final pred = provider.predictions[index];
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    Icons.place_outlined,
                                    color: azulMedio,
                                    size: 20,
                                  ),
                                  title: Text(
                                    pred.primaryText,
                                    style: const TextStyle(
                                      color: textoOscuro,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  subtitle: pred.secondaryText.isNotEmpty
                                      ? Text(
                                          pred.secondaryText,
                                          style: const TextStyle(
                                            color: textoGris,
                                            fontSize: 11.5,
                                          ),
                                        )
                                      : null,
                                  onTap: () async {
                                    _searchController.text = pred.primaryText;
                                    _searchFocusNode.unfocus();
                                    await provider.selectPlace(pred);
                                    if (provider.selectedLocation != null) {
                                      _animarCamara(provider.selectedLocation!);
                                    }
                                  },
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 14),

                        // =====================================================
                        // 4. MAPA DE GOOGLE
                        // =====================================================
                        Container(
                          height: 240,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFCBD5E1),
                              width: 1.2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: selectedLoc ??
                                    _obtenerCoordenadasIniciales(context),
                                zoom: selectedLoc != null ? 16.5 : 12.5,
                              ),
                              markers: markers,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              zoomControlsEnabled: true,
                              mapToolbarEnabled: false,
                              gestureRecognizers: <Factory<
                                  OneSequenceGestureRecognizer>>{
                                Factory<OneSequenceGestureRecognizer>(
                                  () => EagerGestureRecognizer(),
                                ),
                              },
                              onMapCreated: (controller) {
                                _mapController = controller;
                                if (selectedLoc != null) {
                                  _animarCamara(selectedLoc);
                                }
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // =====================================================
                        // 5. BANNER: ¿Tu iglesia no aparece en el mapa?
                        // =====================================================
                        InkWell(
                          onTap: () => _abrirModalAyudaMaps(context),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: amarilloClaro.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFFDE68A),
                                width: 1.1,
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.help_outline_rounded,
                                  color: Color(0xFFB45309),
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      style: TextStyle(
                                        color: Color(0xFF92400E),
                                        fontSize: 12.5,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '¿Tu iglesia no aparece en el mapa? ',
                                        ),
                                        TextSpan(
                                          text: 'Solicitá ayuda',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            decoration:
                                                TextDecoration.underline,
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

                        const SizedBox(height: 16),

                        // =====================================================
                        // 6. TARJETA DE IGLESIA SELECCIONADA
                        // =====================================================
                        if (provider.hasSelectedPlace) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: grisBorde,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.location_on_rounded,
                                        color: Color(0xFFEF4444),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            provider.selectedPlaceName ??
                                                'Iglesia seleccionada',
                                            style: const TextStyle(
                                              color: textoOscuro,
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            provider.selectedPlaceAddress ??
                                                'Dirección de Google Maps',
                                            style: const TextStyle(
                                              color: textoGris,
                                              fontSize: 12.5,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: textoOscuro,
                                        side: BorderSide(color: grisBorde),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () {
                                        provider.clearSelection();
                                        _searchController.clear();
                                        _searchFocusNode.requestFocus();
                                      },
                                      child: const Text(
                                        'Cambiar',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ===================================================
                          // 7. SECCIÓN DE CONTACTO OPCIONAL
                          // ===================================================
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: grisBorde),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '¿Conocés a alguien de la iglesia? (opcional)',
                                  style: TextStyle(
                                    color: textoOscuro,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Nos ayuda a contactarla más rápido: pastor, secretaría o un líder.',
                                  style: TextStyle(
                                    color: textoGris,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                LayoutBuilder(
                                  builder: (context, boxConstraints) {
                                    final isWide = boxConstraints.maxWidth > 380;
                                    final nameField = TextField(
                                      controller: _contactNameController,
                                      style: const TextStyle(fontSize: 13),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        labelText: 'Nombre de contacto',
                                        labelStyle: const TextStyle(
                                          fontSize: 12.5,
                                          color: textoGris,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide:
                                              BorderSide(color: grisBorde),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide:
                                              BorderSide(color: grisBorde),
                                        ),
                                      ),
                                    );

                                    final phoneField = TextField(
                                      controller: _contactPhoneController,
                                      keyboardType: TextInputType.phone,
                                      style: const TextStyle(fontSize: 13),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        labelText: 'Teléfono de contacto',
                                        labelStyle: const TextStyle(
                                          fontSize: 12.5,
                                          color: textoGris,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide:
                                              BorderSide(color: grisBorde),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide:
                                              BorderSide(color: grisBorde),
                                        ),
                                      ),
                                    );

                                    if (isWide) {
                                      return Row(
                                        children: [
                                          Expanded(child: nameField),
                                          const SizedBox(width: 10),
                                          Expanded(child: phoneField),
                                        ],
                                      );
                                    } else {
                                      return Column(
                                        children: [
                                          nameField,
                                          const SizedBox(height: 10),
                                          phoneField,
                                        ],
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ===================================================
                          // 8. BOTÓN DE ACCIÓN CONTEXTUAL SEGÚN ESTADO ODOO
                          // ===================================================
                          _buildBotonAccionContextual(
                            context: context,
                            provider: provider,
                          ),
                        ] else ...[
                          const SizedBox(height: 10),
                          Center(
                            child: Text(
                              'Escribe en el buscador o selecciona una iglesia para ver sus opciones.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: textoGris.withValues(alpha: 0.8),
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBotonAccionContextual({
    required BuildContext context,
    required RecomendacionIglesiaProvider provider,
  }) {
    if (provider.isValidatingPlace) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: azulMedio,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Consultando estado con Atrio...',
              style: TextStyle(
                color: textoOscuro,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final lookup = provider.placeLookupResult;
    final status = provider.currentLookupStatus;

    // Caso 1: Ya está en Atrio (activa o pendiente de activación)
    if (status == PlaceLookupStatus.inAtrio ||
        status == PlaceLookupStatus.pendingActivation) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Color(0xFF1D4ED8), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '¡Esta iglesia ya forma parte de Atrio!',
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulFondo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  final churchId = lookup?.church?['id'] as int?;
                  final churchName = (lookup?.church?['name'] as String?) ?? 'Iglesia';
                  if (churchId != null && churchId > 0) {
                    context.read<UserProvider>().solicitarMembresia(
                      churchId: churchId,
                      churchName: churchName,
                    );
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Solicitud de membresía enviada a la iglesia.',
                      ),
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text(
                  'Solicitar ingreso a esta congregación',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Caso 2: Atrio ya la contactó y declinó
    if (status == PlaceLookupStatus.declined) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: Color(0xFFDC2626), size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Atrio ya contactó a esta iglesia y por ahora no se sumará a la plataforma.',
                style: TextStyle(
                  color: Color(0xFF991B1B),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Caso 3: No disponible en Atrio
    if (status == PlaceLookupStatus.unavailable) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: grisBorde),
        ),
        child: const Text(
          'Esta iglesia no se encuentra disponible para recomendación en Atrio.',
          textAlign: TextAlign.center,
          style: TextStyle(color: textoGris, fontSize: 12.5),
        ),
      );
    }

    // Caso 4: Ya recomendada
    if (status == PlaceLookupStatus.recommended) {
      final rec = lookup?.recommendation;
      final bool byMe = rec?.recommendedByMe == true;
      final daysLeft = rec?.daysLeft ?? 30;

      if (byMe) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: amarilloClaro.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_rounded,
                  color: Color(0xFFB45309), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ya recomendaste esta iglesia. Atrio tiene $daysLeft días para sumarla.',
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        // Alguien más la recomendó -> Sumarme a la recomendación
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: provider.isSubmitting
                ? null
                : () => _enviarRecomendacion(context, provider),
            child: provider.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_add_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Sumarme a la recomendación',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      }
    }

    // Caso 5 por defecto: not_found -> Recomendar mi iglesia
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: azulFondo,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: provider.isSubmitting
            ? null
            : () => _enviarRecomendacion(context, provider),
        child: provider.isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Recomendar mi iglesia',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
      ),
    );
  }
}
