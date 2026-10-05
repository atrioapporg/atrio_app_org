import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../widgets/modal_otro_monto.dart';

class AportarAProyectoScreen extends StatefulWidget {
  static const routeName = 'aportar_a_proyecto_screen';
  const AportarAProyectoScreen({super.key});

  @override
  State<AportarAProyectoScreen> createState() => _AportarAProyectoScreenState();
}

class _AportarAProyectoScreenState extends State<AportarAProyectoScreen> {
  final TextEditingController _supportMessageController =
      TextEditingController();

  int _selectedAmountIndex = 1; // Preseleccionado: segundo valor (1000)
  int? _montoPersonalizado;
  bool _isAnonymous = false;
  bool _isInit = true;

  // Selección dinámica de método de pago
  String _selectedPaymentMethod = 'Transferencia';

  // Montos predefinidos
  final List<int> _presetAmounts = [500, 1000, 2500];

  // Datos simulados del proyecto
  String _proyectoTitulo = 'Un techo para servir';
  String _proyectoSubtitulo = 'Renovemos el salón comunitario';
  final String _comunidad = 'Comunidad de Esperanza';

  // Paleta de diseño oficial ATRIO
  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFE8ECEF);
  static const Color azulBadge = Color(0xFF00386C);
  static const Color celesteCard = Color(0xFFE8F2F8);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        _proyectoTitulo = args['titulo'] ?? _proyectoTitulo;
        _proyectoSubtitulo = args['subtitulo'] ?? _proyectoSubtitulo;
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
    // Métricas dinámicas relativas (Flutter 3.22+)
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    final formatCurrency = NumberFormat("#,##0", "en_US");

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: true,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight,
          child: Column(
            children: [
              // Encabezado Superior
              Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  children: [
                    SizedBox(height: usableHeight * 0.01),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox.shrink(),
                        Row(
                          children: [
                            Container(
                              width: screenWidth * 0.018,
                              height: screenWidth * 0.018,
                              decoration: const BoxDecoration(
                                color: Colors.white70,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.01),
                            Container(
                              width: screenWidth * 0.018,
                              height: screenWidth * 0.018,
                              decoration: const BoxDecoration(
                                color: Colors.white70,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.01),
                            Container(
                              width: screenWidth * 0.035,
                              height: screenWidth * 0.015,
                              decoration: BoxDecoration(
                                color: Colors.white70,
                                borderRadius: BorderRadius.circular(
                                  screenWidth * 0.01,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.01),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: screenWidth * 0.085,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: screenWidth * 0.085,
                              ),
                              child: Text(
                                'Realizar un aporte',
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
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.055,
                        vertical: usableHeight * 0.025,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Tarjeta de Identificación del Proyecto dinámico
                          _buildProjectHeaderCard(
                            titulo: _proyectoTitulo,
                            subtitulo: _proyectoSubtitulo,
                            comunidad: _comunidad,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                          ),
                          SizedBox(height: usableHeight * 0.025),

                          // 2. ¿Cuánto deseas aportar?
                          Text(
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
                              return _buildAmountCard(
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
                          _buildOtherAmountCard(
                            isSelected: _selectedAmountIndex == -1,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            montoPersonalizado: _montoPersonalizado,
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

                          // 3. NUEVO: Selección Dinámica del Método de Pago
                          Text(
                            'Método de pago',
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.045,
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
                                  isSelected:
                                      _selectedPaymentMethod == 'Transferencia',
                                  screenWidth: screenWidth,
                                  usableHeight: usableHeight,
                                  onTap: () {
                                    setState(
                                      () => _selectedPaymentMethod =
                                          'Transferencia',
                                    );
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
                                  isSelected:
                                      _selectedPaymentMethod == 'Apple Pay',
                                  screenWidth: screenWidth,
                                  usableHeight: usableHeight,
                                  onTap: () => setState(
                                    () => _selectedPaymentMethod = 'Apple Pay',
                                  ),
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
                                  isSelected:
                                      _selectedPaymentMethod == 'Google Pay',
                                  screenWidth: screenWidth,
                                  usableHeight: usableHeight,
                                  onTap: () => setState(
                                    () => _selectedPaymentMethod = 'Google Pay',
                                  ),
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Expanded(
                                child: _buildPaymentOption(
                                  title: 'PayPal',
                                  icon: FontAwesomeIcons.paypal,
                                  isSelected:
                                      _selectedPaymentMethod == 'PayPal',
                                  screenWidth: screenWidth,
                                  usableHeight: usableHeight,
                                  onTap: () => setState(
                                    () => _selectedPaymentMethod = 'PayPal',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: usableHeight * 0.025),

                          // 4. Mensaje de apoyo
                          Text(
                            'Mensaje de apoyo',
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.012),
                          Container(
                            height: usableHeight * 0.11,
                            padding: EdgeInsets.symmetric(
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
                                hintText: 'Escribe un mensaje opcional...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: screenWidth * 0.036,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.02),

                          // 5. Checkbox: Mostrar mi aporte como anónimo
                          Row(
                            children: [
                              SizedBox(
                                width: screenWidth * 0.06,
                                height: screenWidth * 0.06,
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
                              Text(
                                'Mostrar mi aporte como anónimo',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: screenWidth * 0.034,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: usableHeight * 0.03),

                          // 6. Botón: Continuar con el aporte
                          SizedBox(
                            width: screenWidth,
                            height: usableHeight * 0.065,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: amarilloOro,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.03,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                // Determinamos el monto seleccionado
                                final String montoAEnviar =
                                    _selectedAmountIndex == -1
                                    ? 'RD\$ ${formatCurrency.format(_montoPersonalizado ?? 0)}'
                                    : 'RD\$ ${formatCurrency.format(_presetAmounts[_selectedAmountIndex])}';

                                Navigator.pushNamed(
                                  context,
                                  'confirmar_donacion_screen',
                                  arguments: {
                                    'comunidad': _comunidad,
                                    'concepto': 'Proyecto: $_proyectoTitulo',
                                    'monto': montoAEnviar,
                                    'frecuencia': 'Una sola vez',
                                    'metodoPago': _selectedPaymentMethod,
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
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    'Continuar con el aporte',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.04,
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Componente: Tarjeta superior de presentación del proyecto
  Widget _buildProjectHeaderCard({
    required String titulo,
    required String subtitulo,
    required String comunidad,
    required double screenWidth,
    required double usableHeight,
  }) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
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
                Positioned(
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
                  'PROYECTO',
                  style: TextStyle(
                    color: Colors.grey.shade500,
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
                    color: Colors.grey.shade600,
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

  // Componente: Tarjeta de Monto Predefinido
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
              color: isSelected ? Colors.white : azulFondo,
              fontSize: screenWidth * 0.036,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // Componente: Botón "Otro monto"
  Widget _buildOtherAmountCard({
    required bool isSelected,
    required double screenWidth,
    required double usableHeight,
    required VoidCallback onTap,
    int? montoPersonalizado,
  }) {
    final formatCurrency = NumberFormat("#,##0", "en_US");
    final String label = (isSelected && montoPersonalizado != null)
        ? 'RD\$ ${formatCurrency.format(montoPersonalizado)}'
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

  // Componente: Opción de Método de Pago
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

  // =========================================================
  // NOTIFICACIÓN FLOTANTE VISIBLE SOBRE EL MODAL (OVERLAY)
  // =========================================================
  void _copiarCuenta(
    BuildContext modalContext,
    String banco,
    String cuenta,
    double screenWidth,
    double usableHeight,
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
                        '$banco · $cuenta',
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

  // =========================================================
  // MODAL BOTTOM SHEET DE TRANSFERENCIAS BANCARIAS
  // =========================================================
  void _mostrarModalTransferencia(
    BuildContext context,
    double screenWidth,
    double usableHeight,
  ) {
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

  // Componente Reutilizable para cada Banco en el Modal
  Widget _buildBancoCard({
    required BuildContext modalContext,
    required String nombreBanco,
    required String logoBanco,
    required String subtitulo,
    required String cuenta,
    required Color colorLogo,
    required double screenWidth,
    required double usableHeight,
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
