// Modelos de datos para el módulo administrativo de iglesia (Odoo 19 /admin/*)
// Utilizados por roles church_admin y usuarios con permisos de moderación/publicación.

/// Modelo de Aviso Congregacional Administrativo (/admin/announcements)
class AdminAnnouncementModel {
  final int id;
  final String title;
  final String content;
  final List<int> targetGroupIds;
  final List<String> targetGroupNames;
  final bool isPinned;
  final String authorName;
  final int? churchId;
  final String createDate;

  AdminAnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    this.targetGroupIds = const [],
    this.targetGroupNames = const [],
    this.isPinned = false,
    this.authorName = '',
    this.churchId,
    this.createDate = '',
  });

  factory AdminAnnouncementModel.fromJson(Map<String, dynamic> json) {
    final rawGroups =
        json['target_group_ids'] ?? json['group_ids'] ?? json['groups'] ?? [];
    final List<int> groupIds = [];
    final List<String> groupNames = [];

    if (rawGroups is List) {
      for (final g in rawGroups) {
        if (g is int) {
          groupIds.add(g);
        } else if (g is Map) {
          if (g['id'] is int) groupIds.add(g['id'] as int);
          if (g['name'] is String) groupNames.add(g['name'] as String);
        }
      }
    }

    return AdminAnnouncementModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? json['name'] as String? ?? '',
      content:
          json['content'] as String? ??
          json['message'] as String? ??
          json['description'] as String? ??
          '',
      targetGroupIds: groupIds,
      targetGroupNames: groupNames,
      isPinned: json['pinned'] as bool? ?? json['is_pinned'] as bool? ?? false,
      authorName:
          json['author_name'] as String? ?? json['created_by'] as String? ?? '',
      churchId: json['church_id'] as int?,
      createDate:
          json['sent_date'] as String? ??
          json['send_date'] as String? ??
          json['create_date'] as String? ??
          json['date'] as String? ??
          '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'target_group_ids': targetGroupIds,
    'pinned': isPinned,
    if (churchId != null) 'church_id': churchId,
  };

  /// Contenido despojado de etiquetas HTML para renderizado accesible.
  String get plainContent {
    return content
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAllMapped(RegExp(r'\s+([.,;:!?])'), (m) => m[1]!)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

/// Modelo de Grupo de Audiencia / Segmentación (/admin/groups)
class AdminGroupModel {
  final int id;
  final String name;
  final String code;
  final int memberCount;
  final String description;
  final bool isDefault;

  AdminGroupModel({
    required this.id,
    required this.name,
    this.code = '',
    this.memberCount = 0,
    this.description = '',
    this.isDefault = false,
  });

  factory AdminGroupModel.fromJson(Map<String, dynamic> json) {
    return AdminGroupModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      memberCount:
          json['member_count'] as int? ?? json['members_count'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'member_count': memberCount,
    'description': description,
  };
}

/// Modelo de Petición de Oración / Solicitud a Moderar (/admin/prayer-requests)
class AdminPrayerRequestModel {
  final int id;
  final String title;
  final String description;
  final String applicantName;
  final String applicantEmail;
  final String state; // 'pending', 'approved', 'rejected'
  final bool isAnonymous;
  final String createDate;
  final String? moderatedBy;
  final String? moderationReason;
  final String? moderationDate;

  AdminPrayerRequestModel({
    required this.id,
    required this.title,
    required this.description,
    this.applicantName = '',
    this.applicantEmail = '',
    this.state = 'pending',
    this.isAnonymous = false,
    this.createDate = '',
    this.moderatedBy,
    this.moderationReason,
    this.moderationDate,
  });

  factory AdminPrayerRequestModel.fromJson(Map<String, dynamic> json) {
    return AdminPrayerRequestModel(
      id: json['id'] as int? ?? 0,
      title:
          json['title'] as String? ??
          json['subject'] as String? ??
          json['name'] as String? ??
          '',
      description:
          json['description'] as String? ?? json['content'] as String? ?? '',
      applicantName:
          json['applicant_name'] as String? ??
          json['author_name'] as String? ??
          'Anónimo',
      applicantEmail: json['applicant_email'] as String? ?? '',
      state: (json['state'] ?? json['status'] ?? 'pending')
          .toString()
          .toLowerCase(),
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      createDate:
          json['create_date'] as String? ?? json['date'] as String? ?? '',
      moderatedBy: json['moderated_by'] as String?,
      moderationReason:
          json['moderation_reason'] as String? ?? json['reason'] as String?,
      moderationDate: json['moderation_date'] as String?,
    );
  }

  bool get isPending =>
      state == 'pending' || state == 'draft' || state == 'en_espera';
  bool get isApproved =>
      state == 'approved' || state == 'aprobada' || state == 'done';
  bool get isRejected => state == 'rejected' || state == 'rechazada';

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'state': state,
    'is_anonymous': isAnonymous,
  };
}

/// Modelo de Métricas y Analítica de Comunidad (/admin/analytics)
class AdminAnalyticsModel {
  final int totalMembers;
  final int newMembersThisMonth;
  final int activeGroupsCount;
  final int prayerRequestsCount;
  final int pendingModerationCount;
  final double totalOfferingsAmount;
  final int eventRegistrationsCount;
  final String period;
  final Map<String, dynamic> rawMetrics;

  AdminAnalyticsModel({
    this.totalMembers = 0,
    this.newMembersThisMonth = 0,
    this.activeGroupsCount = 0,
    this.prayerRequestsCount = 0,
    this.pendingModerationCount = 0,
    this.totalOfferingsAmount = 0.0,
    this.eventRegistrationsCount = 0,
    this.period = 'month',
    this.rawMetrics = const {},
  });

  factory AdminAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final metrics = (json['metrics'] is Map<String, dynamic>)
        ? json['metrics'] as Map<String, dynamic>
        : json;

    return AdminAnalyticsModel(
      totalMembers:
          metrics['total_members'] as int? ??
          metrics['members_count'] as int? ??
          0,
      newMembersThisMonth:
          metrics['new_members'] as int? ??
          metrics['new_members_month'] as int? ??
          0,
      activeGroupsCount:
          metrics['active_groups'] as int? ??
          metrics['groups_count'] as int? ??
          0,
      prayerRequestsCount:
          metrics['prayer_requests_total'] as int? ??
          metrics['requests_count'] as int? ??
          0,
      pendingModerationCount:
          metrics['pending_moderation'] as int? ??
          metrics['pending_requests'] as int? ??
          0,
      totalOfferingsAmount: (metrics['total_offerings'] is num)
          ? (metrics['total_offerings'] as num).toDouble()
          : 0.0,
      eventRegistrationsCount:
          metrics['event_registrations'] as int? ??
          metrics['registrations_count'] as int? ??
          0,
      period: json['period'] as String? ?? 'month',
      rawMetrics: metrics,
    );
  }
}

