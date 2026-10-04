import 'package:atrio/screens/confirmar_donacion_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../widgets/modal_otro_monto.dart';
import '../providers/aporte_provider.dart';

import 'package:flutter/services.dart';

class RealizarAporteScreen extends StatefulWidget {
  static const routeName = 'realizar_aporte_screen';
  const RealizarAporteScreen({super.key});

  @override
  State createState() => _RealizarAporteScreenState();
}

class _RealizarAporteScreenState extends State {
  final List _tiposDonacion = [
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
  String _selectedPaymentMethod = 'Tarjeta';
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
      final provider = Provider.of(context, listen: false);
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;
    final aporteProvider = Provider.of(context);
    final configData = aporteProvider.configuracion;

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: true,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight,
          child: Column(
            children: [
              // Encabezado Superior (Botón Volver + Título + Campana)
              Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: usableHeight * 0.015,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white,
                          size: screenWidth * 0.07,
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Text(
                        'Realiza tu aporte',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.058,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.02),
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
                        Positioned(
                          top: screenWidth * 0.015,
                          right: screenWidth * 0.015,
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
                  child: _buildFormContent(
                    configData,
                    aporteProvider,
                    screenWidth,
                    usableHeight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(
    dynamic config,
    AporteProvider provider,
    double screenWidth,
    double usableHeight,
  ) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: amarilloOro));
    }
    if (provider.errorMessage != null || config == null) {
      return Center(
        child: Text(
          provider.errorMessage ?? 'Error al cargar datos',
          style: TextStyle(color: azulFondo, fontSize: screenWidth * 0.04),
        ),
      );
    }
    final formatCurrency = NumberFormat("#,##0", "en_US");
    final List<String> opcionesTipo =
        (config.propositos is List && (config.propositos as List).isNotEmpty)
        ? (config.propositos as List).map((value) => value.toString()).toList()
        : _tiposDonacion.map((value) => value.toString()).toList();
    if (!opcionesTipo.contains(_selectedTipoDonacion)) {
      _selectedTipoDonacion = opcionesTipo.first;
    }
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(screenWidth * 0.08),
        topRight: Radius.circular(screenWidth * 0.08),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.055,
          vertical: usableHeight * 0.025,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Dropdown Box de Tipo de Donación
            Text(
              'Tipo de donación',
              style: TextStyle(
                color: azulFondo,
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: usableHeight * 0.01),
            Container(
              height: usableHeight * 0.062,
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                border: Border.all(color: grisBorde),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton(
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
                    return DropdownMenuItem(
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
                            value,
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
              'Selecciona el monto',
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
                config.configPago.montosSugeridos.length,
                (index) => _buildAmountCard(
                  label: '\({config.configPago.monedaSimbolo}\){formatCurrency.format(config.configPago.montosSugeridos[index])}',
                  isSelected: _selectedAmountIndex == index,
                  screenWidth: screenWidth,
                  usableHeight: usableHeight,
                  onTap: () => setState(() => _selectedAmountIndex = index),
                ),
              ),
            ),
            SizedBox(height: usableHeight * 0.012),
            _buildOtherAmountCard(
              isSelected: _selectedAmountIndex == -1,
              screenWidth: screenWidth,
              usableHeight: usableHeight,
              montoPersonalizado: _montoPersonalizado,
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
              'Frecuencia',
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
                  child: _buildFrequencyCard(
                    title: config.configPago.frecuencias[0],
                    isSelected: _selectedFrequencyIndex == 0,
                    screenWidth: screenWidth,
                    usableHeight: usableHeight,
                    onTap: () => setState(() => _selectedFrequencyIndex = 0),
                  ),
                ),
                SizedBox(width: screenWidth * 0.035),
                Expanded(
                  child: _buildFrequencyCard(
                    title: config.configPago.frecuencias.length > 1
                        ? config.configPago.frecuencias[1]
                        : 'Mensual',
                    isSelected: _selectedFrequencyIndex == 1,
                    screenWidth: screenWidth,
                    usableHeight: usableHeight,
                    onTap: () => setState(() => _selectedFrequencyIndex = 1),
                  ),
                ),
              ],
            ),
            SizedBox(height: usableHeight * 0.025),

            // 4. Selección Dinámica del Método de Pago
            Text(
              'Método de pago',
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
                  child: _buildPaymentOption(
                    title: 'Transferencia',
                    icon: FontAwesomeIcons.buildingColumns,
                    isSelected: _selectedPaymentMethod == 'Transferencia',
                    screenWidth: screenWidth,
                    usableHeight: usableHeight,
                    onTap: () {
                      setState(() => _selectedPaymentMethod = 'Transferencia');
                      _mostrarModalTransferencia(
                        context,
                        screenWidth,
                        usableHeight,
                      );
                    },
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: _buildPaymentOption(
                    title: 'Apple Pay',
                    icon: FontAwesomeIcons.applePay,
                    isSelected: _selectedPaymentMethod == 'Apple Pay',
                    screenWidth: screenWidth,
                    usableHeight: usableHeight,
                    onTap: () =>
                        setState(() => _selectedPaymentMethod = 'Apple Pay'),
                  ),
                ),
              ],
            ),
            SizedBox(height: usableHeight * 0.015),
            Row(
              children: [
                Expanded(
                  child: _buildPaymentOption(
                    title: 'Google Pay',
                    icon: FontAwesomeIcons.googlePay,
                    isSelected: _selectedPaymentMethod == 'Google Pay',
                    screenWidth: screenWidth,
                    usableHeight: usableHeight,
                    onTap: () =>
                        setState(() => _selectedPaymentMethod = 'Google Pay'),
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: _buildPaymentOption(
                    title: 'PayPal',
                    icon: FontAwesomeIcons.paypal,
                    isSelected: _selectedPaymentMethod == 'PayPal',
                    screenWidth: screenWidth,
                    usableHeight: usableHeight,
                    onTap: () =>
                        setState(() => _selectedPaymentMethod = 'PayPal'),
                  ),
                ),
              ],
            ),
            SizedBox(height: usableHeight * 0.025),

            // 5. Donación anónima
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Donación anónima',
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: usableHeight * 0.003),
                      Text(
                        'Tu nombre no será visible en los listados.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: screenWidth * 0.032,
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
            SizedBox(height: usableHeight * 0.03),

            // 6. Botón de Acción
            SizedBox(
              width: screenWidth,
              height: usableHeight * 0.062,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: amarilloOro,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    ConfirmarDonacionScreen.routeName,
                    arguments: {
                      'comunidad': 'Comunidad de Esperanza',
                      'concepto': _selectedTipoDonacion,
                      'monto': _selectedAmountIndex == -1
                          ? 'RD\$${formatCurrency.format(_montoPersonalizado ?? 0)}'
                          : 'RD\$${formatCurrency.format(config.configPago.montosSugeridos[_selectedAmountIndex])}',
                      'frecuencia': _selectedFrequencyIndex == 0
                          ? 'Una sola vez'
                          : 'Mensual',
                      'metodoPago': _selectedPaymentMethod,
                    },
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: screenWidth * 0.050,
                      color: Colors.white,
                    ),
                    SizedBox(width: screenWidth * 0.02),
                    Text(
                      'Continuar de forma segura',
                      style: TextStyle(
                        fontSize: screenWidth * 0.044,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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

  Widget _buildAmountCard({
    required String label,
    required bool isSelected,
    required double screenWidth,
    required double usableHeight,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: screenWidth * 0.27,
        height: usableHeight * 0.062,
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
              color: isSelected ? Colors.white : azulFondo,
              fontSize: screenWidth * 0.038,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtherAmountCard({
    required bool isSelected,
    required double screenWidth,
    required double usableHeight,
    required VoidCallback onTap,
    int? montoPersonalizado,
  }) {
    final formatCurrency = NumberFormat("#,##0", "en_US");
    final String label = (isSelected && montoPersonalizado != null)
        ? 'RD\$${formatCurrency.format(montoPersonalizado)}'
        : 'Otro monto';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: usableHeight * 0.060,
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
              color: isSelected ? Colors.white : azulFondo,
              fontSize: screenWidth * 0.038,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencyCard({
    required String title,
    required bool isSelected,
    required double screenWidth,
    required double usableHeight,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: usableHeight * 0.065,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          border: Border.all(
            color: isSelected ? amarilloOro : grisBorde,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.035),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? amarilloOro : azulFondo,
                fontSize: screenWidth * 0.036,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            Container(
              width: screenWidth * 0.05,
              height: screenWidth * 0.05,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? amarilloOro : Colors.grey.shade400,
                  width: isSelected ? 2.5 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required FaIconData icon,
    required bool isSelected,
    required double screenWidth,
    required double usableHeight,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: usableHeight * 0.065,
        decoration: BoxDecoration(
          color: isSelected ? azulFondo.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          border: Border.all(
            color: isSelected ? amarilloOro : grisBorde,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              icon,
              color: isSelected ? amarilloOro : azulFondo,
              size: screenWidth * 0.055,
            ),
            SizedBox(width: screenWidth * 0.025),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? amarilloOro : azulFondo,
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copiarCuenta(
    BuildContext modalContext,
    String banco,
    String cuenta,
    double screenWidth,
    double usableHeight,
    Color azulFondo,
    Color amarilloOro,
    Color blancoFondo,
    Color grisBorde,
  ) {
    Clipboard.setData(ClipboardData(text: cuenta));
    final overlay = Overlay.of(modalContext);
    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(modalContext).padding.top + (usableHeight * 0.055),
        left: screenWidth * 0.03,
        right: screenWidth * 0.03,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: usableHeight * 0.030,
            ),
            decoration: BoxDecoration(
              color: azulFondo,
              borderRadius: BorderRadius.circular(screenWidth * 0.035),
              border: Border.all(
                color: amarilloOro.withValues(alpha: 0.5),
                width: 3.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.018),
                  decoration: BoxDecoration(
                    color: amarilloOro.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: amarilloOro,
                    size: screenWidth * 0.05,
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '¡Cuenta copiada al portapapeles!',
                        style: TextStyle(
                          color: amarilloOro,
                          fontSize: screenWidth * 0.055,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: usableHeight * 0.020),
                      Text(
                        '\(banco ·\)cuenta',
                        style: TextStyle(
                          color: blancoFondo,
                          fontSize: screenWidth * 0.030,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  void _mostrarModalTransferencia(
    BuildContext context,
    double screenWidth,
    double usableHeight,
  ) {
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);
    const Color grisBorde = Color(0xFFE8ECEF);
    const Color azulBadge = Color(0xFF00386C);
    const Color celesteCard = Color(0xFFE8F2F8);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: usableHeight * 0.88,
          decoration: BoxDecoration(
            color: blancoFondo,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(screenWidth * 0.08),
              topRight: Radius.circular(screenWidth * 0.08),
            ),
            border: Border.all(color: grisBorde),
          ),
          child: Column(
            children: [
              SizedBox(height: usableHeight * 0.018),
              Center(
                child: Container(
                  width: screenWidth * 0.12,
                  height: usableHeight * 0.006,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(screenWidth * 0.01),
                  ),
                ),
              ),
              SizedBox(height: usableHeight * 0.012),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.015,
                    vertical: usableHeight * 0.01,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'MÉTODOS',
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.075,
                          fontWeight: FontWeight.w900,
                          letterSpacing: screenWidth * 0.004,
                        ),
                      ),
                      Text(
                        'de pago',
                        style: TextStyle(
                          color: amarilloOro,
                          fontSize: screenWidth * 0.070,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                          height: 0.9,
                        ),
                      ),
                      SizedBox(height: usableHeight * 0.02),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: usableHeight * 0.010,
                        ),
                        decoration: BoxDecoration(
                          color: azulBadge,
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.08,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_balance_rounded,
                              color: amarilloOro,
                              size: screenWidth * 0.05,
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              'VÍA TRANSFERENCIA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: usableHeight * 0.015),
                      Text(
                        'Aceptamos transferencias bancarias desde\ncualquier banco de la República Dominicana.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: azulFondo.withValues(alpha: 0.8),
                          fontSize: screenWidth * 0.032,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: usableHeight * 0.025),
                      _buildBancoCard(
                        modalContext: ctx,
                        nombreBanco: 'BHD',
                        subtitulo: 'Banco BHD',
                        cuenta: '1234567-001-1',
                        colorLogo: const Color(0xFF007A33),
                        screenWidth: screenWidth,
                        usableHeight: usableHeight,
                        azulFondo: azulFondo,
                        amarilloOro: amarilloOro,
                        grisBorde: grisBorde,
                        celesteCard: celesteCard,
                        blancoFondo: blancoFondo,
                        logoBanco: 'bhd_logo',
                      ),
                      SizedBox(height: usableHeight * 0.014),
                      _buildBancoCard(
                        modalContext: ctx,
                        nombreBanco: 'POPULAR',
                        subtitulo: 'Banco Popular Dominicano',
                        cuenta: '765432198',
                        colorLogo: const Color(0xFF003B70),
                        screenWidth: screenWidth,
                        usableHeight: usableHeight,
                        azulFondo: azulFondo,
                        amarilloOro: amarilloOro,
                        grisBorde: grisBorde,
                        celesteCard: celesteCard,
                        blancoFondo: blancoFondo,
                        logoBanco: 'popular_logo',
                      ),
                      SizedBox(height: usableHeight * 0.014),
                      _buildBancoCard(
                        modalContext: ctx,
                        nombreBanco: 'BANRESERVAS',
                        subtitulo: 'Banco de Reservas',
                        cuenta: '9600012345',
                        colorLogo: const Color(0xFF0066B3),
                        screenWidth: screenWidth,
                        usableHeight: usableHeight,
                        azulFondo: azulFondo,
                        amarilloOro: amarilloOro,
                        grisBorde: grisBorde,
                        celesteCard: celesteCard,
                        blancoFondo: blancoFondo,
                        logoBanco: 'banreservas_logo',
                      ),
                      SizedBox(height: usableHeight * 0.015),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: usableHeight * 0.014,
                        ),
                        decoration: BoxDecoration(
                          color: azulFondo,
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.035,
                          ),
                          border: Border.all(color: grisBorde),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(screenWidth * 0.018),
                              decoration: BoxDecoration(
                                color: amarilloOro.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.verified_user_rounded,
                                color: amarilloOro,
                                size: screenWidth * 0.05,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.045),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TU PAGO ESTÁ SEGURO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.031,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Confianza, rapidez y seguridad en cada transacción.',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: screenWidth * 0.026,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: usableHeight * 0.005),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBancoCard({
    required BuildContext modalContext,
    required String nombreBanco,
    required String logoBanco,
    required String subtitulo,
    required String cuenta,
    required Color colorLogo,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color amarilloOro,
    required Color grisBorde,
    required Color celesteCard,
    required Color blancoFondo,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
        border: Border.all(color: grisBorde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(screenWidth * 0.035),
      child: Row(
        children: [
          Container(
            width: screenWidth * 0.30,
            height: screenWidth * 0.20,
            decoration: BoxDecoration(
              color: colorLogo.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/$logoBanco.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombreBanco,
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.055,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitulo,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: screenWidth * 0.028,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: usableHeight * 0.003),
                Text(
                  cuenta,
                  style: TextStyle(
                    color: const Color.fromARGB(255, 1, 25, 48),
                    fontSize: screenWidth * 0.032,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(screenWidth * 0.08),
              onTap: () => _copiarCuenta(
                modalContext,
                nombreBanco,
                cuenta,
                screenWidth,
                usableHeight,
                azulFondo,
                amarilloOro,
                blancoFondo,
                grisBorde,
              ),
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.025),
                decoration: BoxDecoration(
                  color: celesteCard,
                  shape: BoxShape.circle,
                  border: Border.all(color: grisBorde),
                ),
                child: Icon(
                  Icons.copy_rounded,
                  color: azulFondo,
                  size: screenWidth * 0.048,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
