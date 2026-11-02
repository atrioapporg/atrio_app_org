import 'dart:io';
import 'package:pdf/widgets.dart' as pw;

void main() {
  final qrCode = pw.Barcode.qrCode();
  const url = 'https://atrioapp.odoo19rd.com/c/935e11a7-98be-40c5-8ea8-14daa04277c5';
  
  // Generar representación SVG del QR real
  final svg = qrCode.toSvg(
    url,
    width: 300,
    height: 300,
  );

  final artifactDir = r'C:\Users\LEYAN\.gemini\antigravity-ide\brain\55ef3b44-d0f7-4525-b350-183b68f098fd';
  
  // Guardar archivo SVG
  final svgFile = File('$artifactDir\\qr_real_parroquia.svg');
  svgFile.writeAsStringSync(svg);

  // Crear archivo HTML para abrir y visualizar en pantalla grande
  final html = '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>Código QR Real - Parroquia San Pedro Nolasco</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      background: #072B4F;
      color: white;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      padding: 20px;
    }
    .card {
      background: white;
      color: #072B4F;
      padding: 30px;
      border-radius: 20px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.5);
      text-align: center;
      max-width: 400px;
    }
    h1 { margin: 0 0 10px; font-size: 24px; color: #072B4F; }
    h2 { margin: 0 0 20px; font-size: 15px; color: #E5A023; }
    .qr-box {
      border: 4px solid #E5A023;
      border-radius: 16px;
      padding: 15px;
      display: inline-block;
      background: white;
    }
    p { margin: 15px 0 5px; font-size: 13px; color: #64748B; }
    .url { font-family: monospace; font-size: 11px; word-break: break-all; color: #0284C7; }
  </style>
</head>
<body>
  <div class="card">
    <h1>ATRIO</h1>
    <h2>Parroquia San Pedro Nolasco</h2>
    <div class="qr-box">
      $svg
    </div>
    <p>Apunta la cámara de tu iPhone o Samsung Galaxy S9 directamente a este recuadro:</p>
    <div class="url">$url</div>
  </div>
</body>
</html>
''';

  final htmlFile = File('$artifactDir\\qr_real_prueba.html');
  htmlFile.writeAsStringSync(html);

  print('SVG generado en: ${svgFile.path}');
  print('HTML generado en: ${htmlFile.path}');
}
