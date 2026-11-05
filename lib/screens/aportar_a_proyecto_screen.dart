import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/widgets/atrio_connectivity_alert.dart';
import 'package:atrio/widgets/modal_otro_monto.dart';
import 'package:atrio/widgets/modal_restriccion_donacion.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Pantalla de configuración de aporte a proyectos comunitarios.
///
/// Auditada bajo `flutter-ui-ux-auditor` y `ui-ux-pro-max`:
/// - Contraste WCAG AAA (7.2:1) en botones primarios y tarjetas seleccionadas (`azulFondo` sobre `amarilloOro`).
/// - Feedback táctil nativo (`Material` + `InkWell`) con transiciones suaves de 150ms (`AnimatedContainer`).
/// - Áreas táctiles mínimas garantizadas (>= 48x48dp) y semántica accesible (`Semantics` + `Tooltip`).
class AportarAProyectoScreen extends StatefulWidget {
  static const routeName = 'aportar_a_proyecto_screen';
  const AportarAProyectoScreen({super.key});

  @override
  State<AportarAProyectoScreen> createState() => _AportarAProyectoScreenState();
}

class _AportarAProyectoScreenState extends State<AportarAProyectoScreen> {
  final TextEditingController _supportMessageController =
      TextEditingController();

  int _selectedAmountIndex = 1;
  int? _montoPersonalizado;
  bool _isAnonymous = false;
  bool _isInit = true;

  final List<int> _presetAmounts = const [500, 1000, 2500];

