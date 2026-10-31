import 'package:flutter/foundation.dart';

/// Enumeración con los estados del ciclo de vida de un anuncio en Odoo 19.
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
/// Soporta tanto el consumo público de miembros (Feed/Notificaciones) como la
/// administración de campañas de iglesias (/admin/ads).
@immutable
class AdModel {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String? redirectUrl;
  final String placement;
  final AdStatus status;
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

  const AdModel({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.redirectUrl,
    this.placement = 'all',
    this.status = AdStatus.requested,
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
  });

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
  bool get hasInteractiveLink => redirectUrl != null && redirectUrl!.trim().isNotEmpty;

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
      final str = val.toString();
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

    final rawStatus = json['status']?.toString();
    final adStatus = AdStatus.fromString(rawStatus);

    return AdModel(
      id: parsedId,
      name: json['name']?.toString() ?? json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? json['subtitle']?.toString(),
      imageUrl: json['image_url']?.toString() ??
          json['image']?.toString() ??
          json['cover_url']?.toString() ??
          json['image_1920']?.toString(),
      redirectUrl: json['redirect_url']?.toString() ?? json['action_url']?.toString(),
      placement: json['placement']?.toString() ?? 'all',
      status: adStatus,
      payable: json['payable'] == true || json['is_payable'] == true,
      rejectionReason: json['rejection_reason']?.toString(),
      churchId: json['church_id'] is int
          ? json['church_id'] as int
          : (json['church_id'] is List && (json['church_id'] as List).isNotEmpty
              ? (json['church_id'] as List).first as int?
              : int.tryParse(json['church_id']?.toString() ?? '')),
      churchName: json['church_name']?.toString() ??
          (json['church_id'] is List && (json['church_id'] as List).length > 1
              ? (json['church_id'] as List)[1].toString()
              : null),
      startDate: parseUtc(json['start_date'] ?? json['date_start']),
      endDate: parseUtc(json['end_date'] ?? json['date_end']),
      createdAt: parseUtc(json['create_date'] ?? json['created_at']),
      totalImpressions: parseInt(json['impressions'] ?? json['total_impressions']),
      totalClicks: parseInt(json['clicks'] ?? json['total_clicks']),
      cost: parseDouble(json['cost'] ?? json['amount'] ?? json['total_price']),
      currency: json['currency']?.toString() ?? 'USD',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'image_url': imageUrl,
        'redirect_url': redirectUrl,
        'placement': placement,
        'status': status.value,
        'payable': payable,
        'rejection_reason': rejectionReason,
        'church_id': churchId,
        'church_name': churchName,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'create_date': createdAt?.toIso8601String(),
        'impressions': totalImpressions,
        'clicks': totalClicks,
        'cost': cost,
        'currency': currency,
      };

  AdModel copyWith({
    int? id,
    String? name,
    String? description,
    String? imageUrl,
    String? redirectUrl,
    String? placement,
    AdStatus? status,
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
  }) {
    return AdModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      placement: placement ?? this.placement,
      status: status ?? this.status,
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
    );
  }
}

/// Modelo de objetivo de segmentación de audiencia (`/admin/ads/targets`).
@immutable
class AdTargetModel {
  final int id;
  final String name;
  final String kind; // 'church', 'denomination', 'country'
  final String? location;
  final int? membersCount;

  const AdTargetModel({
    required this.id,
    required this.name,
    required this.kind,
    this.location,
    this.membersCount,
  });

  factory AdTargetModel.fromJson(Map<String, dynamic> json) {
    return AdTargetModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'church',
      location: json['location']?.toString() ?? json['country_name']?.toString(),
      membersCount: json['members_count'] is int
          ? json['members_count'] as int
          : int.tryParse(json['members_count']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'kind': kind,
        'location': location,
        'members_count': membersCount,
      };
}

/// Modelo de cotización de campaña publicitaria (`/admin/ads/quote`).
@immutable
class AdQuoteModel {
  final double basePrice;
  final int churchesCount;
  final int weeksCount;
  final double totalPrice;
  final String currency;
  final Map<String, dynamic>? details;

  const AdQuoteModel({
    required this.basePrice,
    required this.churchesCount,
    required this.weeksCount,
    required this.totalPrice,
    this.currency = 'USD',
    this.details,
  });

  factory AdQuoteModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> source = json.containsKey('quote') && json['quote'] is Map
        ? Map<String, dynamic>.from(json['quote'] as Map)
        : json;

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

    return AdQuoteModel(
      basePrice: parseDouble(source['base_price'] ?? source['base']),
      churchesCount: parseInt(source['churches_count'] ?? source['churches'] ?? source['targets_count'], 1),
      weeksCount: parseInt(source['weeks_count'] ?? source['weeks'] ?? source['duration_weeks'], 1),
      totalPrice: parseDouble(source['total_price'] ?? source['total'] ?? source['amount']),
      currency: source['currency']?.toString() ?? 'USD',
      details: json['reach'] is Map
          ? Map<String, dynamic>.from(json['reach'] as Map)
          : (json['details'] is Map ? Map<String, dynamic>.from(json['details'] as Map) : null),
    );
  }

  Map<String, dynamic> toJson() => {
        'base_price': basePrice,
        'churches_count': churchesCount,
        'weeks_count': weeksCount,
        'total_price': totalPrice,
        'currency': currency,
        if (details != null) 'details': details,
      };
}

