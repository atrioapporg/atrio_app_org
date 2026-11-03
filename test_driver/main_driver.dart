// Entrypoint de pruebas automatizadas (solo debug / profile).
// Habilita la extensión de Flutter Driver para que un agente (Dart MCP
// `flutter_driver_command`) pueda controlar Atrio en un dispositivo real
// sin necesidad de WebDriverAgent ni Xcode.
//
// Ejecutar en el iPhone:
//   xcross flutter run --target test_driver/main_driver.dart
import 'package:atrio/main.dart' as app;
import 'package:flutter_driver/driver_extension.dart';

Future<void> main() async {
  // disableTextEntryEmulation: false permite que aparezca el teclado nativo de iOS
  // cuando tocas la pantalla manualmente, sin perder el control por Flutter Driver.
  enableFlutterDriverExtension(enableTextEntryEmulation: false);
  await app.main();
}

