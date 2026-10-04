import 'package:flutter/material.dart';

import '../widgets/odoo_pago_dialog.dart';

class TestPagoScreen extends StatelessWidget {
  static const routeName = 'test_pago_screen';

  const TestPagoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      appBar: AppBar(
        title: const Text('Prueba de Pago Odoo'),
        backgroundColor: azulFondo,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: azulFondo,
              ),
              const SizedBox(height: 16),
              const Text(
                'Simulación de Transacción Odoo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: azulFondo,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Presiona el botón para disparar el flujo de prueba.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: amarilloOro,
                    foregroundColor: azulFondo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.payment_rounded),
                  label: const Text(
                    'Probar Modal de Pago',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    // Dispara el diálogo con datos falsos simulados
                    OdooPagoDialog.mostrarConfirmacionPago(
                      context: context,
                      concepto: 'Ofrenda Dominical (Prueba)',
                      monto: 'RD\$ 1,000.00',
                      metodoPago: 'Visa •••• 1234',
                      onConfirmado: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '¡Callback ejecutado! Transacción validada en la app.',
                            ),
                            backgroundColor: Color(0xFF2E7D32),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
