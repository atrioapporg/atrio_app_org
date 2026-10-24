import 'dart:async';
import 'package:flutter/material.dart';

/// Widget de alerta visual sutil con animación de entrada y desvanecimiento
/// automático (auto-dismiss) no invasivo controlado por temporizador y AnimationController.
class AlertaAutoDismiss extends StatefulWidget {
  final String mensaje;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duracion;
  final VoidCallback? onDismissed;
  final EdgeInsetsGeometry? margin;
  final IconData icono;

  const AlertaAutoDismiss({
    super.key,
    required this.mensaje,
    this.actionLabel,
    this.onAction,
    this.duracion = const Duration(seconds: 7),
    this.onDismissed,
    this.margin,
    this.icono = Icons.church_outlined,
  });

  @override
  State<AlertaAutoDismiss> createState() => _AlertaAutoDismissState();
}

class _AlertaAutoDismissState extends State<AlertaAutoDismiss>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _timer;
  bool _dismissed = false;

  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    // Auto-dismiss temporizado no invasivo
    _timer = Timer(widget.duracion, () {
      _desvanecer();
    });
  }

  void _desvanecer() {
    if (!mounted || _dismissed) return;
    _dismissed = true;
    _timer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismissed?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SizeTransition(
          sizeFactor: _fadeAnimation,
          axisAlignment: 0.0,
          child: Container(
            margin: widget.margin ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: azulFondo,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: amarilloOro.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  widget.icono,
                  color: amarilloOro,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.mensaje,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (widget.actionLabel != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      _desvanecer();
                      widget.onAction?.call();
                    },
                    child: Text(
                      widget.actionLabel!,
                      style: const TextStyle(
                        color: amarilloOro,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                GestureDetector(
                  onTap: _desvanecer,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.close,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
