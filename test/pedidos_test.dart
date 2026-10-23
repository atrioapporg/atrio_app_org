import 'package:flutter_test/flutter_test.dart';
import 'package:atrio/modelos/pedido_model.dart';

void main() {
  group('Pruebas de PedidoModel y Sincronización Odoo 19', () {
    test('Deserializa correctamente pedido de Odoo 19 con status "payment_review"', () {
      final json = {
        'id': 9,
        'name': 'S00009',
        'date_order': '2026-10-23T02:51:55Z',
        'amount_total': 7640.0,
        'currency': {'code': 'DOP', 'symbol': 'RD\$', 'position': 'before'},
        'status': 'payment_review',
        'status_label': 'Pago en verificación',
        'status_color': 'orange',
        'item_count': 4,
        'items': [
          {'name': 'Adoración', 'quantity': 2.0},
          {'name': 'Bolsa de tela "Luz en el camino"', 'quantity': 2.0},
          {'name': 'Paquete Hogar', 'quantity': 2.0},
        ],
        'portal_url': 'http://atrioapp.odoo19rd.com/my/orders/9?access_token=token123',
      };

      final pedido = PedidoModel.fromJson(json);

      expect(pedido.id, 9);
      expect(pedido.nombre, 'S00009');
      expect(pedido.total, 7640.0);
      expect(pedido.simboloMoneda, 'RD\$');
      expect(pedido.totalFormateado, 'RD\$ 7,640.00');
      expect(pedido.estado, 'payment_review');
      expect(pedido.estadoEtiqueta, 'Pago en verificación');
      expect(pedido.colorEstado, 'orange');
      expect(pedido.items.length, 3);
      expect(pedido.items.first.nombre, 'Adoración');
      expect(pedido.items.first.cantidad, 2.0);
      expect(pedido.portalUrl, 'http://atrioapp.odoo19rd.com/my/orders/9?access_token=token123');
      expect(pedido.fechaFormateada, contains('2026'));
    });

    test('Maneja datos mínimos y fallbacks seguros', () {
      final json = <String, dynamic>{
        'id': '15',
        'total': '1500.50',
      };

      final pedido = PedidoModel.fromJson(json);
      expect(pedido.id, 15);
      expect(pedido.total, 1500.50);
      expect(pedido.nombre, 'S00000');
      expect(pedido.estado, 'draft');
      expect(pedido.estadoEtiqueta, 'Pendiente');
    });
  });
}
