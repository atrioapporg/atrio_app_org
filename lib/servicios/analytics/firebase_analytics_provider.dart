import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'analytics_provider.dart';

/// Implementación de [AnalyticsProvider] sobre Google Analytics for Firebase.
///
/// - Pantallas y eventos aparecen en la consola de Firebase / GA4.
/// - Con el enlace a BigQuery activado, los eventos crudos se exportan
///   diariamente para análisis personalizados.
class FirebaseAnalyticsProvider implements AnalyticsProvider {
  FirebaseAnalytics? _analytics;

  @override
  String get name => 'firebase';

  @override
  Future<void> initialize() async {
    _analytics = FirebaseAnalytics.instance;
    // Privacidad por diseño: ATRIO no usa Analytics para publicidad.
    await _analytics!.setConsent(
      adStorageConsentGranted: false,
      adUserDataConsentGranted: false,
      adPersonalizationSignalsConsentGranted: false,
    );
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    final analytics = _analytics;
    if (analytics == null) return;
    await analytics.setConsent(analyticsStorageConsentGranted: enabled);
    await analytics.setAnalyticsCollectionEnabled(enabled);
  }

  @override
  Future<void> logEvent(String name, Map<String, Object>? parameters) async {
    await _analytics?.logEvent(name: name, parameters: parameters);
  }

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics?.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  @override
  Future<void> setUserId(String? id) async {
    await _analytics?.setUserId(id: id);
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    await _analytics?.setUserProperty(name: name, value: value);
  }

  @override
  Future<void> reset() async {
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.setUserId(id: null);
      await analytics.resetAnalyticsData();
    } catch (e) {
      debugPrint('ℹ️ [FirebaseAnalyticsProvider] reset no disponible: $e');
    }
  }
}

