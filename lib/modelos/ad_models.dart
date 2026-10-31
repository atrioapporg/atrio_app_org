import 'package:flutter/foundation.dart';

import '../data/app_config.dart';

/// Enumeración con los estados del ciclo de vida de un anuncio en Odoo 19 ERP.
enum AdStatus {
  requested('requested'),
  toPay('to_pay'),
  paymentReview('payment_review'),
  ready('ready'),
  active('active'),
  paused('paused'),
  finished('finished'),
  rejected('rejected'),
  unknown('unknown');

  final String value;
  const AdStatus(this.value);

  static AdStatus fromString(String? val) {
    if (val == null) return AdStatus.unknown;
    final normalized = val.trim().toLowerCase();
    for (final s in AdStatus.values) {
      if (s.value == normalized) return s;
    }
    return AdStatus.unknown;
  }
}

/// Modelo inmutable de anuncio publicitario (Ads) sincronizado con Odoo 19 ERP.
/// Soporta tanto el consumo público de miembros (Feed / Notificaciones) como la
/// administración de campañas de iglesias (/admin/ads).
@immutable
class AdModel {
  final int id;
  final String name;
  final String? message;
  final String? imageUrl;
  final String? linkUrl;
  final String? ctaLabel;
  final String placement;
  final String delivery;
  final AdStatus status;
  final String? statusLabel;
  final String? statusColor;
  final bool payable;
  final String? rejectionReason;
  final int? churchId;
  final String? churchName;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final int totalImpressions;
  final int totalClicks;
  final double? cost;
  final String currency;
  final int? durationWeeks;
  final String? targetScope;
  final String? clickUrl;

  const AdModel({
    required this.id,
    required this.name,
    this.message,
    this.imageUrl,
    this.linkUrl,
    this.ctaLabel,
    this.placement = 'all',
    this.delivery = 'both',
    this.status = AdStatus.requested,
    this.statusLabel,
    this.statusColor,
    this.payable = false,
    this.rejectionReason,
    this.churchId,
    this.churchName,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.totalImpressions = 0,
    this.totalClicks = 0,
    this.cost,
    this.currency = 'USD',
    this.durationWeeks,
    this.targetScope,
    this.clickUrl,
  });

  /// Getter compatible con referencias previas a descripción
  String? get description => message;

  /// Getter compatible con referencias previas a URL de redirección
  String? get redirectUrl => linkUrl;

  bool get isRequested => status == AdStatus.requested;
  bool get isToPay => status == AdStatus.toPay;
  bool get isPaymentReview => status == AdStatus.paymentReview;
  bool get isReady => status == AdStatus.ready;
  bool get isActive => status == AdStatus.active;
  bool get isPaused => status == AdStatus.paused;
  bool get isFinished => status == AdStatus.finished;
  bool get isRejected => status == AdStatus.rejected;

  /// Retorna si el anuncio puede ser pagado inmediatamente
  bool get canBePaid => isToPay && payable;

  /// Retorna si el anuncio tiene un destino web interactivo
  bool get hasInteractiveLink => linkUrl != null && linkUrl!.trim().isNotEmpty;

  /// Click-Through Rate (CTR) calculado como porcentaje (0.0 a 100.0)
  double get ctrPercentage {
    if (totalImpressions <= 0) return 0.0;
    return (totalClicks / totalImpressions) * 100.0;
  }

