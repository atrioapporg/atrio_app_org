import 'package:flutter/foundation.dart';

/// Estatus de la recomendación de una iglesia en Odoo 19.
enum ChurchRecommendationStatus {
  recommended,
  enrolled,
  expired,
  discarded,
  unknown;

  static ChurchRecommendationStatus fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'recommended':
        return ChurchRecommendationStatus.recommended;
      case 'enrolled':
        return ChurchRecommendationStatus.enrolled;
      case 'expired':
        return ChurchRecommendationStatus.expired;
      case 'discarded':
        return ChurchRecommendationStatus.discarded;
      default:
        return ChurchRecommendationStatus.unknown;
    }
  }

  String toOdooString() {
    switch (this) {
      case ChurchRecommendationStatus.recommended:
        return 'recommended';
      case ChurchRecommendationStatus.enrolled:
        return 'enrolled';
      case ChurchRecommendationStatus.expired:
        return 'expired';
      case ChurchRecommendationStatus.discarded:
        return 'discarded';
      case ChurchRecommendationStatus.unknown:
        return 'unknown';
    }
  }
}

/// Estado de resolución de un lugar obtenido desde Google Maps (`GET /churches/by-place`).
enum PlaceLookupStatus {
  notFound,
  recommended,
  inAtrio,
  pendingActivation,
  declined,
  unavailable,
  unknown;

  static PlaceLookupStatus fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'not_found':
        return PlaceLookupStatus.notFound;
      case 'recommended':
        return PlaceLookupStatus.recommended;
      case 'in_atrio':
        return PlaceLookupStatus.inAtrio;
      case 'pending_activation':
        return PlaceLookupStatus.pendingActivation;
      case 'declined':
        return PlaceLookupStatus.declined;
      case 'unavailable':
        return PlaceLookupStatus.unavailable;
      default:
        return PlaceLookupStatus.unknown;
    }
  }

  String toOdooString() {
    switch (this) {
      case PlaceLookupStatus.notFound:
        return 'not_found';
      case PlaceLookupStatus.recommended:
        return 'recommended';
      case PlaceLookupStatus.inAtrio:
        return 'in_atrio';
      case PlaceLookupStatus.pendingActivation:
        return 'pending_activation';
      case PlaceLookupStatus.declined:
        return 'declined';
      case PlaceLookupStatus.unavailable:
        return 'unavailable';
      case PlaceLookupStatus.unknown:
        return 'unknown';
    }
  }
}

/// DTO representativo del objeto `recommendation` devuelto por Odoo 19.
@immutable
class ChurchRecommendationModel {
  final int id;
  final String name;
  final String? address;
  final String? city;
  final String? country;
  final String placeId;
  final String? mapsUrl;
  final double? latitude;
  final double? longitude;
  final ChurchRecommendationStatus status;
  final String rawStatus;
  final String? recommendedOn;
  final String? deadline;
  final int? daysLeft;
  final int recommendationCount;
  final bool recommendedByMe;

  const ChurchRecommendationModel({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.country,
    required this.placeId,
    this.mapsUrl,
    this.latitude,
    this.longitude,
    required this.status,
    required this.rawStatus,
    this.recommendedOn,
    this.deadline,
    this.daysLeft,
    this.recommendationCount = 1,
    this.recommendedByMe = false,
  });

  factory ChurchRecommendationModel.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    final rawStatus = (json['status'] ?? 'recommended').toString();
    final status = ChurchRecommendationStatus.fromString(rawStatus);

