import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
// ignore: depend_on_referenced_packages
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Asegura que en entornos de test de widgets (`FLUTTER_TEST`) exista una
/// implementación ligera de [WebViewPlatform] si el test no registró una manualmente.
void ensureWebViewPlatformReadyForTesting() {
  if (!kIsWeb &&
      Platform.environment.containsKey('FLUTTER_TEST') &&
      WebViewPlatform.instance == null) {
    WebViewPlatform.instance = _NoOpTestWebViewPlatform();
  }
}

/// Reproductor embebido de YouTube de alto rendimiento para iOS (WKWebView + Impeller)
/// y Android, diseñado para evitar los bugs de `youtube_player_iframe 6.0.2`:
/// 1. Evita `JSON.stringify(event)` con referencias DOM cíclicas en `onReady`.
/// 2. Usa `webkit.messageHandlers.<id>.postMessage(msg)` con 1 solo argumento en iOS.
/// 3. Pasa `videoId` directamente en la instanciación de `YT.Player` para carga inmediata.
/// 4. Elimina el `OverlayPortal` y el `_PlayerLoadingOverlay` opaco que bloqueaban toques
///    dentro de `showModalBottomSheet`.
class AtrioYoutubeWebViewPlayer extends StatefulWidget {
  final YoutubePlayerController controller;
  final String videoId;
  final bool autoPlay;
  final double? startSeconds;
  final double? endSeconds;
  final double aspectRatio;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  const AtrioYoutubeWebViewPlayer({
    super.key,
    required this.controller,
    required this.videoId,
    this.autoPlay = true,
    this.startSeconds,
    this.endSeconds,
    this.aspectRatio = 16 / 9,
    this.gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{},
  });

  /// Ejecuta `playVideo()` directamente sobre el `WKWebView` / `WebView` sin
  /// depender de `packages/youtube_player_iframe/assets/player.html`.
  static void play(YoutubePlayerController? controller) {
    if (controller == null) return;
    if (!kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST')) {
      try {
        controller.webViewController.runJavaScript(
          'if (window.player && typeof window.player.playVideo === "function") { window.player.playVideo(); }',
        );
      } catch (_) {}
    }
    controller.update(playerState: PlayerState.playing);
  }

  /// Ejecuta `pauseVideo()` directamente sobre el `WKWebView` / `WebView` sin
  /// depender de `packages/youtube_player_iframe/assets/player.html`.
  static void pause(YoutubePlayerController? controller) {
    if (controller == null) return;
    if (!kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST')) {
      try {
        controller.webViewController.runJavaScript(
          'if (window.player && typeof window.player.pauseVideo === "function") { window.player.pauseVideo(); }',
        );
      } catch (_) {}
    }
    controller.update(playerState: PlayerState.paused);
  }

  @override
  State<AtrioYoutubeWebViewPlayer> createState() =>
      _AtrioYoutubeWebViewPlayerState();
}

