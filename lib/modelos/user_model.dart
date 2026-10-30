import 'auth_permissions.dart';
import 'church_recommendation_model.dart';

export 'app_stage.dart';
export 'auth_permissions.dart';
export 'church_recommendation_model.dart';

class UserModel {
  final int id;
  final String nombre;
  final String email;
  final String? telefono;
  final String iglesiaActual;
  final int? iglesiaId;
  final String fechaRegistro;
  final String avatarIniciales;
  final bool esMiembroVerificado;
  final UserRole role;
  final Set<String> permissions;
  final bool isReadOnly;

  /// Estado de membresía en Odoo 19: 'none', 'membership_pending', 'change_pending', etc.
  final String membershipStatus;

  /// ID de la congregación a la que se solicitó ingreso (cuando membershipStatus == 'membership_pending').
  final int? requestedChurchId;

  /// Datos informativos de la congregación solicitada (nombre, logo, etc.).
  final Map<String, dynamic>? requestedChurchData;

  /// Indica si la iglesia a la que pertenece el usuario cuenta con una suscripción/plan activo en ATRIO.
  final bool hasActiveSubscription;

  /// Información de la iglesia recomendada por el usuario en proceso de incorporación (Odoo 19).
  final ChurchRecommendationModel? churchRecommendation;

  // Objeto anidado de estadísticas
  final UserStats estadisticas;

  UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    this.telefono,
    required this.iglesiaActual,
    this.iglesiaId,
    required this.fechaRegistro,
    required this.avatarIniciales,
    required this.esMiembroVerificado,
    this.role = UserRole.user,
    this.permissions = const {},
    this.isReadOnly = false,
    this.membershipStatus = 'none',
    this.requestedChurchId,
    this.requestedChurchData,
    this.hasActiveSubscription = false,
    this.churchRecommendation,
    this.estadisticas = const UserStats(),
  });

  /// Verifica si el usuario cuenta con un permiso específico en su arreglo activo.
  bool hasPermission(String permission) => permissions.contains(permission);

  /// Indica si el usuario es administrador de su congregación local.
  bool get isChurchAdmin => role == UserRole.churchAdmin;

  /// Indica si el usuario es superadministrador global de la plataforma ATRIO.
  bool get isPlatformAdmin => role == UserRole.platformAdmin;

  /// Indica si el usuario cuenta con estatus de miembro regular o líder.
  bool get isMember => role == UserRole.member || role == UserRole.churchAdmin;

  /// Indica si la solicitud de membresía está pendiente de aprobación por el pastor o admin.
  bool get isMembershipPending =>
      membershipStatus == 'membership_pending' ||
      membershipStatus == 'pending' ||
      membershipStatus == 'waiting' ||
      membershipStatus == 'in_review';

  /// Indica si el usuario tiene una solicitud de cambio de congregación en curso.
  bool get isChangePending => membershipStatus == 'change_pending';

  /// Indica si el usuario tiene una recomendación de iglesia en curso activa en Atrio.
  bool get hasActiveRecommendation =>
      churchRecommendation != null &&
      churchRecommendation!.status == ChurchRecommendationStatus.recommended;

  /// Indica si el usuario puede realizar operaciones de escritura según rol y bandera read_only.
  bool get canWrite =>
      !isReadOnly && (role == UserRole.churchAdmin || role == UserRole.member);

  /// Valida si el nombre de una iglesia corresponde a una iglesia genérica,
  /// de demostración o no asignada (ej. 'Atrio Demo', 'Iglesia Atrio',
  /// 'Sin iglesia seleccionada', o variaciones de demostración).
  static bool isDefaultOrDemoChurchName(String? name) {
    if (name == null) return true;
    final trimmed = name.trim().toLowerCase();
    if (trimmed.isEmpty) return true;
    if (trimmed == 'sin iglesia seleccionada') return true;
    if (trimmed == 'iglesia atrio') return true;
    if (trimmed == 'iglesia asignada') return true;
    if (trimmed == 'atrio demo') return true;
    if (trimmed.contains('atrio demo')) return true;
    return false;
  }

  /// Indica si el usuario cuenta con una congregación asignada válida.
  /// No se considera asignada si el nombre es de demostración / por defecto
  /// o si el usuario nuevo (rol user) no cuenta con membresía aprobada.
  bool get hasChurchAssigned {
    if (iglesiaId == null || iglesiaId! <= 0) return false;
    if (isDefaultOrDemoChurchName(iglesiaActual)) return false;
    if (role == UserRole.user &&
        (membershipStatus == 'none' ||
            membershipStatus.isEmpty ||
            membershipStatus == 'draft')) {
      return false;
    }
    return true;
  }

  /// Estatus canónico de la congregación/membresía del usuario según Odoo.
  /// Ejemplos: 'membership_pending', 'approved', 'none', 'change_pending'.
  String get churchStatus => membershipStatus;

  /// Indica si la congregación del usuario está plenamente asignada y aprobada por el backend.
  /// No se considera aprobada si la membresía está pendiente ('membership_pending') o no tiene iglesia asignada.
  bool get isChurchApproved =>
      hasChurchAssigned &&
      (isMember || membershipStatus == 'approved') &&
      !isMembershipPending &&
      membershipStatus != 'membership_pending' &&
      membershipStatus != 'pending';

  /// Indica si el usuario ya cuenta con una congregación seleccionada o vinculada
  /// en su perfil (asignada formalmente, solicitada/pendiente de aprobación, o guardada en perfil),
  /// independientemente del estatus de aprobación en backend ('pending', 'approved', etc.).
  bool get hasSelectedOrLinkedChurch {
    if (hasChurchAssigned) return true;
    if (requestedChurchId != null &&
        requestedChurchId! > 0 &&
        (isMembershipPending || isChangePending)) {
      return true;
    }
    if (requestedChurchData != null &&
        requestedChurchData!.isNotEmpty &&
        (isMembershipPending || isChangePending)) {
      return true;
    }
    if (isMembershipPending || isChangePending) return true;
    if (membershipStatus.isNotEmpty &&
        membershipStatus != 'none' &&
        membershipStatus != 'draft') {
      return true;
    }
    final nombre = iglesiaActual.trim();
    if (nombre.isNotEmpty && !isDefaultOrDemoChurchName(nombre)) {
      return true;
    }
    return false;
  }

  /// Referencia a la congregación seleccionada o vinculada por el usuario.
  /// Retorna null si el usuario no tiene ninguna congregación seleccionada o vinculada (nuevo registro).
  String? get selectedChurch {
    if (!hasSelectedOrLinkedChurch) return null;
    final nombre = iglesiaActual.trim();
    if (nombre.isNotEmpty && !isDefaultOrDemoChurchName(nombre)) {
      return nombre;
    }
    if (iglesiaId != null &&
        iglesiaId! > 0 &&
        !isDefaultOrDemoChurchName(iglesiaActual)) {
      return 'Iglesia #$iglesiaId';
    }
    return null;
  }

  UserModel copyWith({
    int? id,
    String? nombre,
    String? email,
    String? telefono,
    String? iglesiaActual,
    int? iglesiaId,
    String? fechaRegistro,
    String? avatarIniciales,
    bool? esMiembroVerificado,
    UserRole? role,
    Set<String>? permissions,
    bool? isReadOnly,
    String? membershipStatus,
    int? requestedChurchId,
    Map<String, dynamic>? requestedChurchData,
    bool? hasActiveSubscription,
    ChurchRecommendationModel? churchRecommendation,
    UserStats? estadisticas,
  }) {
    return UserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      iglesiaActual: iglesiaActual ?? this.iglesiaActual,
      iglesiaId: iglesiaId ?? this.iglesiaId,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      avatarIniciales: avatarIniciales ?? this.avatarIniciales,
      esMiembroVerificado: esMiembroVerificado ?? this.esMiembroVerificado,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      requestedChurchId: requestedChurchId ?? this.requestedChurchId,
      requestedChurchData: requestedChurchData ?? this.requestedChurchData,
      hasActiveSubscription:
          hasActiveSubscription ?? this.hasActiveSubscription,
      churchRecommendation: churchRecommendation ?? this.churchRecommendation,
      estadisticas: estadisticas ?? this.estadisticas,
    );
  }

  // Constructor factory para convertir el Map (JSON) a nuestro objeto Dart
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawRole = json['role'] as String?;
    final rawPerms = json['permissions'] as List<dynamic>?;
    final permsSet = rawPerms?.map((e) => e.toString()).toSet() ?? const {};

    return UserModel(
      id: json['id'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? 'Usuario',
      email: json['email'] as String? ?? '',
      iglesiaActual:
          json['iglesia_actual'] as String? ?? 'Sin iglesia seleccionada',
      iglesiaId: json['iglesia_id'] as int?,
      fechaRegistro: json['fecha_registro'] as String? ?? '',
      avatarIniciales: json['avatar_iniciales'] as String? ?? 'U',
      esMiembroVerificado: json['es_miembro_verificado'] as bool? ?? false,
      role: UserRole.fromString(rawRole),
      permissions: permsSet,
      isReadOnly: (json['is_read_only'] ?? json['read_only']) as bool? ?? false,
      membershipStatus:
          (json['membership_status'] ?? json['membershipStatus']) as String? ??
          'none',
      requestedChurchId:
          json['requested_church_id'] as int? ??
          json['requestedChurchId'] as int?,
      requestedChurchData:
          json['requested_church_data'] as Map<String, dynamic>?,
      hasActiveSubscription:
          (json['has_active_subscription'] ?? json['hasActiveSubscription'])
              as bool? ??
          false,
      churchRecommendation:
          json['church_recommendation'] is Map<String, dynamic>
          ? ChurchRecommendationModel.fromJson(
              json['church_recommendation'] as Map<String, dynamic>,
            )
          : null,
      estadisticas: json['estadisticas'] is Map<String, dynamic>
          ? UserStats.fromJson(json['estadisticas'] as Map<String, dynamic>)
          : const UserStats(
              solicitudesActivas: 0,
              donacionesMes: 0,
              notasBiblia: 0,
            ),
    );
  }

  /// Constructor factory adaptado a la respuesta de Odoo 19 (login y endpoint /me).
  factory UserModel.fromOdooJson(Map<String, dynamic> odooData) {
    final user = (odooData['user'] as Map<String, dynamic>?) ?? {};
    final member = (odooData['member'] as Map<String, dynamic>?) ?? {};
    final church = (odooData['church'] as Map<String, dynamic>?) ?? {};

    final id = (user['id'] ?? member['id'] ?? odooData['id'] ?? 0) as int;
    final nombre =
        (user['name'] ?? member['name'] ?? odooData['name'] ?? 'Usuario')
            as String;
    final email =
        (user['email'] ??
                user['login'] ??
                member['email'] ??
                odooData['email'] ??
                '')
            as String;
    final telefono =
        (member['phone'] ?? user['phone'] ?? odooData['phone']) as String?;

    // Extracción tolerante y tipada para Odoo 19 (enteros, listas [id, name], strings)
    int? parseId(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is List && val.isNotEmpty && val[0] is int) return val[0] as int;
      if (val is String) return int.tryParse(val);
      return null;
    }

    String? parseName(dynamic val) {
      if (val == null) return null;
      if (val is String && val.trim().isNotEmpty) return val.trim();
      if (val is List &&
          val.length > 1 &&
          val[1] is String &&
          (val[1] as String).trim().isNotEmpty) {
        return (val[1] as String).trim();
      }
      return null;
    }

    // Parseo de Rol
    final rawRole =
        (odooData['role'] ?? user['role'] ?? member['role'] ?? 'user')
            as String?;
    final role = UserRole.fromString(rawRole);

    final int? rawIglesiaId =
        parseId(church['id']) ??
        parseId(user['church_id']) ??
        parseId(user['iglesia_id']) ??
        parseId(member['church_id']) ??
        parseId(member['iglesia_id']) ??
        parseId(odooData['church_id']) ??
        parseId(odooData['iglesia_id']);

    // Extracción de membresía y suscripción de Odoo 19
    final String membershipStatus =
        (odooData['membership_status'] ??
                odooData['church_status'] ??
                member['membership_status'] ??
                member['church_status'] ??
                member['status'] ??
                member['state'] ??
                user['membership_status'] ??
                user['church_status'] ??
                user['status'] ??
                'none')
            as String;

    final int? requestedChurchId =
        parseId(odooData['requested_church_id']) ??
        parseId(user['requested_church_id']) ??
        parseId(member['requested_church_id']);

    final Map<String, dynamic>? requestedChurchData =
        (odooData['requested_church'] as Map<String, dynamic>?) ??
        (church.isNotEmpty &&
                (membershipStatus == 'membership_pending' ||
                    membershipStatus == 'pending')
            ? church
            : null);

    final String? nombreIglesiaExtraido =
        parseName(church['name']) ??
        parseName(church['public_name']) ??
        parseName(odooData['church_name']) ??
        parseName(user['church_name']) ??
        parseName(member['church_name']) ??
        parseName(odooData['iglesia_actual']) ??
        parseName(user['iglesia_actual']) ??
        parseName(odooData['iglesia_nombre']) ??
        parseName(user['iglesia_nombre']) ??
        parseName(member['iglesia_nombre']) ??
        parseName(church['display_name']) ??
        parseName(requestedChurchData?['name']) ??
        parseName(requestedChurchData?['public_name']) ??
        parseName(odooData['requested_church_name']) ??
        parseName(user['requested_church_name']) ??
        parseName(user['church_id']) ??
        parseName(member['church_id']) ??
        parseName(odooData['church_id']);

    final bool esDemo = isDefaultOrDemoChurchName(nombreIglesiaExtraido);
    final bool esUsuarioSinAprobacion =
        (membershipStatus == 'none' ||
            membershipStatus.isEmpty ||
            membershipStatus == 'draft') &&
        (role == UserRole.user);

    final int? iglesiaId =
        (esDemo && esUsuarioSinAprobacion) ? null : rawIglesiaId;

    final String iglesiaActual = (!esDemo &&
            nombreIglesiaExtraido != null &&
            nombreIglesiaExtraido.isNotEmpty)
        ? nombreIglesiaExtraido
        : ((iglesiaId != null && iglesiaId > 0 && !esDemo)
              ? 'Iglesia Asignada'
              : ((requestedChurchData?['name'] != null &&
                        (requestedChurchData!['name'] as String)
                            .trim()
                            .isNotEmpty &&
                        !isDefaultOrDemoChurchName(
                            requestedChurchData['name'] as String))
                    ? (requestedChurchData['name'] as String).trim()
                    : 'Sin iglesia seleccionada'));

    final fechaRegistro =
        (user['create_date'] ?? DateTime.now().toIso8601String()) as String;

    final avatarIniciales = nombre.trim().isNotEmpty
        ? nombre
              .trim()
              .split(' ')
              .map((e) => e.isNotEmpty ? e[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : 'U';

    final rawPerms =
        (odooData['permissions'] ?? user['permissions'] ?? [])
            as List<dynamic>?;
    final permissions =
        rawPerms?.map((e) => e.toString()).toSet() ?? <String>{};

    final isReadOnly =
        (odooData['read_only'] ?? user['read_only'] ?? false) as bool;

    final isMemberVerified =
        role == UserRole.member ||
        role == UserRole.churchAdmin ||
        member.isNotEmpty;

    final bool hasActiveSubscription =
        (church['has_active_subscription'] as bool?) ??
        (odooData['has_active_subscription'] as bool?) ??
        false;

    ChurchRecommendationModel? churchRecommendation;
    final rawRec = odooData['church_recommendation'];
    if (rawRec is Map<String, dynamic>) {
      churchRecommendation = ChurchRecommendationModel.fromJson(rawRec);
    }

    final statsMap = odooData['estadisticas'] as Map<String, dynamic>? ?? {};

    return UserModel(
      id: id,
      nombre: nombre,
      email: email,
      telefono: telefono,
      iglesiaActual: iglesiaActual,
      iglesiaId: iglesiaId,
      fechaRegistro: fechaRegistro,
      avatarIniciales: avatarIniciales,
      esMiembroVerificado: isMemberVerified,
      role: role,
      permissions: permissions,
      isReadOnly: isReadOnly,
      membershipStatus: membershipStatus,
      requestedChurchId: requestedChurchId,
      requestedChurchData: requestedChurchData,
      hasActiveSubscription: hasActiveSubscription,
      churchRecommendation: churchRecommendation,
      estadisticas: UserStats.fromJson(statsMap),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'iglesia_actual': iglesiaActual,
      'iglesia_id': iglesiaId,
      'church_id': iglesiaId,
      'fecha_registro': fechaRegistro,
      'avatar_iniciales': avatarIniciales,
      'es_miembro_verificado': esMiembroVerificado,
      'role': role.toOdooString(),
      'permissions': permissions.toList(),
      'read_only': isReadOnly,
      'is_read_only': isReadOnly,
      'membership_status': membershipStatus,
      'requested_church_id': requestedChurchId,
      'requested_church_data': requestedChurchData,
      'has_active_subscription': hasActiveSubscription,
      'church_recommendation': churchRecommendation?.toJson(),
      'estadisticas': {
        'solicitudes_activas': estadisticas.solicitudesActivas,
        'donaciones_mes': estadisticas.donacionesMes,
        'notas_biblia': estadisticas.notasBiblia,
      },
    };
  }
}

// Sub-modelo para las estadísticas de actividad
class UserStats {
  final int solicitudesActivas;
  final int donacionesMes;
  final int notasBiblia;

  const UserStats({
    this.solicitudesActivas = 0,
    this.donacionesMes = 0,
    this.notasBiblia = 0,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      solicitudesActivas: json['solicitudes_activas'] as int? ?? 0,
      donacionesMes: json['donaciones_mes'] as int? ?? 0,
      notasBiblia: json['notas_biblia'] as int? ?? 0,
    );
  }
}
