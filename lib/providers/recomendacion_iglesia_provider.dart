import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart'
    as places_sdk;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import '../atrio_api.dart';
import '../data/app_config.dart';
import '../modelos/church_recommendation_model.dart';

/// Provider central para la gestión del flujo «Mi iglesia no está en Atrio»:
/// - Búsqueda predictiva con Places API (debounce de 350 ms y session tokens automáticos)
/// - Geocodificación y renderizado de marcador reactivo en Google Maps
/// - Consulta de máquina de estados en Odoo 19 (`GET /churches/by-place`)
/// - Mutación de recomendación y vinculación de pedido de ingreso (`POST /churches/recommend`)
/// - Solicitud de asistencia para iglesias no publicadas en Maps (`POST /churches/maps-help`)
/// - Consulta histórica de recomendaciones del usuario (`GET /me/church-recommendations`)
class RecomendacionIglesiaProvider extends ChangeNotifier {
  final AtrioApi api;
  AtrioApi get _api => api;
  places_sdk.FlutterGooglePlacesSdk? placesClient;
  places_sdk.FlutterGooglePlacesSdk? get _placesClient => placesClient;
  set _placesClient(places_sdk.FlutterGooglePlacesSdk? val) => placesClient = val;
  Timer? _debounceTimer;

  // ===========================================================================
  // ESTADOS DE BÚSQUEDA Y PREDICCIONES (GOOGLE PLACES)
  // ===========================================================================
  String _searchQuery = '';
  List<places_sdk.AutocompletePrediction> _predictions = [];
  bool _isSearching = false;

  // ===========================================================================
  // ESTADOS DEL LUGAR SELECCIONADO Y MAPA
  // ===========================================================================
  String? _selectedPlaceId;
  String? _selectedPlaceName;
  String? _selectedPlaceAddress;
  gmaps.LatLng? _selectedLocation;

  // ===========================================================================
  // ESTADOS DE VALIDACIÓN EN ODOO 19 (`by-place`)
  // ===========================================================================
  bool _isValidatingPlace = false;
  PlaceLookupResult? _placeLookupResult;

  // ===========================================================================
  // ESTADOS DE ENVÍO DE RECOMENDACIÓN (`recommend`)
  // ===========================================================================
  bool _isSubmitting = false;
  ChurchRecommendationModel? _lastRecommendation;

  // ===========================================================================
  // ESTADOS DE ASISTENCIA MAPS (`maps-help`)
  // ===========================================================================
  bool _isSubmittingHelp = false;
  bool _mapsHelpSubmitted = false;
  int? _lastHelpTicketId;

  // ===========================================================================
  // ESTADOS HISTÓRICOS Y DE ERROR
  // ===========================================================================
  List<ChurchRecommendationModel> _myRecommendations = [];
  bool _isLoadingHistory = false;
  String? _errorMessage;
  String? _errorCode;

  RecomendacionIglesiaProvider({
    required this.api,
    this.placesClient,
  }) {
    _initPlacesClient();
  }

  void _initPlacesClient() {
    if (_placesClient == null) {
      final apiKey = AppConfig.googleMapsApiKey;
      if (apiKey.isNotEmpty) {
        _placesClient = places_sdk.FlutterGooglePlacesSdk(
          apiKey,
          locale: const Locale('es'),
        );
      }
    }
  }

  // ===========================================================================
  // GETTERS PÚBLICOS
  // ===========================================================================
  String get searchQuery => _searchQuery;
  List<places_sdk.AutocompletePrediction> get predictions => _predictions;
  bool get isSearching => _isSearching;

  String? get selectedPlaceId => _selectedPlaceId;
  String? get selectedPlaceName => _selectedPlaceName;
  String? get selectedPlaceAddress => _selectedPlaceAddress;
  gmaps.LatLng? get selectedLocation => _selectedLocation;
  bool get hasSelectedPlace =>
      _selectedPlaceId != null && _selectedPlaceId!.isNotEmpty;

  bool get isValidatingPlace => _isValidatingPlace;
  PlaceLookupResult? get placeLookupResult => _placeLookupResult;
  PlaceLookupStatus get currentLookupStatus =>
      _placeLookupResult?.status ?? PlaceLookupStatus.unknown;

  bool get isSubmitting => _isSubmitting;
  ChurchRecommendationModel? get lastRecommendation => _lastRecommendation;

