import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/ajustes_provider.dart';

/// Tarjeta moderna de configuración para las notificaciones diarias del Versículo del Día.
///
/// Permite al usuario:
/// 1. Visualizar y ajustar la hora de la notificación matutina predeterminada (7:00 a.m.).
/// 2. Activar/desactivar la segunda notificación diaria opcional mediante un [SwitchListTile].
/// 3. Visualizar y configurar el segundo horario diario (ej. 2:00 p.m.) con picker nativo adaptado a Material 3.
class DailyVerseNotificationSettingsCard extends StatelessWidget {
  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFEFEFEF);
  static const Color grisSubtitulo = Color(0xFF6B7280);

  const DailyVerseNotificationSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final double screenWidth = size.width;
    final double usableHeight = size.height;
    final ajustes = context.watch<AjustesProvider>();

    final bool isDoubleActive = ajustes.isDoubleNotificationEnabled;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        border: Border.all(color: grisBorde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Cabecera de la tarjeta con icono distintivo
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              screenWidth * 0.045,
              usableHeight * 0.02,
              screenWidth * 0.045,
              usableHeight * 0.015,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsetsDirectional.all(screenWidth * 0.025),
                  decoration: BoxDecoration(
                    color: azulFondo.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: azulFondo,
                    size: screenWidth * 0.06,
                  ),
                ),
                SizedBox(width: screenWidth * 0.035),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.notificacionesVersiculoDiario,
                        style: TextStyle(
                          color: azulFondo,
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.038,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: usableHeight * 0.004),
                      Text(
                        l10n.notificacionesVersiculoDiarioDesc,
                        style: TextStyle(
                          color: grisSubtitulo,
                          fontSize: screenWidth * 0.031,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: grisBorde),

          // Fila 1: Notificación Matutina Predeterminada (7:00 a.m. o configurada)
          _TimeRowTile(
            icon: Icons.wb_sunny_rounded,
            iconColor: amarilloOro,
            iconBackgroundColor: amarilloOro.withValues(alpha: 0.12),
            title: l10n.primeraHoraNotificacion,
            subtitle: l10n.primeraHoraNotificacionDesc,
            timeString: ajustes.horaNotifDevocional,
            onTap: () => _seleccionarHora(
              context: context,
              horaActual: ajustes.horaNotifDevocional,
              onGuardar: (hora) async {
                await context.read<AjustesProvider>().cambiarHoraDevocional(hora);
                if (context.mounted) {
                  final formattedTime = _formatearHoraLocalizada(context, hora);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.horaNotificacionActualizada(formattedTime),
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
          ),

          const Divider(height: 1, color: grisBorde),

          // Fila 2: Interruptor de control para Doble Notificación Diaria
          SwitchListTile.adaptive(
            contentPadding: EdgeInsetsDirectional.symmetric(
              horizontal: screenWidth * 0.045,
              vertical: usableHeight * 0.006,
            ),
            secondary: Container(
              padding: EdgeInsetsDirectional.all(screenWidth * 0.02),
              decoration: BoxDecoration(
                color: (isDoubleActive ? amarilloOro : Colors.grey)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                color: isDoubleActive ? amarilloOro : Colors.grey.shade600,
                size: screenWidth * 0.055,
              ),
            ),
            title: Text(
              l10n.dobleNotificacionDiaria,
              style: TextStyle(
                color: azulFondo,
                fontWeight: FontWeight.w600,
                fontSize: screenWidth * 0.036,
              ),
            ),
            subtitle: Text(
              l10n.dobleNotificacionDiariaDesc,
              style: TextStyle(
                color: grisSubtitulo,
                fontSize: screenWidth * 0.03,
                height: 1.25,
              ),
            ),
            activeThumbColor: amarilloOro,
            activeTrackColor: amarilloOro.withValues(alpha: 0.35),
            inactiveTrackColor: Colors.grey.shade200,
            value: isDoubleActive,
            onChanged: (bool valor) async {
              await context.read<AjustesProvider>().toggleDobleNotificacion(valor);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      valor
                          ? l10n.dobleNotificacionActivada
                          : l10n.dobleNotificacionDesactivada,
                    ),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),

          // Fila 3: Selector de Segunda Hora (aparece suavemente cuando está activo el switch)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isDoubleActive
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(height: 1, color: grisBorde),
                      _TimeRowTile(
                        icon: Icons.nightlight_round,
                        iconColor: const Color(0xFF1E3A8A),
                        iconBackgroundColor:
                            const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                        title: l10n.segundaHoraNotificacion,
                        subtitle: l10n.segundaHoraNotificacionDesc,
                        timeString: ajustes.segundaHoraNotifDevocional,
                        onTap: () => _seleccionarHora(
                          context: context,
                          horaActual: ajustes.segundaHoraNotifDevocional,
                          onGuardar: (hora) async {
                            await context
                                .read<AjustesProvider>()
                                .cambiarSegundaHoraDevocional(hora);
                            if (context.mounted) {
                              final formattedTime =
                                  _formatearHoraLocalizada(context, hora);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.horaNotificacionActualizada(
                                      formattedTime,
                                    ),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      ),
    );
  }

  /// Despliega el TimePicker con la paleta de colores institucional ATRIO
  static Future<void> _seleccionarHora({
    required BuildContext context,
    required String horaActual,
    required Future<void> Function(String hora) onGuardar,
  }) async {
    final partes = horaActual.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(partes[0]) ?? 7,
      minute: partes.length > 1 ? int.tryParse(partes[1]) ?? 0 : 0,
    );

    final seleccion = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext ctx, Widget? child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: azulFondo,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: azulFondo,
            ),
            timePickerTheme: const TimePickerThemeData(
              dialHandColor: amarilloOro,
              dialBackgroundColor: blancoFondo,
              backgroundColor: Colors.white,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (seleccion != null) {
      final horaStr =
          '${seleccion.hour.toString().padLeft(2, '0')}:${seleccion.minute.toString().padLeft(2, '0')}';
      await onGuardar(horaStr);
    }
  }

  /// Formatea la cadena "HH:mm" según el locale activo usando [DateFormat.jm]
  static String _formatearHoraLocalizada(
    BuildContext context,
    String timeString,
  ) {
    final partes = timeString.split(':');
    final int h = int.tryParse(partes.first) ?? 0;
    final int m = partes.length > 1 ? int.tryParse(partes[1]) ?? 0 : 0;
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, h, m);
    final localeStr = Localizations.localeOf(context).toString();
    return DateFormat.jm(localeStr).format(dt);
  }
}

/// Widget interno aislado para renderizar una fila de selección de hora de forma óptima
class _TimeRowTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String title;
  final String subtitle;
  final String timeString;
  final VoidCallback onTap;

  const _TimeRowTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.title,
    required this.subtitle,
    required this.timeString,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final double screenWidth = size.width;
    final double usableHeight = size.height;
    final String formattedTime =
        DailyVerseNotificationSettingsCard._formatearHoraLocalizada(
      context,
      timeString,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: screenWidth * 0.045,
          vertical: usableHeight * 0.014,
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsetsDirectional.all(screenWidth * 0.02),
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: screenWidth * 0.055,
              ),
            ),
            SizedBox(width: screenWidth * 0.035),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: DailyVerseNotificationSettingsCard.azulFondo,
                      fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.003),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: DailyVerseNotificationSettingsCard.grisSubtitulo,
                      fontSize: screenWidth * 0.03,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Container(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: screenWidth * 0.032,
                vertical: usableHeight * 0.007,
              ),
              decoration: BoxDecoration(
                color: DailyVerseNotificationSettingsCard.azulFondo
                    .withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                border: Border.all(
                  color: DailyVerseNotificationSettingsCard.azulFondo
                      .withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formattedTime,
                    style: TextStyle(
                      color: DailyVerseNotificationSettingsCard.azulFondo,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.034,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.01),
                  Icon(
                    Icons.edit_outlined,
                    color: DailyVerseNotificationSettingsCard.azulFondo,
                    size: screenWidth * 0.036,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
