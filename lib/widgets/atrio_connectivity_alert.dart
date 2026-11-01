import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/servicios/connectivity_service.dart';

/// Alerta flotante moderna de conectividad para ATRIO.
///
/// Integra diseño Material 3 con colores de identidad corporativa:
/// - Fondo azul noche oscuro (`0xFF072B4F`)
/// - Acentos en ámbar/oro (`0xFFE5A023`) y carmesí de alerta (`0xFFE53935`)
/// - Soporte completo de gestos para descartar (Swipe up), animaciones fluidas
///   y feedback háptico.
class AtrioConnectivityAlert {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// Método de conveniencia de un solo paso:
  /// Valida la conexión real a internet mediante [ConnectivityService].
  /// Si NO hay internet, dispara la alerta visual en [context] y retorna `false`.
  /// Si hay internet, retorna `true`.
  static Future<bool> checkAndNotify(
    BuildContext context, {
    String? message,
    VoidCallback? onRetry,
  }) async {
    final bool hasInternet =
        await ConnectivityService.instance.hasRealInternet();

    if (!hasInternet && context.mounted) {
      show(
        context,
        message: message,
        onRetry: onRetry,
      );
      return false;
    }
    return hasInternet;
  }

  /// Muestra el banner flotante con animación de entrada y temporizador de salida.
  static void show(
    BuildContext context, {
    String? title,
    String? message,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final l10n = AppLocalizations.of(context);
    final displayTitle =
        title ?? (l10n?.sinConexionTitulo ?? 'Sin conexión a internet');
    final displayMessage = message ??
        (l10n?.sinConexionMensajeDefecto ??
            'Verifica tu señal Wi-Fi o datos móviles para continuar.');

    // Feedback háptico sutil al alertar al usuario
    HapticFeedback.mediumImpact();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _AtrioConnectivityToastOverlay(
        title: displayTitle,
        message: displayMessage,
        onRetry: onRetry,
        onDismiss: () => dismiss(),
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () {
      dismiss();
    });
  }

  /// Descarta activamente la alerta en pantalla con animación suave.
  static void dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

/// Widget interno para aislar la animación y evitar reconstrucciones externas.
class _AtrioConnectivityToastOverlay extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback onDismiss;

  const _AtrioConnectivityToastOverlay({
    required this.title,
    required this.message,
    required this.onDismiss,
    this.onRetry,
  });

  @override
  State<_AtrioConnectivityToastOverlay> createState() =>
      _AtrioConnectivityToastOverlayState();
}

class _AtrioConnectivityToastOverlayState
    extends State<_AtrioConnectivityToastOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _fadeAnimation;

  // Paleta corporativa ATRIO
  static const Color _azulFondo = Color(0xFF072B4F);
  static const Color _amarilloOro = Color(0xFFE5A023);
  static const Color _rojoAlerta = Color(0xFFE53935);
  static const Color _blancoTexto = Color(0xFFFAF7F0);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 280),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInQuad,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  Future<void> _handleDismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top + 8;
    final l10n = AppLocalizations.of(context);

    return PositionedDirectional(
      top: topPadding,
      start: 16,
      end: 16,
      child: Material(
        type: MaterialType.transparency,
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta != null && details.primaryDelta! < -4) {
                  _handleDismiss();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _azulFondo.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _amarilloOro.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: _rojoAlerta.withValues(alpha: 0.20),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsetsDirectional.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const _IconoAlerta(
                      colorAlerta: _rojoAlerta,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: _blancoTexto,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _blancoTexto.withValues(alpha: 0.88),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onRetry != null) ...[
                      const SizedBox(width: 8),
                      _BotonReintentar(
                        label: l10n?.reintentar ?? 'Reintentar',
                        colorOro: _amarilloOro,
                        onPressed: () {
                          _handleDismiss();
                          widget.onRetry!();
                        },
                      ),
                    ] else ...[
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: _blancoTexto.withValues(alpha: 0.6),
                        ),
                        onPressed: _handleDismiss,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconoAlerta extends StatelessWidget {
  final Color colorAlerta;

  const _IconoAlerta({
    required this.colorAlerta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: colorAlerta.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(
          color: colorAlerta.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.wifi_off_rounded,
          color: Color(0xFFFF5252),
          size: 22,
        ),
      ),
    );
  }
}

class _BotonReintentar extends StatelessWidget {
  final String label;
  final Color colorOro;
  final VoidCallback onPressed;

  const _BotonReintentar({
    required this.label,
    required this.colorOro,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: colorOro,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
