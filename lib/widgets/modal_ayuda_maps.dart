import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ajustes_provider.dart';
import '../providers/recomendacion_iglesia_provider.dart';

/// Modal BottomSheet de alta fidelidad UI/UX para reportar una iglesia que no aparece en Google Maps (POST /churches/maps-help).
class ModalAyudaMaps extends StatefulWidget {
  final ValueChanged<int>? onSuccess;

  const ModalAyudaMaps({super.key, this.onSuccess});

  static Future<void> show(
    BuildContext context, {
    ValueChanged<int>? onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ModalAyudaMaps(onSuccess: onSuccess),
    );
  }

  @override
  State<ModalAyudaMaps> createState() => _ModalAyudaMapsState();
}

class _ModalAyudaMapsState extends State<ModalAyudaMaps> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isSending = false;

  static const Color azulFondo = Color(0xFF072B4F);
  static const Color azulMedio = Color(0xFF0F4C81);
  static const Color textoOscuro = Color(0xFF0F172A);
  static const Color textoGris = Color(0xFF64748B);
  static const Color grisBorde = Color(0xFFCBD5E1);

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);
    final provider = context.read<RecomendacionIglesiaProvider>();

    final ok = await provider.submitMapsHelp(
      name: _nameController.text.trim(),
      city: _cityController.text.trim(),
      contactName: _contactNameController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),
      message: _messageController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSending = false);

    if (ok) {
      final ticketId = provider.lastHelpTicketId ?? 0;
      Navigator.pop(context);
      widget.onSuccess?.call(ticketId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Text(
            provider.errorMessage ??
                'No se pudo enviar la solicitud. Verifica tu conexión.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final ajustes = context.watch<AjustesProvider>();
    final paisActual = ajustes.paisRegion.isNotEmpty
        ? ajustes.paisRegion
        : 'Guatemala';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: bottomInset + 18,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tirador superior del BottomSheet
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Ícono y Título
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.map_rounded,
                          color: azulMedio,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¿Tu iglesia no aparece en Maps?',
                              style: TextStyle(
                                color: textoOscuro,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Solicitud de asistencia con Google Maps',
                              style: TextStyle(
                                color: textoGris,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Mensaje de contexto
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Text(
                      'Déjanos los datos de tu congregación. El equipo de soporte de Atrio te orientará para verificarla y publicarla en Google Maps sin costo.',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Campo 1: Nombre de la iglesia (Obligatorio)
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(fontSize: 13.5, color: textoOscuro),
                    textCapitalization: TextCapitalization.words,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Por favor ingresa el nombre de la iglesia';
                      }
                      if (val.trim().length < 3) {
                        return 'El nombre debe tener al menos 3 letras';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Nombre de la congregación *',
                      labelStyle: const TextStyle(fontSize: 13, color: textoGris),
                      prefixIcon: const Icon(Icons.church_outlined, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: grisBorde),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Campo 2: Ciudad y País detectado
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _cityController,
                          style: const TextStyle(fontSize: 13.5, color: textoOscuro),
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Ciudad / Municipio',
                            labelStyle: const TextStyle(
                              fontSize: 13,
                              color: textoGris,
                            ),
                            prefixIcon: const Icon(
                              Icons.location_city_outlined,
                              size: 20,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: grisBorde),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: grisBorde),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.flag_outlined,
                                size: 16,
                                color: textoGris,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  paisActual,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textoOscuro,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Campo 3: Persona de contacto y Teléfono
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _contactNameController,
                          style: const TextStyle(fontSize: 13.5, color: textoOscuro),
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Contacto (Pastor/Líder)',
                            labelStyle: const TextStyle(
                              fontSize: 12,
                              color: textoGris,
                            ),
                            prefixIcon: const Icon(Icons.person_outline, size: 20),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: grisBorde),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _contactPhoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontSize: 13.5, color: textoOscuro),
                          decoration: InputDecoration(
                            labelText: 'Teléfono',
                            labelStyle: const TextStyle(
                              fontSize: 12,
                              color: textoGris,
                            ),
                            prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: grisBorde),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Campo 4: Mensaje o dirección aproximada
                  TextFormField(
                    controller: _messageController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13.5, color: textoOscuro),
                    decoration: InputDecoration(
                      labelText: 'Dirección aproximada o referencias',
                      labelStyle: const TextStyle(fontSize: 13, color: textoGris),
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Icon(Icons.edit_note_rounded, size: 22),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: grisBorde),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Botón de Envío
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: azulFondo,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSending ? null : _enviarSolicitud,
                      child: _isSending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Enviar solicitud de ayuda',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.send_rounded, size: 16),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