/// Información del feligrés solicitante en Odoo 19
class AdminRequesterInfo {
  final int? id;
  final String name;
  final String? email;
  final String? phone;

  const AdminRequesterInfo({
    this.id,
    required this.name,
    this.email,
    this.phone,
  });

  factory AdminRequesterInfo.fromJson(Map<String, dynamic> json) {
    return AdminRequesterInfo(
      id: json['id'] as int?,
      name: json['name'] as String? ?? 'Anónimo',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }
}

/// Modelo oficial de Solicitud Pastoral de la Iglesia en Odoo 19 (GET /admin/requests)
class AdminChurchRequestModel {
  final int id;
  final String type; // 'oracion', 'ayuda', 'consejeria', etc.
  final String title;
  final String message;
  final String state; // 'nueva', 'en_progreso', 'respondida', 'rechazada', 'cancelada'
  final String? response;
  final String? rejectionReason;
  final String createdAt;
  final String? updatedAt;
  final String requesterName;
  final AdminRequesterInfo? requester;

  const AdminChurchRequestModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.state,
    this.response,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
    required this.requesterName,
    this.requester,
  });

  factory AdminChurchRequestModel.fromJson(Map<String, dynamic> json) {
    final reqMap = json['requester'] is Map<String, dynamic>
        ? json['requester'] as Map<String, dynamic>
        : (json['requester'] is Map
              ? Map<String, dynamic>.from(json['requester'] as Map)
              : null);

    return AdminChurchRequestModel(
      id: json['id'] as int? ?? 0,
      type: (json['type'] as String? ?? 'oracion').toLowerCase(),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      state: (json['state'] as String? ?? 'nueva').toLowerCase(),
      response: json['response'] as String?,
      rejectionReason: json['rejection_reason'] as String?,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String?,
      requesterName:
          json['requester_name'] as String? ??
          (reqMap != null ? reqMap['name'] as String? ?? 'Anónimo' : 'Anónimo'),
      requester: reqMap != null ? AdminRequesterInfo.fromJson(reqMap) : null,
    );
  }

  bool get isNew => state == 'nueva' || state == 'draft' || state == 'pending';
  bool get isInProgress => state == 'en_progreso';
  bool get isAnswered =>
      state == 'respondida' || state == 'approved' || state == 'done';
  bool get isRejected => state == 'rechazada';
  bool get isCancelled => state == 'cancelada' || state == 'cancelled';

  AdminChurchRequestModel copyWith({
    String? state,
    String? response,
    String? rejectionReason,
    String? updatedAt,
  }) {
    return AdminChurchRequestModel(
      id: id,
      type: type,
      title: title,
      message: message,
      state: state ?? this.state,
      response: response ?? this.response,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      requesterName: requesterName,
      requester: requester,
    );
  }
}