  factory AdModel.fromJson(Map<String, dynamic> json) {
    int parsedId = 0;
    if (json['id'] is int) {
      parsedId = json['id'] as int;
    } else if (json['id'] != null) {
      parsedId = int.tryParse(json['id'].toString()) ?? 0;
    }

    DateTime? parseUtc(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val.toUtc();
      final str = val.toString().trim();
      if (str.isEmpty) return null;
      return DateTime.tryParse(str)?.toUtc();
    }

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    String? resolveImageUrl(dynamic val) {
      if (val == null) return null;
      final str = val.toString().trim();
      if (str.isEmpty) return null;
      if (str.startsWith('http://') || str.startsWith('https://')) {
        return str;
      }
      if (str.startsWith('/')) {
        return '${AppConfig.odooBaseUrl}$str';
      }
      return '${AppConfig.odooBaseUrl}/$str';
    }

    final rawStatus = json['status']?.toString();
    final adStatus = AdStatus.fromString(rawStatus);

    final rawImage =
        json['image_url'] ??
        json['image'] ??
        json['cover_url'] ??
        json['image_1920'];

    return AdModel(
      id: parsedId,
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      message:
          json['message']?.toString() ??
          json['description']?.toString() ??
          json['subtitle']?.toString(),
      imageUrl: resolveImageUrl(rawImage),
      linkUrl:
          json['link_url']?.toString() ??
          json['redirect_url']?.toString() ??
          json['action_url']?.toString(),
      ctaLabel: json['cta_label']?.toString() ?? json['cta']?.toString(),
      placement:
          json['placement']?.toString() ??
          json['delivery']?.toString() ??
          'all',
      delivery:
          json['delivery']?.toString() ??
          json['placement']?.toString() ??
          'both',
      status: adStatus,
      statusLabel: json['status_label']?.toString(),
      statusColor: json['status_color']?.toString(),
      payable: json['payable'] == true || json['is_payable'] == true,
      rejectionReason: json['rejection_reason']?.toString(),
      churchId: json['church_id'] is int
          ? json['church_id'] as int
          : (json['church_id'] is List && (json['church_id'] as List).isNotEmpty
                ? (json['church_id'] as List).first as int?
                : int.tryParse(json['church_id']?.toString() ?? '')),
      churchName:
          json['church_name']?.toString() ??
          (json['church_id'] is List && (json['church_id'] as List).length > 1
              ? (json['church_id'] as List)[1].toString()
              : null),
      startDate: parseUtc(json['date_start'] ?? json['start_date']),
      endDate: parseUtc(json['date_end'] ?? json['end_date']),
      createdAt: parseUtc(json['create_date'] ?? json['created_at']),
      totalImpressions: parseInt(
        json['impressions'] ?? json['total_impressions'],
      ),
      totalClicks: parseInt(json['clicks'] ?? json['total_clicks']),
      cost: parseDouble(json['amount'] ?? json['cost'] ?? json['total_price']),
      currency: json['currency']?.toString() ?? 'USD',
      durationWeeks: json['duration_weeks'] is int
          ? json['duration_weeks'] as int
          : int.tryParse(json['duration_weeks']?.toString() ?? ''),
      targetScope: json['target_scope']?.toString(),
      clickUrl: json['click_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'message': message,
    'image': imageUrl,
    'image_url': imageUrl,
    'link_url': linkUrl,
    'redirect_url': linkUrl,
    'cta_label': ctaLabel,
    'placement': placement,
    'delivery': delivery,
    'status': status.value,
    'status_label': statusLabel,
    'status_color': statusColor,
    'payable': payable,
    'rejection_reason': rejectionReason,
    'church_id': churchId,
    'church_name': churchName,
    'date_start': startDate?.toIso8601String(),
    'date_end': endDate?.toIso8601String(),
    'create_date': createdAt?.toIso8601String(),
    'impressions': totalImpressions,
    'clicks': totalClicks,
    'amount': cost,
    'cost': cost,
    'currency': currency,
    'duration_weeks': durationWeeks,
    'target_scope': targetScope,
    'click_url': clickUrl,
  };

  AdModel copyWith({
    int? id,
    String? name,
    String? message,
    String? imageUrl,
    String? linkUrl,
    String? ctaLabel,
    String? placement,
    String? delivery,
    AdStatus? status,
    String? statusLabel,
    String? statusColor,
    bool? payable,
    String? rejectionReason,
    int? churchId,
    String? churchName,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    int? totalImpressions,
    int? totalClicks,
    double? cost,
    String? currency,
    int? durationWeeks,
    String? targetScope,
    String? clickUrl,
  }) {
    return AdModel(
      id: id ?? this.id,
      name: name ?? this.name,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      linkUrl: linkUrl ?? this.linkUrl,
      ctaLabel: ctaLabel ?? this.ctaLabel,
      placement: placement ?? this.placement,
      delivery: delivery ?? this.delivery,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      statusColor: statusColor ?? this.statusColor,
      payable: payable ?? this.payable,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      churchId: churchId ?? this.churchId,
      churchName: churchName ?? this.churchName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      totalImpressions: totalImpressions ?? this.totalImpressions,
      totalClicks: totalClicks ?? this.totalClicks,
      cost: cost ?? this.cost,
      currency: currency ?? this.currency,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      targetScope: targetScope ?? this.targetScope,
      clickUrl: clickUrl ?? this.clickUrl,
    );
  }
}

/// Modelo de objetivo de segmentación de audiencia (`/admin/ads/targets`).
/// Odoo 19 retorna: `{ "options": [{ "id": 61, "label": "República Dominicana", "hint": "12 iglesias", "churches": 12 }] }`
@immutable
class AdTargetModel {
  final int id;
  final String label;
  final String? hint;
  final int? churches;
  final String kind; // 'country', 'state', 'city', 'church'

  const AdTargetModel({
    required this.id,
    required this.label,
    this.hint,
    this.churches,
    this.kind = 'country',
  });

  /// Compatibilidad con código previo
  String get name => label;
  String? get location => hint;
  int? get membersCount => churches;

  factory AdTargetModel.fromJson(
    Map<String, dynamic> json, {
    String defaultKind = 'country',
  }) {
    int parsedId = 0;
    if (json['id'] is int) {
      parsedId = json['id'] as int;
    } else if (json['id'] != null) {
      parsedId = int.tryParse(json['id'].toString()) ?? 0;
    }

    int? parsedChurches;
    if (json['churches'] is int) {
      parsedChurches = json['churches'] as int;
    } else if (json['churches'] != null) {
      parsedChurches = int.tryParse(json['churches'].toString());
    } else if (json['members_count'] != null) {
      parsedChurches = int.tryParse(json['members_count'].toString());
    }

    return AdTargetModel(
      id: parsedId,
      label: json['label']?.toString() ?? json['name']?.toString() ?? '',
      hint:
          json['hint']?.toString() ??
          json['location']?.toString() ??
          json['country_name']?.toString(),
      churches: parsedChurches,
      kind: json['kind']?.toString() ?? defaultKind,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'name': label,
    'hint': hint,
    'churches': churches,
    'kind': kind,
  };
}

/// Alcance de audiencia estimado en la cotización (`/admin/ads/quote`).
/// Odoo 19: `{ "churches": 4, "members": 120, "sample": ["Iglesia Vida Nueva"] }`
@immutable
class AdReachModel {
  final int churches;
  final int members;
  final List<String> sample;

  const AdReachModel({
    required this.churches,
    required this.members,
    this.sample = const [],
  });

  factory AdReachModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val, [int defaultVal = 0]) {
      if (val == null) return defaultVal;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? defaultVal;
    }

    List<String> parseSample(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      return const [];
    }

    return AdReachModel(
      churches: parseInt(json['churches']),
      members: parseInt(json['members']),
      sample: parseSample(json['sample']),
    );
  }

  Map<String, dynamic> toJson() => {
    'churches': churches,
    'members': members,
    'sample': sample,
  };
}

/// Desglose de cotización monetaria (`/admin/ads/quote`).
/// Odoo 19: `{ "amount": 76.0, "currency": "USD", "weeks": 2, "churches": 4, "base": 30.0, "per_church": 2.0, "per_week": 38.0, "min_applied": false }`
@immutable
class AdQuoteBreakdownModel {
  final double amount;
  final String currency;
  final int weeks;
  final int churches;
  final double base;
  final double perChurch;
  final double perWeek;
  final bool minApplied;

