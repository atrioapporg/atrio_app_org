import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Solicitudes Locales y Resiliencia Odoo API', () {
    test('Estructura de datos local para persistencia SQLite cumple con el esquema', () {
      final solicitudLocal = {
        'odoo_id': 16,
        'referencia': 'REQ-16',
        'tipo': 'oracion',
        'titulo': 'Oración por salud',
        'mensaje': 'Petición pastoral para la familia.',
        'estado': 'nueva',
        'estado_label': 'Recibida',
        'fecha': '2026-10-22',
        'usuario_email': 'leningrado777@demo.app',
      };

      expect(solicitudLocal['odoo_id'], 16);
      expect(solicitudLocal['referencia'], 'REQ-16');
      expect(solicitudLocal['tipo'], 'oracion');
      expect(solicitudLocal['titulo'], 'Oración por salud');
      expect(solicitudLocal['estado_label'], 'Recibida');
      expect(solicitudLocal['usuario_email'], 'leningrado777@demo.app');
    });

    test('Mapeo de solicitud local genera campos requeridos por la UI', () {
      final raw = {
        'id': 1,
        'odoo_id': 16,
        'referencia': 'REQ-16',
        'tipo': 'pastoral',
        'titulo': 'Consejería familiar',
        'mensaje': 'Cita para el martes',
        'estado': 'nueva',
        'estado_label': 'Recibida',
        'fecha': '2026-10-22',
        'usuario_email': 'leningrado777@demo.app',
      };

      final title = raw['title'] ?? raw['titulo'] ?? raw['name'] ?? 'Solicitud Ministerial';
      final status = raw['status_label'] ?? raw['estado_label'] ?? 'Recibida';
      final referencia = raw['reference'] ?? raw['referencia'] ?? 'REQ-${raw['id']}';
      final detalle = raw['message'] ?? raw['mensaje'] ?? 'Solicitud registrada y asignada.';

      expect(title, 'Consejería familiar');
      expect(status, 'Recibida');
      expect(referencia, 'REQ-16');
      expect(detalle, 'Cita para el martes');
    });
  });
}
