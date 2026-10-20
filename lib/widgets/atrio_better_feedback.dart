// ignore_for_file: implementation_imports, public_member_api_docs
import 'package:feedback/feedback.dart';
import 'package:feedback/src/controls_column.dart';
import 'package:feedback/src/feedback_bottom_sheet.dart';
import 'package:feedback/src/feedback_builder/string_feedback.dart';
import 'package:feedback/src/feedback_data.dart';
import 'package:feedback/src/paint_on_background.dart';
import 'package:feedback/src/painter.dart';
import 'package:feedback/src/scale_and_clip.dart';
import 'package:feedback/src/scale_and_fade.dart';
import 'package:feedback/src/screenshot.dart';
import 'package:feedback/src/theme/feedback_theme.dart';
import 'package:feedback/src/utilities/back_button_interceptor.dart';
import 'package:feedback/src/utilities/feedback_app.dart';
import 'package:flutter/material.dart';

/// Versión robusta y corregida de BetterFeedback para ATRIO.
/// Soluciona de raíz el fallo de viewport en el paquete oficial donde
/// el layout queda desplazado permanentemente tras cerrar la captura o navegar.
class AtrioBetterFeedback extends StatefulWidget {
  const AtrioBetterFeedback({
    super.key,
    required this.child,
    this.feedbackBuilder,
    this.themeMode,
    this.theme,
    this.darkTheme,
    this.localizationsDelegates,
    this.localeOverride,
    this.mode = FeedbackMode.draw,
    this.pixelRatio = 3.0,
  });

  final Widget child;
  final FeedbackBuilder? feedbackBuilder;
  final ThemeMode? themeMode;
  final FeedbackThemeData? theme;
  final FeedbackThemeData? darkTheme;
  final List<LocalizationsDelegate<dynamic>>? localizationsDelegates;
  final Locale? localeOverride;
  final FeedbackMode mode;
  final double pixelRatio;

  @override
  State<AtrioBetterFeedback> createState() => _AtrioBetterFeedbackState();
}

class _AtrioBetterFeedbackState extends State<AtrioBetterFeedback> {
  final FeedbackController controller = FeedbackController();

  @override
  void initState() {
    super.initState();
    controller.addListener(_onUpdate);
  }

  @override
  void dispose() {
    controller.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FeedbackApp(
      themeMode: widget.themeMode,
      theme: widget.theme,
      darkTheme: widget.darkTheme,
      localizationsDelegates: widget.localizationsDelegates,
      localeOverride: widget.localeOverride,
      child: FeedbackData(
        controller: controller,
        child: AtrioFeedbackWidget(
          isFeedbackVisible: controller.isVisible,
          drawColors:
              widget.theme?.drawColors ??
              [
                const Color(0xFFE5A023),
                const Color(0xFFE53935),
                const Color(0xFF072B4F),
                Colors.white,
              ],
          mode: widget.mode,
          pixelRatio: widget.pixelRatio,
          feedbackBuilder: widget.feedbackBuilder ?? simpleFeedbackBuilder,
          child: widget.child,
        ),
      ),
    );
  }
}

class AtrioFeedbackWidget extends StatefulWidget {
  const AtrioFeedbackWidget({
    super.key,
    required this.child,
    required this.isFeedbackVisible,
    required this.drawColors,
    required this.mode,
    required this.pixelRatio,
    required this.feedbackBuilder,
  });

  final bool isFeedbackVisible;
  final FeedbackMode mode;
  final double pixelRatio;
  final Widget child;
  final List<Color> drawColors;
  final FeedbackBuilder feedbackBuilder;

  @override
  State<AtrioFeedbackWidget> createState() => _AtrioFeedbackWidgetState();
}