  const AdQuoteBreakdownModel({
    required this.amount,
    this.currency = 'USD',
    required this.weeks,
    required this.churches,
    required this.base,
    required this.perChurch,
    required this.perWeek,
    this.minApplied = false,
  });

  factory AdQuoteBreakdownModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val, [double defaultVal = 0.0]) {
      if (val == null) return defaultVal;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? defaultVal;
    }

    int parseInt(dynamic val, [int defaultVal = 1]) {
      if (val == null) return defaultVal;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? defaultVal;
    }

    return AdQuoteBreakdownModel(
      amount: parseDouble(
        json['amount'] ?? json['total_price'] ?? json['total'],
      ),
      currency: json['currency']?.toString() ?? 'USD',
      weeks: parseInt(
        json['weeks'] ?? json['duration_weeks'] ?? json['weeks_count'],
      ),
      churches: parseInt(
        json['churches'] ?? json['churches_count'] ?? json['targets_count'],
      ),
      base: parseDouble(json['base'] ?? json['base_price']),
      perChurch: parseDouble(json['per_church']),
      perWeek: parseDouble(json['per_week']),
      minApplied: json['min_applied'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'currency': currency,
    'weeks': weeks,
    'churches': churches,
    'base': base,
    'per_church': perChurch,
    'per_week': perWeek,
    'min_applied': minApplied,
  };
}

/// Modelo completo de cotización de campaña publicitaria (`/admin/ads/quote`).
/// Responde: `{ "quote": { ... }, "reach": { ... } }`
@immutable
class AdQuoteModel {
  final AdQuoteBreakdownModel quote;
  final AdReachModel? reach;

