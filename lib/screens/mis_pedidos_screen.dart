import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../modelos/pedido_model.dart';
import '../providers/user_provider.dart';
import 'tienda_screen.dart';

class MisPedidosScreen extends StatefulWidget {
  static const routeName = 'mis_pedidos_screen';

  const MisPedidosScreen({super.key});

  @override
  State<MisPedidosScreen> createState() => _MisPedidosScreenState();
}

class _MisPedidosScreenState extends State<MisPedidosScreen> {
  bool _isLoading = false;
  String _selectedScope = 'active'; // 'active' o 'past'
  List<PedidoModel> _pedidos = [];
  int _activeCount = 0;
  int _pastCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarPedidos();
    });
  }

  /// Consulta el listado real de pedidos en Odoo (GET /orders?scope={active|past})
  Future<void> _cargarPedidos() async {
    if (!mounted) return;
    final userProvider = context.read<UserProvider>();
    if (!userProvider.isAuthenticated) {
      if (mounted) {
        setState(() {
          _pedidos = [];
          _activeCount = 0;
          _pastCount = 0;
          _isLoading = false;
        });
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = userProvider.api;
      final data = await api.orders(scope: _selectedScope, limit: 50);

      final dynamic raw = data['orders'] ?? data['items'] ?? data['data'];
      final dynamic counts = data['counts'];

      if (mounted) {
        setState(() {
          if (raw is List) {
            _pedidos = raw
                .whereType<Map<String, dynamic>>()
                .map(PedidoModel.fromJson)
                .toList();
          } else {
            _pedidos = [];
          }

          if (counts is Map) {
            _activeCount = counts['active'] is int ? counts['active'] as int : _activeCount;
            _pastCount = counts['past'] is int ? counts['past'] as int : _pastCount;
          }
        });
      }
    } catch (e) {
      debugPrint('[PEDIDOS] Error al consultar pedidos: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _obtenerColorEstado(PedidoModel pedido) {
    final status = pedido.estado.toLowerCase();
    final colorStr = pedido.colorEstado.toLowerCase();

    if (colorStr == 'green' || status == 'done' || status == 'sale' || status == 'confirmed') {
      return const Color(0xFF2E7D32);
    }
    if (colorStr == 'orange' || status == 'payment_review' || status == 'sent') {
      return const Color(0xFFE5A023);
    }
    if (colorStr == 'blue' || status == 'draft') {
      return const Color(0xFF0055A5);
    }
    if (colorStr == 'red' || status == 'cancel' || status == 'cancelled') {
      return const Color(0xFFC62828);
    }
    return const Color(0xFF072B4F);
  }

  String _obtenerTextoEstado(PedidoModel pedido, AppLocalizations? l10n) {
    final status = pedido.estado.toLowerCase();
    switch (status) {
      case 'payment_review':
        return l10n?.estadoPagoEnVerificacion ?? 'Pago en verificación';
      case 'sale':
      case 'confirmed':
        return l10n?.estadoPedidoConfirmado ?? 'Confirmado';
      case 'done':
        return l10n?.estadoPedidoCompletado ?? 'Completado';
      case 'cancel':
      case 'cancelled':
        return l10n?.estadoPedidoCancelado ?? 'Cancelado';
      case 'draft':
        return l10n?.estadoPedidoBorrador ?? 'Borrador';
      case 'sent':
        return l10n?.estadoPedidoEnviado ?? 'Enviado';
      default:
        return pedido.estadoEtiqueta;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';

    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);
    const Color grisBorde = Color(0xFFE5E5E5);

    final String textoActivos = _activeCount > 0
        ? (l10n?.pedidosActivosConConteo(_activeCount) ?? 'Activos ($_activeCount)')
        : (l10n?.pedidosActivos ?? 'Activos');

    final String textoHistorial = _pastCount > 0
        ? (l10n?.pedidosHistorialConConteo(_pastCount) ?? 'Historial ($_pastCount)')
        : (l10n?.pedidosHistorial ?? 'Historial');

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: true,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight,
          child: Column(
            children: [
              // 1. Encabezado con Botón de Retroceso y Título
              Padding(
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
                    SizedBox(width: screenWidth * 0.035),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.misPedidos ?? 'Mis pedidos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.056,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            l10n?.historialComprasTienda ??
                                'Historial de compras en la Tienda Atrio',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: screenWidth * 0.032,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Botón para refrescar
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      onPressed: _cargarPedidos,
                    ),
                  ],
                ),
              ),

              // 2. Selector de Ámbito / Pestañas (Activos / Historial)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: usableHeight * 0.01,
                ),
                child: Container(
                  height: usableHeight * 0.052,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_selectedScope != 'active') {
                              setState(() => _selectedScope = 'active');
                              _cargarPedidos();
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedScope == 'active'
                                  ? amarilloOro
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(screenWidth * 0.03),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              textoActivos,
                              style: TextStyle(
                                color: _selectedScope == 'active'
                                    ? azulFondo
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.036,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_selectedScope != 'past') {
                              setState(() => _selectedScope = 'past');
                              _cargarPedidos();
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedScope == 'past'
                                  ? amarilloOro
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(screenWidth * 0.03),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              textoHistorial,
                              style: TextStyle(
                                color: _selectedScope == 'past'
                                    ? azulFondo
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.036,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Contenedor Principal Blanco con Esquinas Redondeadas
              Expanded(
                child: Container(
                  width: screenWidth,
                  decoration: BoxDecoration(
                    color: blancoFondo,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.07),
                      topRight: Radius.circular(screenWidth * 0.07),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.07),
                      topRight: Radius.circular(screenWidth * 0.07),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        screenWidth * 0.05,
                        usableHeight * 0.02,
                        screenWidth * 0.05,
                        usableHeight * 0.015,
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: _isLoading && _pedidos.isEmpty
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: azulFondo,
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _cargarPedidos,
                                    color: azulFondo,
                                    child: _pedidos.isEmpty
                                        ? _buildEstadoVacio(
                                            screenWidth,
                                            usableHeight,
                                            azulFondo,
                                            amarilloOro,
                                            l10n,
                                          )
                                        : ListView.separated(
                                            physics:
                                                const AlwaysScrollableScrollPhysics(
                                              parent: BouncingScrollPhysics(),
                                            ),
                                            itemCount: _pedidos.length,
                                            separatorBuilder:
                                                (context, index) => SizedBox(
                                              height: usableHeight * 0.014,
                                            ),
                                            itemBuilder: (context, index) {
                                              final pedido = _pedidos[index];
                                              return _buildPedidoCard(
                                                pedido: pedido,
                                                screenWidth: screenWidth,
                                                usableHeight: usableHeight,
                                                azulFondo: azulFondo,
                                                grisBorde: grisBorde,
                                                amarilloOro: amarilloOro,
                                                blancoFondo: blancoFondo,
                                                l10n: l10n,
                                                isEnglish: isEnglish,
                                              );
                                            },
                                          ),
                                  ),
                          ),

                          SizedBox(height: usableHeight * 0.015),

                          // Botón Inferior "Explorar Tienda"
                          SizedBox(
                            width: screenWidth,
                            height: usableHeight * 0.062,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.storefront_outlined),
                              label: Text(
                                l10n?.explorarTienda ?? 'Explorar Tienda',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: amarilloOro,
                                foregroundColor: azulFondo,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.035,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  TiendaScreen.routeName,
                                );
                              },
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.008),
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

  // Componente: Estado Vacío
  Widget _buildEstadoVacio(
    double screenWidth,
    double usableHeight,
    Color azulFondo,
    Color amarilloOro,
    AppLocalizations? l10n,
  ) {
    final userProvider = context.watch<UserProvider>();
    final bool esInvitado = !userProvider.isAuthenticated;

    final String tituloVacio = esInvitado
        ? (l10n?.modoInvitado ?? 'Modo invitado')
        : (_selectedScope == 'active'
            ? (l10n?.noTienesPedidosActivos ?? 'No tienes pedidos activos')
            : (l10n?.noTienesPedidosAnteriores ?? 'No tienes pedidos anteriores'));

    final String descVacio = esInvitado
        ? (l10n?.pedidosInvitadoDesc ??
            'En modo invitado no se registran compras ni pedidos. Inicia sesión para consultar tus pedidos.')
        : (_selectedScope == 'active'
            ? (l10n?.pedidosActivosDesc ??
                'Tus compras recientes de la tienda ATRIO aparecerán aquí para que hagas seguimiento a su entrega.')
            : (l10n?.pedidosAnterioresDesc ??
                'Cuando tus pedidos sean completados o entregados, podrás consultarlos en este historial.'));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: [
        SizedBox(height: usableHeight * 0.12),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.05),
                decoration: BoxDecoration(
                  color: azulFondo.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  esInvitado ? Icons.account_circle_outlined : Icons.receipt_long_outlined,
                  size: screenWidth * 0.16,
                  color: azulFondo.withValues(alpha: 0.5),
                ),
              ),
              SizedBox(height: usableHeight * 0.02),
              Text(
                tituloVacio,
                style: TextStyle(
                  fontSize: screenWidth * 0.046,
                  fontWeight: FontWeight.bold,
                  color: azulFondo,
                ),
              ),
              SizedBox(height: usableHeight * 0.01),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                child: Text(
                  descVacio,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.034,
                    color: Colors.black54,
                    height: 1.35,
                  ),
                ),
              ),
              if (esInvitado) ...[
                SizedBox(height: usableHeight * 0.025),
                ElevatedButton.icon(
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: Text(
                    l10n?.iniciarSesion ?? 'Iniciar sesión',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azulFondo,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: usableHeight * 0.012,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                  ),
                  onPressed: () {
                    final nav = Navigator.maybeOf(context) ??
                        MyApp.navigatorKey.currentState;
                    nav?.pushNamed(
                      'inicio_sesion_screen',
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Componente: Tarjeta de Pedido
  Widget _buildPedidoCard({
    required PedidoModel pedido,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color grisBorde,
    required Color amarilloOro,
    required Color blancoFondo,
    required AppLocalizations? l10n,
    required bool isEnglish,
  }) {
    final statusColor = _obtenerColorEstado(pedido);
    final statusText = _obtenerTextoEstado(pedido, l10n);

    return GestureDetector(
      onTap: () => _mostrarDetallePedido(
        pedido: pedido,
        screenWidth: screenWidth,
        usableHeight: usableHeight,
        azulFondo: azulFondo,
        blancoFondo: blancoFondo,
        grisBorde: grisBorde,
        amarilloOro: amarilloOro,
        l10n: l10n,
        isEnglish: isEnglish,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.045,
          vertical: usableHeight * 0.016,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          border: Border.all(color: grisBorde),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila Superior: Referencia + Estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.02),
                      decoration: BoxDecoration(
                        color: azulFondo.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: screenWidth * 0.05,
                        color: azulFondo,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.025),
                    Text(
                      l10n?.pedidoItemTitulo(pedido.nombre) ??
                          'Pedido ${pedido.nombre}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.042,
                        color: azulFondo,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.025,
                    vertical: usableHeight * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: screenWidth * 0.03,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: usableHeight * 0.012),

            // Artículos Resumen
            if (pedido.items.isNotEmpty) ...[
              Text(
                pedido.items
                    .map((it) => '${it.cantidad.toInt()}x ${it.nombre}')
                    .join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: screenWidth * 0.034,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: usableHeight * 0.008),
            ],

            // Fila Inferior: Fecha + Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  pedido.formatearFecha(isEnglish: isEnglish),
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    color: Colors.black45,
                  ),
                ),
                Text(
                  pedido.totalFormateado,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.044,
                    color: azulFondo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Modal / BottomSheet de Detalle del Pedido
  void _mostrarDetallePedido({
    required PedidoModel pedido,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color blancoFondo,
    required Color grisBorde,
    required Color amarilloOro,
    required AppLocalizations? l10n,
    required bool isEnglish,
  }) {
    final statusColor = _obtenerColorEstado(pedido);
    final statusText = _obtenerTextoEstado(pedido, l10n);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: blancoFondo,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(screenWidth * 0.06),
            topRight: Radius.circular(screenWidth * 0.06),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          screenWidth * 0.06,
          usableHeight * 0.025,
          screenWidth * 0.06,
          usableHeight * 0.03,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: screenWidth * 0.12,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: usableHeight * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.detalleDeOrden ?? 'Detalle de Orden',
                  style: TextStyle(
                    fontSize: screenWidth * 0.052,
                    fontWeight: FontWeight.bold,
                    color: azulFondo,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.03,
                    vertical: usableHeight * 0.006,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.032,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: usableHeight * 0.015),

            // Tarjeta de información del pedido
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                border: Border.all(color: grisBorde),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(
                    l10n?.referenciaOdooColon ?? 'Referencia Odoo:',
                    pedido.nombre,
                    isBold: true,
                  ),
                  SizedBox(height: usableHeight * 0.008),
                  _infoRow(
                    l10n?.fechaDelPedido ?? 'Fecha del pedido:',
                    pedido.formatearFecha(isEnglish: isEnglish),
                  ),
                  SizedBox(height: usableHeight * 0.008),
                  _infoRow(
                    l10n?.totalAPagar ?? 'Total a pagar:',
                    pedido.totalFormateado,
                    isBold: true,
                    textColor: azulFondo,
                  ),
                ],
              ),
            ),
            SizedBox(height: usableHeight * 0.02),

            Text(
              l10n?.articulosIncluidos ?? 'Artículos incluidos:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.038,
                color: azulFondo,
              ),
            ),
            SizedBox(height: usableHeight * 0.01),

            // Lista de artículos
            ...pedido.items.map(
              (it) => Container(
                margin: EdgeInsets.only(bottom: usableHeight * 0.008),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.035,
                  vertical: usableHeight * 0.01,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: grisBorde),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        it.nombre,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      l10n?.unidadesProducto(it.cantidad.toInt()) ??
                          '${it.cantidad.toInt()} ud(s).',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: azulFondo,
                        fontSize: screenWidth * 0.034,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: usableHeight * 0.02),

            // Botón Cerrar
            SizedBox(
              width: double.infinity,
              height: usableHeight * 0.055,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulFondo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n?.cerrar ?? 'Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value,
      {bool isBold = false, Color? textColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: textColor ?? Colors.black87,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
