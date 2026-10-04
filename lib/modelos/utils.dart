import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class Utils {
  /// Devuelve `true` si el dispositivo tiene acceso real a Internet.
  /*
  final tieneInternet = await NetworkUtils.hasRealInternetAccess();

  if (tieneInternet) {
      print('Acceso real a Internet confirmado');
    } else {
      print('Sin acceso real a Internet');
    }
  */
  static Future<bool> hasRealInternetAccess() async {
    return await InternetConnection().hasInternetAccess;
  }

  //
  //
}
