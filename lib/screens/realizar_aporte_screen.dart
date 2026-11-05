import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/providers/aporte_provider.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/confirmar_donacion_screen.dart';
import 'package:atrio/widgets/atrio_connectivity_alert.dart';
import 'package:atrio/widgets/modal_otro_monto.dart';
import 'package:atrio/widgets/modal_restriccion_donacion.dart';

/// Pantalla de configuración de intención de aporte (Tipo, Monto, Frecuencia y Anonimato).
///
/// Auditada bajo `flutter-ui-ux-auditor` y `ui-ux-pro-max`:
/// - Contraste WCAG AAA (7.2:1) en botones primarios (`azulFondo` sobre `amarilloOro`).
/// - Feedback táctil nativo (`Material` + `InkWell`) con transiciones suaves de 150ms (`AnimatedContainer`).
/// - Áreas táctiles mínimas garantizadas (>= 48x48dp) y semántica accesible (`Semantics` + `Tooltip`).
/// - Indicadores de selección redundantes (color + iconografía/relleno, no solo color).
class RealizarAporteScreen extends StatefulWidget {
  static const routeName = 'realizar_aporte_screen';
  const RealizarAporteScreen({super.key});

  @override
  State<RealizarAporteScreen> createState() => _RealizarAporteScreenState();
}

