import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModalOtroMonto {
  static Future<int?> mostrar(BuildContext context) {
    // Cálculo estricto de dimensiones dinámicas relativas
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color grisBorde = Color(0xFFE8ECEF);

    final TextEditingController controller = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    return showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
          ),
          title: Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                color: azulFondo,
                size: screenWidth * 0.06,
              ),
              SizedBox(width: screenWidth * 0.02),
              Text(
                'Monto personalizado',
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: screenWidth * 0.85,
            child: Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.04,
                ),
                decoration: InputDecoration(
                  labelText: 'Monto a donar (RD\$)',
                  labelStyle: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: screenWidth * 0.035,
                  ),
                  prefixIcon: Icon(
                    Icons.attach_money_rounded,
                    color: azulFondo,
                    size: screenWidth * 0.05,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    borderSide: const BorderSide(color: grisBorde),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    borderSide: const BorderSide(color: azulFondo, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    borderSide: const BorderSide(color: Colors.red, width: 1.0),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un monto';
                  }
                  final intMonto = int.tryParse(value);
                  if (intMonto == null) return 'Monto inválido';
                  if (intMonto < 500) return 'El mínimo es RD\$500';
                  if (intMonto > 1000000) return 'El máximo es RD\$1,000,000';
                  return null;
                },
              ),
            ),
          ),
          actionsPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: usableHeight * 0.015,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: amarilloOro,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: usableHeight * 0.012,
                ),
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  // Cierra el dialog y envía el valor de vuelta
                  Navigator.pop(ctx, int.parse(controller.text.trim()));
                }
              },
              child: Text(
                'Confirmar',
                style: TextStyle(
                  fontSize: screenWidth * 0.036,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
