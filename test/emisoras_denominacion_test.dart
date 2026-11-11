import 'dart:convert';
import 'dart:typed_data';

import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/modelos/emisora_model.dart';
import 'package:atrio/screens/emisoras_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmisorasCatalogParser - Nueva columna denominación', () {
    test('Parsea correctamente la columna "denominacion" desde CSV de Google Sheets', () {
      const String csvContent = '''
"emisora_id","pais_codigo","pais","es_favorita","emisora_nombre","emisora_poster","emisora_url","idioma","denominacion"
"101","DO","República Dominicana","1","Radio Renuevo","https://logo.png","https://stream.audio/stream","es","Evangélica"
"102","DO","República Dominicana","0","Radio Católica","https://logo2.png","https://stream2.audio/stream","es","Católica"
"103","HN","Honduras","0","Radio Vida","https://logo3.png","https://stream3.audio/stream","es","Pentecostal"
"104","US","Estados Unidos","0","Air1","https://logo4.png","https://stream4.audio/stream","en",""
"105","CO","Colombia","0","Radio Desconocida","https://logo5.png","https://stream5.audio/stream","es","Desconocida"
''';

      final Uint8List bytes = Uint8List.fromList(utf8.encode(csvContent));
      final List<EmisoraModel> emisoras = EmisorasCatalogParser.parseCsvBytes(bytes);

      expect(emisoras.length, equals(5));

      expect(emisoras[0].denomination, equals('Evangélica'));
      expect(emisoras[0].denominacion, equals('Evangélica'));
      expect(emisoras[0].searchBlob, contains('evangelica'));

      expect(emisoras[1].denomination, equals('Católica'));
      expect(emisoras[1].searchBlob, contains('catolica'));

      expect(emisoras[2].denomination, equals('Pentecostal'));
      expect(emisoras[2].searchBlob, contains('pentecostal'));

      // Si está vacía o es 'Desconocida', se normaliza a 'Desconocida'
      expect(emisoras[3].denomination, equals('Desconocida'));
      expect(emisoras[4].denomination, equals('Desconocida'));
    });

    test('Parsea columna con tilde "denominación" correctamente', () {
      const String csvContent = '''
"emisora_id","pais_codigo","pais","es_favorita","emisora_nombre","emisora_poster","emisora_url","idioma","denominación"
"201","DO","República Dominicana","0","Radio Adventista","https://logo.png","https://stream.audio/stream","es","Adventista"
"202","CO","Colombia","0","Radio Bautista","https://logo.png","https://stream.audio/stream","es","Bautista"
"203","AR","Argentina","0","Radio Reformada","https://logo.png","https://stream.audio/stream","es","Reformada"
''';

      final Uint8List bytes = Uint8List.fromList(utf8.encode(csvContent));
      final List<EmisoraModel> emisoras = EmisorasCatalogParser.parseCsvBytes(bytes);

      expect(emisoras.length, equals(3));
      expect(emisoras[0].denomination, equals('Adventista'));
      expect(emisoras[1].denomination, equals('Bautista'));
      expect(emisoras[2].denomination, equals('Reformada'));
    });
  });

  group('EmisorasScreen - Helpers y Localización de Denominación', () {
    testWidgets('Traduce nombres de denominación en español e inglés sin textos hardcodeados', (WidgetTester tester) async {
      late AppLocalizations l10nEs;
      late AppLocalizations l10nEn;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Builder(
            builder: (context) {
              l10nEs = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              l10nEn = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Español
      expect(
        EmisorasScreen.obtenerNombreDenominacion('TODOS', l10nEs),
        equals('Todas'),
      );
      expect(
        EmisorasScreen.obtenerNombreDenominacion('Evangélica', l10nEs),
        equals('Evangélica'),
      );
      expect(
        EmisorasScreen.obtenerNombreDenominacion('Católica', l10nEs),
        equals('Católica'),
      );
      expect(
        EmisorasScreen.obtenerNombreDenominacion('Pentecostal', l10nEs),
        equals('Pentecostal'),
      );
      expect(
        EmisorasScreen.obtenerNombreDenominacion('Adventista', l10nEs),
        equals('Adventista'),
      );
      expect(
        EmisorasScreen.obtenerNombreDenominacion('Bautista', l10nEs),
        equals('Bautista'),
      );
      expect(
        EmisorasScreen.obtenerNombreDenominacion('Reformada', l10nEs),
        equals('Reformada'),
      );
      expect(
        EmisorasScreen.obtenerNombreDenominacion('OTRAS', l10nEs),
        equals('Otras'),
      );

      // English
      expect(
        EmisorasScreen.obtenerNombreDenominacion('TODOS', l10nEn),
        equals('All'),
      );
      expect(
        EmisorasScreen.obtenerNombreDenominacion('Evangélica', l10nEn),
        equals('Evangelical'),
      );
      expect(
        EmisorasScreen.obtenerNombreDenominacion('Católica', l10nEn),
        equals('Catholic'),
      );
      expect(
        EmisorasScreen.obtenerNombreDenominacion('Adventista', l10nEn),
        equals('Adventist'),
      );
      expect(
        EmisorasScreen.obtenerNombreDenominacion('OTRAS', l10nEn),
        equals('Other'),
      );
    });

    test('Retorna iconos contextuales apropiados para cada denominación', () {
      expect(
        EmisorasScreen.obtenerIconoDenominacion('TODOS'),
        equals(Icons.radio_rounded),
      );
      expect(
        EmisorasScreen.obtenerIconoDenominacion('Católica'),
        equals(Icons.church_rounded),
      );
      expect(
        EmisorasScreen.obtenerIconoDenominacion('Evangélica'),
        equals(Icons.menu_book_rounded),
      );
      expect(
        EmisorasScreen.obtenerIconoDenominacion('Pentecostal'),
        equals(Icons.local_fire_department_rounded),
      );
      expect(
        EmisorasScreen.obtenerIconoDenominacion('Adventista'),
        equals(Icons.wb_sunny_outlined),
      );
      expect(
        EmisorasScreen.obtenerIconoDenominacion('Bautista'),
        equals(Icons.water_drop_outlined),
      );
      expect(
        EmisorasScreen.obtenerIconoDenominacion('Reformada'),
        equals(Icons.history_edu_rounded),
      );
      expect(
        EmisorasScreen.obtenerIconoDenominacion('OTRAS'),
        equals(Icons.auto_awesome_outlined),
      );
    });
  });
}