    return ChurchRecommendationModel(
      id: parseInt(json['id']) ?? 0,
      name: (json['name'] ?? 'Iglesia').toString(),
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      placeId: (json['place_id'] ?? '').toString(),
      mapsUrl: json['maps_url'] as String?,
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      status: status,
      rawStatus: rawStatus,
      recommendedOn: json['recommended_on'] as String?,
      deadline: json['deadline'] as String?,
      daysLeft: parseInt(json['days_left']),
      recommendationCount: parseInt(json['recommendation_count']) ?? 1,
      recommendedByMe: json['recommended_by_me'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'city': city,
        'country': country,
        'place_id': placeId,
        'maps_url': mapsUrl,
        'latitude': latitude,
        'longitude': longitude,
        'status': rawStatus,
        'recommended_on': recommendedOn,
        'deadline': deadline,
        'days_left': daysLeft,
        'recommendation_count': recommendationCount,
        'recommended_by_me': recommendedByMe,
      };

  /// Texto sugerido por la especificación de negocio según el estatus
  String get statusMessage {
    switch (status) {
      case ChurchRecommendationStatus.recommended:
        final left = daysLeft ?? 30;
        return 'Recomendada — Atrio tiene $left ${left == 1 ? "día" : "días"} para sumarla';
      case ChurchRecommendationStatus.enrolled:
        return '¡Ya está en Atrio!';
      case ChurchRecommendationStatus.expired:
        return 'Venció el plazo. Podés recomendarla de nuevo';
      case ChurchRecommendationStatus.discarded:
        return 'Atrio la contactó y por ahora no se sumará';
      case ChurchRecommendationStatus.unknown:
        return rawStatus;
    }
  }

  bool get isRecommended => status == ChurchRecommendationStatus.recommended;
  bool get isEnrolled => status == ChurchRecommendationStatus.enrolled;
  bool get isExpired => status == ChurchRecommendationStatus.expired;
  bool get isDiscarded => status == ChurchRecommendationStatus.discarded;

  ChurchRecommendationModel copyWith({
    int? id,
    String? name,
    String? address,
    String? city,
    String? country,
    String? placeId,
    String? mapsUrl,
    double? latitude,
    double? longitude,
    ChurchRecommendationStatus? status,
    String? rawStatus,
    String? recommendedOn,
    String? deadline,
    int? daysLeft,
    int? recommendationCount,
    bool? recommendedByMe,
  }) {
    return ChurchRecommendationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      placeId: placeId ?? this.placeId,
      mapsUrl: mapsUrl ?? this.mapsUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      rawStatus: rawStatus ?? this.rawStatus,
      recommendedOn: recommendedOn ?? this.recommendedOn,
      deadline: deadline ?? this.deadline,
      daysLeft: daysLeft ?? this.daysLeft,
      recommendationCount: recommendationCount ?? this.recommendationCount,
      recommendedByMe: recommendedByMe ?? this.recommendedByMe,
    );
  }
}

/// Resultado de la verificación de un lugar por `place_id` (`GET /churches/by-place`).
@immutable
class PlaceLookupResult {
  final PlaceLookupStatus status;
  final String rawStatus;
  final Map<String, dynamic>? church;
  final ChurchRecommendationModel? recommendation;

  const PlaceLookupResult({
    required this.status,
    required this.rawStatus,
    this.church,
    this.recommendation,
  });

  factory PlaceLookupResult.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] ?? 'not_found').toString();
    final status = PlaceLookupStatus.fromString(rawStatus);

    ChurchRecommendationModel? rec;
    if (json['recommendation'] is Map<String, dynamic>) {
      rec = ChurchRecommendationModel.fromJson(
        json['recommendation'] as Map<String, dynamic>,
      );
    }

    final churchMap = json['church'] is Map<String, dynamic>
        ? json['church'] as Map<String, dynamic>
        : null;

    return PlaceLookupResult(
      status: status,
      rawStatus: rawStatus,
      church: churchMap,
      recommendation: rec,
    );
  }

  bool get isNotFound => status == PlaceLookupStatus.notFound;
  bool get isRecommended => status == PlaceLookupStatus.recommended;
  bool get isInAtrio => status == PlaceLookupStatus.inAtrio;
  bool get isPendingActivation => status == PlaceLookupStatus.pendingActivation;
  bool get isDeclined => status == PlaceLookupStatus.declined;
  bool get isUnavailable => status == PlaceLookupStatus.unavailable;

  /// Permite recomendar la iglesia desde cero
  bool get canRecommend => isNotFound;

  /// Permite sumarse a una recomendación iniciada por otra persona
  bool get canJoinRecommendation =>
      isRecommended && (recommendation?.recommendedByMe != true);

  /// El usuario actual ya la recomendó y está vigente en plazo
  bool get isAlreadyRecommendedByMe =>
      isRecommended && (recommendation?.recommendedByMe == true);

  /// La congregación ya pertenece a Atrio (ofrecer solicitar membresía directa)
  bool get canRequestMembership => isInAtrio || isPendingActivation;
}
