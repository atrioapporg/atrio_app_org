import 'dart:async';
import 'package:flutter/foundation.dart';
import '../atrio_api.dart';
import '../modelos/moderation_models.dart';

/// Servicio de red para la API de Moderación de Plataforma de ATRIO en Odoo 19.
/// Permite al Super Admin (`role: platform_admin`) auditar contenidos marcados,
/// aplicar/remover bloqueos, gestionar palabras restringidas y disparar reescaneo.
class ModerationService {
  final AtrioApi api;

  ModerationService({required this.api});

  /// Consulta el resumen estadístico de totales por tipo y estado.
  /// `GET /platform/moderation/summary`
  Future<ModerationSummaryModel> getSummary() async {
    try {
      final res = await api.moderationSummary();
      return ModerationSummaryModel.fromJson(res);
    } on AtrioApiException {
      rethrow;
    } catch (e) {
      debugPrint('[ModerationService] Error en getSummary: $e');
      throw AtrioApiException(500, 'network_error', e.toString());
    }
  }

  /// Lista el contenido auditado filtrado por tipo, estado y búsqueda.
  /// `GET /platform/moderation/content`
  Future<({List<ModeratedItemModel> items, int total})> getContent({
    String type = 'post',
    String status = 'flagged',
    int? churchId,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final res = await api.moderationContent(
        type: type,
        status: status,
        churchId: churchId,
        search: search,
        limit: limit,
        offset: offset,
      );

      final rawList = res['items'] ?? res['data'] ?? [];
      final total = res['total'] is int
          ? res['total'] as int
          : int.tryParse(res['total']?.toString() ?? '') ?? 0;

      List<ModeratedItemModel> items = [];
      if (rawList is List) {
        items = rawList
            .map((e) => ModeratedItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }

      return (items: items, total: total > 0 ? total : items.length);
    } on AtrioApiException {
      rethrow;
    } catch (e) {
      debugPrint('[ModerationService] Error en getContent: $e');
      throw AtrioApiException(500, 'network_error', e.toString());
    }
  }

  /// Bloquea un contenido marcado o infractor con motivo explícito que se notifica a la iglesia.
  /// `POST /platform/moderation/content/{type}/{id}/ban`
  Future<ModeratedItemModel?> banContent({
    required String type,
    required int id,
    required String reason,
  }) async {
    try {
      final res = await api.banContent(type, id, reason);
      final rawItem = res['item'] ?? res['data'];
      if (rawItem is Map) {
        return ModeratedItemModel.fromJson(Map<String, dynamic>.from(rawItem));
      }
      return null;
    } on AtrioApiException {
      rethrow;
    } catch (e) {
      debugPrint('[ModerationService] Error en banContent: $e');
      throw AtrioApiException(500, 'network_error', e.toString());
    }
  }

  /// Desbloquea un contenido previamente censurado y notifica a la iglesia.
  /// `POST /platform/moderation/content/{type}/{id}/unban`
  Future<ModeratedItemModel?> unbanContent({
    required String type,
    required int id,
  }) async {
    try {
      final res = await api.unbanContent(type, id);
      final rawItem = res['item'] ?? res['data'];
      if (rawItem is Map) {
        return ModeratedItemModel.fromJson(Map<String, dynamic>.from(rawItem));
      }
      return null;
    } on AtrioApiException {
      rethrow;
    } catch (e) {
      debugPrint('[ModerationService] Error en unbanContent: $e');
      throw AtrioApiException(500, 'network_error', e.toString());
    }
  }

  /// Consulta el catálogo de palabras restringidas.
  /// `GET /platform/moderation/words`
  Future<List<ModerationWordModel>> getWords() async {
    try {
      final res = await api.moderationWords();
      final rawList = res['words'] ?? res['items'] ?? [];
      if (rawList is List) {
        return rawList
            .map((e) => ModerationWordModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } on AtrioApiException {
      rethrow;
    } catch (e) {
      debugPrint('[ModerationService] Error en getWords: $e');
      throw AtrioApiException(500, 'network_error', e.toString());
    }
  }

  /// Crea una nueva palabra restringida.
  /// `POST /platform/moderation/words`
  Future<ModerationWordModel> createWord({
    required String word,
    String mode = 'flag',
    bool wholeWord = true,
    String? note,
  }) async {
    try {
      final res = await api.createModerationWord(
        word: word,
        mode: mode,
        wholeWord: wholeWord,
        note: note,
      );
      final rawWord = res['word'] ?? res['item'] ?? res;
      if (rawWord is Map) {
        return ModerationWordModel.fromJson(Map<String, dynamic>.from(rawWord));
      }
      throw AtrioApiException(500, 'invalid_response', 'Respuesta no válida al crear palabra');
    } on AtrioApiException {
      rethrow;
    } catch (e) {
      debugPrint('[ModerationService] Error en createWord: $e');
      throw AtrioApiException(500, 'network_error', e.toString());
    }
  }

  /// Edita una palabra restringida existente o cambia su estado activo.
  /// `PATCH /platform/moderation/words/{id}`
  Future<ModerationWordModel> updateWord(
    int id, {
    String? word,
    String? mode,
    bool? wholeWord,
    bool? active,
    String? note,
  }) async {
    try {
      final res = await api.updateModerationWord(
        id,
        word: word,
        mode: mode,
        wholeWord: wholeWord,
        active: active,
        note: note,
      );
      final rawWord = res['word'] ?? res['item'] ?? res;
      if (rawWord is Map) {
        return ModerationWordModel.fromJson(Map<String, dynamic>.from(rawWord));
      }
      throw AtrioApiException(500, 'invalid_response', 'Respuesta no válida al actualizar palabra');
    } on AtrioApiException {
      rethrow;
    } catch (e) {
      debugPrint('[ModerationService] Error en updateWord: $e');
      throw AtrioApiException(500, 'network_error', e.toString());
    }
  }

  /// Elimina una palabra restringida de la base de datos.
  /// `DELETE /platform/moderation/words/{id}`
  Future<bool> deleteWord(int id) async {
    try {
      final res = await api.deleteModerationWord(id);
      return res['success'] == true || res['status'] == 'success';
    } on AtrioApiException {
      rethrow;
    } catch (e) {
      debugPrint('[ModerationService] Error en deleteWord: $e');
      throw AtrioApiException(500, 'network_error', e.toString());
    }
  }

  /// Ejecuta un reescaneo global asíncrono de todo el contenido de la plataforma.
  /// Solo marca contenido sin bloquearlo ni borrarlo.
  /// `POST /platform/moderation/rescan`
  Future<int> rescanAll() async {
    try {
      final res = await api.moderationRescan();
      final flagged = res['flagged'] is int
          ? res['flagged'] as int
          : int.tryParse(res['flagged']?.toString() ?? '') ?? 0;
      return flagged;
    } on AtrioApiException {
      rethrow;
    } catch (e) {
      debugPrint('[ModerationService] Error en rescanAll: $e');
      throw AtrioApiException(500, 'network_error', e.toString());
    }
  }
}
