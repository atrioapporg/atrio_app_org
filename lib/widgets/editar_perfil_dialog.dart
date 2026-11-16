import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/user_provider.dart';
import '../utils/profile_validators.dart';
import 'atrio_connectivity_alert.dart';

/// Modal para editar los datos básicos del perfil y sincronizarlos con Odoo 19.
class EditarPerfilDialog extends StatefulWidget {
  final String initialNombre;
  final String initialEmail;
  final String initialTelefono;
  final Future<void> Function() onSaved;

  const EditarPerfilDialog({
    super.key,
    required this.initialNombre,
    required this.initialEmail,
    required this.initialTelefono,
    required this.onSaved,
  });

  @override
  State<EditarPerfilDialog> createState() => _EditarPerfilDialogState();
}

class _EditarPerfilDialogState extends State<EditarPerfilDialog> {
  static const Color _azulFondo = Color(0xFF072B4F);
  static const Color _amarilloOro = Color(0xFFF3A712);
  static const Color _blancoFondo = Color(0xFFFBF9F5);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _telefonoCtrl;

  bool _isSaving = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.initialNombre);
    _emailCtrl = TextEditingController(text: widget.initialEmail);
    _telefonoCtrl = TextEditingController(text: widget.initialTelefono);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  void _applyDomain(String domain) {
    final updated = ProfileValidators.applyEmailDomain(_emailCtrl.text, domain);
    _emailCtrl.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: updated.length),
    );
    if (_submitError != null) {
      setState(() => _submitError = null);
    }
  }

  Future<void> _handleSave() async {
    final l10n = AppLocalizations.of(context);
    final userProvider = context.read<UserProvider>();

    if (userProvider.isReadOnly) {
      setState(() {
        _submitError =
            l10n?.accionRestringidaSoloLectura ??
            'Acción restringida: Modo de solo lectura activado.';
      });
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final hasInternet = await AtrioConnectivityAlert.checkAndNotify(
      context,
      onRetry: _handleSave,
    );
    if (!hasInternet || !mounted) return;

    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    final formattedPhone = ProfileValidators.formatDominicanPhone(
      _telefonoCtrl.text,
    );

    final ok = await userProvider.actualizarPerfilUsuario(
      nombre: _nombreCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      telefono: formattedPhone,
    );

    if (!mounted) return;

    if (!ok) {
      setState(() {
        _isSaving = false;
        _submitError =
            userProvider.errorMessage ??
            (l10n?.errorActualizarPerfil ??
                'No se pudieron actualizar tus datos en el servidor.');
      });
      return;
    }

    await widget.onSaved();
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: _azulFondo,
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n?.datosActualizadosCorrectamente ??
                    'Datos actualizados correctamente',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    final usableHeight =
        mq.size.height - mq.padding.top - mq.padding.bottom;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: usableHeight * 0.03,
      ),
      backgroundColor: _blancoFondo,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.edit_note_rounded, color: _azulFondo, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n?.misDatosDePerfil ?? 'Mis datos de perfil',
              style: const TextStyle(
                color: _azulFondo,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: screenWidth * 0.90,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ProfileTextField(
                  controller: _nombreCtrl,
                  label: l10n?.nombreCompleto ?? 'Nombre completo',
                  icon: Icons.person_outline,
                  enabled: !_isSaving,
                  textInputAction: TextInputAction.next,
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? (l10n?.ingresaUnNombre ?? 'Ingresa un nombre')
                      : null,
                ),
                const SizedBox(height: 16),
                _ProfileTextField(
                  controller: _telefonoCtrl,
                  label: l10n?.telefonoCelular ?? 'Teléfono celular',
                  icon: Icons.phone_outlined,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
                    LengthLimitingTextInputFormatter(16),
                  ],
                  helperText:
                      l10n?.helperTelefonoRd ??
                      'Formato RD: 809, 829 u 849 + 7 dígitos (ej. 809-555-1234)',
                  validator: (val) =>
                      ProfileValidators.isValidDominicanPhone(val)
                      ? null
                      : (l10n?.ingresaUnTelefonoValidoRd ??
                            'Ingresa un celular válido de RD (10 dígitos: 809, 829 u 849)'),
                ),
                const SizedBox(height: 16),
                _ProfileTextField(
                  controller: _emailCtrl,
                  label: l10n?.correoElectronico ?? 'Correo electrónico',
                  icon: Icons.email_outlined,
                  enabled: !_isSaving,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: (val) => ProfileValidators.isValidEmail(val)
                      ? null
                      : (l10n?.ingresaUnCorreoValido ??
                            'Ingresa un correo válido'),
                ),
                const SizedBox(height: 10),
                _EmailDomainSuggestionBar(
                  emailController: _emailCtrl,
                  label:
                      l10n?.sugerenciasDominioCorreo ?? 'Completar dominio:',
                  enabled: !_isSaving,
                  onSelectDomain: _applyDomain,
                ),
                if (_submitError != null) ...[
                  const SizedBox(height: 14),
                  _InlineErrorBanner(message: _submitError!),
                ],
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 14),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: Text(
            l10n?.cancelar ?? 'Cancelar',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _amarilloOro,
            foregroundColor: _azulFondo,
            minimumSize: const Size(120, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 18,
              vertical: 10,
            ),
          ),
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(_azulFondo),
                  ),
                )
              : Text(
                  l10n?.guardarCambios ?? 'Guardar cambios',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ],
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  static const Color _azulFondo = Color(0xFF072B4F);
  static const Color _grisBorde = Color(0xFFDADADA);

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool enabled;
  final String? helperText;
  final List<TextInputFormatter>? inputFormatters;

  const _ProfileTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.validator,
    this.enabled = true,
    this.helperText,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(color: _azulFondo, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 14),
        helperText: helperText,
        helperMaxLines: 2,
        helperStyle: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        errorMaxLines: 2,
        prefixIcon: Icon(icon, color: _azulFondo, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _grisBorde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _azulFondo, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade700),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
        ),
      ),
    );
  }
}

class _EmailDomainSuggestionBar extends StatelessWidget {
  static const Color _azulFondo = Color(0xFF072B4F);

  final TextEditingController emailController;
  final String label;
  final bool enabled;
  final ValueChanged<String> onSelectDomain;

  const _EmailDomainSuggestionBar({
    required this.emailController,
    required this.label,
    required this.enabled,
    required this.onSelectDomain,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: emailController,
      builder: (context, value, _) {
        final currentLower = value.text.trim().toLowerCase();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                const double spacing = 8;
                final double itemWidth = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: ProfileValidators.suggestedEmailDomains.map((domain) {
                    final bool isSelected = currentLower.endsWith(domain);
                    return SizedBox(
                      width: itemWidth,
                      child: ActionChip(
                        materialTapTargetSize: MaterialTapTargetSize.padded,
                        visualDensity: VisualDensity.compact,
                        avatar: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                        label: SizedBox(
                          width: double.infinity,
                          child: Text(
                            domain,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : _azulFondo,
                            ),
                          ),
                        ),
                        backgroundColor: isSelected ? _azulFondo : Colors.white,
                        side: BorderSide(
                          color: isSelected
                              ? _azulFondo
                              : _azulFondo.withValues(alpha: 0.25),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onPressed: enabled ? () => onSelectDomain(domain) : null,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _InlineErrorBanner extends StatelessWidget {
  final String message;

  const _InlineErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
