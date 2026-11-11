import 'package:flutter/widgets.dart';

import 'analytics_service.dart';

/// Observador de navegación que registra un `screen_view` cada vez que una
/// pantalla (`PageRoute`) pasa a ser visible: push, replace o al volver con pop.
///
/// Los diálogos y bottom sheets (`PopupRoute`) se ignoran para no
/// fragmentar el tiempo de permanencia de la pantalla subyacente.
///
/// Los nombres se normalizan: `'/admin-requests'` → `'admin_requests'`,
/// `'biblia_screen'` → `'biblia_screen'`. Las rutas sin nombre
/// (`MaterialPageRoute` sin `settings.name`) no se registran; para medirlas,
/// pásales `RouteSettings(name: MiPantalla.routeName)`.
class AnalyticsRouteObserver extends RouteObserver<ModalRoute<dynamic>> {
  AnalyticsRouteObserver({AnalyticsService? analytics})
    : _analytics = analytics ?? AnalyticsService.instance;

  final AnalyticsService _analytics;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _track(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _track(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // Solo si se vuelve a una pantalla tras cerrar otra pantalla completa.
    if (route is PageRoute && previousRoute != null) _track(previousRoute);
  }

  void _track(Route<dynamic> route) {
    if (route is! PageRoute) return;
    final String? name = normalizeScreenName(route.settings.name);
    if (name == null) return;
    _analytics.logScreenView(name);
  }

  /// Convierte el nombre de ruta en un `screen_name` estable para GA4.
  static String? normalizeScreenName(String? routeName) {
    if (routeName == null) return null;
    final cleaned = routeName
        .trim()
        .replaceAll(RegExp(r'^/+'), '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]+'), '_');
    if (cleaned.isEmpty) return 'root';
    return cleaned;
  }
}