class _AtrioYoutubeWebViewPlayerState extends State<AtrioYoutubeWebViewPlayer> {
  bool _isWebViewLoaded = false;
  bool _hasError = false;
  StreamSubscription<YoutubePlayerValue>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.controller.listen((value) {
      if (!mounted) return;
      if (value.playerState == PlayerState.playing ||
          value.playerState == PlayerState.paused ||
          value.playerState == PlayerState.buffering ||
          value.playerState == PlayerState.cued) {
        if (!_isWebViewLoaded) {
          setState(() => _isWebViewLoaded = true);
        }
      }
      if (value.error != YoutubeError.none && !_hasError) {
        setState(() => _hasError = true);
      }
    });
    _initializeOptimizedPlayer();
  }

  @override
  void didUpdateWidget(covariant AtrioYoutubeWebViewPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId ||
        oldWidget.controller != widget.controller) {
      _isWebViewLoaded = false;
      _hasError = false;
      _initializeOptimizedPlayer();
    }
  }

  Future<void> _initializeOptimizedPlayer() async {
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }

    try {
      try {
        await widget.controller.webViewController.setBackgroundColor(
          Colors.black,
        );
      } catch (_) {}

      if (!mounted) return;

      final safeOrigin = _resolveSafeEmbedOrigin(widget.controller.params.origin);

      // Cargar directamente el HTML5 IFrame Player en memoria para iOS WKWebView
      // y Android sin invocar `controller.init()`, evitando la dependencia del
      // asset `packages/youtube_player_iframe/assets/player.html`.
      final html = _buildFixedPlayerHtml(
        // ignore: invalid_use_of_internal_member
        playerId: widget.controller.playerId,
        videoId: widget.videoId,
        autoPlay: widget.autoPlay,
        startSeconds: widget.startSeconds,
        endSeconds: widget.endSeconds,
        params: widget.controller.params,
        safeOrigin: safeOrigin,
      );

      await widget.controller.webViewController.loadHtmlString(
        html,
        baseUrl: safeOrigin,
      );

      if (mounted) {
        setState(() => _isWebViewLoaded = true);
      }
    } catch (e) {
      debugPrint('⚠️ [AtrioYoutubeWebViewPlayer] Error inicializando WebView: $e');
    }
  }

  /// YouTube rechaza `https://www.youtube.com` como `origin` / `Referer` de un
  /// reproductor embebido de terceros con `Error 152 - 4`
  /// (`PLAYABILITY_ERROR_CODE_EMBEDDER_IDENTITY_DENIED` / `sameAsNotEmbeddable2`).
  /// En cambio, `https://www.youtube-nocookie.com` está autorizado como origen
  /// de embed y devuelve `status: OK, playableInEmbed: true`.
  String _resolveSafeEmbedOrigin(String? rawOrigin) {
    if (rawOrigin == null ||
        rawOrigin.isEmpty ||
        rawOrigin.contains('www.youtube.com') ||
        rawOrigin.contains('://youtube.com')) {
      return 'https://www.youtube-nocookie.com';
    }
    return rawOrigin;
  }

  String _buildFixedPlayerHtml({
    required String playerId,
    required String videoId,
    required bool autoPlay,
    required YoutubePlayerParams params,
    required String safeOrigin,
    double? startSeconds,
    double? endSeconds,
  }) {
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();
    final Map<String, dynamic> playerVars = {
      'autoplay': autoPlay ? 1 : 0,
      'playsinline': 1,
      'controls': 1,
      'enablejsapi': 1,
      'fs': params.showFullscreenButton ? 1 : 0,
      'rel': 0,
      'modestbranding': 1,
      'iv_load_policy': 3,
      'cc_load_policy': params.enableCaption ? 1 : 0,
      'origin': safeOrigin,
      'widget_referrer': safeOrigin,
      if (startSeconds != null && startSeconds > 0)
        'start': startSeconds.round(),
      if (endSeconds != null && endSeconds > 0) 'end': endSeconds.round(),
    };

    final playerVarsJson = jsonEncode(playerVars);
    const host = 'https://www.youtube-nocookie.com';
    final updateInterval = params.videoStateUpdateInterval;
    final autoPlayFlag = autoPlay ? 1 : 0;

    return '''
<!DOCTYPE html>
<html lang="es">
  <head>
    <meta
      name="viewport"
      content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"
    />
    <meta name="referrer" content="strict-origin-when-cross-origin" />
    <style>
      * {
        box-sizing: border-box;
        -webkit-tap-highlight-color: transparent;
      }
      html, body {
        margin: 0;
        padding: 0;
        width: 100%;
        height: 100%;
        background-color: #000000;
        overflow: hidden;
      }
      .embed-container {
        position: relative;
        width: 100%;
        height: 100%;
      }
      .embed-container iframe,
      .embed-container object,
      .embed-container embed {
        position: absolute;
        top: 0;
        left: 0;
        width: 100% !important;
        height: 100% !important;
        border: 0;
      }
    </style>
    <title>ATRIO Player</title>
  </head>
  <body>
    <div class="embed-container">
      <div id="$playerId"></div>
    </div>
    <script>
      var platform = "$platform";
      var host = "$host";
      var initialVideoId = "$videoId";
      var autoPlayRequested = $autoPlayFlag === 1;
      var player;
      var timerId;
      var _initialLoadHandled = false;

      // Shim universal para WKWebView (iOS) y WebView (Android)
      function sendPlatformMessage(messageString) {
        try {
          if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers["$playerId"]) {
            window.webkit.messageHandlers["$playerId"].postMessage(messageString);
            return;
          }
          if (window["$playerId"] && typeof window["$playerId"].postMessage === "function") {
            window["$playerId"].postMessage(messageString);
            return;
          }
        } catch (err) {
          console.error("Error enviando mensaje a Dart:", err);
        }
      }

      function sendMessage(key, data) {
        try {
          var message = {};
          message[key] = data;
          message["playerId"] = "$playerId";
          sendPlatformMessage(JSON.stringify(message));
        } catch (err) {
          console.error("Error serializando mensaje:", err);
        }
      }

      var tag = document.createElement("script");
      tag.src = "https://www.youtube.com/iframe_api";
      var firstScriptTag = document.getElementsByTagName("script")[0];
      firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

      function onYouTubeIframeAPIReady() {
        player = new YT.Player("$playerId", {
          height: "100%",
          width: "100%",
          host: host,
          videoId: initialVideoId,
          playerVars: $playerVarsJson,
          events: {
            onReady: function (event) {
              // Interceptar la primera llamada redundante de loadVideoById/cueVideoById
              // que YoutubePlayerController.fromVideoId encoló al crearse, evitando
              // recargar el iframe desde cero en iOS.
              if (player && player.loadVideoById) {
                var origLoad = player.loadVideoById.bind(player);
                player.loadVideoById = function(arg, startSeconds, suggestedQuality) {
                  var reqId = (typeof arg === "object" && arg !== null) ? arg.videoId : arg;
                  if (!_initialLoadHandled && reqId === initialVideoId) {
                    _initialLoadHandled = true;
                    if (autoPlayRequested && typeof player.playVideo === "function") {
                      player.playVideo();
                    }
                    return;
                  }
                  return origLoad(arg, startSeconds, suggestedQuality);
                };
              }
              if (player && player.cueVideoById) {
                var origCue = player.cueVideoById.bind(player);
                player.cueVideoById = function(arg, startSeconds, suggestedQuality) {
                  var reqId = (typeof arg === "object" && arg !== null) ? arg.videoId : arg;
                  if (!_initialLoadHandled && reqId === initialVideoId) {
                    _initialLoadHandled = true;
                    return;
                  }
                  return origCue(arg, startSeconds, suggestedQuality);
                };
              }

              // IMPORTANTE: Nunca pasar 'event' crudo porque contiene referencias DOM cíclicas
              sendMessage("Ready", true);

              if (autoPlayRequested && event && event.target && typeof event.target.playVideo === "function") {
                try {
                  event.target.playVideo();
                } catch (_) {}
              }
            },
            onStateChange: function (event) {
              clearInterval(timerId);
              sendMessage("StateChange", event.data);
              if (event.data === 1) {
                timerId = setInterval(function () {
                  if (!player || typeof player.getCurrentTime !== "function") return;
                  var state = {
                    currentTime: player.getCurrentTime() || 0,
                    loadedFraction: (typeof player.getVideoLoadedFraction === "function")
                      ? (player.getVideoLoadedFraction() || 0)
                      : 0
                  };
                  sendMessage("VideoState", JSON.stringify(state));
                }, $updateInterval);
              }
            },
            onPlaybackQualityChange: function (event) {
              sendMessage("PlaybackQualityChange", event.data);
            },
            onPlaybackRateChange: function (event) {
              sendMessage("PlaybackRateChange", event.data);
            },
            onApiChange: function (event) {
              sendMessage("ApiChange", "");
            },
            onError: function (event) {
              sendMessage("PlayerError", event.data);
            },
            onAutoplayBlocked: function (event) {
              sendMessage("AutoplayBlocked", "");
            }
          }
        });
      }

      function getVideoData() {
        var data = (player && typeof player.getVideoData === "function")
          ? player.getVideoData()
          : { video_id: initialVideoId, author: "", title: "" };
        return prepareDataForPlatform(data);
      }

      function getPlaylist() {
        var list = (player && typeof player.getPlaylist === "function")
          ? player.getPlaylist()
          : [];
        return prepareDataForPlatform(list);
      }

      function getAvailablePlaybackRates() {
        var rates = (player && typeof player.getAvailablePlaybackRates === "function")
          ? player.getAvailablePlaybackRates()
          : [1.0];
        return prepareDataForPlatform(rates);
      }

      function prepareDataForPlatform(data) {
        if (platform === "android") return data;
        return JSON.stringify(data);
      }

      window.onresize = function () {
        if (player && typeof player.setSize === "function") {
          player.setSize(window.innerWidth, window.innerHeight);
        }
      };
    </script>
  </body>
</html>
''';
  }

  @override
  void dispose() {
    _sub?.cancel();
    AtrioYoutubeWebViewPlayer.pause(widget.controller);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Entorno de pruebas unitarias / de widgets
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: Container(
          color: Colors.black87,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.play_circle_filled_rounded,
                  color: Color(0xFFE5A023),
                  size: 44,
                ),
                const SizedBox(height: 6),
                Text(
                  'YouTube Embebido: ${widget.videoId}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            WebViewWidget(
              controller: widget.controller.webViewController,
              gestureRecognizers: widget.gestureRecognizers,
            ),
            if (!_isWebViewLoaded)
              const IgnorePointer(
                ignoring: true,
                child: Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFFE5A023),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PLATAFORMA NO-OP PARA ENTORNOS DE TEST (FLUTTER_TEST)
// =============================================================================

class _NoOpTestWebViewPlatform extends WebViewPlatform {
  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) =>
      _NoOpTestNavigationDelegate(params);

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) =>
      _NoOpTestWebViewController(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) =>
      _NoOpTestWebViewWidget(params);
}

class _NoOpTestWebViewController extends PlatformWebViewController {
  _NoOpTestWebViewController(super.params) : super.implementation();

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}

  @override
  Future<void> setUserAgent(String? userAgent) async {}

  @override
  Future<void> enableZoom(bool enabled) async {}

  @override
  Future<void> addJavaScriptChannel(
    JavaScriptChannelParams javaScriptChannelParams,
  ) async {}

  @override
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {}

  @override
  Future<void> removeJavaScriptChannel(String javaScriptChannelName) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> runJavaScript(String javaScript) async {}

  @override
  Future<Object> runJavaScriptReturningResult(String javaScript) async => '';
}

class _NoOpTestNavigationDelegate extends PlatformNavigationDelegate {
  _NoOpTestNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {}

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {}

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {}
}

class _NoOpTestWebViewWidget extends PlatformWebViewWidget {
  _NoOpTestWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

