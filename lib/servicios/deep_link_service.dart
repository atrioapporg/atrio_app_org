import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:atrio/main.dart';
import 'package:atrio/providers/join_church_provider.dart';
import 'package:atrio/providers/user_provider.dart';
import 'package:atrio/screens/inicio_sesion_screen.dart';
import 'package:atrio/utils/qr_token_parser.dart';
import 'package:atrio/widgets/church_join_confirmation_modal.dart';
import 'package:atrio/widgets/odoo_pago_dialog.dart';

/// Servicio responsable de escuchar y redirigir los enlaces profundos
/// (App Links en Android y Universal Links en iOS) hacia la lógica de negocio:
/// 1. Vinculación de iglesia (`/c/<uuid>`)
/// 2. Retorno automático tras completar donación/ofrenda (`atrio://donation-completed?tx_id=...`)
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _isInitialized = false;

  /// Acceso a la clave de navegación global de la aplicación
  static GlobalKey<NavigatorState> get navigatorKey => MyApp.navigatorKey;

  /// Inicializa los escuchadores de enlaces profundos.
  /// Debe llamarse una única vez en el arranque de la aplicación.
  Future<void> initDeepLinks() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. Manejo de Cold Start (App abierta directamente al hacer clic en el enlace)
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('[DEEP_LINK] Cold start detectado: $initialUri');
        _handleIncomingUri(initialUri);
      }
    } catch (e) {
      debugPrint('[DEEP_LINK] Error al capturar initial link: $e');
    }

    // 2. Manejo de Warm/Foreground (App ya abierta o en segundo plano)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        debugPrint('[DEEP_LINK] Enlace recibido en stream: $uri');
        _handleIncomingUri(uri);
      },
      onError: (Object err) {
        debugPrint('[DEEP_LINK] Error en el stream de AppLinks: $err');
      },
    );
  }

  /// Verifica si el URI corresponde al retorno automático de una ofrenda/donación
  /// completada en el portal web seguro de Odoo 19 (`atrio://donation-completed?tx_id=...`).
  bool _isDonationCompletedUri(Uri uri) {
    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    return host == 'donation-completed' ||
        path == '/donation-completed' ||
        path.endsWith('/donation-completed');
  }

  /// Procesa cualquier URI entrante y canaliza al Provider correspondiente.
  Future<void> _handleIncomingUri(Uri uri) async {
    // 1. Retorno automático de Ofrendas y Donaciones (Apple Guideline 3.2.1.vi / Play Store)
    if (_isDonationCompletedUri(uri)) {
      await _handleDonationCompletedUri(uri);
      return;
    }

    // 2. Vinculación de iglesia mediante token QR / Deep Link (/c/<uuid>)
    final String rawUri = uri.toString();
    final String? token = joinTokenFromUri(rawUri);

    if (token != null) {
      final navContext = navigatorKey.currentContext;
      if (navContext == null || !navContext.mounted) return;

      final joinProvider = navContext.read<JoinChurchProvider>();
      final userProvider = navContext.read<UserProvider>();

      final bool success = await joinProvider.handleJoinToken(
        rawInput: rawUri,
        userProvider: userProvider,
      );

      if (!navContext.mounted) return;

      if (success) {
        if (joinProvider.step == JoinChurchStep.requiresLogin) {
          // El token ya quedó guardado en storage seguro ('pending_join_token')
          navigatorKey.currentState?.pushNamed(InicioSesionScreen.routeName);
        } else if (joinProvider.step == JoinChurchStep.previewReady) {
          // Usuario autenticado: mostrar inmediatamente el modal de confirmación
          await showModalBottomSheet<void>(
            context: navContext,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const ChurchJoinConfirmationModal(),
          );
        }
      }
    }
  }

  /// Cierra la sesión de SFSafariViewController / Chrome Custom Tabs,
  /// consulta silenciosamente `GET /donations/status` y muestra la pantalla
  /// nativa de gratitud pastoral.
  Future<void> _handleDonationCompletedUri(Uri uri) async {
    try {
      await closeInAppWebView();
    } catch (_) {
      // Ignorar si no había un inAppBrowserView abierto
    }

    final navContext = navigatorKey.currentContext;
    if (navContext == null || !navContext.mounted) return;

    final String txId = uri.queryParameters['tx_id'] ??
        uri.queryParameters['reference'] ??
        'DON-WEB';
    final userProvider = navContext.read<UserProvider>();

    String verifiedStatus = 'completed';
    String effectiveRef = txId;

    try {
      final statusRes = await userProvider.api.donationStatus(txId);
      verifiedStatus =
          (statusRes['status'] ?? statusRes['state'] ?? 'completed').toString();
      effectiveRef = (statusRes['reference'] ?? txId).toString();
    } catch (e) {
      debugPrint('[DEEP_LINK] Consulta silenciosa GET /donations/status: $e');
    }

    if (!navContext.mounted) return;

    await showModalBottomSheet<void>(
      context: navContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DonationGratitudeModal(
        txId: effectiveRef,
        status: verifiedStatus,
      ),
    );
  }

  /// Cancela la suscripción a streams al destruir el servicio.
  void dispose() {
    _linkSubscription?.cancel();
    _isInitialized = false;
  }
}
