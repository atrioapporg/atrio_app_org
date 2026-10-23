import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper de prueba para verificar la lógica de mapeo de donaciones de Odoo 19
Map<String, dynamic> mapearDonacionOdoo(Map<String, dynamic> m) {
  final rawAmount = m['amount'] ?? m['monto'] ?? 0.0;
  final currency = (m['currency'] ?? 'DOP').toString().toUpperCase();
  final state = (m['state'] ?? m['status'] ?? '').toString().toLowerCase().trim();
  final stateLabel = m['state_label']?.toString();

  String statusText;
  Color statusColor;
  IconData icon;
  Color iconColor;

  if (state == 'processed' ||
      state == 'procesada' ||
      state == 'approved' ||
      state == 'aprobada' ||
      state == 'completed' ||
      state == 'completada' ||
      state == 'done') {
    statusColor = const Color(0xFF2E7D32); // Verde Odoo
    statusText = stateLabel ?? 'Procesada';
    icon = Icons.check_circle_outline_rounded;
    iconColor = const Color(0xFF2E7D32);
  } else if (state == 'pending' ||
      state == 'pendiente' ||
      state == 'draft' ||
      state == 'borrador') {
    statusColor = const Color(0xFFE5A023); // Amarillo/Ámbar Odoo
    statusText = stateLabel ?? 'Pendiente';
    icon = Icons.hourglass_top_rounded;
    iconColor = const Color(0xFFE5A023);
  } else if (state == 'rejected' ||
      state == 'denied' ||
      state == 'rechazada' ||
      state == 'denegada' ||
      state == 'cancelled' ||
      state == 'cancelada') {
    statusColor = const Color(0xFFC62828); // Rojo
    statusText = stateLabel ?? 'Denegada';
    icon = Icons.cancel_outlined;
    iconColor = const Color(0xFFC62828);
  } else {
    statusColor = const Color(0xFF0055A5); // Azul
    statusText = stateLabel ?? (state.isNotEmpty ? state : 'En proceso');
    icon = Icons.favorite_border_rounded;
    iconColor = const Color(0xFF0055A5);
  }

  double numAmount = 0.0;
  if (rawAmount is num) {
    numAmount = rawAmount.toDouble();
  } else if (rawAmount is String) {
    numAmount = double.tryParse(rawAmount) ?? 0.0;
  }
  final partes = numAmount.toStringAsFixed(2).split('.');
  final entero = partes[0].replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match match) => '${match[1]},',
  );
  final montoFormateado = '$currency $entero.${partes[1]}';

  final rawDate = m['date'] ?? m['create_date'] ?? m['fecha'];
  String fechaCorta = 'Reciente';
  String fechaCompleta = 'Reciente';
  if (rawDate != null) {
    try {
      final dt = DateTime.parse(rawDate.toString()).toLocal();
      const meses = [
        'ene', 'feb', 'mar', 'abr', 'may', 'jun',
        'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
      ];
      final mes = meses[dt.month - 1];
      final hora = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final ampm = dt.hour >= 12 ? 'p.m.' : 'a.m.';
      final min = dt.minute.toString().padLeft(2, '0');
      fechaCorta = '${dt.day} $mes ${dt.year}';
      fechaCompleta = '${dt.day} de $mes de ${dt.year}, $hora:$min $ampm';
    } catch (_) {
      fechaCorta = rawDate.toString().split('T').first;
      fechaCompleta = rawDate.toString();
    }
  }

  final rawMethod = (m['payment_method'] ?? '').toString().toLowerCase();
  String metodoLabel = m['payment_method_label']?.toString() ?? '';
  if (metodoLabel.isEmpty) {
    if (rawMethod.contains('transfer')) {
      metodoLabel = 'Transferencia bancaria';
    } else if (rawMethod.contains('paypal')) {
      metodoLabel = 'PayPal';
    } else {
      metodoLabel = 'Transferencia / Online';
    }
  }

  final String ref = m['reference']?.toString() ??
      (m['id'] != null ? 'DON-${m['id']}' : 'DON-0000');

  final String titulo = m['name']?.toString() ??
      m['title']?.toString() ??
      'Aporte ($metodoLabel)';

  return {
    'title': titulo,
    'monto': montoFormateado,
    'status': statusText,
    'statusColor': statusColor,
    'state': state,
    'dateInfo': fechaCorta,
    'fechaCompleta': fechaCompleta,
    'icon': icon,
    'iconColor': iconColor,
    'referencia': ref,
    'metodoPago': metodoLabel,
  };
}

void main() {
  group('Mapeo y Normalización de Donaciones Odoo 19', () {
    test('Donación con state "processed" se mapea a "Procesada" y color verde', () {
      final odooPayload = {
        'id': 17,
        'date': '2026-10-22T23:49:19Z',
        'amount': 55777.0,
        'currency': 'DOP',
        'payment_method': 'transfer',
        'payment_method_label': 'Transferencia bancaria',
        'state': 'processed',
        'state_label': 'Procesada',
        'reference': 'APP-1792712959083',
      };

      final res = mapearDonacionOdoo(odooPayload);
      expect(res['status'], 'Procesada');
      expect(res['statusColor'], const Color(0xFF2E7D32));
      expect(res['monto'], 'DOP 55,777.00');
      expect(res['referencia'], 'APP-1792712959083');
      expect(res['metodoPago'], 'Transferencia bancaria');
      expect(res['title'], 'Aporte (Transferencia bancaria)');
      expect(res['dateInfo'], contains('2026'));
    });

    test('Donación con state "pending" se mapea a "Pendiente" y color ámbar', () {
      final odooPayload = {
        'id': 18,
        'date': '2026-10-23T01:00:00Z',
        'amount': 1000.0,
        'currency': 'DOP',
        'payment_method': 'transfer',
        'state': 'pending',
        'state_label': 'Pendiente',
        'reference': 'APP-1792785456244',
      };

      final res = mapearDonacionOdoo(odooPayload);
      expect(res['status'], 'Pendiente');
      expect(res['statusColor'], const Color(0xFFE5A023));
      expect(res['monto'], 'DOP 1,000.00');
    });

    test('Donación con state "rejected" se mapea a "Denegada" y color rojo', () {
      final odooPayload = {
        'id': 19,
        'date': '2026-10-23T01:00:00Z',
        'amount': 500.0,
        'currency': 'DOP',
        'payment_method': 'transfer',
        'state': 'rejected',
        'reference': 'APP-REJECTED-01',
      };

      final res = mapearDonacionOdoo(odooPayload);
      expect(res['status'], 'Denegada');
      expect(res['statusColor'], const Color(0xFFC62828));
    });
  });
}
