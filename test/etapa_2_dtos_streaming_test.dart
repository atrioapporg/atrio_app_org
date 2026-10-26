import 'package:flutter_test/flutter_test.dart';
import 'package:atrio/models/event_dto.dart';
import 'package:atrio/models/sermon_dto.dart';
import 'package:atrio/utils/youtube_helper.dart';

void main() {
  group('Etapa 2 - YoutubeHelper Tests', () {
    const expectedId = 'uE53d7_-Unc';

    test('Extrae ID correctamente desde URL estándar de YouTube', () {
      expect(
        YoutubeHelper.extractId('https://www.youtube.com/watch?v=$expectedId'),
        equals(expectedId),
      );
      expect(
        YoutubeHelper.extractId('http://youtube.com/watch?v=$expectedId'),
        equals(expectedId),
      );
    });

    test('Extrae ID correctamente con parámetros adicionales y marcas de tiempo', () {
      expect(
        YoutubeHelper.extractId(
          'https://www.youtube.com/watch?v=$expectedId&t=45s&feature=shared',
        ),
        equals(expectedId),
      );
      expect(
        YoutubeHelper.extractId(
          'https://www.youtube.com/watch?feature=shared&v=$expectedId',
        ),
        equals(expectedId),
      );
    });

    test('Extrae ID correctamente desde enlace corto youtu.be', () {
      expect(
        YoutubeHelper.extractId('https://youtu.be/$expectedId'),
        equals(expectedId),
      );
      expect(
        YoutubeHelper.extractId('https://youtu.be/$expectedId?t=10'),
        equals(expectedId),
      );
    });

    test('Extrae ID correctamente desde URLs de transmisión en vivo (/live/)', () {
      expect(
        YoutubeHelper.extractId('https://www.youtube.com/live/$expectedId'),
        equals(expectedId),
      );
      expect(
        YoutubeHelper.extractId('https://youtube.com/live/$expectedId?si=xyz123'),
        equals(expectedId),
      );
    });

    test('Extrae ID correctamente desde URLs móviles y embebidas (/embed/ y shorts)', () {
      expect(
        YoutubeHelper.extractId('https://m.youtube.com/watch?v=$expectedId'),
        equals(expectedId),
      );
      expect(
        YoutubeHelper.extractId('https://www.youtube.com/embed/$expectedId'),
        equals(expectedId),
      );
      expect(
        YoutubeHelper.extractId('https://www.youtube.com/shorts/$expectedId'),
        equals(expectedId),
      );
    });

    test('Reconoce un ID directo de 11 caracteres sin protocolo', () {
      expect(YoutubeHelper.extractId(expectedId), equals(expectedId));
      expect(YoutubeHelper.isValidYoutubeUrlOrId(expectedId), isTrue);
    });

    test('Retorna null ante URLs inválidas o entradas corruptas', () {
      expect(YoutubeHelper.extractId(null), isNull);
      expect(YoutubeHelper.extractId(''), isNull);
      expect(YoutubeHelper.extractId('    '), isNull);
      expect(YoutubeHelper.extractId('https://google.com'), isNull);
      expect(YoutubeHelper.extractId('https://vimeo.com/987654321'), isNull);
      expect(YoutubeHelper.extractId('short_id'), isNull);
    });

    test('Detecta adecuadamente plataformas de streaming', () {
      expect(
        YoutubeHelper.detectPlatform('https://www.youtube.com/watch?v=$expectedId'),
        equals(StreamingPlatform.youtube),
      );
      expect(
        YoutubeHelper.detectPlatform('https://vimeo.com/987654321'),
        equals(StreamingPlatform.vimeo),
      );
      expect(
        YoutubeHelper.detectPlatform('https://servidor.com/live/stream.m3u8'),
        equals(StreamingPlatform.hlsDirect),
      );
    });

    test('Construye URLs de miniaturas y vistas correctamente', () {
      final thumb = YoutubeHelper.buildThumbnailUrl(expectedId);
      expect(thumb, contains('img.youtube.com/vi/$expectedId/maxresdefault.jpg'));

      final watch = YoutubeHelper.buildWatchUrl(expectedId);
      expect(watch, equals('https://www.youtube.com/watch?v=$expectedId'));

      final embed = YoutubeHelper.buildEmbedUrl(expectedId, autoPlay: true);
      expect(embed, equals('https://www.youtube.com/embed/$expectedId?autoplay=1'));
    });
  });

  group('Etapa 2 - EventDto Tests', () {
    final now = DateTime(2026, 10, 25, 10, 0, 0);

    test('Serialización y Deserialización completa compatible con Odoo 19', () {
      final jsonOdoo = {
        'id': 42,
        'name': 'Gran Culto de Avivamiento',
        'description': 'Servicio especial conmemorativo de adoración e intercesión.',
        'date_begin': '2026-10-25T10:00:00.000Z',
        'date_end': '2026-10-25T12:00:00.000Z',
        'modalidad': 'hibrido',
        'stream_url': 'https://www.youtube.com/live/uE53d7_-Unc',
        'seats_max': 250,
        'seats_reserved': 180,
        'is_featured': true,
        'organizer': 'Pastor Carlos Gómez',
        'category': 'Adoración',
        'location': 'Auditorio Principal',
        'cover_url': '/atrio/portal/api/image/atrio.event/42/cover_image',
      };

      final dto = EventDto.fromJson(jsonOdoo);

      expect(dto.id, equals(42));
      expect(dto.titulo, equals('Gran Culto de Avivamiento'));
      expect(dto.modalidad, equals(EventModality.hibrido));
      expect(dto.tieneStreaming, isTrue);
      expect(dto.enlaceUbicacionOStream, equals('https://www.youtube.com/live/uE53d7_-Unc'));
      expect(dto.cupoMaximo, equals(250));
      expect(dto.cupoReservado, equals(180));
      expect(dto.porcentajeOcupacion, closeTo(0.72, 0.01));
      expect(dto.tieneCupoDisponible, isTrue);
      expect(dto.esDestacado, isTrue);
      expect(dto.coverUrl, startsWith('https://atrioapp.odoo19rd.com'));

      final jsonOutput = dto.toJson();
      expect(jsonOutput['name'], equals('Gran Culto de Avivamiento'));
      expect(jsonOutput['title'], equals('Gran Culto de Avivamiento'));
      expect(jsonOutput['date'], isNotNull);
      expect(jsonOutput['date_begin'], isNotNull);
      expect(jsonOutput['time'], isA<double>());
      expect(jsonOutput['time_label'], isNotNull);
      expect(jsonOutput['place'], equals('Auditorio Principal'));
      expect(jsonOutput['max_capacity'], equals(250));
      expect(jsonOutput['modalidad'], equals('hibrido'));
      expect(jsonOutput['stream_url'], equals('https://www.youtube.com/live/uE53d7_-Unc'));
      expect(jsonOutput['seats_max'], equals(250));
      expect(jsonOutput['allow_registration'], isTrue);
    });

    test('Inmutabilidad y copyWith en EventDto', () {
      final dtoOriginal = EventDto(
        titulo: 'Vigilia Juvenil',
        descripcion: 'Noche de búsqueda espiritual',
        fechaInicio: now,
        fechaFin: now.add(const Duration(hours: 4)),
        modalidad: EventModality.presencial,
        cupoMaximo: 100,
      );

      final dtoModificado = dtoOriginal.copyWith(
        modalidad: EventModality.virtual,
        enlaceUbicacionOStream: 'https://youtu.be/uE53d7_-Unc',
        imagenPortadaBase64: 'BASE64_DATA',
      );

      expect(dtoOriginal.modalidad, equals(EventModality.presencial));
      expect(dtoOriginal.tieneStreaming, isFalse);
      expect(dtoModificado.modalidad, equals(EventModality.virtual));
      expect(dtoModificado.tieneStreaming, isTrue);
      expect(dtoModificado.imagenPortadaBase64, equals('BASE64_DATA'));
    });
  });

  group('Etapa 2 - SermonDto Tests', () {
    test('Serialización y deserialización de Prédica y Streaming en Vivo', () {
      final jsonSermon = {
        'id': 105,
        'title': 'Caminando sobre las Aguas',
        'speaker': 'Pastor Andrés Morales',
        'date': '2026-10-25T11:00:00.000Z',
        'is_live': true,
        'platform': 'youtube',
        'video_url': 'https://www.youtube.com/watch?v=uE53d7_-Unc',
        'content': 'Mensaje sobre cómo vencer el miedo en tiempos de tormenta.',
        'category': 'Prédicas',
        'pinned': true,
        'church_name': 'Iglesia Central ATRIO',
      };

      final sermon = SermonDto.fromJson(jsonSermon);

      expect(sermon.id, equals(105));
      expect(sermon.titulo, equals('Caminando sobre las Aguas'));
      expect(sermon.predicador, equals('Pastor Andrés Morales'));
      expect(sermon.esEnVivo, isTrue);
      expect(sermon.esYoutube, isTrue);
      expect(sermon.youtubeId, equals('uE53d7_-Unc'));
      expect(sermon.miniaturaEfectiva, contains('uE53d7_-Unc/maxresdefault.jpg'));
      expect(sermon.fijado, isTrue);

      final payloadOdoo = sermon.toJson();
      expect(payloadOdoo['title'], equals('Caminando sobre las Aguas'));
      expect(payloadOdoo['is_live'], isTrue);
      expect(payloadOdoo['platform'], equals('youtube'));
      expect(payloadOdoo['video_url'], equals('https://www.youtube.com/watch?v=uE53d7_-Unc'));
      expect(payloadOdoo['action'], equals('publish'));
    });

    test('Autodetección de miniatura en SermonDto con ID directo', () {
      final sermon = SermonDto(
        titulo: 'Alabanza y Adoración',
        predicador: 'Ministerio de Música',
        fecha: DateTime.now(),
        urlOIdVideo: 'uE53d7_-Unc',
        esEnVivo: false,
      );

      expect(sermon.youtubeId, equals('uE53d7_-Unc'));
      expect(sermon.esYoutube, isTrue);
      expect(sermon.miniaturaEfectiva, contains('uE53d7_-Unc/maxresdefault.jpg'));
    });
  });
}