  const AdQuoteModel({required this.quote, this.reach});

  /// Getters de retrocompatibilidad con código existente
  double get basePrice => quote.base;
  int get churchesCount => quote.churches;
  int get weeksCount => quote.weeks;
  double get totalPrice => quote.amount;
  String get currency => quote.currency;
  double get amount => quote.amount;
  bool get minApplied => quote.minApplied;
  Map<String, dynamic>? get details => reach?.toJson();

  factory AdQuoteModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> quoteMap =
        json.containsKey('quote') && json['quote'] is Map
        ? Map<String, dynamic>.from(json['quote'] as Map)
        : json;

    final breakdown = AdQuoteBreakdownModel.fromJson(quoteMap);

    AdReachModel? reachModel;
    if (json.containsKey('reach') && json['reach'] is Map) {
      reachModel = AdReachModel.fromJson(
        Map<String, dynamic>.from(json['reach'] as Map),
      );
    }

    return AdQuoteModel(quote: breakdown, reach: reachModel);
  }

  Map<String, dynamic> toJson() => {
    'quote': quote.toJson(),
    if (reach != null) 'reach': reach!.toJson(),
    'base_price': basePrice,
    'churches_count': churchesCount,
    'weeks_count': weeksCount,
    'total_price': totalPrice,
    'currency': currency,
  };
}

/// Cuenta bancaria para pagos por transferencia (`/admin/ads/{id}/payment`).
/// Odoo 19: `{ "bank_name": "Banco Popular", "account_holder": "Atrio Plataforma", "account_number": "798412356", "currency": "DOP", "iban": null }`
@immutable
class AdBankAccountModel {
  final String bankName;
  final String accountHolder;
  final String accountNumber;
  final String accountType; // Corriente, Ahorros, etc.
  final String currency;
  final String? iban;
  final String? taxId; // RNC o Cédula

  const AdBankAccountModel({
    required this.bankName,
    required this.accountHolder,
    required this.accountNumber,
    this.accountType = 'Corriente',
    this.currency = 'DOP',
    this.iban,
    this.taxId,
  });

  factory AdBankAccountModel.fromJson(Map<String, dynamic> json) {
    return AdBankAccountModel(
      bankName: json['bank_name']?.toString() ?? json['bank']?.toString() ?? '',
      accountHolder:
          json['account_holder']?.toString() ??
          json['holder']?.toString() ??
          '',
      accountNumber:
          json['account_number']?.toString() ??
          json['number']?.toString() ??
          '',
      accountType:
          json['account_type']?.toString() ??
          json['type']?.toString() ??
          'Corriente',
      currency: json['currency']?.toString() ?? 'DOP',
      iban: json['iban']?.toString(),
      taxId: json['tax_id']?.toString() ?? json['rnc']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'bank_name': bankName,
    'account_holder': accountHolder,
    'account_number': accountNumber,
    'account_type': accountType,
    'currency': currency,
    if (iban != null) 'iban': iban,
    if (taxId != null) 'tax_id': taxId,
  };
}

/// Alias para claridad semántica con la guía técnica de Odoo 19
typedef AdTransferBankModel = AdBankAccountModel;

/// Modelo de datos de pasarela de pago para una campaña (`/admin/ads/{id}/payment`).
/// Odoo 19:
/// ```json
/// {
///   "payable": true,
///   "payment_status": "unpaid",
///   "amount": 76.0,
///   "currency": "USD",
///   "reference": "ATRIO-AD-40",
///   "rejection_reason": null,
///   "paypal_available": true,
///   "transfer": { "bank_name": "Banco Popular", "account_holder": "Atrio Plataforma", "account_number": "798412356", "currency": "DOP", "iban": null }
/// }
/// ```
@immutable
class AdPaymentModel {
  final int adId;
  final double amount;
  final String currency;
  final bool payable;
  final String paymentStatus;
  final String? reference;
  final String? rejectionReason;
  final bool paypalAvailable;
  final AdBankAccountModel? transfer;
  final List<AdBankAccountModel> bankAccounts;

  const AdPaymentModel({
    required this.adId,
    required this.amount,
    this.currency = 'USD',
    required this.payable,
    this.paymentStatus = 'unpaid',
    this.reference,
    this.rejectionReason,
    this.paypalAvailable = true,
    this.transfer,
    this.bankAccounts = const [],
  });

