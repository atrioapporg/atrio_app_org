import 'package:flutter/foundation.dart';

/// Datos públicos de la iglesia obtenidos a partir del token del QR.
@immutable
class ChurchJoinPublicInfo {
  final int id;
  final String name;
  final String logoUrl;

  const ChurchJoinPublicInfo({
    required this.id,
    required this.name,
    required this.logoUrl,
  });

  factory ChurchJoinPublicInfo.fromJson(Map<String, dynamic> json) {
    return ChurchJoinPublicInfo(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      logoUrl: json['logo_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logo_url': logoUrl,
  };
}

/// Respuesta completa del endpoint de consulta pública: GET /churches/join/{token}
@immutable
class JoinChurchPreview {
  final ChurchJoinPublicInfo church;
  final bool canJoin;
  final String joinUrl;

  const JoinChurchPreview({
    required this.church,
    required this.canJoin,
    required this.joinUrl,
  });

  factory JoinChurchPreview.fromJson(Map<String, dynamic> json) {
    return JoinChurchPreview(
      church: ChurchJoinPublicInfo.fromJson(
        json['church'] as Map<String, dynamic>? ?? {},
      ),
      canJoin: json['can_join'] as bool? ?? false,
      joinUrl: json['join_url'] as String? ?? '',
    );
  }
}

/// Resultado de la radicación de membresía: POST /membership/request
@immutable
class MembershipRequestResult {
  final String status; // 'pending', 'approved', etc.
  final String? message;

  const MembershipRequestResult({
    required this.status,
    this.message,
  });

  factory MembershipRequestResult.fromJson(Map<String, dynamic> json) {
    return MembershipRequestResult(
      status: json['status'] as String? ?? 'pending',
      message: json['message'] as String?,
    );
  }
}
