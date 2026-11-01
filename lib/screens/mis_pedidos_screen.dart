import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../modelos/pedido_model.dart';
import '../providers/user_provider.dart';
import '../widgets/atrio_connectivity_alert.dart';
import 'tienda_screen.dart';

class MisPedidosScreen extends StatefulWidget {
  static const routeName = 'mis_pedidos_screen';

  const MisPedidosScreen({super.key});

  @override
  State<MisPedidosScreen> createState() => _MisPedidosScreenState();
}

class _MisPedidosScreenState extends State<MisPedidosScreen> {
  bool _isLoading = false;
  bool _errorServidor = false;
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
          _errorServidor = false;
        });
      }
      return;
    }

    final bool hasInternet = await AtrioConnectivityAlert.checkAndNotify(
      context,
      onRetry: _cargarPedidos,
    );
    if (!hasInternet || !mounted) {
      setState(() {
        _isLoading = false;
        _errorServidor = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorServidor = false;
    });

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
            _activeCount = counts['active'] is int
                ? counts['active'] as int
                : _activeCount;
            _pastCount = counts['past'] is int
                ? counts['past'] as int
                : _pastCount;
          }
          _errorServidor = false;
        });
      }
    } catch (e) {
      debugPrint('[PEDIDOS] Error al consultar pedidos: $e');
      if (mounted) {
        setState(() => _errorServidor = true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _obtenerColorEstado(PedidoModel pedido) {
    final status = pedido.estado.toLowerCase();
    final colorStr = pedido.colorEstado.toLowerCase();

    if (colorStr == 'green' ||
        status == 'done' ||
        status == 'sale' ||
        status == 'confirmed' ||
        status == 'delivered' ||
        status == 'paid' ||
        status == 'approved' ||
        status == 'completado' ||
        status == 'entregado') {
      return const Color(0xFF2E7D32);
    }
    if (colorStr == 'orange' ||
        status == 'payment_review' ||
        status == 'sent' ||
        status == 'processing' ||
        status == 'preparation' ||
        status == 'en_proceso' ||
        status == 'pendiente') {
      return const Color(0xFFE5A023);
    }
    if (colorStr == 'blue' || status == 'draft' || status == 'borrador') {
      return const Color(0xFF0055A5);
    }
    if (colorStr == 'red' ||
        status == 'cancel' ||
        status == 'cancelled' ||
        status == 'cancelado' ||
        status == 'denied') {
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
      case 'completed':
        return l10n?.estadoPedidoCompletado ?? 'Completado';
      case 'delivered':
        return l10n?.estadoPedidoEntregado ?? 'Entregado';
      case 'paid':
        return l10n?.estadoPedidoPagado ?? 'Pagado';
      case 'cancel':
      case 'cancelled':
        return l10n?.estadoPedidoCancelado ?? 'Cancelado';
      case 'draft':
        return l10n?.estadoPedidoBorrador ?? 'Borrador';
      case 'sent':
        return l10n?.estadoPedidoEnviado ?? 'Enviado';
      default:
        return pedido.estadoEtiqueta.isNotEmpty
            ? pedido.estadoEtiqueta
            : status;
    }
  }

  void _mostrarDetallePedido(PedidoModel pedido) {
    final l10n = AppLocalizations.of(context);
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    const Color azulFondo = Color(0xFF072B4F);
    const Color blancoFondo = Color(0xFFFAF7F0);
    const Color grisBorde = Color(0xFFE5E5E5);

    final statusColor = _obtenerColorEstado(pedido);
    final statusText = _obtenerTextoEstado(pedido, l10n);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PedidoDetalleSheet(
        pedido: pedido,
        screenWidth: screenWidth,
        usableHeight: usableHeight,
        azulFondo: azulFondo,
        blancoFondo: blancoFondo,
        grisBorde: grisBorde,
        statusColor: statusColor,
        statusText: statusText,
        l10n: l10n,
        isEnglish: isEnglish,
      ),
    );
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
        ? (l10n?.pedidosActivosConConteo(_activeCount) ??
              'Activos ($_activeCount)')
        : (l10n?.pedidosActivos ?? 'Activos');

    final String textoHistorial = _pastCount > 0
        ? (l10n?.pedidosHistorialConConteo(_pastCount) ??
              'Historial ($_pastCount)')
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
                padding: EdgeInsetsDirectional.symmetric(
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
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                      ),
                      onPressed: _cargarPedidos,
                    ),
                  ],
                ),
              ),

              // 2. Selector de Ámbito / Pestañas (Activos / Historial)
              Padding(
                padding: EdgeInsetsDirectional.symmetric(
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
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.03,
                              ),
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
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.03,
                              ),
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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(screenWidth * 0.07),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(screenWidth * 0.07),
                    ),
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
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
                                        ? _EstadoVacioPedidos(
                                            screenWidth: screenWidth,
                                            usableHeight: usableHeight,
                                            azulFondo: azulFondo,
                                            errorServidor: _errorServidor,
                                            selectedScope: _selectedScope,
                                            onRetry: _cargarPedidos,
                                            l10n: l10n,
                                          )
                                        : ListView.separated(
                                            physics:
                                                const AlwaysScrollableScrollPhysics(
                                                  parent:
                                                      BouncingScrollPhysics(),
                                                ),
                                            itemCount: _pedidos.length,
                                            separatorBuilder:
                                                (context, index) => SizedBox(
                                                  height: usableHeight * 0.014,
                                                ),
                                            itemBuilder: (context, index) {
                                              final pedido = _pedidos[index];
                                              return _PedidoCard(
                                                pedido: pedido,
                                                screenWidth: screenWidth,
                                                usableHeight: usableHeight,
                                                azulFondo: azulFondo,
                                                grisBorde: grisBorde,
                                                amarilloOro: amarilloOro,
                                                blancoFondo: blancoFondo,
                                                statusColor:
                                                    _obtenerColorEstado(pedido),
                                                statusText: _obtenerTextoEstado(
                                                  pedido,
                                                  l10n,
                                                ),
                                                l10n: l10n,
                                                isEnglish: isEnglish,
                                                onTap: () =>
                                                    _mostrarDetallePedido(
                                                      pedido,
                                                    ),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
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
}

/// Estado Vacío de pedidos o error de sincronización
class _EstadoVacioPedidos extends StatelessWidget {
  const _EstadoVacioPedidos({
    required this.screenWidth,
    required this.usableHeight,
    required this.azulFondo,
    required this.errorServidor,
    required this.selectedScope,
    required this.onRetry,
    required this.l10n,
  });

  final double screenWidth;
  final double usableHeight;
  final Color azulFondo;
  final bool errorServidor;
  final String selectedScope;
  final VoidCallback onRetry;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final bool esInvitado = !userProvider.isAuthenticated;

    final String tituloVacio = esInvitado
        ? (l10n?.modoInvitado ?? 'Modo invitado')
        : (errorServidor
              ? (l10n?.errorSincronizacion ?? 'Error de sincronización')
              : (selectedScope == 'active'
                    ? (l10n?.noTienesPedidosActivos ??
                          'No tienes pedidos activos')
                    : (l10n?.noTienesPedidosAnteriores ??
                          'No tienes pedidos anteriores')));

    final String descVacio = esInvitado
        ? (l10n?.pedidosInvitadoDesc ??
              'En modo invitado no se registran compras ni pedidos. Inicia sesión para consultar tus pedidos.')
        : (errorServidor
              ? (l10n?.errorSincronizacionPedidosDesc ??
                    'No pudimos conectar con el servidor para consultar tus pedidos. Reintenta la conexión.')
              : (selectedScope == 'active'
                    ? (l10n?.pedidosActivosDesc ??
                          'Tus compras recientes de la tienda ATRIO aparecerán aquí para que hagas seguimiento a su entrega.')
                    : (l10n?.pedidosAnterioresDesc ??
                          'Cuando tus pedidos sean completados o entregados, podrás consultarlos en este historial.')));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
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
                  esInvitado
                      ? Icons.account_circle_outlined
                      : (errorServidor
                            ? Icons.cloud_off_rounded
                            : Icons.receipt_long_outlined),
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
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: screenWidth * 0.08,
                ),
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
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: usableHeight * 0.012,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                  ),
                  onPressed: () {
                    final nav =
                        MyApp.navigatorKey.currentState ??
                        (context.mounted ? Navigator.maybeOf(context) : null);
                    nav?.pushNamed('inicio_sesion_screen');
                  },
                ),
              ] else if (errorServidor) ...[
                SizedBox(height: usableHeight * 0.025),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    l10n?.reintentar ?? 'Reintentar',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: azulFondo,
                    foregroundColor: Colors.white,
                    padding: EdgeInsetsDirectional.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: usableHeight * 0.012,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    ),
                  ),
                  onPressed: onRetry,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Tarjeta individual de pedido en la lista