/// Estadísticas y métricas consolidadas de la congregación en Odoo 19 (GET /admin/stats)
class AdminChurchStatsModel {
  final String period;
  final String since;
  final int activeMembers;
  final int pendingMembers;
  final int newMembers;
  final int publishedPosts;
  final int sentAnnouncements;
  final int heldEvents;
  final int eventRegistrations;
  final int offeringsCount;
  final double offeringsTotal;
  final String currencyCode;
  final String currencySymbol;
  final String kycStatus;

  const AdminChurchStatsModel({
    this.period = 'month',
    this.since = '',
    this.activeMembers = 0,
    this.pendingMembers = 0,
    this.newMembers = 0,
    this.publishedPosts = 0,
    this.sentAnnouncements = 0,
    this.heldEvents = 0,
    this.eventRegistrations = 0,
    this.offeringsCount = 0,
    this.offeringsTotal = 0.0,
    this.currencyCode = 'DOP',
    this.currencySymbol = 'RD\$',
    this.kycStatus = 'approved',
  });

  factory AdminChurchStatsModel.fromJson(Map<String, dynamic> json) {
    final members = json['members'] is Map ? json['members'] as Map : const {};
    final posts = json['posts'] is Map ? json['posts'] as Map : const {};
    final announcements = json['announcements'] is Map
        ? json['announcements'] as Map
        : const {};
    final events = json['events'] is Map ? json['events'] as Map : const {};
    final offerings = json['offerings'] is Map
        ? json['offerings'] as Map
        : const {};
    final currency = offerings['currency'] is Map
        ? offerings['currency'] as Map
        : const {};

    return AdminChurchStatsModel(
      period: json['period'] as String? ?? 'month',
      since: json['since'] as String? ?? '',
      activeMembers: members['active'] as int? ?? 0,
      pendingMembers: members['pending'] as int? ?? 0,
      newMembers: members['new'] as int? ?? 0,
      publishedPosts: posts['published'] as int? ?? 0,
      sentAnnouncements: announcements['sent'] as int? ?? 0,
      heldEvents: events['held'] as int? ?? 0,
      eventRegistrations: events['registrations'] as int? ?? 0,
      offeringsCount: offerings['count'] as int? ?? 0,
      offeringsTotal: (offerings['total'] is num)
          ? (offerings['total'] as num).toDouble()
          : 0.0,
      currencyCode: currency['code'] as String? ?? 'DOP',
      currencySymbol: currency['symbol'] as String? ?? 'RD\$',
      kycStatus: (json['kyc_status'] ??
              json['verification_status'] ??
              offerings['kyc_status'] ??
              'approved')
          as String,
    );
  }
}

/// Elemento de notificación del buzón administrativo en Odoo 19 (GET /admin/notifications)
class AdminNotificationItemModel {
  final int id;
  final String title;
  final String message;
  final String category;
  final String? targetPage;
  final bool isRead;
  final String createdAt;
  final String? dismissedAt;

  const AdminNotificationItemModel({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    this.targetPage,
    required this.isRead,
    required this.createdAt,
    this.dismissedAt,
  });

  factory AdminNotificationItemModel.fromJson(Map<String, dynamic> json) {
    return AdminNotificationItemModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      targetPage: json['target_page'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
      dismissedAt: json['dismissed_at'] as String?,
    );
  }
}