  bool get isSubmittingHelp => _isSubmittingHelp;
  bool get mapsHelpSubmitted => _mapsHelpSubmitted;
  int? get lastHelpTicketId => _lastHelpTicketId;

  List<ChurchRecommendationModel> get myRecommendations => _myRecommendations;
  bool get isLoadingHistory => _isLoadingHistory;

  String? get errorMessage => _errorMessage;
  String? get errorCode => _errorCode;

  // ===========================================================================
  // 1. GESTIÓN DE BÚSQUEDA Y DEBOUNCE (PLACES API)
  // ===========================================================================

  /// Invocado en cada cambio del campo de texto de búsqueda.
  /// Aplica un debounce de 350 ms y consulta predicciones tipo ESTABLISHMENT en español.
  void onSearchQueryChanged(String query) {
    _searchQuery = query;
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      _predictions = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      await _executePlacesSearch(query.trim());
    });
  }

  Future<void> _executePlacesSearch(String text) async {
    if (_placesClient == null) {
      _initPlacesClient();
      if (_placesClient == null) {
        _errorMessage = 'Clave de Google Maps no configurada en la aplicación.';
        notifyListeners();
        return;
      }
    }

    _isSearching = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _placesClient!.findAutocompletePredictions(
        text,
        placeTypesFilter: const [places_sdk.PlaceTypeFilter.ESTABLISHMENT],
      );

      _predictions = response.predictions;
    } catch (e) {
      debugPrint('⚠️ [RecomendacionIglesiaProvider] Error en Places Autocomplete: $e');
      _predictions = [];
      _errorMessage = 'No se pudieron cargar sugerencias de lugares.';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // 2. SELECCIÓN DE LUGAR Y EVALUACIÓN CON ODOO (`by-place`)
  // ===========================================================================

  /// Invocado cuando el usuario toca una de las predicciones de Google Places.
  /// Obtiene los detalles geográficos (coordenadas para el mapa) y consulta
  /// el estado canónico del lugar en Odoo 19 mediante `GET /churches/by-place`.
  Future<void> selectPlace(places_sdk.AutocompletePrediction prediction) async {
    _selectedPlaceId = prediction.placeId;
    _selectedPlaceName = prediction.primaryText;
    _selectedPlaceAddress = prediction.secondaryText.isNotEmpty
        ? prediction.secondaryText
        : prediction.fullText;
    _predictions = [];
    _isValidatingPlace = true;
    _errorMessage = null;
    _errorCode = null;
    _placeLookupResult = null;
    notifyListeners();

    try {
      // 1. Obtener coordenadas del lugar para centrar el mapa y ubicar el pin
      if (_placesClient != null) {
        try {
          final placeDetails = await _placesClient!.fetchPlace(
            prediction.placeId,
            fields: const [
              places_sdk.PlaceField.Location,
              places_sdk.PlaceField.Address,
              places_sdk.PlaceField.Name,
            ],
          );

          final loc = placeDetails.place?.latLng;
          if (loc != null) {
            _selectedLocation = gmaps.LatLng(loc.lat, loc.lng);
          }
          if (placeDetails.place?.name != null &&
              placeDetails.place!.name!.isNotEmpty) {
            _selectedPlaceName = placeDetails.place!.name;
          }
          if (placeDetails.place?.address != null &&
              placeDetails.place!.address!.isNotEmpty) {
            _selectedPlaceAddress = placeDetails.place!.address;
          }
        } catch (placeErr) {
          debugPrint(
            'ℹ️ [RecomendacionIglesiaProvider] fetchPlace omitido o falló: $placeErr',
          );
        }
      }

      // 2. Consultar el estado canónico en Odoo 19 (Zero Payload Geo)
      final result = await _api.getChurchByPlace(prediction.placeId);
      _placeLookupResult = result;
    } on AtrioApiException catch (apiErr) {
      debugPrint('❌ [RecomendacionIglesiaProvider] Error en by-place: $apiErr');
      _errorMessage = apiErr.message;
      _errorCode = apiErr.code;
    } catch (e) {
      debugPrint('💥 [RecomendacionIglesiaProvider] Error inesperado en selección: $e');
      _errorMessage = 'No se pudo verificar el estado de la iglesia seleccionada.';
    } finally {
      _isValidatingPlace = false;
      notifyListeners();
    }
  }

  /// Limpia la selección actual para permitir buscar una nueva iglesia
  void clearSelection() {
    _selectedPlaceId = null;
    _selectedPlaceName = null;
    _selectedPlaceAddress = null;
    _selectedLocation = null;
    _placeLookupResult = null;
    _errorMessage = null;
    _errorCode = null;
    _predictions = [];
    notifyListeners();
  }

  // ===========================================================================
  // 3. ENVÍO DE RECOMENDACIÓN (`POST /churches/recommend`)
  // ===========================================================================

  /// Envía la recomendación de la iglesia a Odoo 19 con el `place_id` y datos opcionales de contacto.
  Future<ChurchRecommendationModel> submitRecommendation({
    String? contactName,
    String? contactPhone,
  }) async {
    if (_selectedPlaceId == null || _selectedPlaceId!.isEmpty) {
      throw AtrioApiException(
        400,
        'missing_fields',
        'Debes seleccionar una iglesia en el mapa antes de continuar.',
      );
    }

    _isSubmitting = true;
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();

    try {
      final response = await _api.recommendChurch(
        placeId: _selectedPlaceId!,
        contactName: contactName,
        contactPhone: contactPhone,
      );

      final recMap = response['recommendation'] as Map<String, dynamic>? ?? {};
      final recommendation = ChurchRecommendationModel.fromJson(recMap);
      _lastRecommendation = recommendation;

      // Actualizar el resultado de validación local para reflejar el nuevo estado
      _placeLookupResult = PlaceLookupResult(
        status: PlaceLookupStatus.recommended,
        rawStatus: 'recommended',
        recommendation: recommendation.copyWith(recommendedByMe: true),
      );

      return recommendation;
    } on AtrioApiException catch (e) {
      _errorMessage = e.message;
      _errorCode = e.code;
      rethrow;
    } catch (e) {
      _errorMessage = 'No se pudo registrar la recomendación. Intenta de nuevo.';
      throw AtrioApiException(500, 'client_error', _errorMessage!);
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // 4. SOLICITUD DE ASISTENCIA MAPS (`POST /churches/maps-help`)
  // ===========================================================================

  /// Envía una solicitud de soporte para iglesias ausentes en Google Maps.
  Future<bool> submitMapsHelp({
    required String name,
    String? city,
    int? countryId,
    String? contactName,
    String? contactPhone,
    String? message,
  }) async {
    _isSubmittingHelp = true;
    _errorMessage = null;
    _errorCode = null;
    _mapsHelpSubmitted = false;
    notifyListeners();

    try {
      final response = await _api.submitMapsHelp(
        name: name,
        city: city,
        countryId: countryId,
        contactName: contactName,
        contactPhone: contactPhone,
        message: message,
      );

      _mapsHelpSubmitted = response['success'] == true;
      _lastHelpTicketId = response['id'] as int?;
      return true;
    } on AtrioApiException catch (e) {
      _errorMessage = e.message;
      _errorCode = e.code;
      return false;
    } catch (e) {
      _errorMessage = 'Error al enviar la solicitud de ayuda con Maps.';
      return false;
    } finally {
      _isSubmittingHelp = false;
      notifyListeners();
    }
  }

  void resetMapsHelpStatus() {
    _mapsHelpSubmitted = false;
    _lastHelpTicketId = null;
    _isSubmittingHelp = false;
    notifyListeners();
  }

  // ===========================================================================
  // 5. CONSULTA DE MIS RECOMENDACIONES (`GET /me/church-recommendations`)
  // ===========================================================================

  /// Carga la lista histórica de recomendaciones del usuario autenticado.
  Future<void> fetchMyRecommendations() async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      final list = await _api.getMyChurchRecommendations();
      _myRecommendations = list;
    } catch (e) {
      debugPrint(
        '⚠️ [RecomendacionIglesiaProvider] Error al obtener recomendaciones: $e',
      );
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  @visibleForTesting
  void setCustomSelectionForTesting({
    required String placeId,
    required String placeName,
    String? placeAddress,
    gmaps.LatLng? location,
  }) {
    _selectedPlaceId = placeId;
    _selectedPlaceName = placeName;
    _selectedPlaceAddress = placeAddress;
    _selectedLocation = location;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
