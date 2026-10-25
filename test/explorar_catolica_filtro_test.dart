import 'package:flutter_test/flutter_test.dart';
import 'package:atrio/providers/explorar_provider.dart';
import 'package:atrio/modelos/iglesia_explorar_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

void main() {
  group('ExplorarProvider - Filtro Inclusivo Católico', () {
    test('terminosEclesiasticosCatolicos contiene la jerarquía institucional requerida', () {
      final terminos = ExplorarProvider.terminosEclesiasticosCatolicos;
      expect(terminos, contains('iglesia'));
      expect(terminos, contains('parroquia'));
      expect(terminos, contains('capilla'));
      expect(terminos, contains('catedral'));
      expect(terminos, contains('santuario'));
      expect(terminos, contains('basílica'));
    });

    test('esLugarCatolico identifica correctamente templos con nombres católicos', () {
      expect(
        ExplorarProvider.esLugarCatolico('Parroquia Nuestra Señora del Amparo'),
        isTrue,
      );
      expect(
        ExplorarProvider.esLugarCatolico('Catedral Primada de América'),
        isTrue,
      );
      expect(
        ExplorarProvider.esLugarCatolico('Capilla San José'),
        isTrue,
      );
      expect(
        ExplorarProvider.esLugarCatolico('Santuario Nuestra Señora de la Altagracia'),
        isTrue,
      );
      expect(
        ExplorarProvider.esLugarCatolico('Basílica Catedral Nuestra Señora de la Altagracia'),
        isTrue,
      );
      expect(
        ExplorarProvider.esLugarCatolico('Centro Cristiano Monte de Dios'),
        isFalse,
      );
    });

    test('contieneTerminoEnNombre incluye parroquias, capillas y catedrales al filtrar por fe católica', () {
      // 1: Católica
      expect(
        ExplorarProvider.contieneTerminoEnNombre(
          'Parroquia Nuestra Señora del Amparo',
          'iglesia',
          filtroDenominacionIndex: 1,
        ),
        isTrue,
      );

      expect(
        ExplorarProvider.contieneTerminoEnNombre(
          'Parroquia Nuestra Señora del Amparo',
          'amparo',
          filtroDenominacionIndex: 1,
        ),
        isTrue,
      );

      expect(
        ExplorarProvider.contieneTerminoEnNombre(
          'Catedral Santa Ana',
          'catedral',
          filtroDenominacionIndex: 1,
        ),
        isTrue,
      );

      expect(
        ExplorarProvider.contieneTerminoEnNombre(
          'Capilla Divino Niño',
          'capilla',
          filtroDenominacionIndex: 1,
        ),
        isTrue,
      );

      expect(
        ExplorarProvider.contieneTerminoEnNombre(
          'Santuario Nacional San Cristóbal',
          'santuario',
          filtroDenominacionIndex: 1,
        ),
        isTrue,
      );
    });

    test('IglesiaExplorarModel.fromPlacesApi cataloga denominación como Católica si el nombre o dirección es eclesiástico', () {
      final placeParroquia = {
        'id': 'place_123',
        'displayName': {'text': 'Parroquia Nuestra Señora del Amparo'},
        'formattedAddress': 'Calle Principal 10, Santo Domingo, República Dominicana',
        'location': {'latitude': 18.4861, 'longitude': -69.9312},
        'rating': 4.8,
        'userRatingCount': 120,
      };

      final model = IglesiaExplorarModel.fromPlacesApi(
        placeParroquia,
        Position(
          longitude: -69.9312,
          latitude: 18.4861,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 10.0,
          altitudeAccuracy: 1.0,
          heading: 0.0,
          headingAccuracy: 1.0,
          speed: 0.0,
          speedAccuracy: 1.0,
        ),
        const Color(0xFF072B4F),
      );

      expect(model.nombre, 'Parroquia Nuestra Señora del Amparo');
      expect(model.denominacion, 'Católica');
    });

    test('esLugarCatolico rechaza iglesias no católicas aunque contengan la palabra iglesia', () {
      expect(
        ExplorarProvider.esLugarCatolico('Iglesia Bautista Central'),
        isFalse,
      );
      expect(
        ExplorarProvider.esLugarCatolico('Iglesia Pentecostal de Jesucristo'),
        isFalse,
      );
      expect(
        ExplorarProvider.esLugarCatolico('Iglesia Adventista del Séptimo Día'),
        isFalse,
      );
      expect(
        ExplorarProvider.esLugarCatolico('Iglesia Cristiana Evangélica'),
        isFalse,
      );
    });

    test('cumpleFiltroDenominacion aprueba Parroquia Nuestra Señora del Amparo en filtro Católico', () {
      final provider = ExplorarProvider();
      provider.cambiarDenominacion(1, recargar: false);

      final amparo = IglesiaExplorarModel(
        id: 'amparo_1',
        nombre: 'Parroquia Nuestra Señora del Amparo',
        denominacion: 'Católica',
        direccion: 'Calle Juan Pablo Duarte, Santo Domingo',
        distanciaKm: 0.8,
        rating: 4.6,
        totalResenas: 123,
        colorHex: '#072B4F',
      );

      expect(provider.cumpleFiltroDenominacion(amparo), isTrue);

      final bautista = IglesiaExplorarModel(
        id: 'bautista_1',
        nombre: 'Iglesia Bautista El Redentor',
        denominacion: 'Bautista',
        direccion: 'Av. Jacobo Majluta, Santo Domingo',
        distanciaKm: 1.2,
        rating: 4.5,
        totalResenas: 30,
        colorHex: '#072B4F',
      );

      expect(provider.cumpleFiltroDenominacion(bautista), isFalse);
    });

    test('cambiarDenominacion a 1 (Católica) sincroniza el estado de filtro correctamente', () {
      final provider = ExplorarProvider();
      expect(provider.filtroDenominacionIndex, 0);

      provider.cambiarDenominacion(1, recargar: false);
      expect(provider.filtroDenominacionIndex, 1);
    });
  });
}