class _PedidoCard extends StatelessWidget {
  const _PedidoCard({
    required this.pedido,
    required this.screenWidth,
    required this.usableHeight,
    required this.azulFondo,
    required this.grisBorde,
    required this.amarilloOro,
    required this.blancoFondo,
    required this.statusColor,
    required this.statusText,
    required this.l10n,
    required this.isEnglish,
    required this.onTap,
  });

  final PedidoModel pedido;
  final double screenWidth;
  final double usableHeight;
  final Color azulFondo;
  final Color grisBorde;
  final Color amarilloOro;
  final Color blancoFondo;
  final Color statusColor;
  final String statusText;
  final AppLocalizations? l10n;
  final bool isEnglish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsetsDirectional.symmetric(
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
                  padding: EdgeInsetsDirectional.symmetric(
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
}

/// Bottom Sheet modal con el detalle completo del pedido
class _PedidoDetalleSheet extends StatelessWidget {
  const _PedidoDetalleSheet({
    required this.pedido,
    required this.screenWidth,
    required this.usableHeight,
    required this.azulFondo,
    required this.blancoFondo,
    required this.grisBorde,
    required this.statusColor,
    required this.statusText,
    required this.l10n,
    required this.isEnglish,
  });

  final PedidoModel pedido;
  final double screenWidth;
  final double usableHeight;
  final Color azulFondo;
  final Color blancoFondo;
  final Color grisBorde;
  final Color statusColor;
  final String statusText;
  final AppLocalizations? l10n;
  final bool isEnglish;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: blancoFondo,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.06),
        ),
      ),
      padding: EdgeInsetsDirectional.fromSTEB(
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
                padding: EdgeInsetsDirectional.symmetric(
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
                _InfoRow(
                  label: l10n?.referenciaOdooColon ?? 'Referencia Odoo:',
                  value: pedido.nombre,
                  isBold: true,
                ),
                SizedBox(height: usableHeight * 0.008),
                _InfoRow(
                  label: l10n?.fechaDelPedido ?? 'Fecha del pedido:',
                  value: pedido.formatearFecha(isEnglish: isEnglish),
                ),
                SizedBox(height: usableHeight * 0.008),
                _InfoRow(
                  label: l10n?.totalAPagar ?? 'Total a pagar:',
                  value: pedido.totalFormateado,
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
              padding: EdgeInsetsDirectional.symmetric(
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

          // Enlace al portal web si está disponible en Odoo
          if (pedido.portalUrl != null && pedido.portalUrl!.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              height: usableHeight * 0.052,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: azulFondo,
                  side: BorderSide(color: azulFondo),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                label: Text(
                  l10n?.verOrdenPortalOdoo ?? 'Ver orden en Portal Odoo',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final bool hasNet =
                      await AtrioConnectivityAlert.checkAndNotify(
                        context,
                        onRetry: () {},
                      );
                  if (!hasNet) return;
                  try {
                    final uri = Uri.parse(pedido.portalUrl!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  } catch (e) {
                    debugPrint('[PEDIDOS] Error abriendo portal_url: $e');
                  }
                },
              ),
            ),
            SizedBox(height: usableHeight * 0.012),
          ],

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
              onPressed: () => Navigator.pop(context),
              child: Text(l10n?.cerrar ?? 'Cerrar'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de información clave-valor con alineación adaptada
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.textColor,
  });

  final String label;
  final String value;
  final bool isBold;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
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
