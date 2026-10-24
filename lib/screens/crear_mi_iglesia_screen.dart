import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import 'iglesia_pendiente_activacion_screen.dart';

/// Formulario para que un usuario autenticado (`role: user`) registre su propia congregación en ATRIO (POST /me/church).
/// Al crearse, el usuario se convierte en `church_admin` y pasa a `IglesiaPendienteActivacionScreen`.
class CrearMiIglesiaScreen extends StatefulWidget {
  static const String routeName = 'crear_mi_iglesia_screen';

  const CrearMiIglesiaScreen({super.key});

  @override
  State<CrearMiIglesiaScreen> createState() => _CrearMiIglesiaScreenState();
}

class _CrearMiIglesiaScreenState extends State<CrearMiIglesiaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _ciudadController = TextEditingController();

  double? _latitud;
  double? _longitud;
  bool _obteniendoUbicacion = false;
  bool _isSubmitting = false;

  static const Color azulFondo = Color(0xFF072B4F);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFE2E8F0);
  static const Color textoOscuro = Color(0xFF0F172A);
  static const Color textoGris = Color(0xFF64748B);

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    super.dispose();
  }

  Future<void> _obtenerCoordenadasGps() async {
    setState(() => _obteniendoUbicacion = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permiso de ubicación no concedido.'),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (mounted) {
        setState(() {
          _latitud = position.latitude;
          _longitud = position.longitude;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Text(
              'Ubicación detectada (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[CrearMiIglesia] Error obteniendo GPS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo obtener la posición GPS.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _obteniendoUbicacion = false);
      }
    }
  }

  Future<void> _enviarFormulario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final userProvider = context.read<UserProvider>();

    final payload = <String, dynamic>{
      'name': _nombreController.text.trim(),
      if (_telefonoController.text.trim().isNotEmpty)
        'phone': _telefonoController.text.trim(),
      if (_direccionController.text.trim().isNotEmpty)
        'address': _direccionController.text.trim(),
      if (_ciudadController.text.trim().isNotEmpty)
        'city': _ciudadController.text.trim(),
      if (_latitud != null) 'latitude': _latitud,
      if (_longitud != null) 'longitude': _longitud,
    };

    try {
      await userProvider.createMyChurch(payload);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF16A34A),
          content: Text('¡Congregación registrada exitosamente!'),
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        IglesiaPendienteActivacionScreen.routeName,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(
            userProvider.errorMessage ?? 'Error al registrar la congregación.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blancoFondo,
      appBar: AppBar(
        title: const Text(
          'Registrar Congregación',
          style: TextStyle(
            color: textoOscuro,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textoOscuro),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado
                const Text(
                  'Datos de la Iglesia',
                  style: TextStyle(
                    color: textoOscuro,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Como pastor o administrador, ingresa los datos oficiales para registrar tu congregación en la plataforma.',
                  style: TextStyle(color: textoGris, fontSize: 13.5, height: 1.4),
                ),
                const SizedBox(height: 24),

                // Campo: Nombre de la Iglesia
                _buildLabel('Nombre de la iglesia *'),
                TextFormField(
                  controller: _nombreController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    hint: 'Ej: Iglesia Vida Nueva',
                    icon: Icons.church_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre de la iglesia es obligatorio';
                    }
                    if (value.trim().length < 3) {
                      return 'Ingresa al menos 3 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Campo: Teléfono
                _buildLabel('Teléfono de contacto'),
                TextFormField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(
                    hint: 'Ej: +1 809 555 0000',
                    icon: Icons.phone_rounded,
                  ),
                ),
                const SizedBox(height: 18),

                // Campo: Ciudad
                _buildLabel('Ciudad'),
                TextFormField(
                  controller: _ciudadController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    hint: 'Ej: Santo Domingo',
                    icon: Icons.location_city_rounded,
                  ),
                ),
                const SizedBox(height: 18),

                // Campo: Dirección
                _buildLabel('Dirección física'),
                TextFormField(
                  controller: _direccionController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 2,
                  decoration: _inputDecoration(
                    hint: 'Ej: Av. Principal #10, Sector Los Prados',
                    icon: Icons.pin_drop_rounded,
                  ),
                ),
                const SizedBox(height: 18),

                // Coordenadas GPS opcionales
                _buildLabel('Ubicación en el mapa (GPS)'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: grisBorde),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _latitud != null
                            ? Icons.my_location_rounded
                            : Icons.location_searching_rounded,
                        color: _latitud != null
                            ? const Color(0xFF16A34A)
                            : textoGris,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _latitud != null
                              ? 'Lat: ${_latitud!.toStringAsFixed(4)}, Lng: ${_longitud!.toStringAsFixed(4)}'
                              : 'Coordenadas no asignadas',
                          style: TextStyle(
                            color: _latitud != null ? textoOscuro : textoGris,
                            fontSize: 13,
                            fontWeight: _latitud != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _obteniendoUbicacion
                            ? null
                            : _obtenerCoordenadasGps,
                        icon: _obteniendoUbicacion
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.gps_fixed_rounded, size: 16),
                        label: Text(
                          _latitud != null ? 'Actualizar' : 'Detectar',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Botón Enviar
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azulFondo,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _enviarFormulario,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Registrar mi congregación',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: textoOscuro,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: textoGris, fontSize: 13.5),
      prefixIcon: Icon(icon, color: azulFondo, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: grisBorde),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: grisBorde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: azulFondo, width: 1.5),
      ),
    );
  }
}