  /// Getters de compatibilidad previa
  bool get paypalEnabled => paypalAvailable;
  String? get receiptStatus => paymentStatus;
  String? get receiptFilename => null;

  factory AdPaymentModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val is int) return val;
      return int.tryParse(val?.toString() ?? '') ?? 0;
    }

    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      return double.tryParse(val?.toString() ?? '') ?? 0.0;
    }

    AdBankAccountModel? transferModel;
    if (json.containsKey('transfer') && json['transfer'] is Map) {
      transferModel = AdBankAccountModel.fromJson(
        Map<String, dynamic>.from(json['transfer'] as Map),
      );
    }

    List<AdBankAccountModel> accounts = [];
    final rawBanks = json['bank_accounts'] ?? json['accounts'] ?? json['banks'];
    if (rawBanks is List) {
      accounts = rawBanks
          .map(
            (e) => AdBankAccountModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    } else if (transferModel != null) {
      accounts = [transferModel];
    }

    return AdPaymentModel(
      adId: parseInt(json['ad_id'] ?? json['id']),
      amount: parseDouble(
        json['amount'] ?? json['cost'] ?? json['total_price'],
      ),
      currency: json['currency']?.toString() ?? 'USD',
      payable: json['payable'] == true || json['is_payable'] == true,
      paymentStatus:
          json['payment_status']?.toString() ??
          json['receipt_status']?.toString() ??
          'unpaid',
      reference: json['reference']?.toString(),
      rejectionReason: json['rejection_reason']?.toString(),
      paypalAvailable:
          json['paypal_available'] == true || json['paypal_enabled'] != false,
      transfer: transferModel,
      bankAccounts: accounts,
    );
  }

  Map<String, dynamic> toJson() => {
    'ad_id': adId,
    'amount': amount,
    'currency': currency,
    'payable': payable,
    'payment_status': paymentStatus,
    'reference': reference,
    'rejection_reason': rejectionReason,
    'paypal_available': paypalAvailable,
    'paypal_enabled': paypalAvailable,
    if (transfer != null) 'transfer': transfer!.toJson(),
    'bank_accounts': bankAccounts.map((a) => a.toJson()).toList(),
  };
}

/// Estructura de la serie temporal en Odoo 19:
/// `"series": { "labels": ["2026-09-26"], "impressions": [20], "clicks": [3] }`
@immutable
class AdStatsSeriesModel {
  final List<String> labels;
  final List<int> impressions;
  final List<int> clicks;

  const AdStatsSeriesModel({
    this.labels = const [],
    this.impressions = const [],
    this.clicks = const [],
  });

  factory AdStatsSeriesModel.fromJson(Map<String, dynamic> json) {
    List<String> parseStrings(dynamic list) {
      if (list is List) return list.map((e) => e.toString()).toList();
      return const [];
    }

    List<int> parseInts(dynamic list) {
      if (list is List) {
        return list
            .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
            .toList();
      }
      return const [];
    }

    return AdStatsSeriesModel(
      labels: parseStrings(json['labels']),
      impressions: parseInts(json['impressions']),
      clicks: parseInts(json['clicks']),
    );
  }

  Map<String, dynamic> toJson() => {
    'labels': labels,
    'impressions': impressions,
    'clicks': clicks,
  };
}

/// Punto temporal de la serie de estadísticas para gráficos UI.
@immutable
class AdStatsPointModel {
  final DateTime date;
  final String dateLabel;
  final int impressions;
  final int clicks;

  const AdStatsPointModel({
    required this.date,
    required this.dateLabel,
    required this.impressions,
    required this.clicks,
  });

  double get ctrPercentage {
    if (impressions <= 0) return 0.0;
    return (clicks / impressions) * 100.0;
  }

  factory AdStatsPointModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val.toUtc();
      return DateTime.tryParse(val?.toString() ?? '')?.toUtc() ??
          DateTime.now().toUtc();
    }

    int parseInt(dynamic val) {
      if (val is int) return val;
      return int.tryParse(val?.toString() ?? '') ?? 0;
    }

    final rawDate = json['date'] ?? json['day'] ?? json['label'];
    return AdStatsPointModel(
      date: parseDate(rawDate),
      dateLabel: rawDate?.toString() ?? '',
      impressions: parseInt(json['impressions']),
      clicks: parseInt(json['clicks']),
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'dateLabel': dateLabel,
    'impressions': impressions,
    'clicks': clicks,
  };
}