class _AtrioFeedbackWidgetState extends State<AtrioFeedbackWidget>
    with SingleTickerProviderStateMixin {
  final double padding = 8;
  final ValueNotifier<double> sheetProgress = ValueNotifier(0);
  late PainterController painterController = createPainter();
  final ScreenshotController screenshotController = ScreenshotController();
  late FeedbackMode mode = widget.mode;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  PainterController createPainter() {
    final c = PainterController();
    c.thickness = 5.0;
    c.drawColor = widget.drawColors.isNotEmpty
        ? widget.drawColors[0]
        : const Color(0xFFE5A023);
    return c;
  }

  @override
  void initState() {
    super.initState();
    BackButtonInterceptor.add(backButtonIntercept);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    BackButtonInterceptor.remove(backButtonIntercept);
    super.dispose();
  }

  bool backButtonIntercept() {
    if (mode == FeedbackMode.draw && widget.isFeedbackVisible) {
      if (painterController.getStepCount() > 0) {
        painterController.undo();
      } else {
        BetterFeedback.of(context).hide();
      }
      return true;
    }
    return false;
  }

  @override
  void didUpdateWidget(AtrioFeedbackWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    mode = widget.mode;
    if (oldWidget.isFeedbackVisible != widget.isFeedbackVisible) {
      if (widget.isFeedbackVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
        sheetProgress.value = 0;
      }
    }
  }

  Future<void> _handleSendFeedback(
    String feedback, {
    Map<String, dynamic>? extras,
  }) async {
    final onFeedback = BetterFeedback.of(context).onFeedback;

    // 1. Capturar pantalla inmediatamente en alta resolución
    final screenshot = await screenshotController.capture(
      pixelRatio: widget.pixelRatio,
      delay: const Duration(milliseconds: 0),
    );

    // 2. Cerrar inmediatamente el modo feedback para restaurar la app al 100%
    if (mounted) {
      BetterFeedback.of(context).hide();
    }

    // 3. Limpiar dibujos
    painterController.clear();

    // 4. Invocar el callback de la app con la captura ya lista
    if (onFeedback != null) {
      await onFeedback(
        UserFeedback(text: feedback, screenshot: screenshot, extra: extras),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final animation = Tween<double>(
      begin: 0,
      end: 1,
    ).chain(CurveTween(curve: Curves.easeInSine)).animate(_controller);

    final FeedbackThemeData feedbackThemeData = FeedbackTheme.of(context);
    final ThemeData theme = ThemeData(
      brightness: feedbackThemeData.brightness,
      cardColor: feedbackThemeData.feedbackSheetColor,
      colorScheme: feedbackThemeData.colorScheme,
    );

    // SI EL FEEDBACK NO ESTÁ ACTIVO Y LA ANIMACIÓN ESTÁ EN CERO:
    // Retornamos el widget hijo directamente sin overlays, paddings ni distorsiones
    final bool isFeedbackActive =
        widget.isFeedbackVisible || !animation.isDismissed;

    if (!isFeedbackActive) {
      return widget.child;
    }

    return Overlay(
      initialEntries: [
        OverlayEntry(
          builder: (context) => Theme(
            data: theme,
            child: Material(
              color: FeedbackTheme.of(context).background,
              child: AnimatedBuilder(
                animation: _controller,
                child: Screenshot(
                  controller: screenshotController,
                  child: PaintOnChild(
                    controller: painterController,
                    isPaintingActive:
                        mode == FeedbackMode.draw && widget.isFeedbackVisible,
                    child: widget.child,
                  ),
                ),
                builder: (context, screenshotChild) {
                  return CustomMultiChildLayout(
                    delegate: _FixedFeedbackLayoutDelegate(
                      displayFeedback: !animation.isDismissed,
                      query: MediaQuery.of(context),
                      sheetFraction: feedbackThemeData.feedbackSheetHeight,
                      animationProgress: animation.value,
                    ),
                    children: [
                      LayoutId(
                        id: '_screenshot_id',
                        child: (!animation.isDismissed)
                            ? Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: padding,
                                ),
                                child: ScaleAndFade(
                                  progress: sheetProgress,
                                  minScale: .7,
                                  minOpacity: .01,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final size = MediaQuery.of(context).size;
                                      return OverflowBox(
                                        maxWidth: size.width,
                                        maxHeight: size.height,
                                        child: ScaleAndClip(
                                          progress: animation.value,
                                          scaleFactor:
                                              constraints.maxWidth / size.width,
                                          child: screenshotChild!,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              )
                            : screenshotChild!,
                      ),
                      if (!animation.isDismissed)
                        LayoutId(
                          id: '_controls_column_id',
                          child: Padding(
                            padding: EdgeInsets.only(left: padding),
                            child: ScaleAndFade(
                              progress: sheetProgress,
                              minScale: .7,
                              child: ControlsColumn(
                                mode: mode,
                                activeColor: painterController.drawColor,
                                colors: widget.drawColors,
                                onColorChanged: (color) {
                                  setState(() {
                                    painterController.drawColor = color;
                                  });
                                  FocusScope.of(context).unfocus();
                                },
                                onUndo: () {
                                  painterController.undo();
                                  FocusScope.of(context).unfocus();
                                },
                                onClearDrawing: () {
                                  painterController.clear();
                                  FocusScope.of(context).unfocus();
                                },
                                onControlModeChanged: (newMode) {
                                  setState(() {
                                    mode = newMode;
                                  });
                                  FocusScope.of(context).unfocus();
                                },
                                onCloseFeedback: () {
                                  FocusScope.of(context).unfocus();
                                  BetterFeedback.of(context).hide();
                                },
                              ),
                            ),
                          ),
                        ),
                      if (!animation.isDismissed)
                        LayoutId(
                          id: '_sheet_id',
                          child:
                              NotificationListener<
                                DraggableScrollableNotification
                              >(
                                onNotification: (notification) {
                                  sheetProgress.value =
                                      (notification.extent -
                                          notification.minExtent) /
                                      (notification.maxExtent -
                                          notification.minExtent);
                                  return false;
                                },
                                child: FeedbackBottomSheet(
                                  key: const Key('feedback_bottom_sheet'),
                                  feedbackBuilder: widget.feedbackBuilder,
                                  onSubmit: _handleSendFeedback,
                                  sheetProgress: sheetProgress,
                                ),
                              ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FixedFeedbackLayoutDelegate extends MultiChildLayoutDelegate {
  _FixedFeedbackLayoutDelegate({
    required this.displayFeedback,
    required this.query,
    required this.sheetFraction,
    required this.animationProgress,
  });

  final bool displayFeedback;
  final MediaQueryData query;
  final double sheetFraction;
  final double animationProgress;

  static const String _screenshotId = '_screenshot_id';
  static const String _controlsColumnId = '_controls_column_id';
  static const String _sheetId = '_sheet_id';

  double get safeAreaHeight => query.padding.top;
  double get screenHeight => query.size.height;
  double get screenshotFraction =>
      1 - sheetFraction - (safeAreaHeight / screenHeight);
  double get screenshotHeight => screenshotFraction * screenHeight;

  @override
  void performLayout(Size size) {
    // CORRECCIÓN CRÍTICA:
    // Si no está activo el feedback, posicionar SIEMPRE el screenshot en Offset.zero
    if (!displayFeedback) {
      layoutChild(_screenshotId, BoxConstraints.tight(size));
      positionChild(_screenshotId, Offset.zero);
      return;
    }

    final Size controlsSize = layoutChild(
      _controlsColumnId,
      BoxConstraints.loose(Size(size.width, screenshotHeight)),
    );

    final Size screenShotSize = layoutChild(
      _screenshotId,
      BoxConstraints.tight(
        applyBoxFit(
          BoxFit.scaleDown,
          query.size,
          Size(
            size.width - animationProgress * (controlsSize.width),
            size.height - animationProgress * (size.height - screenshotHeight),
          ),
        ).destination,
      ),
    );

    final double remainingWidth =
        query.size.width - screenShotSize.width - controlsSize.width;

    positionChild(
      _screenshotId,
      Offset(
        animationProgress * remainingWidth / 2,
        animationProgress * safeAreaHeight,
      ),
    );

    positionChild(
      _controlsColumnId,
      Offset(
        size.width -
            animationProgress * (controlsSize.width + remainingWidth / 2),
        safeAreaHeight + (screenshotHeight - controlsSize.height) / 2,
      ),
    );

    layoutChild(_sheetId, BoxConstraints.loose(Size(size.width, size.height)));
    positionChild(_sheetId, Offset.zero);
  }

  @override
  bool shouldRelayout(_FixedFeedbackLayoutDelegate oldDelegate) {
    return displayFeedback != oldDelegate.displayFeedback ||
        animationProgress != oldDelegate.animationProgress ||
        query != oldDelegate.query;
  }
}