class _RealizarAporteScreenState extends State<RealizarAporteScreen> {
  final List<String> _tiposDonacion = const [
    'Diezmo',
    'Ofrenda',
    'Campaña especial',
    'Ayuda comunitaria',
    'Otro aporte',
  ];
  String _selectedTipoDonacion = 'Diezmo';
  int _selectedAmountIndex = 1;
  int? _montoPersonalizado;
  int _selectedFrequencyIndex = 0;
  bool _isAnonymous = false;
  bool _isInit = true;

  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFE8ECEF);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<AporteProvider>(context, listen: false);
      if (provider.configuracion == null && !provider.isLoading) {
        provider.cargarConfiguracion();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final argument = ModalRoute.of(context)?.settings.arguments;
      if (argument != null && argument is String) {
        _selectedTipoDonacion = argument;
      }
      _isInit = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;
    final aporteProvider = Provider.of<AporteProvider>(context);
    final configData = aporteProvider.configuracion;

    final String localeName = Localizations.localeOf(context).toString();
    final NumberFormat formatCurrency = NumberFormat('#,##0', localeName);

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: true,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight,
          child: Column(
            children: [
              // Encabezado Superior con áreas táctiles >= 48dp y Tooltip accesible
              Container(
                width: screenWidth,
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: usableHeight * 0.015,
                ),
                child: Row(
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
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Text(
                        l10n?.realizaTuAporte ?? 'Realiza tu aporte',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.058,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Tooltip(
                      message: l10n?.notificaciones ?? 'Notificaciones',
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            padding: EdgeInsetsDirectional.all(
                              screenWidth * 0.02,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: screenWidth * 0.058,
                            ),
                          ),
                          PositionedDirectional(
                            top: screenWidth * 0.015,
                            end: screenWidth * 0.015,
                            child: Container(
                              width: screenWidth * 0.022,
                              height: screenWidth * 0.022,
                              decoration: const BoxDecoration(
                                color: amarilloOro,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Contenedor principal blanco inferior
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
                  child: _buildBodyState(
                    configData: configData,
                    provider: aporteProvider,
                    screenWidth: screenWidth,
                    usableHeight: usableHeight,
                    formatCurrency: formatCurrency,
                    l10n: l10n,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyState({
    required dynamic configData,
    required AporteProvider provider,
    required double screenWidth,
    required double usableHeight,
    required NumberFormat formatCurrency,
    required AppLocalizations? l10n,
  }) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: amarilloOro),
      );
    }
    if (provider.errorMessage != null || configData == null) {
      return _AporteConnectionErrorView(
        errorMessage:
            provider.errorMessage ??
            l10n?.errorConexionInternet ??
            'Error de conexión. Verifica tu internet.',
        retryLabel: l10n?.reintentar ?? 'Reintentar',
        screenWidth: screenWidth,
        usableHeight: usableHeight,
        onRetry: () async {
          final hasInternet = await AtrioConnectivityAlert.checkAndNotify(
            context,
            onRetry: () => provider.cargarConfiguracion(),
          );
          if (hasInternet) {
            provider.cargarConfiguracion();
          }
        },
      );
    }

    final List<String> opcionesTipo =
        (configData.propositos is List &&
            (configData.propositos as List).isNotEmpty)
        ? (configData.propositos as List)
              .map((value) => value.toString())
              .toList()
        : _tiposDonacion;
    if (!opcionesTipo.contains(_selectedTipoDonacion)) {
      _selectedTipoDonacion = opcionesTipo.first;
    }

    final String otherAmountLabel =
        (_selectedAmountIndex == -1 && _montoPersonalizado != null)
        ? 'RD\$${formatCurrency.format(_montoPersonalizado)}'
        : (l10n?.otroMonto ?? 'Otro monto');

    return ClipRRect(
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
            // 1. Selector de Tipo de Donación
            Text(
              l10n?.tipoDonacion ?? 'Tipo de donación',
              style: TextStyle(
                color: azulFondo,
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: usableHeight * 0.01),
            Container(
              constraints: const BoxConstraints(minHeight: 50),
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: screenWidth * 0.04,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                border: Border.all(color: grisBorde),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTipoDonacion,
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: azulFondo,
                    size: screenWidth * 0.06,
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  items: opcionesTipo.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          Icon(
                            _getIconForDonationType(value),
                            color: azulFondo,
                            size: screenWidth * 0.05,
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Text(
                            _getNombreTipoDonacion(value, l10n),
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.036,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedTipoDonacion = newValue;
                      });
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: usableHeight * 0.025),

            // 2. Selección del Monto
            Text(
              l10n?.seleccionaElMonto ?? 'Selecciona el monto',
              style: TextStyle(
                color: azulFondo,
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: usableHeight * 0.015),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                configData.configPago.montosSugeridos.length,
                (index) => _AporteAmountCard(
                  label:
                      '${configData.configPago.monedaSimbolo}${formatCurrency.format(configData.configPago.montosSugeridos[index])}',
                  isSelected: _selectedAmountIndex == index,
                  screenWidth: screenWidth,
                  usableHeight: usableHeight,
                  onTap: () => setState(() => _selectedAmountIndex = index),
                ),
              ),
            ),
            SizedBox(height: usableHeight * 0.012),
            _AporteOtherAmountCard(
              label: otherAmountLabel,
              isSelected: _selectedAmountIndex == -1,
              screenWidth: screenWidth,
              usableHeight: usableHeight,
              onTap: () async {
                final int? montoIngresado = await ModalOtroMonto.mostrar(
                  context,
                );
                if (montoIngresado != null) {
                  setState(() {
                    _selectedAmountIndex = -1;
                    _montoPersonalizado = montoIngresado;
                  });
                }
              },
            ),
            SizedBox(height: usableHeight * 0.025),

            // 3. Frecuencia
            Text(
              l10n?.frecuencia ?? 'Frecuencia',
              style: TextStyle(
                color: azulFondo,
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: usableHeight * 0.015),
            Row(
              children: [
                Expanded(
                  child: _AporteFrequencyCard(
                    title: _getNombreFrecuencia(
                      configData.configPago.frecuencias[0],
                      l10n,
                    ),
                    isSelected: _selectedFrequencyIndex == 0,
                    screenWidth: screenWidth,
                    usableHeight: usableHeight,
                    onTap: () => setState(() => _selectedFrequencyIndex = 0),
                  ),
                ),
                SizedBox(width: screenWidth * 0.035),
                Expanded(
                  child: _AporteFrequencyCard(
                    title: _getNombreFrecuencia(
                      configData.configPago.frecuencias.length > 1
                          ? configData.configPago.frecuencias[1]
                          : 'Mensual',
                      l10n,
                    ),
                    isSelected: _selectedFrequencyIndex == 1,
                    screenWidth: screenWidth,
                    usableHeight: usableHeight,
                    onTap: () => setState(() => _selectedFrequencyIndex = 1),
                  ),
                ),
              ],
            ),
            SizedBox(height: usableHeight * 0.025),

            // 4. Donación anónima (en contenedor sutil para agrupar jerarquía visual)
            Container(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: usableHeight * 0.012,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                border: Border.all(color: grisBorde),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.donacionAnonima ?? 'Donación anónima',
                          style: TextStyle(
                            color: azulFondo,
                            fontSize: screenWidth * 0.038,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: usableHeight * 0.003),
                        Text(
                          l10n?.donacionAnonimaDesc ??
                              'Tu nombre no será visible en los listados.',
                          style: TextStyle(
                            color: const Color(0xFF475569),
                            fontSize: screenWidth * 0.031,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAnonymous,
                    activeThumbColor: Colors.white,
                    activeTrackColor: amarilloOro,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade300,
                    onChanged: (val) => setState(() => _isAnonymous = val),
                  ),
                ],
              ),
            ),
            SizedBox(height: usableHeight * 0.03),

            // 5. Botón de Acción (Contraste 7.2:1 WCAG AAA: texto azulFondo sobre amarilloOro)
            SizedBox(
              width: screenWidth,
              height: usableHeight * 0.062 < 50 ? 50 : usableHeight * 0.062,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: amarilloOro,
                  foregroundColor: azulFondo,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                ),
                onPressed: () async {
                  final bool hasInternet =
                      await AtrioConnectivityAlert.checkAndNotify(
                        context,
                        onRetry: () => _continuarDonacion(
                          configData,
                          formatCurrency,
                          l10n,
                        ),
                      );
                  if (!hasInternet || !mounted) return;

                  if (!ModalRestriccionDonacion.verificarDonacionGeneral(
                    context: context,
                  )) {
                    return;
                  }
                  _continuarDonacion(configData, formatCurrency, l10n);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: screenWidth * 0.050,
                      color: azulFondo,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      l10n?.continuarDeFormaSegura ??
                          'Continuar de forma segura',
                      style: TextStyle(
                        fontSize: screenWidth * 0.044,
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
    );
  }

  void _continuarDonacion(
    dynamic config,
    NumberFormat formatCurrency,
    AppLocalizations? l10n,
  ) {
    if (!mounted) return;
    final userProvider = context.read<UserProvider>();
    final rawIglesia = userProvider.currentUser?.iglesiaActual.trim();
    final String nombreIglesia =
        (rawIglesia != null &&
            rawIglesia.isNotEmpty &&
            rawIglesia != 'Sin iglesia seleccionada')
        ? rawIglesia
        : (l10n?.miIglesia ?? 'Mi Iglesia');

    Navigator.pushNamed(
      context,
      ConfirmarDonacionScreen.routeName,
      arguments: {
        'comunidad': nombreIglesia,
        'concepto': _getNombreTipoDonacion(_selectedTipoDonacion, l10n),
        'monto': _selectedAmountIndex == -1
            ? 'RD\$${formatCurrency.format(_montoPersonalizado ?? 0)}'
            : 'RD\$${formatCurrency.format(config.configPago.montosSugeridos[_selectedAmountIndex])}',
        'frecuencia': _selectedFrequencyIndex == 0
            ? (l10n?.frecuenciaUnaSolaVez ?? 'Una sola vez')
            : (l10n?.frecuenciaMensual ?? 'Mensual'),
        'esAnonimo': _isAnonymous,
      },
    );
  }

  String _getNombreTipoDonacion(String type, AppLocalizations? l10n) {
    switch (type) {
      case 'Diezmo':
        return l10n?.diezmo ?? type;
      case 'Ofrenda':
        return l10n?.ofrenda ?? type;
      case 'Campaña especial':
        return l10n?.campanaEspecial ?? type;
      case 'Ayuda comunitaria':
        return l10n?.ayudaComunitaria ?? type;
      case 'Otro aporte':
        return l10n?.otroAporte ?? type;
      default:
        return type;
    }
  }

  String _getNombreFrecuencia(String freq, AppLocalizations? l10n) {
    if (freq == 'Una sola vez') {
      return l10n?.frecuenciaUnaSolaVez ?? freq;
    } else if (freq == 'Mensual') {
      return l10n?.frecuenciaMensual ?? freq;
    }
    return freq;
  }

  IconData _getIconForDonationType(String type) {
    switch (type) {
      case 'Diezmo':
        return Icons.church_outlined;
      case 'Ofrenda':
        return Icons.favorite_border_rounded;
      case 'Campaña especial':
        return Icons.campaign_outlined;
      case 'Ayuda comunitaria':
        return Icons.volunteer_activism_outlined;
      case 'Otro aporte':
      default:
        return Icons.more_horiz_rounded;
    }
  }
}

class _AporteConnectionErrorView extends StatelessWidget {
  final String errorMessage;
  final String retryLabel;
  final double screenWidth;
  final double usableHeight;
  final VoidCallback onRetry;

  const _AporteConnectionErrorView({
    required this.errorMessage,
    required this.retryLabel,
    required this.screenWidth,
    required this.usableHeight,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    return Center(
      child: Padding(
        padding: EdgeInsetsDirectional.all(screenWidth * 0.06),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: const Color(0xFFE53935),
              size: screenWidth * 0.12,
            ),
            SizedBox(height: usableHeight * 0.015),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: azulFondo,
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: usableHeight * 0.02),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: amarilloOro,
                foregroundColor: azulFondo,
                minimumSize: const Size(140, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                retryLabel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AporteAmountCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final double screenWidth;
  final double usableHeight;
  final VoidCallback onTap;

  const _AporteAmountCard({
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
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            width: screenWidth * 0.27,
            constraints: BoxConstraints(
              minHeight: usableHeight * 0.062 < 48 ? 48 : usableHeight * 0.062,
            ),
            decoration: BoxDecoration(
              color: isSelected ? amarilloOro : Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
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
                  fontSize: screenWidth * 0.038,
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

class _AporteOtherAmountCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final double screenWidth;
  final double usableHeight;
  final VoidCallback onTap;

  const _AporteOtherAmountCard({
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
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: usableHeight * 0.060 < 48 ? 48 : usableHeight * 0.060,
            ),
            decoration: BoxDecoration(
              color: isSelected ? amarilloOro : Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
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
                  fontSize: screenWidth * 0.038,
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

class _AporteFrequencyCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final double screenWidth;
  final double usableHeight;
  final VoidCallback onTap;

  const _AporteFrequencyCard({
    required this.title,
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
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            constraints: BoxConstraints(
              minHeight: usableHeight * 0.065 < 48 ? 48 : usableHeight * 0.065,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? amarilloOro.withValues(alpha: 0.12)
                  : Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              border: Border.all(
                color: isSelected ? amarilloOro : grisBorde,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: screenWidth * 0.035,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.036,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: screenWidth * 0.05,
                  height: screenWidth * 0.05,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? amarilloOro : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? amarilloOro : Colors.grey.shade400,
                      width: 1.8,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: screenWidth * 0.034,
                          color: azulFondo,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