/// Punto temporal de la serie de estadísticas para gráficos.
@immutable
class AdStatsPointModel {
  final DateTime date;
  final int impressions;
  final int clicks;

  const AdStatsPointModel({
    required this.date,
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
      return DateTime.tryParse(val?.toString() ?? '')?.toUtc() ?? DateTime.now().toUtc();
    }

    int parseInt(dynamic val) {
      if (val is int) return val;
      return int.tryParse(val?.toString() ?? '') ?? 0;
    }

    return AdStatsPointModel(
      date: parseDate(json['date'] ?? json['day']),
      impressions: parseInt(json['impressions']),
      clicks: parseInt(json['clicks']),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'impressions': impressions,
        'clicks': clicks,
      };
}

/// Modelo de estadísticas de rendimiento de anuncio (`/admin/ads/{id}/stats`).
@immutable
class AdStatsModel {
  final int adId;
  final int impressions;
  final int clicks;
  final double ctr;
  final List<AdStatsPointModel> timeSeries;

  const AdStatsModel({
    required this.adId,
    required this.impressions,
    required this.clicks,
    required this.ctr,
    this.timeSeries = const [],
  });

  factory AdStatsModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val is int) return val;
      return int.tryParse(val?.toString() ?? '') ?? 0;
    }

    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      return double.tryParse(val?.toString() ?? '') ?? 0.0;
    }

    final rawSeries = json['time_series'] ?? json['daily_stats'] ?? json['history'];
    List<AdStatsPointModel> series = [];
    if (rawSeries is List) {
      series = rawSeries
          .map((e) => AdStatsPointModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return AdStatsModel(
      adId: parseInt(json['ad_id'] ?? json['id']),
      impressions: parseInt(json['impressions'] ?? json['total_impressions']),
      clicks: parseInt(json['clicks'] ?? json['total_clicks']),
      ctr: parseDouble(json['ctr'] ?? json['ctr_percentage']),
      timeSeries: series,
    );
  }

  Map<String, dynamic> toJson() => {
        'ad_id': adId,
        'impressions': impressions,
        'clicks': clicks,
        'ctr': ctr,
        'time_series': timeSeries.map((p) => p.toJson()).toList(),
      };
}

/// Cuenta bancaria para pagos por transferencia (`/admin/ads/{id}/payment`).
@immutable
class AdBankAccountModel {
  final String bankName;
  final String accountHolder;
  final String accountNumber;
  final String accountType; // Corriente, Ahorros, etc.
  final String? taxId; // RNC o Cédula

  const AdBankAccountModel({
    required this.bankName,
    required this.accountHolder,
    required this.accountNumber,
    required this.accountType,
    this.taxId,
  });

  factory AdBankAccountModel.fromJson(Map<String, dynamic> json) {
    return AdBankAccountModel(
      bankName: json['bank_name']?.toString() ?? json['bank']?.toString() ?? '',
      accountHolder: json['account_holder']?.toString() ?? json['holder']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? json['number']?.toString() ?? '',
      accountType: json['account_type']?.toString() ?? json['type']?.toString() ?? 'Corriente',
      taxId: json['tax_id']?.toString() ?? json['rnc']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'bank_name': bankName,
        'account_holder': accountHolder,
        'account_number': accountNumber,
        'account_type': accountType,
        if (taxId != null) 'tax_id': taxId,
      };
}

/// Modelo de datos de pasarela de pago para una campaña (`/admin/ads/{id}/payment`).
@immutable
class AdPaymentModel {
  final int adId;
  final double amount;
  final String currency;
  final bool payable;
  final bool paypalEnabled;
  final String? receiptStatus; // 'none', 'pending', 'approved', 'rejected'
  final String? receiptFilename;
  final String? reference;
  final List<AdBankAccountModel> bankAccounts;

  const AdPaymentModel({
    required this.adId,
    required this.amount,
    this.currency = 'USD',
    required this.payable,
    this.paypalEnabled = true,
    this.receiptStatus,
    this.receiptFilename,
    this.reference,
    this.bankAccounts = const [],
  });

  factory AdPaymentModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val is int) return val;
      return int.tryParse(val?.toString() ?? '') ?? 0;
    }

    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      return double.tryParse(val?.toString() ?? '') ?? 0.0;
    }

    final rawBanks = json['bank_accounts'] ?? json['accounts'] ?? json['banks'];
    List<AdBankAccountModel> accounts = [];
    if (rawBanks is List) {
      accounts = rawBanks
          .map((e) => AdBankAccountModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return AdPaymentModel(
      adId: parseInt(json['ad_id'] ?? json['id']),
      amount: parseDouble(json['amount'] ?? json['cost'] ?? json['total_price']),
      currency: json['currency']?.toString() ?? 'USD',
      payable: json['payable'] == true || json['is_payable'] == true,
      paypalEnabled: json['paypal_enabled'] != false,
      receiptStatus: json['receipt_status']?.toString() ?? json['payment_status']?.toString(),
      receiptFilename: json['receipt_filename']?.toString(),
      reference: json['reference']?.toString(),
      bankAccounts: accounts,
    );
  }

  Map<String, dynamic> toJson() => {
        'ad_id': adId,
        'amount': amount,
        'currency': currency,
        'payable': payable,
        'paypal_enabled': paypalEnabled,
        'receipt_status': receiptStatus,
        'receipt_filename': receiptFilename,
        'reference': reference,
        'bank_accounts': bankAccounts.map((a) => a.toJson()).toList(),
      };
}