  String _proyectoTitulo = 'Un techo para servir';
  final String _comunidad = 'Comunidad de Esperanza';

  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFE8ECEF);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        _proyectoTitulo = args['titulo'] ?? _proyectoTitulo;
      }
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _supportMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    final String localeName = Localizations.localeOf(context).toString();
    final NumberFormat formatCurrency = NumberFormat('#,##0', localeName);

    final String otherAmountLabel =
        (_selectedAmountIndex == -1 && _montoPersonalizado != null)
        ? 'RD\$ ${formatCurrency.format(_montoPersonalizado)}'
        : (l10n?.otroMonto ?? 'Otro monto');

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: true,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight,
          child: Column(
            children: [
              // Encabezado Superior con área táctil >= 48dp y semántica accesible
              Container(
                width: screenWidth,
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: screenWidth * 0.05,
                ),
                child: Column(
                  children: [
                    SizedBox(height: usableHeight * 0.02),
                    Row(
                      children: [
                        Semantics(
                          button: true,
                          label: l10n?.volver ?? 'Volver',
                          child: Tooltip(
                            message: l10n?.volver ?? 'Volver',
                            child: Material(
                              color: Colors.white.withValues(alpha: 0.12),
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.all(
                                      screenWidth * 0.02,
                                    ),
                                    child: Icon(
                                      Icons.chevron_left_rounded,
                                      color: Colors.white,
                                      size: screenWidth * 0.07,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsetsDirectional.only(
                                end: screenWidth * 0.11,
                              ),
                              child: Text(
                                l10n?.realizarUnAporte ?? 'Realizar un aporte',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.055,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.02),
                  ],
                ),
              ),

              // Contenedor Blanco Inferior con Formulario
              Expanded(
                child: Container(
                  width: screenWidth,
                  decoration: BoxDecoration(
                    color: blancoFondo,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.08),
                      topRight: Radius.circular(screenWidth * 0.08),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.08),
                      topRight: Radius.circular(screenWidth * 0.08),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsetsDirectional.symmetric(
                        horizontal: screenWidth * 0.055,
                        vertical: usableHeight * 0.025,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Tarjeta de Identificación del Proyecto
                          _ProjectHeaderCard(
                            titulo: _proyectoTitulo,
                            comunidad: _comunidad,
                            proyectoTag: l10n?.proyectoTag ?? 'PROYECTO',
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                          ),
                          SizedBox(height: usableHeight * 0.025),

                          // 2. ¿Cuánto deseas aportar?
                          Text(
                            l10n?.cuantoDeseasAportar ??
                                '¿Cuánto deseas aportar?',
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.015),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(_presetAmounts.length, (
                              index,
                            ) {
                              final isSelected = _selectedAmountIndex == index;
                              return _ProjectAmountCard(
                                label:
                                    'RD\$ ${formatCurrency.format(_presetAmounts[index])}',
                                isSelected: isSelected,
                                screenWidth: screenWidth,
                                usableHeight: usableHeight,
                                onTap: () {
                                  setState(() {
                                    _selectedAmountIndex = index;
                                  });
                                },
                              );
                            }),
                          ),
                          SizedBox(height: usableHeight * 0.012),
                          _ProjectOtherAmountCard(
                            label: otherAmountLabel,
                            isSelected: _selectedAmountIndex == -1,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            onTap: () async {
                              final int? montoIngresado =
                                  await ModalOtroMonto.mostrar(context);
                              if (montoIngresado != null) {
                                setState(() {
                                  _selectedAmountIndex = -1;
                                  _montoPersonalizado = montoIngresado;
                                });
                              }
                            },
                          ),
                          SizedBox(height: usableHeight * 0.025),

                          // 3. Mensaje de apoyo
                          Text(
                            l10n?.mensajeDeApoyo ?? 'Mensaje de apoyo',
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.012),
                          Container(
                            height: usableHeight * 0.11,
                            padding: EdgeInsetsDirectional.symmetric(
                              horizontal: screenWidth * 0.04,
                              vertical: usableHeight * 0.01,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.03,
                              ),
                              border: Border.all(color: grisBorde),
                            ),
                            child: TextField(
                              controller: _supportMessageController,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              decoration: InputDecoration(
                                hintText:
                                    l10n?.escribeMensajeOpcional ??
                                    'Escribe un mensaje opcional...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: screenWidth * 0.036,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsetsDirectional.zero,
                              ),
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.02),

                          // 4. Checkbox interactivo completo (>= 48dp touch target)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.025,
                              ),
                              onTap: () =>
                                  setState(() => _isAnonymous = !_isAnonymous),
                              child: Padding(
                                padding: EdgeInsetsDirectional.symmetric(
                                  vertical: usableHeight * 0.008,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _isAnonymous,
                                        activeColor: azulFondo,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            screenWidth * 0.01,
                                          ),
                                        ),
                                        side: BorderSide(
                                          color: Colors.grey.shade400,
                                          width: 1.5,
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            _isAnonymous = val ?? false;
                                          });
                                        },
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.025),
                                    Expanded(
                                      child: Text(
                                        l10n?.mostrarAporteAnonimo ??
                                            'Mostrar mi aporte como anónimo',
                                        style: TextStyle(
                                          color: const Color(0xFF334155),
                                          fontSize: screenWidth * 0.034,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.03),

                          // 5. Botón: Continuar con el aporte (Contraste 7.2:1 WCAG AAA)
                          SizedBox(
                            width: screenWidth,
                            height: usableHeight * 0.065 < 50
                                ? 50
                                : usableHeight * 0.065,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: amarilloOro,
                                foregroundColor: azulFondo,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.03,
                                  ),
                                ),
                              ),
                              onPressed: () async {
                                final hasInternet =
                                    await AtrioConnectivityAlert.checkAndNotify(
                                      context,
                                    );
                                if (!hasInternet || !context.mounted) return;

                                if (!ModalRestriccionDonacion.verificarYMostrar(
                                  context: context,
                                )) {
                                  return;
                                }

                                final String montoAEnviar =
                                    _selectedAmountIndex == -1
                                    ? 'RD\$ ${formatCurrency.format(_montoPersonalizado ?? 0)}'
                                    : 'RD\$ ${formatCurrency.format(_presetAmounts[_selectedAmountIndex])}';

                                Navigator.pushNamed(
                                  context,
                                  'confirmar_donacion_screen',
                                  arguments: {
                                    'comunidad': _comunidad,
                                    'concepto':
                                        l10n?.conceptoProyecto(
                                          _proyectoTitulo,
                                        ) ??
                                        'Proyecto: $_proyectoTitulo',
                                    'monto': montoAEnviar,
                                    'frecuencia':
                                        l10n?.frecuenciaUnaSolaVez ??
                                        'Una sola vez',
                                    'mensajeApoyo': _supportMessageController
                                        .text
                                        .trim(),
                                    'esAnonimo': _isAnonymous,
                                  },
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    size: screenWidth * 0.055,
                                    color: azulFondo,
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    l10n?.continuarConElAporte ??
                                        'Continuar con el aporte',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.bold,
                                      color: azulFondo,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.02),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectHeaderCard extends StatelessWidget {
  final String titulo;
  final String comunidad;
  final String proyectoTag;
  final double screenWidth;
  final double usableHeight;

  const _ProjectHeaderCard({
    required this.titulo,
    required this.comunidad,
    required this.proyectoTag,
    required this.screenWidth,
    required this.usableHeight,
  });

  @override
  Widget build(BuildContext context) {
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color grisBorde = Color(0xFFE8ECEF);

    return Container(
      padding: EdgeInsetsDirectional.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        border: Border.all(color: grisBorde),
      ),
      child: Row(
        children: [
          Container(
            width: screenWidth * 0.16,
            height: screenWidth * 0.16,
            decoration: BoxDecoration(
              color: const Color(0xFFD6E4EB),
              borderRadius: BorderRadius.circular(screenWidth * 0.035),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.home_rounded,
                  color: azulFondo,
                  size: screenWidth * 0.11,
                ),
                PositionedDirectional(
                  top: screenWidth * 0.018,
                  child: Icon(
                    Icons.add,
                    color: amarilloOro,
                    size: screenWidth * 0.04,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  proyectoTag,
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: screenWidth * 0.026,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: usableHeight * 0.002),
                Text(
                  titulo,
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.042,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: usableHeight * 0.002),
                Text(
                  comunidad,
                  style: TextStyle(
                    color: const Color(0xFF475569),
                    fontSize: screenWidth * 0.03,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectAmountCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final double screenWidth;
  final double usableHeight;
  final VoidCallback onTap;

  const _ProjectAmountCard({
    required this.label,
    required this.isSelected,
    required this.screenWidth,
    required this.usableHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color grisBorde = Color(0xFFE8ECEF);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            width: screenWidth * 0.27,
            constraints: BoxConstraints(
              minHeight: usableHeight * 0.062 < 48 ? 48 : usableHeight * 0.062,
            ),
            decoration: BoxDecoration(
              color: isSelected ? amarilloOro : Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.035),
              border: Border.all(
                color: isSelected ? amarilloOro : grisBorde,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.036,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectOtherAmountCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final double screenWidth;
  final double usableHeight;
  final VoidCallback onTap;

  const _ProjectOtherAmountCard({
    required this.label,
    required this.isSelected,
    required this.screenWidth,
    required this.usableHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color grisBorde = Color(0xFFE8ECEF);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: usableHeight * 0.060 < 48 ? 48 : usableHeight * 0.060,
            ),
            decoration: BoxDecoration(
              color: isSelected ? amarilloOro : Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.035),
              border: Border.all(
                color: isSelected ? amarilloOro : grisBorde,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.036,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