/// Modelo de estadísticas de rendimiento de anuncio (`/admin/ads/{id}/stats`).
/// Odoo 19:
/// ```json
/// {
///   "stats": {
///     "impressions": 404, "clicks": 54, "unique_clicks": 40, "ctr": 13.37,
///     "series": { "labels": ["2026-09-26"], "impressions": [20], "clicks": [3] },
///     "by_country": [], "by_church": [], "by_channel": [], "recent_clicks": []
///   }
/// }
/// ```
@immutable
class AdStatsModel {
  final int adId;
  final int impressions;
  final int clicks;
  final int uniqueClicks;
  final double ctr;
  final AdStatsSeriesModel series;
  final List<dynamic> byCountry;
  final List<dynamic> byChurch;
  final List<dynamic> byChannel;
  final List<dynamic> recentClicks;
  final List<AdStatsPointModel> timeSeries;

  const AdStatsModel({
    required this.adId,
    required this.impressions,
    required this.clicks,
    this.uniqueClicks = 0,
    required this.ctr,
    this.series = const AdStatsSeriesModel(),
    this.byCountry = const [],
    this.byChurch = const [],
    this.byChannel = const [],
    this.recentClicks = const [],
    this.timeSeries = const [],
  });

  factory AdStatsModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> statsMap =
        json.containsKey('stats') && json['stats'] is Map
        ? Map<String, dynamic>.from(json['stats'] as Map)
        : json;

    int parseInt(dynamic val) {
      if (val is int) return val;
      return int.tryParse(val?.toString() ?? '') ?? 0;
    }

    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      return double.tryParse(val?.toString() ?? '') ?? 0.0;
    }

    AdStatsSeriesModel seriesModel = const AdStatsSeriesModel();
    if (statsMap.containsKey('series') && statsMap['series'] is Map) {
      seriesModel = AdStatsSeriesModel.fromJson(
        Map<String, dynamic>.from(statsMap['series'] as Map),
      );
    }

    // Convertir serie a lista de puntos para los gráficos UI
    List<AdStatsPointModel> points = [];
    if (seriesModel.labels.isNotEmpty) {
      for (int i = 0; i < seriesModel.labels.length; i++) {
        final label = seriesModel.labels[i];
        final imp = i < seriesModel.impressions.length
            ? seriesModel.impressions[i]
            : 0;
        final clk = i < seriesModel.clicks.length ? seriesModel.clicks[i] : 0;
        final parsedDate =
            DateTime.tryParse(label)?.toUtc() ?? DateTime.now().toUtc();
        points.add(
          AdStatsPointModel(
            date: parsedDate,
            dateLabel: label,
            impressions: imp,
            clicks: clk,
          ),
        );
      }
    } else {
      // Retrocompatibilidad con lista de objetos
      final rawSeries =
          statsMap['time_series'] ??
          statsMap['daily_stats'] ??
          statsMap['history'];
      if (rawSeries is List) {
        points = rawSeries
            .map(
              (e) => AdStatsPointModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      }
    }

    return AdStatsModel(
      adId: parseInt(json['ad_id'] ?? json['id'] ?? statsMap['id']),
      impressions: parseInt(
        statsMap['impressions'] ?? statsMap['total_impressions'],
      ),
      clicks: parseInt(statsMap['clicks'] ?? statsMap['total_clicks']),
      uniqueClicks: parseInt(statsMap['unique_clicks']),
      ctr: parseDouble(statsMap['ctr'] ?? statsMap['ctr_percentage']),
      series: seriesModel,
      byCountry: statsMap['by_country'] is List
          ? statsMap['by_country'] as List
          : const [],
      byChurch: statsMap['by_church'] is List
          ? statsMap['by_church'] as List
          : const [],
      byChannel: statsMap['by_channel'] is List
          ? statsMap['by_channel'] as List
          : const [],
      recentClicks: statsMap['recent_clicks'] is List
          ? statsMap['recent_clicks'] as List
          : const [],
      timeSeries: points,
    );
  }

  Map<String, dynamic> toJson() => {
    'ad_id': adId,
    'impressions': impressions,
    'clicks': clicks,
    'unique_clicks': uniqueClicks,
    'ctr': ctr,
    'series': series.toJson(),
    'by_country': byCountry,
    'by_church': byChurch,
    'by_channel': byChannel,
    'recent_clicks': recentClicks,
    'time_series': timeSeries.map((p) => p.toJson()).toList(),
  };
}
