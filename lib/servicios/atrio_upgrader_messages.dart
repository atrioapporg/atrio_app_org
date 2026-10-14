import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';
import '../l10n/app_localizations.dart';

/// Mensajes de Upgrader integrados con el sistema de internacionalización
/// (flutter_localizations + intl) de ATRIO y diseño Cupertino.
class AtrioUpgraderMessages extends UpgraderMessages {
  BuildContext? context;

  AtrioUpgraderMessages({this.context, super.code});

  @override
  String? message(UpgraderMessage messageKey) {
    if (context != null) {
      final l10n = AppLocalizations.of(context!);
      if (l10n != null) {
        switch (messageKey) {
          case UpgraderMessage.body:
            return l10n.upgraderMensaje(
              '{{appName}}',
              '{{currentAppStoreVersion}}',
              '{{currentInstalledVersion}}',
            );
          case UpgraderMessage.buttonTitleIgnore:
            return l10n.upgraderBotonIgnorar;
          case UpgraderMessage.buttonTitleLater:
            return l10n.upgraderBotonMasTarde;
          case UpgraderMessage.buttonTitleUpdate:
            return l10n.upgraderBotonActualizar;
          case UpgraderMessage.prompt:
            return l10n.upgraderPregunta;
          case UpgraderMessage.releaseNotes:
            return l10n.upgraderNotasVersion;
          case UpgraderMessage.title:
            return l10n.upgraderTitulo;
        }
      }
    }

    final code = languageCode.toLowerCase();
    if (code.startsWith('en')) {
      switch (messageKey) {
        case UpgraderMessage.body:
          return 'A new version of {{appName}} is available! Version {{currentAppStoreVersion}} is now available-you have {{currentInstalledVersion}}.';
        case UpgraderMessage.buttonTitleIgnore:
          return 'Ignore';
        case UpgraderMessage.buttonTitleLater:
          return 'Later';
        case UpgraderMessage.buttonTitleUpdate:
          return 'Update Now';
        case UpgraderMessage.prompt:
          return 'Would you like to update it now?';
        case UpgraderMessage.releaseNotes:
          return 'Release Notes';
        case UpgraderMessage.title:
          return 'Update App?';
      }
    }

    // Por defecto en Español (Castellano/Latinoamérica)
    switch (messageKey) {
      case UpgraderMessage.body:
        return '¡Una nueva versión de {{appName}} está disponible! La versión {{currentAppStoreVersion}} ya está disponible, tienes la versión {{currentInstalledVersion}}.';
      case UpgraderMessage.buttonTitleIgnore:
        return 'Ignorar';
      case UpgraderMessage.buttonTitleLater:
        return 'Más tarde';
      case UpgraderMessage.buttonTitleUpdate:
        return 'Actualizar';
      case UpgraderMessage.prompt:
        return '¿Deseas actualizar ahora?';
      case UpgraderMessage.releaseNotes:
        return 'Novedades de la versión';
      case UpgraderMessage.title:
        return '¿Actualizar la aplicación?';
    }
  }
}
