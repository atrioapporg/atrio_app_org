import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../providers/user_provider.dart';
import '../widgets/atrio_connectivity_alert.dart';
import '../widgets/modal_restriccion_donacion.dart';
import 'donaciones_screen.dart';
import 'inicio_sesion_screen.dart';

class MisDonacionesScreen extends StatefulWidget {
  static const routeName = 'mis_donaciones_screen';

  const MisDonacionesScreen({super.key});

  @override
  State<MisDonacionesScreen> createState() => _MisDonacionesScreenState();
}

class _MisDonacionesScreenState extends State<MisDonacionesScreen> {
  bool _isLoading = false;
  bool _errorServidor = false;
  List<Map<String, dynamic>> _rawDonaciones = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDonaciones();
    });
  }

  /// Consulta el historial real de donaciones del usuario en Odoo (GET /donations/mine)
  Future<void> _cargarDonaciones() async {
    if (!mounted) return;
    final userProvider = context.read<UserProvider>();
    if (!userProvider.isAuthenticated) {
      if (mounted) {
        setState(() {
          _rawDonaciones = [];
          _isLoading = false;
          _errorServidor = false;
        });
      }
      return;
    }

    final bool hasInternet = await AtrioConnectivityAlert.checkAndNotify(
      context,
      onRetry: _cargarDonaciones,
    );
    if (!hasInternet || !mounted) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorServidor = true;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorServidor = false;
    });

    try {
      final api = userProvider.api;
      final data = await api.myDonations();
      final dynamic raw = data['donations'] ?? data['items'] ?? data['data'];

      if (raw is List && mounted) {
        setState(() {
          _rawDonaciones = raw.whereType<Map<String, dynamic>>().toList();
          _errorServidor = false;
        });
      }
    } catch (e) {
      debugPrint('[DONACIONES] Error al consultar donaciones en Odoo: $e');
      if (mounted) {
        setState(() => _errorServidor = true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Mapea los registros devueltos por Odoo 19 normalizando estados, etiquetas y formatos según el locale activo.
  Map<String, dynamic> _mapearDonacion(
    Map<String, dynamic> m,
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final rawAmount = m['amount'] ?? m['monto'] ?? 0.0;
    final currency = (m['currency'] ?? 'DOP').toString().toUpperCase();
    final state = (m['state'] ?? m['status'] ?? '')
        .toString()
        .toLowerCase()
        .trim();
    final stateLabel = m['state_label']?.toString();

    // Determinación de estado, etiquetas y colores normalizados con Odoo 19
    String statusText;
    Color statusColor;
    IconData icon;
    Color iconColor;

    if (state == 'processed' ||
        state == 'procesada' ||
        state == 'approved' ||
        state == 'aprobada' ||
        state == 'completed' ||
        state == 'completada' ||
        state == 'done') {
      statusColor = const Color(0xFF2E7D32); // Verde Odoo
      statusText = stateLabel ?? (l10n?.estadoDonacionProcesada ?? 'Procesada');
      icon = Icons.check_circle_outline_rounded;
      iconColor = const Color(0xFF2E7D32);
    } else if (state == 'pending' ||
        state == 'pendiente' ||
        state == 'draft' ||
        state == 'borrador') {
      statusColor = const Color(0xFFE5A023); // Amarillo/Ámbar Odoo
      statusText = stateLabel ?? (l10n?.estadoDonacionPendiente ?? 'Pendiente');
      icon = Icons.hourglass_top_rounded;
      iconColor = const Color(0xFFE5A023);
    } else if (state == 'rejected' ||
        state == 'denied' ||
        state == 'rechazada' ||
        state == 'denegada' ||
        state == 'cancelled' ||
        state == 'cancelada') {
      statusColor = const Color(0xFFC62828); // Rojo
      statusText = stateLabel ?? (l10n?.estadoDonacionDenegada ?? 'Denegada');
      icon = Icons.cancel_outlined;
      iconColor = const Color(0xFFC62828);
    } else {
      statusColor = const Color(0xFF0055A5); // Azul
      statusText =
          stateLabel ??
          (state.isNotEmpty
              ? state
              : (l10n?.estadoDonacionEnProceso ?? 'En proceso'));
      icon = Icons.favorite_border_rounded;
      iconColor = const Color(0xFF0055A5);
    }

    // Formateo del monto con NumberFormat (intl) respetando el locale activo
    double numAmount = 0.0;
    if (rawAmount is num) {
      numAmount = rawAmount.toDouble();
    } else if (rawAmount is String) {
      numAmount = double.tryParse(rawAmount) ?? 0.0;
    }
    final currencyFormat = NumberFormat.currency(
      locale: locale,
      symbol: '$currency ',
      decimalDigits: 2,
    );
    final montoFormateado = currencyFormat.format(numAmount);

    // Formateo de fechas amigable usando DateFormat (intl)
    final rawDate = m['date'] ?? m['create_date'] ?? m['fecha'];
    String fechaCorta = l10n?.fechaReciente ?? 'Reciente';
    String fechaCompleta = l10n?.fechaReciente ?? 'Reciente';
    if (rawDate != null) {
      try {
        final dt = DateTime.parse(rawDate.toString()).toLocal();
        fechaCorta = DateFormat.yMMMd(locale).format(dt);
        fechaCompleta = DateFormat.yMMMd(locale).add_jm().format(dt);
      } catch (_) {
        fechaCorta = rawDate.toString().split('T').first;
        fechaCompleta = rawDate.toString();
      }
    }

    // Método de pago amigable
    final rawMethod = (m['payment_method'] ?? '').toString().toLowerCase();
    String metodoLabel = m['payment_method_label']?.toString() ?? '';
    if (metodoLabel.isEmpty) {
      if (rawMethod.contains('transfer')) {
        metodoLabel =
            l10n?.metodoTransferenciaBancaria ?? 'Transferencia bancaria';
      } else if (rawMethod.contains('paypal')) {
        metodoLabel = 'PayPal';
      } else {
        metodoLabel =
            l10n?.metodoTransferenciaOnline ?? 'Transferencia / Online';
      }
    }

    final String ref =
        m['reference']?.toString() ??
        (m['id'] != null ? 'DON-${m['id']}' : 'DON-0000');

    final String titulo =
        m['name']?.toString() ??
        m['title']?.toString() ??
        (l10n?.aporteConMetodo(metodoLabel) ?? 'Aporte ($metodoLabel)');

    return {
      'title': titulo,
      'monto': montoFormateado,
      'status': statusText,
      'statusColor': statusColor,
      'state': state,
      'dateInfo': fechaCorta,
      'fechaCompleta': fechaCompleta,
      'icon': icon,
      'iconColor': iconColor,
      'referencia': ref,
      'metodoPago': metodoLabel,
      'destino': m['church_name'] ?? 'Comunidad ATRIO',
      'detalle':
          m['notes'] ??
          (l10n?.aporteVoluntarioRegistrado ??
              'Aporte voluntario registrado en ATRIO.'),
    };
  }

  void _mostrarDetalleDonacion(Map<String, dynamic> item) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    const Color azulFondo = Color(0xFF072B4F);
    const Color blancoFondo = Color(0xFFFAF7F0);
    const Color grisBorde = Color(0xFFE5E5E5);
    const Color amarilloOro = Color(0xFFE5A023);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final safeBottom = MediaQuery.of(ctx).padding.bottom;
        return _DonationDetailSheet(
          item: item,
          screenWidth: screenWidth,
          usableHeight: usableHeight,
          safeBottom: safeBottom,
          azulFondo: azulFondo,
          blancoFondo: blancoFondo,
          grisBorde: grisBorde,
          amarilloOro: amarilloOro,
          l10n: l10n,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);
    const Color grisBorde = Color(0xFFE5E5E5);

    // En modo invitado NO se muestran donaciones de prueba ni historial
    final userProvider = context.watch<UserProvider>();
    final bool esInvitado = !userProvider.isAuthenticated;
    final List<Map<String, dynamic>> donaciones = esInvitado
        ? const []
        : _rawDonaciones.map((d) => _mapearDonacion(d, context)).toList();

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: true,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight,
          child: Column(
            children: [
              // Encabezado Superior (Título con Botón Volver)
              Container(
                width: screenWidth,
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: screenWidth * 0.05,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: usableHeight * 0.015),
                    Row(
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
                        Text(
                          l10n?.misDonaciones ?? 'Mis donaciones',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.065,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.02),
                  ],
                ),
              ),

              // Contenedor Blanco Inferior con Lista de Donaciones y Botón
              Expanded(
                child: Container(
                  width: screenWidth,
                  decoration: BoxDecoration(
                    color: blancoFondo,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(screenWidth * 0.08),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(screenWidth * 0.08),
                    ),
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        screenWidth * 0.05,
                        usableHeight * 0.022,
                        screenWidth * 0.05,
                        usableHeight * 0.022,
                      ),
                      child: Column(
                        children: [
                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: LinearProgressIndicator(
                                color: azulFondo,
                                minHeight: 2,
                              ),
                            ),

                          // Lista de Donaciones Desplazable o Estado Vacío
                          Expanded(
                            child: donaciones.isEmpty
                                ? Center(
                                    child: SingleChildScrollView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(
                                            parent: BouncingScrollPhysics(),
                                          ),
                                      child: _EstadoVacioDonaciones(
                                        esInvitado: esInvitado,
                                        errorServidor: _errorServidor,
                                        screenWidth: screenWidth,
                                        usableHeight: usableHeight,
                                        azulFondo: azulFondo,
                                        l10n: l10n,
                                        onRetry: _cargarDonaciones,
                                        onLogin: () {
                                          final nav =
                                              MyApp.navigatorKey.currentState ??
                                              (context.mounted
                                                  ? Navigator.maybeOf(context)
                                                  : null);
                                          nav?.pushNamed(
                                            InicioSesionScreen.routeName,
                                          );
                                        },
                                      ),
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _cargarDonaciones,
                                    color: azulFondo,
                                    child: ListView.separated(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(
                                            parent: BouncingScrollPhysics(),
                                          ),
                                      itemCount: donaciones.length,
                                      separatorBuilder: (context, index) =>
                                          SizedBox(
                                            height: usableHeight * 0.014,
                                          ),
                                      itemBuilder: (context, index) {
                                        final item = donaciones[index];
                                        return _DonationCard(
                                          title: item['title'] as String,
                                          monto: item['monto'] as String,
                                          status: item['status'] as String,
                                          statusColor:
                                              item['statusColor'] as Color,
                                          dateInfo: item['dateInfo'] as String?,
                                          icon: item['icon'] as IconData,
                                          iconColor: item['iconColor'] as Color,
                                          screenWidth: screenWidth,
                                          usableHeight: usableHeight,
                                          azulFondo: azulFondo,
                                          grisBorde: grisBorde,
                                          onTap: () =>
                                              _mostrarDetalleDonacion(item),
                                        );
                                      },
                                    ),
                                  ),
                          ),

                          SizedBox(height: usableHeight * 0.015),

                          // Botón Inferior "Nueva donación"
                          SizedBox(
                            width: screenWidth,
                            height: usableHeight * 0.062,
                            child: ElevatedButton(
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
                                if (!ModalRestriccionDonacion.verificarYMostrar(
                                  context: context,
                                )) {
                                  return;
                                }
                                Navigator.pushNamed(
                                  context,
                                  DonacionesScreen.routeName,
                                );
                              },
                              child: Text(
                                l10n?.nuevaDonacion ?? 'Nueva donación',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.048,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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

/// Estado Vacío de la pantalla de donaciones
class _EstadoVacioDonaciones extends StatelessWidget {
  const _EstadoVacioDonaciones({
    required this.esInvitado,
    required this.errorServidor,
    required this.screenWidth,
    required this.usableHeight,
    required this.azulFondo,
    required this.l10n,
    required this.onRetry,
    required this.onLogin,
  });

  final bool esInvitado;
  final bool errorServidor;
  final double screenWidth;
  final double usableHeight;
  final Color azulFondo;
  final AppLocalizations? l10n;
  final VoidCallback onRetry;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: screenWidth * 0.06,
        vertical: usableHeight * 0.02,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: screenWidth * 0.18,
            height: screenWidth * 0.18,
            decoration: BoxDecoration(
              color: azulFondo.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              esInvitado
                  ? Icons.account_circle_outlined
                  : (errorServidor
                        ? Icons.cloud_off_rounded
                        : Icons.volunteer_activism_outlined),
              color: azulFondo,
              size: screenWidth * 0.09,
            ),
          ),
          SizedBox(height: usableHeight * 0.02),
          Text(
            esInvitado
                ? (l10n?.modoInvitado ?? 'Modo invitado')
                : (errorServidor
                      ? (l10n?.errorSincronizacion ?? 'Error de sincronización')
                      : (l10n?.sinDonacionesRegistradas ??
                            'No tienes donaciones registradas')),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: azulFondo,
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: usableHeight * 0.01),
          Text(
            esInvitado
                ? (l10n?.donacionesInvitadoDesc ??
                      'En modo invitado no se registran aportes ni historial. Inicia sesión para colaborar y consultar tus donaciones.')
                : (errorServidor
                      ? (l10n?.errorSincronizacionDonacionesDesc ??
                            'No pudimos conectar con el servidor para actualizar tus aportes. Reintenta la conexión.')
                      : (l10n?.tusAportesApareceranAqui ??
                            'Tus aportes ministeriales aparecerán aquí.')),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: screenWidth * 0.034,
              height: 1.35,
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
              onPressed: onLogin,
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
    );
  }
}

/// Tarjeta individual de donación
class _DonationCard extends StatelessWidget {
  const _DonationCard({
    required this.title,
    required this.monto,
    required this.status,
    required this.statusColor,
    required this.dateInfo,
    required this.icon,
    required this.iconColor,
    required this.screenWidth,
    required this.usableHeight,
    required this.azulFondo,
    required this.grisBorde,
    required this.onTap,
  });

  final String title;
  final String monto;
  final String status;
  final Color statusColor;
  final String? dateInfo;
  final IconData icon;
  final Color iconColor;
  final double screenWidth;
  final double usableHeight;
  final Color azulFondo;
  final Color grisBorde;
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
        child: Row(
          children: [
            // Icono del tipo de donación
            Container(
              padding: EdgeInsets.all(screenWidth * 0.025),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: screenWidth * 0.075),
            ),
            SizedBox(width: screenWidth * 0.035),

            // Textos de información (Título, Estado, Fecha)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.003),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsetsDirectional.symmetric(
                          horizontal: screenWidth * 0.022,
                          vertical: usableHeight * 0.002,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.015,
                          ),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: screenWidth * 0.030,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (dateInfo != null) ...[
                        SizedBox(width: screenWidth * 0.02),
                        Flexible(
                          child: Text(
                            dateInfo!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: screenWidth * 0.028,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Monto destacado a la derecha
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  monto,
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.042,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: usableHeight * 0.002),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: screenWidth * 0.055,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal con el detalle completo de la donación
class _DonationDetailSheet extends StatelessWidget {
  const _DonationDetailSheet({
    required this.item,
    required this.screenWidth,
    required this.usableHeight,
    required this.safeBottom,
    required this.azulFondo,
    required this.blancoFondo,
    required this.grisBorde,
    required this.amarilloOro,
    required this.l10n,
  });

  final Map<String, dynamic> item;
  final double screenWidth;
  final double usableHeight;
  final double safeBottom;
  final Color azulFondo;
  final Color blancoFondo;
  final Color grisBorde;
  final Color amarilloOro;
  final AppLocalizations? l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(
        screenWidth * 0.06,
        usableHeight * 0.02,
        screenWidth * 0.06,
        usableHeight * 0.03 + safeBottom,
      ),
      decoration: BoxDecoration(
        color: blancoFondo,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra indicadora de arrastre
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

          // Encabezado del modal: Icono + Título + Referencia
          Row(
            children: [
              Container(
                width: screenWidth * 0.13,
                height: screenWidth * 0.13,
                decoration: BoxDecoration(
                  color: (item['iconColor'] as Color).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: item['iconColor'] as Color,
                  size: screenWidth * 0.075,
                ),
              ),
              SizedBox(width: screenWidth * 0.035),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      style: TextStyle(
                        color: azulFondo,
                        fontSize: screenWidth * 0.048,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.003),
                    Text(
                      l10n?.idOdoo(
                            item['referencia'] as String? ?? 'DON-2026-0001',
                          ) ??
                          'ID Odoo: ${item['referencia'] ?? 'DON-2026-0001'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.030,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: usableHeight * 0.006,
                ),
                decoration: BoxDecoration(
                  color: (item['statusColor'] as Color).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Text(
                  item['status'] as String,
                  style: TextStyle(
                    color: item['statusColor'] as Color,
                    fontSize: screenWidth * 0.032,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: usableHeight * 0.025),

          // Contenedor de Detalles
          Container(
            width: screenWidth,
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              border: Border.all(color: grisBorde),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Monto destacado
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n?.montoAportado ?? 'Monto aportado:',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.034,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      item['monto'] as String,
                      style: TextStyle(
                        color: azulFondo,
                        fontSize: screenWidth * 0.048,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Divider(height: usableHeight * 0.025, color: grisBorde),

                if (item['dateInfo'] != null) ...[
                  _DonationDetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: l10n?.fechaYHora ?? 'Fecha y hora:',
                    value:
                        item['fechaCompleta'] as String? ??
                        item['dateInfo'] as String,
                    screenWidth: screenWidth,
                    azulFondo: azulFondo,
                  ),
                  SizedBox(height: usableHeight * 0.012),
                ],

                if (item['metodoPago'] != null) ...[
                  _DonationDetailRow(
                    icon: Icons.credit_card_rounded,
                    label: l10n?.metodo ?? 'Método:',
                    value: item['metodoPago'] as String,
                    screenWidth: screenWidth,
                    azulFondo: azulFondo,
                  ),
                  SizedBox(height: usableHeight * 0.012),
                ],

                if (item['destino'] != null) ...[
                  _DonationDetailRow(
                    icon: Icons.flag_outlined,
                    label: l10n?.destino ?? 'Destino:',
                    value: item['destino'] as String,
                    screenWidth: screenWidth,
                    azulFondo: azulFondo,
                  ),
                  SizedBox(height: usableHeight * 0.012),
                ],

                Divider(height: usableHeight * 0.020, color: grisBorde),

                Text(
                  l10n?.detalleDelAporte ?? 'Detalle del aporte:',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: screenWidth * 0.032,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: usableHeight * 0.006),
                Text(
                  item['detalle'] as String? ??
                      (l10n?.aporteVoluntarioRegistrado ??
                          'Aporte voluntario registrado en ATRIO.'),
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.035,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: usableHeight * 0.025),

          // Botón de cerrar
          SizedBox(
            width: screenWidth,
            height: usableHeight * 0.055,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: azulFondo,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n?.entendido ?? 'Entendido',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de detalle con icono y valor alineado
class _DonationDetailRow extends StatelessWidget {
  const _DonationDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.screenWidth,
    required this.azulFondo,
  });

  final IconData icon;
  final String label;
  final String value;
  final double screenWidth;
  final Color azulFondo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: screenWidth * 0.042, color: azulFondo),
        SizedBox(width: screenWidth * 0.02),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: screenWidth * 0.033,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: screenWidth * 0.02),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: azulFondo,
              fontSize: screenWidth * 0.034,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
