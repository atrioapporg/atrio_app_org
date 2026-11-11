import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/widgets/church_qr_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 1x1 transparent PNG bytes for testing
  final Uint8List dummyPngBytes = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
    0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
    0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x60, 0x60, 0x60, 0x60,
    0x00, 0x00, 0x00, 0x05, 0x00, 0x01, 0xa7, 0x3d, 0x4c, 0x3d, 0x00, 0x00,
    0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
  ]);

  group('ChurchQrDialog - Botones de compartir WhatsApp y Correo', () {
    testWidgets('Muestra botones de WhatsApp y Correo encima del botón copiar enlace',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('es'),
          home: Scaffold(
            body: ChurchQrDialog(
              churchName: 'Parroquia San Pedro',
              denomination: 'Católica',
              qrBytes: dummyPngBytes,
              joinUrl: 'https://atrioapp.odoo19rd.com/join/18',
              azulFondo: const Color(0xFF072B4F),
              amarilloOro: const Color(0xFFE5A023),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar que los botones existen
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Correo'), findsOneWidget);
      expect(find.byType(FaIcon), findsOneWidget);
      expect(find.byIcon(Icons.mail_outline_rounded), findsOneWidget);
      expect(find.text('Copiar enlace de invitación'), findsOneWidget);

      // Verificar orden vertical: los botones de compartir están por encima de 'Copiar enlace de invitación'
      final whatsappTop = tester.getTopLeft(find.text('WhatsApp')).dy;
      final copyTop = tester.getTopLeft(find.text('Copiar enlace de invitación')).dy;

      expect(whatsappTop < copyTop, isTrue,
          reason: 'Los botones de compartir deben ubicarse encima del botón Copiar enlace');
    });

    testWidgets('Muestra textos en inglés correctamente cuando el locale es en',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: ChurchQrDialog(
              churchName: 'Saint Peter Church',
              denomination: 'Catholic',
              qrBytes: dummyPngBytes,
              joinUrl: 'https://atrioapp.odoo19rd.com/join/18',
              azulFondo: const Color(0xFF072B4F),
              amarilloOro: const Color(0xFFE5A023),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Copy invite link'), findsOneWidget);
      expect(find.text('Share'), findsNWidgets(2));
    });
  });
}
