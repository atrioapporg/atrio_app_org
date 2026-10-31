import 'package:flutter/foundation.dart';

/// Conteo de elementos marcados y bloqueados por tipo de contenido.
@immutable
class ModerationTypeCount {
  final int flagged;
  final int banned;

  const ModerationTypeCount({
    this.flagged = 0,
    this.banned = 0,
  });

  factory ModerationTypeCount.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ModerationTypeCount();
    return ModerationTypeCount(
      flagged: json['flagged'] is int
          ? json['flagged'] as int
          : int.tryParse(json['flagged']?.toString() ?? '') ?? 0,
      banned: json['banned'] is int
          ? json['banned'] as int
          : int.tryParse(json['banned']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'flagged': flagged,
        'banned': banned,
      };
}

/// Resumen global de moderación retornado por `GET /platform/moderation/summary`.
@immutable
class ModerationSummaryModel {
  final ModerationTypeCount post;
  final ModerationTypeCount event;
  final ModerationTypeCount notification;

  const ModerationSummaryModel({
    this.post = const ModerationTypeCount(),
    this.event = const ModerationTypeCount(),
    this.notification = const ModerationTypeCount(),
  });

  int get totalFlagged => post.flagged + event.flagged + notification.flagged;
  int get totalBanned => post.banned + event.banned + notification.banned;
  int get grandTotal => totalFlagged + totalBanned;

  factory ModerationSummaryModel.fromJson(Map<String, dynamic> json) {
    return ModerationSummaryModel(
      post: ModerationTypeCount.fromJson(
        json['post'] is Map ? Map<String, dynamic>.from(json['post'] as Map) : null,
      ),
      event: ModerationTypeCount.fromJson(
        json['event'] is Map ? Map<String, dynamic>.from(json['event'] as Map) : null,
      ),
      notification: ModerationTypeCount.fromJson(
        json['notification'] is Map
            ? Map<String, dynamic>.from(json['notification'] as Map)
            : null,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'post': post.toJson(),
        'event': event.toJson(),
        'notification': notification.toJson(),
      };
}

/// Información básica de la iglesia remitente del contenido moderado.
@immutable
class ModerationChurchInfo {
  final int id;
  final String name;

  const ModerationChurchInfo({
    required this.id,
    required this.name,
  });

  factory ModerationChurchInfo.fromJson(dynamic json) {
    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      return ModerationChurchInfo(
        id: map['id'] is int
            ? map['id'] as int
            : int.tryParse(map['id']?.toString() ?? '') ?? 0,
        name: map['name']?.toString() ?? '',
      );
    } else if (json is List && json.isNotEmpty) {
      return ModerationChurchInfo(
        id: json.first is int ? json.first as int : int.tryParse(json.first.toString()) ?? 0,
        name: json.length > 1 ? json[1].toString() : '',
      );
    }
    return const ModerationChurchInfo(id: 0, name: '');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}

/// Elemento de contenido auditado por moderación (`GET /platform/moderation/content`).
@immutable
class ModeratedItemModel {
  final int id;
  final String type; // 'post', 'event', 'notification'
  final String title;
  final ModerationChurchInfo church;
  final bool flagged;
  final String? flaggedWords;
  final bool banned;
  final String? banReason;
  final DateTime? bannedAt;
  final DateTime? createdAt;

  const ModeratedItemModel({
    required this.id,
    required this.type,
    required this.title,
    required this.church,
    this.flagged = false,
    this.flaggedWords,
    this.banned = false,
    this.banReason,
    this.bannedAt,
    this.createdAt,
  });

  factory ModeratedItemModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val.toLocal();
      final str = val.toString();
      if (str.isEmpty) return null;
      return DateTime.tryParse(str)?.toLocal();
    }

    return ModeratedItemModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      type: json['type']?.toString() ?? 'post',
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      church: ModerationChurchInfo.fromJson(json['church']),
      flagged: json['flagged'] == true,
      flaggedWords: json['flagged_words']?.toString(),
      banned: json['banned'] == true,
      banReason: json['ban_reason']?.toString(),
      bannedAt: parseDate(json['banned_at']),
      createdAt: parseDate(json['created_at'] ?? json['create_date']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'church': church.toJson(),
        'flagged': flagged,
        'flagged_words': flaggedWords,
        'banned': banned,
        'ban_reason': banReason,
        'banned_at': bannedAt?.toUtc().toIso8601String(),
        'created_at': createdAt?.toUtc().toIso8601String(),
      };

  ModeratedItemModel copyWith({
    int? id,
    String? type,
    String? title,
    ModerationChurchInfo? church,
    bool? flagged,
    String? flaggedWords,
    bool? banned,
    String? banReason,
    DateTime? bannedAt,
    DateTime? createdAt,
  }) {
    return ModeratedItemModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      church: church ?? this.church,
      flagged: flagged ?? this.flagged,
      flaggedWords: flaggedWords ?? this.flaggedWords,
      banned: banned ?? this.banned,
      banReason: banReason ?? this.banReason,
      bannedAt: bannedAt ?? this.bannedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Palabra restringida en la plataforma (`/platform/moderation/words`).
@immutable
class ModerationWordModel {
  final int id;
  final String word;
  final String mode; // 'flag' (guarda y marca) o 'block' (impide guardar)
  final bool wholeWord;
  final bool active;
  final String? note;
  final DateTime? createdAt;

  const ModerationWordModel({
    required this.id,
    required this.word,
    this.mode = 'flag',
    this.wholeWord = true,
    this.active = true,
    this.note,
    this.createdAt,
  });

  bool get isBlock => mode == 'block';
  bool get isFlag => mode == 'flag';

  factory ModerationWordModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val.toLocal();
      final str = val.toString();
      if (str.isEmpty) return null;
      return DateTime.tryParse(str)?.toLocal();
    }

    return ModerationWordModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      word: json['word']?.toString() ?? '',
      mode: json['mode']?.toString() ?? 'flag',
      wholeWord: json['whole_word'] != false,
      active: json['active'] != false,
      note: json['note']?.toString(),
      createdAt: parseDate(json['created_at'] ?? json['create_date']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'mode': mode,
        'whole_word': wholeWord,
        'active': active,
        if (note != null) 'note': note,
        if (createdAt != null) 'created_at': createdAt?.toUtc().toIso8601String(),
      };

  ModerationWordModel copyWith({
    int? id,
    String? word,
    String? mode,
    bool? wholeWord,
    bool? active,
    String? note,
    DateTime? createdAt,
  }) {
    return ModerationWordModel(
      id: id ?? this.id,
      word: word ?? this.word,
      mode: mode ?? this.mode,
      wholeWord: wholeWord ?? this.wholeWord,
      active: active ?? this.active,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
