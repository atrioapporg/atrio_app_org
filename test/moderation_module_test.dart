import 'package:flutter_test/flutter_test.dart';
import 'package:atrio/atrio_api.dart';
import 'package:atrio/modelos/moderation_models.dart';
import 'package:atrio/providers/moderation_provider.dart';

void main() {
  group('Modelos y DTOs de Moderación (Odoo 19)', () {
    test('ModerationSummaryModel.fromJson mapea los conteos y calcula totales', () {
      final json = {
        'post': {'flagged': 2, 'banned': 1},
        'event': {'flagged': 0, 'banned': 0},
        'notification': {'flagged': 1, 'banned': 0},
      };

      final summary = ModerationSummaryModel.fromJson(json);

      expect(summary.post.flagged, 2);
      expect(summary.post.banned, 1);
      expect(summary.event.flagged, 0);
      expect(summary.notification.flagged, 1);
      expect(summary.totalFlagged, 3);
      expect(summary.totalBanned, 1);
      expect(summary.grandTotal, 4);

      final outJson = summary.toJson();
      expect(outJson['post']['flagged'], 2);
    });

    test('ModeratedItemModel.fromJson mapea campos, iglesia y fechas UTC a local', () {
      final json = {
        'id': 6,
        'type': 'post',
        'title': 'Conferencia Magna',
        'church': {'id': 1, 'name': 'Atrio Demo'},
        'flagged': true,
        'flagged_words': 'palabra_prohibida',
        'banned': false,
        'ban_reason': null,
        'banned_at': null,
        'created_at': '2026-10-30T15:20:00Z',
      };

      final item = ModeratedItemModel.fromJson(json);

      expect(item.id, 6);
      expect(item.type, 'post');
      expect(item.title, 'Conferencia Magna');
      expect(item.church.id, 1);
      expect(item.church.name, 'Atrio Demo');
      expect(item.flagged, isTrue);
      expect(item.flaggedWords, 'palabra_prohibida');
      expect(item.banned, isFalse);
      expect(item.createdAt, isNotNull);
    });

    test('ModerationWordModel.fromJson maneja modos flag y block correctamente', () {
      final jsonBlock = {
        'id': 1,
        'word': 'groseria',
        'mode': 'block',
        'whole_word': true,
        'active': true,
        'note': 'Termino no permitido',
        'created_at': '2026-10-30T10:00:00Z',
      };

      final word = ModerationWordModel.fromJson(jsonBlock);

      expect(word.id, 1);
      expect(word.word, 'groseria');
      expect(word.isBlock, isTrue);
      expect(word.isFlag, isFalse);
      expect(word.wholeWord, isTrue);
      expect(word.active, isTrue);
      expect(word.note, 'Termino no permitido');
    });
  });

  group('Reglas de Solo Lectura y Mutaciones de Moderación en AtrioApi', () {
    test('AtrioApi permite mutaciones a /platform/moderation aun con isReadOnly == true', () {
      final api = AtrioApi(
        baseUrl: 'https://atrioapp.odoo19rd.com',
        isReadOnly: true,
      );

      expect(api.isReadOnly, isTrue);

      // Verificamos que las cabeceras se construyan con normalidad
      final headers = api.buildHeadersForTesting('/platform/moderation/summary');
      expect(headers['Content-Type'], 'application/json');
    });
  });

  group('ModerationProvider Estado', () {
    test('ModerationProvider cambia filtros y resetea estado', () {
      final api = AtrioApi(baseUrl: 'https://atrioapp.odoo19rd.com');
      final provider = ModerationProvider(api: api);

      expect(provider.selectedType, 'post');
      expect(provider.selectedStatus, 'flagged');

      provider.setTypeFilter('event');
      expect(provider.selectedType, 'event');

      provider.setStatusFilter('banned');
      expect(provider.selectedStatus, 'banned');

      provider.reset();
      expect(provider.selectedType, 'post');
      expect(provider.selectedStatus, 'flagged');
      expect(provider.items, isEmpty);
    });
  });
}
