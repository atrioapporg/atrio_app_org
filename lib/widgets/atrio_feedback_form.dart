import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';

enum TipoFeedback {
  error('Bug / Error', Icons.bug_report_rounded, Color(0xFFD32F2F)),
  sugerencia('Sugerencia', Icons.lightbulb_rounded, Color(0xFFE5A023)),
  elogio('Elogio', Icons.favorite_rounded, Color(0xFF388E3C));

  final String label;
  final IconData icon;
  final Color color;
  const TipoFeedback(this.label, this.icon, this.color);
}

class AtrioFeedbackForm extends StatefulWidget {
  final OnSubmit onSubmit;
  final ScrollController? scrollController;

  const AtrioFeedbackForm({
    super.key,
    required this.onSubmit,
    this.scrollController,
  });

  @override
  State<AtrioFeedbackForm> createState() => _AtrioFeedbackFormState();
}

class _AtrioFeedbackFormState extends State<AtrioFeedbackForm> {
  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);

  TipoFeedback _tipoSeleccionado = TipoFeedback.error;
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _enviar() {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();

      final Map<String, dynamic> extras = {
        'tipo': _tipoSeleccionado.name,
        'label': _tipoSeleccionado.label,
        'titulo': _tituloController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'email': email.isNotEmpty ? email : 'No proporcionado',
      };

      final String feedbackText =
          '[${_tipoSeleccionado.label.toUpperCase()}] ${_tituloController.text.trim()}\n\n'
          '${_descripcionController.text.trim()}\n\n'
          'Contacto: ${email.isNotEmpty ? email : "Anónimo"}';

      widget.onSubmit(feedbackText, extras: extras);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Form(
        key: _formKey,
        child: ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shrinkWrap: true,
          children: [
            // Indicador de arrastre superior
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Selector de Categoría (Chips)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: TipoFeedback.values.map((tipo) {
                final isSelected = _tipoSeleccionado == tipo;
                return ChoiceChip(
                  avatar: Icon(
                    tipo.icon,
                    size: 16,
                    color: isSelected ? Colors.white : tipo.color,
                  ),
                  label: Text(
                    tipo.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : azulFondo,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: azulFondo,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? amarilloOro : Colors.grey.shade300,
                    ),
                  ),
                  onSelected: (_) => setState(() => _tipoSeleccionado = tipo),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            // Campo: Título / Resumen breve
            TextFormField(
              controller: _tituloController,
              maxLength: 80,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Título breve (ej. Error al reproducir audio)',
                counterText: '',
                prefixIcon: const Icon(Icons.title, color: azulFondo, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: amarilloOro, width: 2),
                ),
              ),
              validator: (val) =>
                  (val == null || val.trim().isEmpty) ? 'Ingresa un título' : null,
            ),
            const SizedBox(height: 8),

            // Campo: Descripción detallada
            TextFormField(
              controller: _descripcionController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Describe con más detalle lo que viste o deseas...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: amarilloOro, width: 2),
                ),
              ),
              validator: (val) =>
                  (val == null || val.trim().isEmpty) ? 'Ingresa una descripción' : null,
            ),
            const SizedBox(height: 8),

            // Campo: Correo Electrónico (Voluntario)
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Tu correo (opcional, para darte respuesta)',
                prefixIcon: const Icon(Icons.email_outlined,
                    color: azulFondo, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: amarilloOro, width: 2),
                ),
              ),
              validator: (val) {
                if (val != null && val.trim().isNotEmpty) {
                  final emailRegex =
                      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(val.trim())) {
                    return 'Ingresa un correo electrónico válido';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Botón de Envío
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulFondo,
                  foregroundColor: amarilloOro,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                onPressed: _enviar,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text(
                  'Enviar Feedback',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
