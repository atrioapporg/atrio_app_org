import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @bienvenida.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a Atrio'**
  String get bienvenida;

  /// Saludo personalizado con el nombre del usuario
  ///
  /// In es, this message translates to:
  /// **'Hola, {nombre}'**
  String saludo(String nombre);

  /// No description provided for @appTitulo.
  ///
  /// In es, this message translates to:
  /// **'ATRIO'**
  String get appTitulo;

  /// No description provided for @lema.
  ///
  /// In es, this message translates to:
  /// **'Vive tu Fe en comunidad'**
  String get lema;

  /// No description provided for @subtituloBienvenida.
  ///
  /// In es, this message translates to:
  /// **'Un espacio para vivir y compartir tu fe'**
  String get subtituloBienvenida;

  /// No description provided for @sloganAtrio.
  ///
  /// In es, this message translates to:
  /// **'JUNTOS EN LA FE, MÁS CERCA DE TI'**
  String get sloganAtrio;

  /// No description provided for @cargandoAtrio.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get cargandoAtrio;

  /// No description provided for @accesoRapidoSeguro.
  ///
  /// In es, this message translates to:
  /// **'Acceso Rápido y Seguro'**
  String get accesoRapidoSeguro;

  /// No description provided for @ingresaUnToque.
  ///
  /// In es, this message translates to:
  /// **'Ingresa en un solo toque'**
  String get ingresaUnToque;

  /// No description provided for @continuarConGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get continuarConGoogle;

  /// Nombre de usuario por defecto para inicio de sesión con Google
  ///
  /// In es, this message translates to:
  /// **'Usuario Google'**
  String get usuarioGoogle;

  /// No description provided for @continuarConApple.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Apple'**
  String get continuarConApple;

  /// No description provided for @explorarInvitado.
  ///
  /// In es, this message translates to:
  /// **'Explorar como invitado'**
  String get explorarInvitado;

  /// No description provided for @avisoPrivacidadOdoo.
  ///
  /// In es, this message translates to:
  /// **'Al continuar, vinculas tu cuenta de forma segura con el servidor eclesial de ATRIO en Odoo ERP.'**
  String get avisoPrivacidadOdoo;

  /// No description provided for @terminosDeUso.
  ///
  /// In es, this message translates to:
  /// **'Términos de uso'**
  String get terminosDeUso;

  /// No description provided for @politicaPrivacidad.
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get politicaPrivacidad;

  /// No description provided for @privacidad.
  ///
  /// In es, this message translates to:
  /// **'Privacidad'**
  String get privacidad;

  /// No description provided for @eliminarMisDatos.
  ///
  /// In es, this message translates to:
  /// **'Eliminar mis datos'**
  String get eliminarMisDatos;

  /// No description provided for @eliminarCuentaYDatos.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta y datos'**
  String get eliminarCuentaYDatos;

  /// No description provided for @solicitarEliminacion.
  ///
  /// In es, this message translates to:
  /// **'Solicitar eliminación'**
  String get solicitarEliminacion;

  /// No description provided for @opcionNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Opción no disponible'**
  String get opcionNoDisponible;

  /// No description provided for @entendido.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get entendido;

  /// No description provided for @inicio.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get inicio;

  /// No description provided for @perfil.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get perfil;

  /// No description provided for @biblia.
  ///
  /// In es, this message translates to:
  /// **'Biblia'**
  String get biblia;

  /// No description provided for @eventos.
  ///
  /// In es, this message translates to:
  /// **'Eventos'**
  String get eventos;

  /// No description provided for @donaciones.
  ///
  /// In es, this message translates to:
  /// **'Donaciones'**
  String get donaciones;

  /// No description provided for @solicitudes.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get solicitudes;

  /// No description provided for @notificaciones.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notificaciones;

  /// No description provided for @configuracion.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get configuracion;

  /// No description provided for @ajustes.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get ajustes;

  /// No description provided for @idiomaPreferido.
  ///
  /// In es, this message translates to:
  /// **'Idioma preferido'**
  String get idiomaPreferido;

  /// No description provided for @seleccionarIdioma.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar Idioma'**
  String get seleccionarIdioma;

  /// No description provided for @modoVisualizacion.
  ///
  /// In es, this message translates to:
  /// **'Modo de visualización'**
  String get modoVisualizacion;

  /// No description provided for @claro.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get claro;

  /// No description provided for @oscuro.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get oscuro;

  /// No description provided for @sistema.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get sistema;

  /// No description provided for @guardar.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get guardar;

  /// No description provided for @cancelar.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancelar;

  /// No description provided for @cerrar.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get cerrar;

  /// No description provided for @deseasSalirAtrio.
  ///
  /// In es, this message translates to:
  /// **'¿Deseas salir de Atrio?'**
  String get deseasSalirAtrio;

  /// No description provided for @presionaSalirCerrar.
  ///
  /// In es, this message translates to:
  /// **'Presiona \"Salir\" para cerrar la aplicación.'**
  String get presionaSalirCerrar;

  /// No description provided for @salir.
  ///
  /// In es, this message translates to:
  /// **'Salir'**
  String get salir;

  /// No description provided for @iglesia.
  ///
  /// In es, this message translates to:
  /// **'Iglesia'**
  String get iglesia;

  /// No description provided for @explorar.
  ///
  /// In es, this message translates to:
  /// **'Explorar'**
  String get explorar;

  /// No description provided for @radio.
  ///
  /// In es, this message translates to:
  /// **'Radio'**
  String get radio;

  /// No description provided for @miIglesia.
  ///
  /// In es, this message translates to:
  /// **'Mi Iglesia'**
  String get miIglesia;

  /// No description provided for @tocaParaCambiar.
  ///
  /// In es, this message translates to:
  /// **'· Toca para cambiar'**
  String get tocaParaCambiar;

  /// No description provided for @sinIglesiaSeleccionada.
  ///
  /// In es, this message translates to:
  /// **'Sin iglesia seleccionada'**
  String get sinIglesiaSeleccionada;

  /// No description provided for @proyectosSolidarios.
  ///
  /// In es, this message translates to:
  /// **'Proyectos\nsolidarios'**
  String get proyectosSolidarios;

  /// No description provided for @tienda.
  ///
  /// In es, this message translates to:
  /// **'Tienda'**
  String get tienda;

  /// No description provided for @libros.
  ///
  /// In es, this message translates to:
  /// **'Libros'**
  String get libros;

  /// No description provided for @videos.
  ///
  /// In es, this message translates to:
  /// **'Videos'**
  String get videos;

  /// No description provided for @nuevoAviso.
  ///
  /// In es, this message translates to:
  /// **'Nuevo aviso'**
  String get nuevoAviso;

  /// No description provided for @cambioHorarioAviso.
  ///
  /// In es, this message translates to:
  /// **'Cambio de horario · Miércoles, 7:00 p. m.'**
  String get cambioHorarioAviso;

  /// No description provided for @categoriaServicios.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get categoriaServicios;

  /// No description provided for @inscripcionesAbiertas.
  ///
  /// In es, this message translates to:
  /// **'Inscripciones abiertas'**
  String get inscripcionesAbiertas;

  /// No description provided for @retiroAnualAviso.
  ///
  /// In es, this message translates to:
  /// **'Retiro Anual 2026 · Cupos limitados'**
  String get retiroAnualAviso;

  /// No description provided for @categoriaComunidad.
  ///
  /// In es, this message translates to:
  /// **'Comunidad'**
  String get categoriaComunidad;

  /// No description provided for @accionSolidaria.
  ///
  /// In es, this message translates to:
  /// **'Acción solidaria'**
  String get accionSolidaria;

  /// No description provided for @campanaDonacionesAviso.
  ///
  /// In es, this message translates to:
  /// **'Campaña \"Manos que Bendicen\" · Donaciones'**
  String get campanaDonacionesAviso;

  /// No description provided for @anunciosYConciertos.
  ///
  /// In es, this message translates to:
  /// **'ANUNCIOS & CONCIERTOS'**
  String get anunciosYConciertos;

  /// No description provided for @cargandoNovedades.
  ///
  /// In es, this message translates to:
  /// **'Cargando novedades...'**
  String get cargandoNovedades;

  /// Mensaje informativo confirmando envío sobre el artista o evento
  ///
  /// In es, this message translates to:
  /// **'Información sobre \"{artista}\" enviada.'**
  String infoArtistaEnviada(String artista);

  /// Error cuando no se puede abrir el marcador telefónico
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el marcador con el número {telefono}'**
  String noSePudoAbrirMarcador(String telefono);

  /// No description provided for @noSePudoAbrirNavegacion.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir la aplicación de navegación.'**
  String get noSePudoAbrirNavegacion;

  /// Error cuando no se puede abrir un enlace web
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el enlace {url}'**
  String noSePudoAbrirEnlace(String url);

  /// No description provided for @compartirUbicacion.
  ///
  /// In es, this message translates to:
  /// **'Compartir ubicación'**
  String get compartirUbicacion;

  /// No description provided for @plusCodeCopiadoPregunta.
  ///
  /// In es, this message translates to:
  /// **'El Plus Code ha sido copiado al portapapeles. ¿Deseas compartirlo directamente?'**
  String get plusCodeCopiadoPregunta;

  /// Notificación de Plus Code copiado al portapapeles
  ///
  /// In es, this message translates to:
  /// **'Plus Code copiado: {plusCode}'**
  String plusCodeCopiadoSnack(String plusCode);

  /// No description provided for @correo.
  ///
  /// In es, this message translates to:
  /// **'Correo'**
  String get correo;

  /// No description provided for @reintentar.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get reintentar;

  /// No description provided for @cambiarDeIglesia.
  ///
  /// In es, this message translates to:
  /// **'Cambiar de iglesia'**
  String get cambiarDeIglesia;

  /// No description provided for @exploraYSeleccionaComunidad.
  ///
  /// In es, this message translates to:
  /// **'Explora y selecciona otra comunidad'**
  String get exploraYSeleccionaComunidad;

  /// No description provided for @llamar.
  ///
  /// In es, this message translates to:
  /// **'Llamar'**
  String get llamar;

  /// No description provided for @comoLlegar.
  ///
  /// In es, this message translates to:
  /// **'Cómo llegar'**
  String get comoLlegar;

  /// No description provided for @sitioWeb.
  ///
  /// In es, this message translates to:
  /// **'Sitio web'**
  String get sitioWeb;

  /// No description provided for @verAhora.
  ///
  /// In es, this message translates to:
  /// **'Ver ahora'**
  String get verAhora;

  /// No description provided for @horariosDeServicio.
  ///
  /// In es, this message translates to:
  /// **'Horarios de servicio'**
  String get horariosDeServicio;

  /// No description provided for @ubicacionYContacto.
  ///
  /// In es, this message translates to:
  /// **'Ubicación y contacto'**
  String get ubicacionYContacto;

  /// No description provided for @direccion.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get direccion;

  /// No description provided for @telefono.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get telefono;

  /// No description provided for @avisos.
  ///
  /// In es, this message translates to:
  /// **'Avisos'**
  String get avisos;

  /// No description provided for @encuentraTuFeEn10Km.
  ///
  /// In es, this message translates to:
  /// **'Encuentra tu Fe ideal en 10 km'**
  String get encuentraTuFeEn10Km;

  /// No description provided for @buscarIglesiasPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Ej. Iglesia cristiana, Bautista...'**
  String get buscarIglesiasPlaceholder;

  /// No description provided for @catolica.
  ///
  /// In es, this message translates to:
  /// **'Católica'**
  String get catolica;

  /// No description provided for @evangelica.
  ///
  /// In es, this message translates to:
  /// **'Evangélica'**
  String get evangelica;

  /// No description provided for @pentecostal.
  ///
  /// In es, this message translates to:
  /// **'Pentecostal'**
  String get pentecostal;

  /// No description provided for @bautista.
  ///
  /// In es, this message translates to:
  /// **'Bautista'**
  String get bautista;

  /// No description provided for @adventista.
  ///
  /// In es, this message translates to:
  /// **'Adventista'**
  String get adventista;

  /// No description provided for @visualizaIglesiasEnMapa.
  ///
  /// In es, this message translates to:
  /// **'Visualiza las iglesias en el Mapa'**
  String get visualizaIglesiasEnMapa;

  /// No description provided for @comunidadesSugeridas.
  ///
  /// In es, this message translates to:
  /// **'Comunidades sugeridas'**
  String get comunidadesSugeridas;

  /// No description provided for @noSeEncontraronIglesias10km.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron iglesias a menos de 10 km.'**
  String get noSeEncontraronIglesias10km;

  /// No description provided for @gpsDesactivado.
  ///
  /// In es, this message translates to:
  /// **'El GPS está desactivado. Por favor, enciéndelo.'**
  String get gpsDesactivado;

  /// No description provided for @permisosUbicacionDenegados.
  ///
  /// In es, this message translates to:
  /// **'Permisos de ubicación denegados.'**
  String get permisosUbicacionDenegados;

  /// No description provided for @permisosUbicacionPermanentemente.
  ///
  /// In es, this message translates to:
  /// **'Permisos de ubicación denegados permanentemente en tu dispositivo.'**
  String get permisosUbicacionPermanentemente;

  /// No description provided for @obteniendoUbicacionEspera.
  ///
  /// In es, this message translates to:
  /// **'Obteniendo tu ubicación, por favor intenta en un momento...'**
  String get obteniendoUbicacionEspera;

  /// No description provided for @errorCargarMapa.
  ///
  /// In es, this message translates to:
  /// **'😕 ¡Ups! No se pudo cargar el Mapa\n\n📡 Revisa tu conexión a internet e inténtalo de nuevo'**
  String get errorCargarMapa;

  /// No description provided for @sinNombre.
  ///
  /// In es, this message translates to:
  /// **'Sin nombre'**
  String get sinNombre;

  /// No description provided for @comunidadCristiana.
  ///
  /// In es, this message translates to:
  /// **'Comunidad cristiana'**
  String get comunidadCristiana;

  /// Distancia en kilómetros
  ///
  /// In es, this message translates to:
  /// **'A {distancia} km'**
  String aDistanciaKm(String distancia);

  /// No description provided for @emisorasCristianas.
  ///
  /// In es, this message translates to:
  /// **'Emisoras Cristianas'**
  String get emisorasCristianas;

  /// No description provided for @buscarEmisorasPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nombre, denominación, ciudad...'**
  String get buscarEmisorasPlaceholder;

  /// No description provided for @todosLosPaises.
  ///
  /// In es, this message translates to:
  /// **'Todos los países'**
  String get todosLosPaises;

  /// No description provided for @otrosPaises.
  ///
  /// In es, this message translates to:
  /// **'Otros países'**
  String get otrosPaises;

  /// No description provided for @todos.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get todos;

  /// No description provided for @espanol.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get espanol;

  /// No description provided for @ingles.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get ingles;

  /// Indicador del banner de favoritos
  ///
  /// In es, this message translates to:
  /// **'Mostrando solo favoritas ({total})'**
  String mostrandoSoloFavoritas(String total);

  /// No description provided for @verTodas.
  ///
  /// In es, this message translates to:
  /// **'Ver todas'**
  String get verTodas;

  /// Mensaje cuando no hay favoritas en el país seleccionado
  ///
  /// In es, this message translates to:
  /// **'No tienes emisoras favoritas guardadas en {pais}.\n\nToca el botón de corazón arriba para ver todas las emisoras.'**
  String sinFavoritasEnPais(String pais);

  /// No description provided for @sinFavoritasAun.
  ///
  /// In es, this message translates to:
  /// **'No tienes emisoras favoritas guardadas todavía.\n\nToca el botón de corazón arriba para ver todas las emisoras.'**
  String get sinFavoritasAun;

  /// Mensaje de búsqueda sin resultados
  ///
  /// In es, this message translates to:
  /// **'No se encontraron emisoras que coincidan con \"{busqueda}\".'**
  String noEmisorasCoincidencia(String busqueda);

  /// Mensaje cuando no hay emisoras disponibles en un país
  ///
  /// In es, this message translates to:
  /// **'No se encontraron emisoras disponibles para {pais}.'**
  String noEmisorasDisponiblesPais(String pais);

  /// No description provided for @verTodasLasEmisoras.
  ///
  /// In es, this message translates to:
  /// **'Ver todas las emisoras'**
  String get verTodasLasEmisoras;

  /// No description provided for @sintonizandoAudio.
  ///
  /// In es, this message translates to:
  /// **'Sintonizando audio...'**
  String get sintonizandoAudio;

  /// Estado en vivo con denominación y frecuencia
  ///
  /// In es, this message translates to:
  /// **'En vivo · {denominacion} ({frecuencia})'**
  String enVivoConDenominacion(String denominacion, String frecuencia);

  /// Estado en vivo con frecuencia
  ///
  /// In es, this message translates to:
  /// **'En vivo · {frecuencia}'**
  String enVivoFrecuencia(String frecuencia);

  /// No description provided for @emisora.
  ///
  /// In es, this message translates to:
  /// **'Emisora'**
  String get emisora;

  /// No description provided for @errorEmisoraNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Error: La emisora no está disponible en este momento.'**
  String get errorEmisoraNoDisponible;

  /// No description provided for @sinInternetSintonizar.
  ///
  /// In es, this message translates to:
  /// **'No hay conexión a internet para sintonizar la emisora.'**
  String get sinInternetSintonizar;

  /// No description provided for @usuario.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get usuario;

  /// No description provided for @miActividad.
  ///
  /// In es, this message translates to:
  /// **'Mi actividad'**
  String get miActividad;

  /// No description provided for @cuenta.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get cuenta;

  /// No description provided for @soporte.
  ///
  /// In es, this message translates to:
  /// **'Soporte'**
  String get soporte;

  /// No description provided for @misSolicitudes.
  ///
  /// In es, this message translates to:
  /// **'Mis solicitudes'**
  String get misSolicitudes;

  /// No description provided for @misDonaciones.
  ///
  /// In es, this message translates to:
  /// **'Mis donaciones'**
  String get misDonaciones;

  /// No description provided for @misNotasDeLaBiblia.
  ///
  /// In es, this message translates to:
  /// **'Mis notas de la Biblia'**
  String get misNotasDeLaBiblia;

  /// No description provided for @misDatos.
  ///
  /// In es, this message translates to:
  /// **'Mis datos'**
  String get misDatos;

  /// No description provided for @ajustesDeLaApp.
  ///
  /// In es, this message translates to:
  /// **'Ajustes de la app'**
  String get ajustesDeLaApp;

  /// No description provided for @ayudaYSoporte.
  ///
  /// In es, this message translates to:
  /// **'Ayuda y soporte'**
  String get ayudaYSoporte;

  /// No description provided for @terminosYPrivacidad.
  ///
  /// In es, this message translates to:
  /// **'Términos y Privacidad'**
  String get terminosYPrivacidad;

  /// No description provided for @cerrarSesion.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get cerrarSesion;

  /// No description provided for @misDatosDePerfil.
  ///
  /// In es, this message translates to:
  /// **'Mis datos de perfil'**
  String get misDatosDePerfil;

  /// No description provided for @nombreCompleto.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get nombreCompleto;

  /// No description provided for @ingresaUnNombre.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un nombre'**
  String get ingresaUnNombre;

  /// No description provided for @correoElectronico.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get correoElectronico;

  /// No description provided for @ingresaUnCorreoValido.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo válido'**
  String get ingresaUnCorreoValido;

  /// No description provided for @telefonoCelular.
  ///
  /// In es, this message translates to:
  /// **'Teléfono celular'**
  String get telefonoCelular;

  /// No description provided for @iglesiaActual.
  ///
  /// In es, this message translates to:
  /// **'Iglesia actual'**
  String get iglesiaActual;

  /// No description provided for @helperCambiarIglesia.
  ///
  /// In es, this message translates to:
  /// **'Para cambiarla usa la opción \"Cambiar de iglesia\"'**
  String get helperCambiarIglesia;

  /// No description provided for @guardarCambios.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get guardarCambios;

  /// No description provided for @datosActualizadosCorrectamente.
  ///
  /// In es, this message translates to:
  /// **'Datos actualizados correctamente'**
  String get datosActualizadosCorrectamente;

  /// No description provided for @seguroDeseasCerrarSesion.
  ///
  /// In es, this message translates to:
  /// **'¿Seguro que deseas cerrar sesión?'**
  String get seguroDeseasCerrarSesion;

  /// No description provided for @eliminarCuenta.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get eliminarCuenta;

  /// No description provided for @seguroEliminarCuenta.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar tu cuenta y todos tus datos personales de ATRIO?'**
  String get seguroEliminarCuenta;

  /// No description provided for @detalleEliminarCuenta.
  ///
  /// In es, this message translates to:
  /// **'Esta acción es definitiva e irreversible. Se eliminarán permanentemente:\n• Tu perfil de usuario y vinculación comunitaria.\n• Todas tus notas personales de la Biblia y favoritos guardados.\n• Tu historial de solicitudes y aportes locales.\n• Se solicitará la desactivación de tu registro en el backend Odoo ERP.'**
  String get detalleEliminarCuenta;

  /// No description provided for @eliminarDefinitivamente.
  ///
  /// In es, this message translates to:
  /// **'Eliminar definitivamente'**
  String get eliminarDefinitivamente;

  /// No description provided for @cuentaEliminadaExito.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta y datos personales han sido eliminados satisfactoriamente.'**
  String get cuentaEliminadaExito;

  /// No description provided for @versionDeLaBiblia.
  ///
  /// In es, this message translates to:
  /// **'Versión de la Biblia'**
  String get versionDeLaBiblia;

  /// No description provided for @noSePudoAbrirWhatsApp.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir WhatsApp.'**
  String get noSePudoAbrirWhatsApp;

  /// No description provided for @buscarBibliaPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Buscar versículo, palabra o frase...'**
  String get buscarBibliaPlaceholder;

  /// No description provided for @buscar.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get buscar;

  /// No description provided for @borrarTexto.
  ///
  /// In es, this message translates to:
  /// **'Borrar texto'**
  String get borrarTexto;

  /// Texto de carga durante búsqueda bíblica
  ///
  /// In es, this message translates to:
  /// **'Buscando en {version}...'**
  String buscandoEnVersion(String version);

  /// No description provided for @versiculoDelDia.
  ///
  /// In es, this message translates to:
  /// **'Versículo del día'**
  String get versiculoDelDia;

  /// No description provided for @compartirVersiculo.
  ///
  /// In es, this message translates to:
  /// **'Compartir versículo'**
  String get compartirVersiculo;

  /// No description provided for @errorCargarVersiculo.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el versículo de hoy.'**
  String get errorCargarVersiculo;

  /// No description provided for @librosDeLaBiblia.
  ///
  /// In es, this message translates to:
  /// **'Libros de la Biblia'**
  String get librosDeLaBiblia;

  /// No description provided for @antiguoYNuevoTestamento.
  ///
  /// In es, this message translates to:
  /// **'Antiguo y Nuevo Testamento'**
  String get antiguoYNuevoTestamento;

  /// No description provided for @continuarLeyendo.
  ///
  /// In es, this message translates to:
  /// **'Continuar leyendo'**
  String get continuarLeyendo;

  /// Número de capítulo bíblico
  ///
  /// In es, this message translates to:
  /// **'Capítulo {numero}'**
  String capituloNumero(String numero);

  /// No description provided for @escuchar.
  ///
  /// In es, this message translates to:
  /// **'Escuchar'**
  String get escuchar;

  /// No description provided for @escuchaLaBibliaNarrada.
  ///
  /// In es, this message translates to:
  /// **'Escucha la Biblia narrada'**
  String get escuchaLaBibliaNarrada;

  /// No description provided for @favoritos.
  ///
  /// In es, this message translates to:
  /// **'Favoritos'**
  String get favoritos;

  /// No description provided for @pasajeGuardado.
  ///
  /// In es, this message translates to:
  /// **'1 pasaje guardado'**
  String get pasajeGuardado;

  /// Conteo de pasajes guardados en favoritos
  ///
  /// In es, this message translates to:
  /// **'{total} pasajes guardados'**
  String pasajesGuardados(String total);

  /// No description provided for @misNotas.
  ///
  /// In es, this message translates to:
  /// **'Mis notas'**
  String get misNotas;

  /// No description provided for @notaSingular.
  ///
  /// In es, this message translates to:
  /// **'1 nota'**
  String get notaSingular;

  /// Conteo de notas personales
  ///
  /// In es, this message translates to:
  /// **'{total} notas'**
  String notasPlural(String total);

  /// Mensaje cuando la búsqueda bíblica no devuelve resultados
  ///
  /// In es, this message translates to:
  /// **'No se encontraron versículos para:\n\"{consulta}\"'**
  String noVersiculosEncontrados(String consulta);

  /// No description provided for @pruebaPalabrasClave.
  ///
  /// In es, this message translates to:
  /// **'Prueba usando palabras clave más generales o revisa la ortografía.'**
  String get pruebaPalabrasClave;

  /// Conteo de versículos encontrados
  ///
  /// In es, this message translates to:
  /// **'{total} versículos encontrados'**
  String versiculosEncontrados(String total);

  /// No description provided for @cerrarBusqueda.
  ///
  /// In es, this message translates to:
  /// **'Cerrar búsqueda'**
  String get cerrarBusqueda;

  /// No description provided for @buscarEventosPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Buscar eventos, expositores o lugares...'**
  String get buscarEventosPlaceholder;

  /// No description provided for @categorias.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get categorias;

  /// No description provided for @categoriaTodos.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get categoriaTodos;

  /// No description provided for @categoriaLiderazgo.
  ///
  /// In es, this message translates to:
  /// **'Liderazgo'**
  String get categoriaLiderazgo;

  /// No description provided for @categoriaAdoracion.
  ///
  /// In es, this message translates to:
  /// **'Adoración'**
  String get categoriaAdoracion;

  /// No description provided for @categoriaJovenes.
  ///
  /// In es, this message translates to:
  /// **'Jóvenes'**
  String get categoriaJovenes;

  /// No description provided for @categoriaFamilias.
  ///
  /// In es, this message translates to:
  /// **'Familias'**
  String get categoriaFamilias;

  /// No description provided for @explorarEventos.
  ///
  /// In es, this message translates to:
  /// **'Explorar eventos'**
  String get explorarEventos;

  /// No description provided for @verTodos.
  ///
  /// In es, this message translates to:
  /// **'Ver todos'**
  String get verTodos;

  /// No description provided for @noEventosEnCategoria.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron eventos en esta categoría'**
  String get noEventosEnCategoria;

  /// No description provided for @proximosEnAgenda.
  ///
  /// In es, this message translates to:
  /// **'Próximos en agenda'**
  String get proximosEnAgenda;

  /// No description provided for @mostrandoCalendarioCompleto.
  ///
  /// In es, this message translates to:
  /// **'Mostrando calendario completo de actividades...'**
  String get mostrandoCalendarioCompleto;

  /// No description provided for @verCalendario.
  ///
  /// In es, this message translates to:
  /// **'Ver calendario'**
  String get verCalendario;

  /// No description provided for @buscarPorFecha.
  ///
  /// In es, this message translates to:
  /// **'Buscar por fecha'**
  String get buscarPorFecha;

  /// No description provided for @buscarEventosPorFechaTitulo.
  ///
  /// In es, this message translates to:
  /// **'BUSCAR EVENTOS POR FECHA'**
  String get buscarEventosPorFechaTitulo;

  /// Encabezado de la lista cuando se filtra por fecha
  ///
  /// In es, this message translates to:
  /// **'Eventos: {fecha}'**
  String eventosFechaEncabezado(String fecha);

  /// No description provided for @noEventosParaFecha.
  ///
  /// In es, this message translates to:
  /// **'No hay eventos para la fecha seleccionada'**
  String get noEventosParaFecha;

  /// No description provided for @mostrarTodosLosEventos.
  ///
  /// In es, this message translates to:
  /// **'Mostrar todos los eventos'**
  String get mostrarTodosLosEventos;

  /// No description provided for @destacadoMayus.
  ///
  /// In es, this message translates to:
  /// **'DESTACADO'**
  String get destacadoMayus;

  /// No description provided for @inscribirmeAhora.
  ///
  /// In es, this message translates to:
  /// **'Inscribirme ahora'**
  String get inscribirmeAhora;

  /// No description provided for @cancelarInscripcion.
  ///
  /// In es, this message translates to:
  /// **'Cancelar inscripción'**
  String get cancelarInscripcion;

  /// No description provided for @rolAdministradorIglesia.
  ///
  /// In es, this message translates to:
  /// **'Administrador de Iglesia'**
  String get rolAdministradorIglesia;

  /// No description provided for @rolSuperAdmin.
  ///
  /// In es, this message translates to:
  /// **'Super Administrador'**
  String get rolSuperAdmin;

  /// No description provided for @rolMiembro.
  ///
  /// In es, this message translates to:
  /// **'Miembro Activo'**
  String get rolMiembro;

  /// No description provided for @rolUsuario.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get rolUsuario;

  /// No description provided for @modoSoloLectura.
  ///
  /// In es, this message translates to:
  /// **'Solo lectura'**
  String get modoSoloLectura;

  /// No description provided for @administracionPastoral.
  ///
  /// In es, this message translates to:
  /// **'Administración Pastoral'**
  String get administracionPastoral;

  /// No description provided for @gestionAvisos.
  ///
  /// In es, this message translates to:
  /// **'Avisos congregacionales'**
  String get gestionAvisos;

  /// No description provided for @gestionGrupos.
  ///
  /// In es, this message translates to:
  /// **'Audiencias y grupos'**
  String get gestionGrupos;

  /// No description provided for @accionRestringidaSoloLectura.
  ///
  /// In es, this message translates to:
  /// **'Acción no disponible en modo solo lectura'**
  String get accionRestringidaSoloLectura;

  /// No description provided for @permisoRequerido.
  ///
  /// In es, this message translates to:
  /// **'Requiere permisos de administrador'**
  String get permisoRequerido;

  /// No description provided for @moderacionPeticiones.
  ///
  /// In es, this message translates to:
  /// **'Moderación de peticiones'**
  String get moderacionPeticiones;

  /// No description provided for @metricasComunidad.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de comunidad'**
  String get metricasComunidad;

  /// No description provided for @publicarAviso.
  ///
  /// In es, this message translates to:
  /// **'Publicar aviso'**
  String get publicarAviso;

  /// No description provided for @tituloAviso.
  ///
  /// In es, this message translates to:
  /// **'Título del aviso'**
  String get tituloAviso;

  /// No description provided for @contenidoAviso.
  ///
  /// In es, this message translates to:
  /// **'Contenido del aviso'**
  String get contenidoAviso;

  /// No description provided for @fijarAviso.
  ///
  /// In es, this message translates to:
  /// **'Fijar al inicio'**
  String get fijarAviso;

  /// No description provided for @seleccionarAudiencia.
  ///
  /// In es, this message translates to:
  /// **'Audiencia / Grupo'**
  String get seleccionarAudiencia;

  /// No description provided for @todasLasAudiencias.
  ///
  /// In es, this message translates to:
  /// **'Toda la congregación'**
  String get todasLasAudiencias;

  /// No description provided for @publicar.
  ///
  /// In es, this message translates to:
  /// **'Publicar'**
  String get publicar;

  /// No description provided for @avisoPublicadoExito.
  ///
  /// In es, this message translates to:
  /// **'Aviso publicado con éxito'**
  String get avisoPublicadoExito;

  /// No description provided for @campoRequerido.
  ///
  /// In es, this message translates to:
  /// **'Este campo es requerido'**
  String get campoRequerido;

  /// No description provided for @errorPublicarAviso.
  ///
  /// In es, this message translates to:
  /// **'No fue posible publicar el aviso'**
  String get errorPublicarAviso;

  /// No description provided for @peticionesPendientes.
  ///
  /// In es, this message translates to:
  /// **'Peticiones pendientes'**
  String get peticionesPendientes;

  /// No description provided for @aprobar.
  ///
  /// In es, this message translates to:
  /// **'Aprobar'**
  String get aprobar;

  /// No description provided for @rechazar.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get rechazar;

  /// No description provided for @peticionAprobada.
  ///
  /// In es, this message translates to:
  /// **'Petición aprobada'**
  String get peticionAprobada;

  /// No description provided for @peticionRechazada.
  ///
  /// In es, this message translates to:
  /// **'Petición rechazada'**
  String get peticionRechazada;

  /// No description provided for @totalMiembros.
  ///
  /// In es, this message translates to:
  /// **'Total de miembros'**
  String get totalMiembros;

  /// No description provided for @nuevosMiembrosMes.
  ///
  /// In es, this message translates to:
  /// **'Nuevos miembros este mes'**
  String get nuevosMiembrosMes;

  /// No description provided for @totalOfrendas.
  ///
  /// In es, this message translates to:
  /// **'Ofrendas registradas'**
  String get totalOfrendas;

  /// No description provided for @inscripcionesEventos.
  ///
  /// In es, this message translates to:
  /// **'Inscripciones a eventos'**
  String get inscripcionesEventos;

  /// No description provided for @sinPeticionesPendientes.
  ///
  /// In es, this message translates to:
  /// **'No hay peticiones pendientes de moderación'**
  String get sinPeticionesPendientes;

  /// No description provided for @sinAvisosActivos.
  ///
  /// In es, this message translates to:
  /// **'No hay avisos congregacionales publicados'**
  String get sinAvisosActivos;

  /// No description provided for @motivoRechazoOpcional.
  ///
  /// In es, this message translates to:
  /// **'Motivo opcional de rechazo'**
  String get motivoRechazoOpcional;

  /// No description provided for @bannerModoSoloLectura.
  ///
  /// In es, this message translates to:
  /// **'Modo de solo lectura activado. Las funciones de publicación y registro están deshabilitadas.'**
  String get bannerModoSoloLectura;

  /// No description provided for @avisoModeracionOracion.
  ///
  /// In es, this message translates to:
  /// **'Nota pastoral: Tu petición de oración será revisada por el equipo pastoral antes de ser visible en la congregación.'**
  String get avisoModeracionOracion;

  /// No description provided for @iglesiaRequeridaParaSolicitud.
  ///
  /// In es, this message translates to:
  /// **'Debes tener una iglesia asignada para enviar solicitudes o peticiones pastorales.'**
  String get iglesiaRequeridaParaSolicitud;

  /// No description provided for @seleccionarIglesiaAccion.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar iglesia'**
  String get seleccionarIglesiaAccion;

  /// No description provided for @solicitudRequiereSesion.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión con tu cuenta para enviar solicitudes o peticiones pastorales a tu congregación.'**
  String get solicitudRequiereSesion;

  /// No description provided for @solicitudRequiereMembresia.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta está pendiente de asignación o aprobación de membresía por parte de tu congregación para enviar solicitudes.'**
  String get solicitudRequiereMembresia;

  /// No description provided for @donacionRequiereSesion.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión con una cuenta de miembro para realizar donaciones y ofrendas.'**
  String get donacionRequiereSesion;

  /// No description provided for @donacionRequiereMembresia.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta está registrada pero aún está pendiente de asignación o aprobación de membresía por parte de tu congregación. Solo miembros activos pueden realizar donaciones.'**
  String get donacionRequiereMembresia;

  /// No description provided for @donacionRequiereIglesia.
  ///
  /// In es, this message translates to:
  /// **'Debes pertenecer a una congregación asignada para realizar donaciones.'**
  String get donacionRequiereIglesia;

  /// No description provided for @inicioSesionRequerido.
  ///
  /// In es, this message translates to:
  /// **'Inicio de sesión requerido'**
  String get inicioSesionRequerido;

  /// No description provided for @tiendaRequiereSesion.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión con tu cuenta para agregar productos y realizar compras en la tienda.'**
  String get tiendaRequiereSesion;

  /// No description provided for @librosRequiereSesion.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión con tu cuenta para leer o escuchar libros de la biblioteca.'**
  String get librosRequiereSesion;

  /// No description provided for @proyectoRequiereSesion.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión con tu cuenta para colaborar y aportar a proyectos solidarios.'**
  String get proyectoRequiereSesion;

  /// No description provided for @sesionRequeridaGenerica.
  ///
  /// In es, this message translates to:
  /// **'Debes iniciar sesión con tu cuenta para acceder a esta función.'**
  String get sesionRequeridaGenerica;

  /// No description provided for @membresiaPendiente.
  ///
  /// In es, this message translates to:
  /// **'Membresía pendiente de aprobación'**
  String get membresiaPendiente;

  /// No description provided for @iniciarSesion.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get iniciarSesion;

  /// No description provided for @modoInvitado.
  ///
  /// In es, this message translates to:
  /// **'Modo invitado'**
  String get modoInvitado;

  /// No description provided for @usuarioInvitado.
  ///
  /// In es, this message translates to:
  /// **'Usuario invitado'**
  String get usuarioInvitado;

  /// No description provided for @perfilInvitadoDesc.
  ///
  /// In es, this message translates to:
  /// **'Estás navegando en modo invitado. Inicia sesión para acceder a tu historial, peticiones y donaciones.'**
  String get perfilInvitadoDesc;

  /// No description provided for @sinSolicitudesRegistradas.
  ///
  /// In es, this message translates to:
  /// **'No tienes solicitudes registradas'**
  String get sinSolicitudesRegistradas;

  /// No description provided for @solicitudesInvitadoDesc.
  ///
  /// In es, this message translates to:
  /// **'En modo invitado no se registran ni muestran solicitudes. Inicia sesión para crear peticiones y darles seguimiento.'**
  String get solicitudesInvitadoDesc;

  /// No description provided for @sinDonacionesRegistradas.
  ///
  /// In es, this message translates to:
  /// **'No tienes donaciones registradas'**
  String get sinDonacionesRegistradas;

  /// No description provided for @donacionesInvitadoDesc.
  ///
  /// In es, this message translates to:
  /// **'En modo invitado no se registran aportes ni historial. Inicia sesión para colaborar y consultar tus donaciones.'**
  String get donacionesInvitadoDesc;

  /// Mensaje al añadir evento al calendario
  ///
  /// In es, this message translates to:
  /// **'Evento \"{titulo}\" añadido a tu calendario.'**
  String eventoAnadidoACalendario(String titulo);

  /// No description provided for @anadirACalendario.
  ///
  /// In es, this message translates to:
  /// **'Añadir a calendario'**
  String get anadirACalendario;

  /// No description provided for @miActividadAgendada.
  ///
  /// In es, this message translates to:
  /// **'Mi actividad agendada'**
  String get miActividadAgendada;

  /// Porcentaje de cupo ocupado
  ///
  /// In es, this message translates to:
  /// **'{porcentaje}% ocupación'**
  String porcentajeOcupacion(int porcentaje);

  /// No description provided for @disponibilidadCupos.
  ///
  /// In es, this message translates to:
  /// **'Disponibilidad de cupos'**
  String get disponibilidadCupos;

  /// No description provided for @detallesDelEvento.
  ///
  /// In es, this message translates to:
  /// **'Detalles del evento'**
  String get detallesDelEvento;

  /// Confirmación de inscripción en evento
  ///
  /// In es, this message translates to:
  /// **'Inscripción confirmada para \"{titulo}\". ¡Te esperamos!'**
  String inscripcionConfirmada(String titulo);

  /// No description provided for @yaEstasInscrito.
  ///
  /// In es, this message translates to:
  /// **'Ya estás inscrito'**
  String get yaEstasInscrito;

  /// Mensaje de evento agregado a la agenda local
  ///
  /// In es, this message translates to:
  /// **'Evento \"{titulo}\" agregado a tu agenda local.'**
  String eventoAgregadoAgendaLocal(String titulo);

  /// No description provided for @mensajeWhatsAppAyuda.
  ///
  /// In es, this message translates to:
  /// **'Hola, necesito ayuda con la app ATRIO.'**
  String get mensajeWhatsAppAyuda;

  /// No description provided for @errorAbrirWhatsAppDispositivo.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir WhatsApp en este dispositivo.'**
  String get errorAbrirWhatsAppDispositivo;

  /// No description provided for @errorAbrirWhatsApp.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error al intentar abrir WhatsApp.'**
  String get errorAbrirWhatsApp;

  /// No description provided for @asuntoCorreoSoporte.
  ///
  /// In es, this message translates to:
  /// **'Soporte - App ATRIO'**
  String get asuntoCorreoSoporte;

  /// No description provided for @cuerpoCorreoSoporte.
  ///
  /// In es, this message translates to:
  /// **'Describe aquí tu consulta o inconveniente:\n\n---\nVersión de la app: 1.0.0'**
  String get cuerpoCorreoSoporte;

  /// No description provided for @errorNoClienteCorreo.
  ///
  /// In es, this message translates to:
  /// **'No se encontró un cliente de correo configurado.'**
  String get errorNoClienteCorreo;

  /// No description provided for @errorAbrirCorreo.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error al intentar abrir el correo.'**
  String get errorAbrirCorreo;

  /// No description provided for @modoClaroSuave.
  ///
  /// In es, this message translates to:
  /// **'Modo Claro Suave'**
  String get modoClaroSuave;

  /// No description provided for @modoLecturaNocturna.
  ///
  /// In es, this message translates to:
  /// **'Modo Lectura Nocturna'**
  String get modoLecturaNocturna;

  /// No description provided for @modoPapiroCalido.
  ///
  /// In es, this message translates to:
  /// **'Modo Papiro Cálido'**
  String get modoPapiroCalido;

  /// No description provided for @ajustesDeLectura.
  ///
  /// In es, this message translates to:
  /// **'Ajustes de lectura'**
  String get ajustesDeLectura;

  /// No description provided for @tamanoDeLetra.
  ///
  /// In es, this message translates to:
  /// **'Tamaño de letra'**
  String get tamanoDeLetra;

  /// No description provided for @tipoDeFuente.
  ///
  /// In es, this message translates to:
  /// **'Tipo de fuente'**
  String get tipoDeFuente;

  /// No description provided for @modoDeLectura.
  ///
  /// In es, this message translates to:
  /// **'Modo de lectura'**
  String get modoDeLectura;

  /// No description provided for @papiro.
  ///
  /// In es, this message translates to:
  /// **'Papiro'**
  String get papiro;

  /// No description provided for @noche.
  ///
  /// In es, this message translates to:
  /// **'Noche'**
  String get noche;

  /// No description provided for @cambiarTonoLecturaTooltip.
  ///
  /// In es, this message translates to:
  /// **'Cambiar tono de lectura'**
  String get cambiarTonoLecturaTooltip;

  /// No description provided for @comoPodemosAyudarte.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo podemos ayudarte?'**
  String get comoPodemosAyudarte;

  /// No description provided for @descripcionAyudaSoporte.
  ///
  /// In es, this message translates to:
  /// **'Encuentra respuestas rápidas o comunícate directamente con nuestro equipo de asistencia técnica de ATRIO.'**
  String get descripcionAyudaSoporte;

  /// No description provided for @canalesDeAtencion.
  ///
  /// In es, this message translates to:
  /// **'Canales de atención'**
  String get canalesDeAtencion;

  /// No description provided for @chatDirecto.
  ///
  /// In es, this message translates to:
  /// **'Chat directo'**
  String get chatDirecto;

  /// No description provided for @preguntasFrecuentes.
  ///
  /// In es, this message translates to:
  /// **'Preguntas frecuentes'**
  String get preguntasFrecuentes;

  /// No description provided for @faq1Pregunta.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo realizar una ofrenda o donación a mi iglesia?'**
  String get faq1Pregunta;

  /// No description provided for @faq1Respuesta.
  ///
  /// In es, this message translates to:
  /// **'Accede a la sección \"Mis donaciones\" desde tu perfil o pulsa el botón \"Ofrendar / Aportar\" en la pantalla de tu iglesia. Podrás seleccionar el proyecto solidario, ingresar el monto y proceder con total seguridad.'**
  String get faq1Respuesta;

  /// No description provided for @faq2Pregunta.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo enviar y consultar el estado de mis solicitudes pastorales?'**
  String get faq2Pregunta;

  /// No description provided for @faq2Respuesta.
  ///
  /// In es, this message translates to:
  /// **'Dirígete a la sección \"Mis solicitudes\" en tu perfil o desde el menú de tu iglesia. Allí podrás enviar peticiones de oración, consejería o apoyo social y verificar el seguimiento de respuesta de tu comunidad.'**
  String get faq2Respuesta;

  /// No description provided for @faq3Pregunta.
  ///
  /// In es, this message translates to:
  /// **'¿Dónde puedo explorar iglesias cercanas y verlas en el mapa?'**
  String get faq3Pregunta;

  /// No description provided for @faq3Respuesta.
  ///
  /// In es, this message translates to:
  /// **'Desde la pantalla principal pulsa sobre \"Explorar Iglesias\" o el mapa interactivo. Podrás filtrar por tradición cristiana, conocer horarios de servicios, pastores encargados y obtener la ruta en el mapa.'**
  String get faq3Respuesta;

  /// No description provided for @faq4Pregunta.
  ///
  /// In es, this message translates to:
  /// **'¿Puedo leer la Biblia y guardar notas o favoritos sin conexión?'**
  String get faq4Pregunta;

  /// No description provided for @faq4Respuesta.
  ///
  /// In es, this message translates to:
  /// **'¡Sí! El texto bíblico, tus notas de estudio y los versículos destacados quedan almacenados de manera segura y local en tu dispositivo mediante SQLite para que los disfrutes en todo momento.'**
  String get faq4Respuesta;

  /// No description provided for @faq5Pregunta.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo actualizar mis datos de perfil o cambiar de iglesia?'**
  String get faq5Pregunta;

  /// No description provided for @faq5Respuesta.
  ///
  /// In es, this message translates to:
  /// **'En la pestaña Perfil, presiona \"Mis datos\" o el botón de edición para actualizar tu nombre, correo o teléfono celular. Si deseas afiliarte a otra comunidad, pulsa \"Cambiar de iglesia\".'**
  String get faq5Respuesta;

  /// Texto con la versión de la aplicación
  ///
  /// In es, this message translates to:
  /// **'ATRIO · Versión {version}'**
  String atrioVersion(String version);

  /// No description provided for @todosLosDerechosReservados.
  ///
  /// In es, this message translates to:
  /// **'Todos los derechos reservados'**
  String get todosLosDerechosReservados;

  /// No description provided for @tiposDeSolicitud.
  ///
  /// In es, this message translates to:
  /// **'Tipos de solicitud'**
  String get tiposDeSolicitud;

  /// No description provided for @peticionDeOracion.
  ///
  /// In es, this message translates to:
  /// **'Petición de oración'**
  String get peticionDeOracion;

  /// No description provided for @orientacionPastoral.
  ///
  /// In es, this message translates to:
  /// **'Orientación pastoral'**
  String get orientacionPastoral;

  /// No description provided for @consejeriaFamiliar.
  ///
  /// In es, this message translates to:
  /// **'Consejería familiar'**
  String get consejeriaFamiliar;

  /// No description provided for @visitaAEnfermos.
  ///
  /// In es, this message translates to:
  /// **'Visita a enfermos'**
  String get visitaAEnfermos;

  /// No description provided for @ayudaComunitaria.
  ///
  /// In es, this message translates to:
  /// **'Ayuda comunitaria'**
  String get ayudaComunitaria;

  /// No description provided for @otraSolicitud.
  ///
  /// In es, this message translates to:
  /// **'Otra solicitud'**
  String get otraSolicitud;

  /// No description provided for @volver.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get volver;

  /// No description provided for @comunidadVerificada.
  ///
  /// In es, this message translates to:
  /// **'Comunidad verificada'**
  String get comunidadVerificada;

  /// No description provided for @diezmo.
  ///
  /// In es, this message translates to:
  /// **'Diezmo'**
  String get diezmo;

  /// No description provided for @ofrenda.
  ///
  /// In es, this message translates to:
  /// **'Ofrenda'**
  String get ofrenda;

  /// No description provided for @campanaEspecial.
  ///
  /// In es, this message translates to:
  /// **'Campaña especial'**
  String get campanaEspecial;

  /// No description provided for @otroAporte.
  ///
  /// In es, this message translates to:
  /// **'Otro aporte'**
  String get otroAporte;

  /// No description provided for @historialYRecibos.
  ///
  /// In es, this message translates to:
  /// **'Historial y recibos'**
  String get historialYRecibos;

  /// No description provided for @proyectosSolidariosTitulo.
  ///
  /// In es, this message translates to:
  /// **'Proyectos solidarios'**
  String get proyectosSolidariosTitulo;

  /// No description provided for @lemaProyectosSolidarios.
  ///
  /// In es, this message translates to:
  /// **'Juntos podemos transformar vidas'**
  String get lemaProyectosSolidarios;

  /// No description provided for @noHayDatosDisponibles.
  ///
  /// In es, this message translates to:
  /// **'No hay datos disponibles'**
  String get noHayDatosDisponibles;

  /// No description provided for @masCampanas.
  ///
  /// In es, this message translates to:
  /// **'Más campañas'**
  String get masCampanas;

  /// No description provided for @metaPrefijo.
  ///
  /// In es, this message translates to:
  /// **'Meta:'**
  String get metaPrefijo;

  /// No description provided for @deMonto.
  ///
  /// In es, this message translates to:
  /// **'de'**
  String get deMonto;

  /// Porcentaje de recaudación alcanzado en un proyecto solidario
  ///
  /// In es, this message translates to:
  /// **'{porcentaje}% alcanzado'**
  String porcentajeAlcanzado(String porcentaje);

  /// Días restantes para finalizar la campaña del proyecto solidario
  ///
  /// In es, this message translates to:
  /// **'{dias} días restantes'**
  String diasRestantes(String dias);

  /// Mensaje en snackbar indicando cantidad de productos en el carrito
  ///
  /// In es, this message translates to:
  /// **'Tienes {cantidad} productos en tu carrito de compras'**
  String carritoCantidadProductos(String cantidad);

  /// No description provided for @buscarProductosPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Buscar biblias, libros o regalos...'**
  String get buscarProductosPlaceholder;

  /// No description provided for @categoriaBiblias.
  ///
  /// In es, this message translates to:
  /// **'Biblias'**
  String get categoriaBiblias;

  /// No description provided for @categoriaLibros.
  ///
  /// In es, this message translates to:
  /// **'Libros'**
  String get categoriaLibros;

  /// No description provided for @categoriaRegalos.
  ///
  /// In es, this message translates to:
  /// **'Regalos'**
  String get categoriaRegalos;

  /// No description provided for @recursosParaCrecerEnTuFe.
  ///
  /// In es, this message translates to:
  /// **'Recursos para\ncrecer en tu fe'**
  String get recursosParaCrecerEnTuFe;

  /// No description provided for @verDestacados.
  ///
  /// In es, this message translates to:
  /// **'Ver destacados'**
  String get verDestacados;

  /// No description provided for @catalogoDeProductos.
  ///
  /// In es, this message translates to:
  /// **'Catálogo de productos'**
  String get catalogoDeProductos;

  /// No description provided for @noSeEncontraronProductosCategoria.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron productos en esta categoría'**
  String get noSeEncontraronProductosCategoria;

  /// No description provided for @entregaORetiro.
  ///
  /// In es, this message translates to:
  /// **'Entrega o retiro'**
  String get entregaORetiro;

  /// No description provided for @envioADomicilio.
  ///
  /// In es, this message translates to:
  /// **'Envío a domicilio'**
  String get envioADomicilio;

  /// No description provided for @retiroEnIglesia.
  ///
  /// In es, this message translates to:
  /// **'Retiro en iglesia'**
  String get retiroEnIglesia;

  /// Indicador de inventario de un producto en la tienda
  ///
  /// In es, this message translates to:
  /// **'{cantidad} unidades en inventario'**
  String unidadesEnInventario(String cantidad);

  /// No description provided for @detallesDelProducto.
  ///
  /// In es, this message translates to:
  /// **'Detalles del producto'**
  String get detallesDelProducto;

  /// Mensaje confirmando que un producto fue agregado al carrito
  ///
  /// In es, this message translates to:
  /// **'¡\"{nombre}\" agregado al carrito!'**
  String productoAgregadoAlCarrito(String nombre);

  /// Texto del botón para agregar al carrito con precio formateado
  ///
  /// In es, this message translates to:
  /// **'Agregar al carrito · {precio}'**
  String agregarAlCarritoConPrecio(String precio);

  /// No description provided for @buscarLibrosPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Buscar libros o autores...'**
  String get buscarLibrosPlaceholder;

  /// No description provided for @categoriaVidaCristiana.
  ///
  /// In es, this message translates to:
  /// **'Vida cristiana'**
  String get categoriaVidaCristiana;

  /// No description provided for @categoriaCrecimiento.
  ///
  /// In es, this message translates to:
  /// **'Crecimiento'**
  String get categoriaCrecimiento;

  /// No description provided for @explorarLibros.
  ///
  /// In es, this message translates to:
  /// **'Explorar libros'**
  String get explorarLibros;

  /// No description provided for @noSeEncontraronLibrosCategoria.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron libros en esta categoría'**
  String get noSeEncontraronLibrosCategoria;

  /// No description provided for @leerAhora.
  ///
  /// In es, this message translates to:
  /// **'Leer ahora'**
  String get leerAhora;

  /// No description provided for @escucharMuestra.
  ///
  /// In es, this message translates to:
  /// **'Escuchar muestra'**
  String get escucharMuestra;

  /// Mensaje en snackbar cuando se reproduce la muestra de un libro
  ///
  /// In es, this message translates to:
  /// **'Reproduciendo muestra de \"{titulo}\"...'**
  String reproduciendoMuestra(String titulo);

  /// Total de páginas de un libro
  ///
  /// In es, this message translates to:
  /// **'{paginas} páginas'**
  String totalPaginas(String paginas);

  /// Porcentaje de lectura completado
  ///
  /// In es, this message translates to:
  /// **'{porcentaje}% leído'**
  String porcentajeLeido(String porcentaje);

  /// No description provided for @sinopsis.
  ///
  /// In es, this message translates to:
  /// **'Sinopsis'**
  String get sinopsis;

  /// Mensaje en snackbar al abrir un libro para leer
  ///
  /// In es, this message translates to:
  /// **'Abriendo \"{titulo}\"...'**
  String abriendoLibro(String titulo);

  /// No description provided for @videosYTransmisiones.
  ///
  /// In es, this message translates to:
  /// **'Videos y transmisiones'**
  String get videosYTransmisiones;

  /// No description provided for @buscarVideosPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Buscar prédicas, canales o temas...'**
  String get buscarVideosPlaceholder;

  /// No description provided for @enVivoBadge.
  ///
  /// In es, this message translates to:
  /// **'EN VIVO'**
  String get enVivoBadge;

  /// No description provided for @categoriaEnVivo.
  ///
  /// In es, this message translates to:
  /// **'En vivo'**
  String get categoriaEnVivo;

  /// No description provided for @categoriaPredicas.
  ///
  /// In es, this message translates to:
  /// **'Prédicas'**
  String get categoriaPredicas;

  /// No description provided for @categoriaEstudios.
  ///
  /// In es, this message translates to:
  /// **'Estudios'**
  String get categoriaEstudios;

  /// No description provided for @categoriaMusica.
  ///
  /// In es, this message translates to:
  /// **'Música'**
  String get categoriaMusica;

  /// No description provided for @noSeEncontraronVideosCategoria.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron videos en esta categoría'**
  String get noSeEncontraronVideosCategoria;

  /// No description provided for @descripcion.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get descripcion;

  /// Mensaje en snackbar al conectar a una transmisión en vivo
  ///
  /// In es, this message translates to:
  /// **'Conectando a transmisión \"{titulo}\"...'**
  String conectandoTransmision(String titulo);

  /// Mensaje en snackbar al reproducir un video
  ///
  /// In es, this message translates to:
  /// **'Reproduciendo \"{titulo}\"...'**
  String reproduciendoVideo(String titulo);

  /// No description provided for @verTransmisionEnVivo.
  ///
  /// In es, this message translates to:
  /// **'Ver transmisión en vivo'**
  String get verTransmisionEnVivo;

  /// No description provided for @reproducirAhora.
  ///
  /// In es, this message translates to:
  /// **'Reproducir ahora'**
  String get reproducirAhora;

  /// Mensaje en snackbar al copiar enlace del video al portapapeles
  ///
  /// In es, this message translates to:
  /// **'Enlace de \"{titulo}\" copiado al portapapeles'**
  String enlaceCopiadoPortapapeles(String titulo);

  /// No description provided for @filtrarPorNombreDeLibro.
  ///
  /// In es, this message translates to:
  /// **'Filtrar por nombre de libro...'**
  String get filtrarPorNombreDeLibro;

  /// No description provided for @antiguoTestamento.
  ///
  /// In es, this message translates to:
  /// **'Antiguo Testamento'**
  String get antiguoTestamento;

  /// No description provided for @nuevoTestamento.
  ///
  /// In es, this message translates to:
  /// **'Nuevo Testamento'**
  String get nuevoTestamento;

  /// No description provided for @noSeEncontraronLibros.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron libros'**
  String get noSeEncontraronLibros;

  /// No description provided for @unCapitulo.
  ///
  /// In es, this message translates to:
  /// **'1 capítulo'**
  String get unCapitulo;

  /// Total de capítulos de un libro
  ///
  /// In es, this message translates to:
  /// **'{total} capítulos'**
  String totalCapitulos(String total);

  /// No description provided for @libroGenesis.
  ///
  /// In es, this message translates to:
  /// **'Génesis'**
  String get libroGenesis;

  /// No description provided for @libroExodo.
  ///
  /// In es, this message translates to:
  /// **'Éxodo'**
  String get libroExodo;

  /// No description provided for @libroLevitico.
  ///
  /// In es, this message translates to:
  /// **'Levítico'**
  String get libroLevitico;

  /// No description provided for @libroNumeros.
  ///
  /// In es, this message translates to:
  /// **'Números'**
  String get libroNumeros;

  /// No description provided for @libroDeuteronomio.
  ///
  /// In es, this message translates to:
  /// **'Deuteronomio'**
  String get libroDeuteronomio;

  /// No description provided for @libroJosue.
  ///
  /// In es, this message translates to:
  /// **'Josué'**
  String get libroJosue;

  /// No description provided for @libroJueces.
  ///
  /// In es, this message translates to:
  /// **'Jueces'**
  String get libroJueces;

  /// No description provided for @libroRut.
  ///
  /// In es, this message translates to:
  /// **'Rut'**
  String get libroRut;

  /// No description provided for @libro1Samuel.
  ///
  /// In es, this message translates to:
  /// **'1 Samuel'**
  String get libro1Samuel;

  /// No description provided for @libro2Samuel.
  ///
  /// In es, this message translates to:
  /// **'2 Samuel'**
  String get libro2Samuel;

  /// No description provided for @libro1Reyes.
  ///
  /// In es, this message translates to:
  /// **'1 Reyes'**
  String get libro1Reyes;

  /// No description provided for @libro2Reyes.
  ///
  /// In es, this message translates to:
  /// **'2 Reyes'**
  String get libro2Reyes;

  /// No description provided for @libro1Cronicas.
  ///
  /// In es, this message translates to:
  /// **'1 Crónicas'**
  String get libro1Cronicas;

  /// No description provided for @libro2Cronicas.
  ///
  /// In es, this message translates to:
  /// **'2 Crónicas'**
  String get libro2Cronicas;

  /// No description provided for @libroEsdras.
  ///
  /// In es, this message translates to:
  /// **'Esdras'**
  String get libroEsdras;

  /// No description provided for @libroNehemias.
  ///
  /// In es, this message translates to:
  /// **'Nehemías'**
  String get libroNehemias;

  /// No description provided for @libroEster.
  ///
  /// In es, this message translates to:
  /// **'Ester'**
  String get libroEster;

  /// No description provided for @libroJob.
  ///
  /// In es, this message translates to:
  /// **'Job'**
  String get libroJob;

  /// No description provided for @libroSalmos.
  ///
  /// In es, this message translates to:
  /// **'Salmos'**
  String get libroSalmos;

  /// No description provided for @libroProverbios.
  ///
  /// In es, this message translates to:
  /// **'Proverbios'**
  String get libroProverbios;

  /// No description provided for @libroEclesiastes.
  ///
  /// In es, this message translates to:
  /// **'Eclesiastés'**
  String get libroEclesiastes;

  /// No description provided for @libroCantares.
  ///
  /// In es, this message translates to:
  /// **'Cantares'**
  String get libroCantares;

  /// No description provided for @libroIsaias.
  ///
  /// In es, this message translates to:
  /// **'Isaías'**
  String get libroIsaias;

  /// No description provided for @libroJeremias.
  ///
  /// In es, this message translates to:
  /// **'Jeremías'**
  String get libroJeremias;

  /// No description provided for @libroLamentaciones.
  ///
  /// In es, this message translates to:
  /// **'Lamentaciones'**
  String get libroLamentaciones;

  /// No description provided for @libroEzequiel.
  ///
  /// In es, this message translates to:
  /// **'Ezequiel'**
  String get libroEzequiel;

  /// No description provided for @libroDaniel.
  ///
  /// In es, this message translates to:
  /// **'Daniel'**
  String get libroDaniel;

  /// No description provided for @libroOseas.
  ///
  /// In es, this message translates to:
  /// **'Oseas'**
  String get libroOseas;

  /// No description provided for @libroJoel.
  ///
  /// In es, this message translates to:
  /// **'Joel'**
  String get libroJoel;

  /// No description provided for @libroAmos.
  ///
  /// In es, this message translates to:
  /// **'Amós'**
  String get libroAmos;

  /// No description provided for @libroAbdias.
  ///
  /// In es, this message translates to:
  /// **'Abdías'**
  String get libroAbdias;

  /// No description provided for @libroJonas.
  ///
  /// In es, this message translates to:
  /// **'Jonás'**
  String get libroJonas;

  /// No description provided for @libroMiqueas.
  ///
  /// In es, this message translates to:
  /// **'Miqueas'**
  String get libroMiqueas;

  /// No description provided for @libroNahum.
  ///
  /// In es, this message translates to:
  /// **'Nahúm'**
  String get libroNahum;

  /// No description provided for @libroHabacuc.
  ///
  /// In es, this message translates to:
  /// **'Habacuc'**
  String get libroHabacuc;

  /// No description provided for @libroSofonias.
  ///
  /// In es, this message translates to:
  /// **'Sofonías'**
  String get libroSofonias;

  /// No description provided for @libroHageo.
  ///
  /// In es, this message translates to:
  /// **'Hageo'**
  String get libroHageo;

  /// No description provided for @libroZacarias.
  ///
  /// In es, this message translates to:
  /// **'Zacarías'**
  String get libroZacarias;

  /// No description provided for @libroMalaquias.
  ///
  /// In es, this message translates to:
  /// **'Malaquías'**
  String get libroMalaquias;

  /// No description provided for @libroMateo.
  ///
  /// In es, this message translates to:
  /// **'Mateo'**
  String get libroMateo;

  /// No description provided for @libroMarcos.
  ///
  /// In es, this message translates to:
  /// **'Marcos'**
  String get libroMarcos;

  /// No description provided for @libroLucas.
  ///
  /// In es, this message translates to:
  /// **'Lucas'**
  String get libroLucas;

  /// No description provided for @libroJuan.
  ///
  /// In es, this message translates to:
  /// **'Juan'**
  String get libroJuan;

  /// No description provided for @libroHechos.
  ///
  /// In es, this message translates to:
  /// **'Hechos'**
  String get libroHechos;

  /// No description provided for @libroRomanos.
  ///
  /// In es, this message translates to:
  /// **'Romanos'**
  String get libroRomanos;

  /// No description provided for @libro1Corintios.
  ///
  /// In es, this message translates to:
  /// **'1 Corintios'**
  String get libro1Corintios;

  /// No description provided for @libro2Corintios.
  ///
  /// In es, this message translates to:
  /// **'2 Corintios'**
  String get libro2Corintios;

  /// No description provided for @libroGalatas.
  ///
  /// In es, this message translates to:
  /// **'Gálatas'**
  String get libroGalatas;

  /// No description provided for @libroEfesios.
  ///
  /// In es, this message translates to:
  /// **'Efesios'**
  String get libroEfesios;

  /// No description provided for @libroFilipenses.
  ///
  /// In es, this message translates to:
  /// **'Filipenses'**
  String get libroFilipenses;

  /// No description provided for @libroColosenses.
  ///
  /// In es, this message translates to:
  /// **'Colosenses'**
  String get libroColosenses;

  /// No description provided for @libro1Tesalonicenses.
  ///
  /// In es, this message translates to:
  /// **'1 Tesalonicenses'**
  String get libro1Tesalonicenses;

  /// No description provided for @libro2Tesalonicenses.
  ///
  /// In es, this message translates to:
  /// **'2 Tesalonicenses'**
  String get libro2Tesalonicenses;

  /// No description provided for @libro1Timoteo.
  ///
  /// In es, this message translates to:
  /// **'1 Timoteo'**
  String get libro1Timoteo;

  /// No description provided for @libro2Timoteo.
  ///
  /// In es, this message translates to:
  /// **'2 Timoteo'**
  String get libro2Timoteo;

  /// No description provided for @libroTito.
  ///
  /// In es, this message translates to:
  /// **'Tito'**
  String get libroTito;

  /// No description provided for @libroFilemon.
  ///
  /// In es, this message translates to:
  /// **'Filemón'**
  String get libroFilemon;

  /// No description provided for @libroHebreos.
  ///
  /// In es, this message translates to:
  /// **'Hebreos'**
  String get libroHebreos;

  /// No description provided for @libroSantiago.
  ///
  /// In es, this message translates to:
  /// **'Santiago'**
  String get libroSantiago;

  /// No description provided for @libro1Pedro.
  ///
  /// In es, this message translates to:
  /// **'1 Pedro'**
  String get libro1Pedro;

  /// No description provided for @libro2Pedro.
  ///
  /// In es, this message translates to:
  /// **'2 Pedro'**
  String get libro2Pedro;

  /// No description provided for @libro1Juan.
  ///
  /// In es, this message translates to:
  /// **'1 Juan'**
  String get libro1Juan;

  /// No description provided for @libro2Juan.
  ///
  /// In es, this message translates to:
  /// **'2 Juan'**
  String get libro2Juan;

  /// No description provided for @libro3Juan.
  ///
  /// In es, this message translates to:
  /// **'3 Juan'**
  String get libro3Juan;

  /// No description provided for @libroJudas.
  ///
  /// In es, this message translates to:
  /// **'Judas'**
  String get libroJudas;

  /// No description provided for @libroApocalipsis.
  ///
  /// In es, this message translates to:
  /// **'Apocalipsis'**
  String get libroApocalipsis;

  /// No description provided for @capitulosTab.
  ///
  /// In es, this message translates to:
  /// **'Capítulos'**
  String get capitulosTab;

  /// No description provided for @informacionTab.
  ///
  /// In es, this message translates to:
  /// **'Información'**
  String get informacionTab;

  /// No description provided for @acercaDelLibro.
  ///
  /// In es, this message translates to:
  /// **'Acerca del libro'**
  String get acercaDelLibro;

  /// No description provided for @errorCargarInfoLibro.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la información del libro.'**
  String get errorCargarInfoLibro;

  /// No description provided for @escucharBiblia.
  ///
  /// In es, this message translates to:
  /// **'Escuchar Biblia'**
  String get escucharBiblia;

  /// No description provided for @sinInternetAudio.
  ///
  /// In es, this message translates to:
  /// **'No hay conexión a internet para reproducir el audio.'**
  String get sinInternetAudio;

  /// Aviso de audio disponible próximamente
  ///
  /// In es, this message translates to:
  /// **'El audio dramatizado de {nombre} estará disponible próximamente.'**
  String audioDramatizadoProximamente(String nombre);

  /// Aviso de fin de lectura de audio
  ///
  /// In es, this message translates to:
  /// **'Fin de la lectura de {libro} {capitulo}'**
  String finLecturaAudio(String libro, String capitulo);

  /// Título del reproductor de audio
  ///
  /// In es, this message translates to:
  /// **'{libro} {capitulo} (Audio)'**
  String audioCapituloTitulo(String libro, String capitulo);

  /// No description provided for @eliminadoDeFavoritos.
  ///
  /// In es, this message translates to:
  /// **'Eliminado de favoritos'**
  String get eliminadoDeFavoritos;

  /// No description provided for @sinFavoritos.
  ///
  /// In es, this message translates to:
  /// **'Sin favoritos'**
  String get sinFavoritos;

  /// No description provided for @sinFavoritosDesc.
  ///
  /// In es, this message translates to:
  /// **'Toca el ícono de marcador en cualquier capítulo para guardarlo aquí y acceder rápidamente.'**
  String get sinFavoritosDesc;

  /// Fecha en que se guardó el favorito
  ///
  /// In es, this message translates to:
  /// **'Guardado el {fecha}'**
  String guardadoEl(String fecha);

  /// No description provided for @desdeFavoritos.
  ///
  /// In es, this message translates to:
  /// **'Desde Favoritos'**
  String get desdeFavoritos;

  /// No description provided for @eliminarNotaTitulo.
  ///
  /// In es, this message translates to:
  /// **'Eliminar nota'**
  String get eliminarNotaTitulo;

  /// No description provided for @seguroEliminarNota.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas eliminar esta nota de forma permanente?'**
  String get seguroEliminarNota;

  /// No description provided for @eliminar.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get eliminar;

  /// No description provided for @notaEliminadaCorrectamente.
  ///
  /// In es, this message translates to:
  /// **'Nota eliminada correctamente'**
  String get notaEliminadaCorrectamente;

  /// No description provided for @aunNoTienesNotas.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes notas'**
  String get aunNoTienesNotas;

  /// No description provided for @aunNoTienesNotasDesc.
  ///
  /// In es, this message translates to:
  /// **'Tus reflexiones y apuntes bíblicos aparecerán aquí. Abre cualquier capítulo y toca el ícono de Nota para empezar.'**
  String get aunNoTienesNotasDesc;

  /// No description provided for @nuevaSolicitud.
  ///
  /// In es, this message translates to:
  /// **'Nueva solicitud'**
  String get nuevaSolicitud;

  /// No description provided for @tipoSolicitudLabel.
  ///
  /// In es, this message translates to:
  /// **'Tipo de solicitud'**
  String get tipoSolicitudLabel;

  /// No description provided for @seleccionaUnaOpcion.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una opción'**
  String get seleccionaUnaOpcion;

  /// No description provided for @asunto.
  ///
  /// In es, this message translates to:
  /// **'Asunto'**
  String get asunto;

  /// No description provided for @asuntoPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Escribe un asunto breve'**
  String get asuntoPlaceholder;

  /// No description provided for @asuntoObligatorio.
  ///
  /// In es, this message translates to:
  /// **'El asunto es obligatorio'**
  String get asuntoObligatorio;

  /// No description provided for @describeComoAyudarte.
  ///
  /// In es, this message translates to:
  /// **'Describe cómo podemos ayudarte'**
  String get describeComoAyudarte;

  /// No description provided for @descripcionObligatoria.
  ///
  /// In es, this message translates to:
  /// **'La descripción es obligatoria'**
  String get descripcionObligatoria;

  /// No description provided for @detallesSolicitudPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos los detalles de tu solicitud'**
  String get detallesSolicitudPlaceholder;

  /// No description provided for @telefonoObligatorio.
  ///
  /// In es, this message translates to:
  /// **'El teléfono es obligatorio'**
  String get telefonoObligatorio;

  /// No description provided for @telefonoInvalido.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un número de teléfono válido'**
  String get telefonoInvalido;

  /// No description provided for @solicitudPrivada.
  ///
  /// In es, this message translates to:
  /// **'Solicitud privada'**
  String get solicitudPrivada;

  /// No description provided for @solicitudPrivadaDesc.
  ///
  /// In es, this message translates to:
  /// **'Solo el equipo pastoral podrá verla'**
  String get solicitudPrivadaDesc;

  /// No description provided for @general.
  ///
  /// In es, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @completaCamposObligatorios.
  ///
  /// In es, this message translates to:
  /// **'Por favor completa todos los campos obligatorios.'**
  String get completaCamposObligatorios;

  /// No description provided for @enviarSolicitud.
  ///
  /// In es, this message translates to:
  /// **'Enviar Solicitud'**
  String get enviarSolicitud;

  /// No description provided for @realizaTuAporte.
  ///
  /// In es, this message translates to:
  /// **'Realiza tu aporte'**
  String get realizaTuAporte;

  /// No description provided for @errorCargarDatos.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar datos'**
  String get errorCargarDatos;

  /// No description provided for @tipoDonacion.
  ///
  /// In es, this message translates to:
  /// **'Tipo de donación'**
  String get tipoDonacion;

  /// No description provided for @seleccionaElMonto.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el monto'**
  String get seleccionaElMonto;

  /// No description provided for @otroMonto.
  ///
  /// In es, this message translates to:
  /// **'Otro monto'**
  String get otroMonto;

  /// No description provided for @frecuencia.
  ///
  /// In es, this message translates to:
  /// **'Frecuencia'**
  String get frecuencia;

  /// No description provided for @frecuenciaUnaSolaVez.
  ///
  /// In es, this message translates to:
  /// **'Una sola vez'**
  String get frecuenciaUnaSolaVez;

  /// No description provided for @frecuenciaMensual.
  ///
  /// In es, this message translates to:
  /// **'Mensual'**
  String get frecuenciaMensual;

  /// No description provided for @metodoDePago.
  ///
  /// In es, this message translates to:
  /// **'Método de pago'**
  String get metodoDePago;

  /// No description provided for @transferencia.
  ///
  /// In es, this message translates to:
  /// **'Transferencia'**
  String get transferencia;

  /// No description provided for @donacionAnonima.
  ///
  /// In es, this message translates to:
  /// **'Donación anónima'**
  String get donacionAnonima;

  /// No description provided for @donacionAnonimaDesc.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre no será visible en los listados.'**
  String get donacionAnonimaDesc;

  /// No description provided for @continuarDeFormaSegura.
  ///
  /// In es, this message translates to:
  /// **'Continuar de forma segura'**
  String get continuarDeFormaSegura;

  /// No description provided for @cuentaCopiadaPortapapeles.
  ///
  /// In es, this message translates to:
  /// **'¡Cuenta copiada al portapapeles!'**
  String get cuentaCopiadaPortapapeles;

  /// No description provided for @metodosTitulo.
  ///
  /// In es, this message translates to:
  /// **'MÉTODOS'**
  String get metodosTitulo;

  /// No description provided for @dePagoTitulo.
  ///
  /// In es, this message translates to:
  /// **'de pago'**
  String get dePagoTitulo;

  /// No description provided for @viaTransferencia.
  ///
  /// In es, this message translates to:
  /// **'VÍA TRANSFERENCIA'**
  String get viaTransferencia;

  /// No description provided for @aceptamosTransferenciasDesc.
  ///
  /// In es, this message translates to:
  /// **'Aceptamos transferencias bancarias desde\ncualquier banco de la República Dominicana.'**
  String get aceptamosTransferenciasDesc;

  /// No description provided for @tuPagoEstaSeguro.
  ///
  /// In es, this message translates to:
  /// **'TU PAGO ESTÁ SEGURO'**
  String get tuPagoEstaSeguro;

  /// No description provided for @tuPagoSeguroDesc.
  ///
  /// In es, this message translates to:
  /// **'Confianza, rapidez y seguridad en cada transacción.'**
  String get tuPagoSeguroDesc;

  /// No description provided for @revisaTuDonacion.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu donación'**
  String get revisaTuDonacion;

  /// No description provided for @resumenDeTuDonacion.
  ///
  /// In es, this message translates to:
  /// **'Resumen de tu donación'**
  String get resumenDeTuDonacion;

  /// No description provided for @para.
  ///
  /// In es, this message translates to:
  /// **'Para'**
  String get para;

  /// No description provided for @concepto.
  ///
  /// In es, this message translates to:
  /// **'Concepto'**
  String get concepto;

  /// No description provided for @monto.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get monto;

  /// No description provided for @tuDonacionEsSegura.
  ///
  /// In es, this message translates to:
  /// **'Tu donación es segura'**
  String get tuDonacionEsSegura;

  /// No description provided for @conexionCifradaProteccion.
  ///
  /// In es, this message translates to:
  /// **'Usamos conexión cifrada para proteger\ntu información y tu aporte.'**
  String get conexionCifradaProteccion;

  /// No description provided for @confirmarDonacion.
  ///
  /// In es, this message translates to:
  /// **'Confirmar donación'**
  String get confirmarDonacion;

  /// No description provided for @confirmarTransaccion.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Transacción'**
  String get confirmarTransaccion;

  /// No description provided for @transaccionValidaraOdoo.
  ///
  /// In es, this message translates to:
  /// **'La transacción se validará mediante la pasarela segura de Odoo.'**
  String get transaccionValidaraOdoo;

  /// No description provided for @totalAProcesar.
  ///
  /// In es, this message translates to:
  /// **'Total a procesar'**
  String get totalAProcesar;

  /// No description provided for @pagarYValidar.
  ///
  /// In es, this message translates to:
  /// **'Pagar y Validar'**
  String get pagarYValidar;

  /// No description provided for @validandoConOdoo.
  ///
  /// In es, this message translates to:
  /// **'Validando con Odoo...'**
  String get validandoConOdoo;

  /// No description provided for @registrandoOrdenConfirmandoPago.
  ///
  /// In es, this message translates to:
  /// **'Estamos registrando tu orden y confirmando el pago.'**
  String get registrandoOrdenConfirmandoPago;

  /// No description provided for @aporteExitoso.
  ///
  /// In es, this message translates to:
  /// **'¡Aporte Exitoso!'**
  String get aporteExitoso;

  /// Referencia de la orden generada por Odoo
  ///
  /// In es, this message translates to:
  /// **'Referencia Odoo: {orden}'**
  String referenciaOdoo(String orden);

  /// No description provided for @contribucionValidadaRecibo.
  ///
  /// In es, this message translates to:
  /// **'Tu contribución ha sido validada y el recibo digital fue enviado a tu correo.'**
  String get contribucionValidadaRecibo;

  /// No description provided for @finalizar.
  ///
  /// In es, this message translates to:
  /// **'Finalizar'**
  String get finalizar;

  /// No description provided for @realizarUnAporte.
  ///
  /// In es, this message translates to:
  /// **'Realizar un aporte'**
  String get realizarUnAporte;

  /// No description provided for @cuantoDeseasAportar.
  ///
  /// In es, this message translates to:
  /// **'¿Cuánto deseas aportar?'**
  String get cuantoDeseasAportar;

  /// No description provided for @mensajeDeApoyo.
  ///
  /// In es, this message translates to:
  /// **'Mensaje de apoyo'**
  String get mensajeDeApoyo;

  /// No description provided for @escribeMensajeOpcional.
  ///
  /// In es, this message translates to:
  /// **'Escribe un mensaje opcional...'**
  String get escribeMensajeOpcional;

  /// No description provided for @mostrarAporteAnonimo.
  ///
  /// In es, this message translates to:
  /// **'Mostrar mi aporte como anónimo'**
  String get mostrarAporteAnonimo;

  /// No description provided for @continuarConElAporte.
  ///
  /// In es, this message translates to:
  /// **'Continuar con el aporte'**
  String get continuarConElAporte;

  /// No description provided for @proyectoTag.
  ///
  /// In es, this message translates to:
  /// **'PROYECTO'**
  String get proyectoTag;

  /// Concepto del aporte al proyecto
  ///
  /// In es, this message translates to:
  /// **'Proyecto: {titulo}'**
  String conceptoProyecto(String titulo);

  /// No description provided for @estadoProgramada.
  ///
  /// In es, this message translates to:
  /// **'Programada'**
  String get estadoProgramada;

  /// No description provided for @estadoRecibida.
  ///
  /// In es, this message translates to:
  /// **'Recibida'**
  String get estadoRecibida;

  /// No description provided for @estadoEnRevision.
  ///
  /// In es, this message translates to:
  /// **'En revisión'**
  String get estadoEnRevision;

  /// No description provided for @estadoConfirmada.
  ///
  /// In es, this message translates to:
  /// **'Confirmada'**
  String get estadoConfirmada;

  /// No description provided for @estadoEnProceso.
  ///
  /// In es, this message translates to:
  /// **'En proceso'**
  String get estadoEnProceso;

  /// No description provided for @fechaMartesHora.
  ///
  /// In es, this message translates to:
  /// **'Martes · 4:00 p. m.'**
  String get fechaMartesHora;

  /// No description provided for @fechaJuevesHora.
  ///
  /// In es, this message translates to:
  /// **'Jueves · 5:30 p. m.'**
  String get fechaJuevesHora;

  /// No description provided for @fechaViernesHora.
  ///
  /// In es, this message translates to:
  /// **'Viernes · 10:00 a. m.'**
  String get fechaViernesHora;

  /// No description provided for @detalleOrientacionPastoral.
  ///
  /// In es, this message translates to:
  /// **'Cita de acompañamiento espiritual y orientación pastoral presencial con el pastor titular.'**
  String get detalleOrientacionPastoral;

  /// No description provided for @detallePeticionOracion.
  ///
  /// In es, this message translates to:
  /// **'Petición de intercesión por pronta recuperación de salud y bienestar familiar en el culto de oración.'**
  String get detallePeticionOracion;

  /// No description provided for @detalleAyudaComunitaria.
  ///
  /// In es, this message translates to:
  /// **'Solicitud de canasta de alimentos básicos y apoyo solidario para una familia en situación de necesidad.'**
  String get detalleAyudaComunitaria;

  /// No description provided for @detalleConsejeriaFamiliar.
  ///
  /// In es, this message translates to:
  /// **'Sesión de consejería familiar y diálogo guiado por el equipo ministerial de la iglesia.'**
  String get detalleConsejeriaFamiliar;

  /// No description provided for @detalleVisitaEnfermos.
  ///
  /// In es, this message translates to:
  /// **'Visita domiciliaria del equipo de visitación pastoral para ministración y oración por sanidad.'**
  String get detalleVisitaEnfermos;

  /// Identificador Odoo de la solicitud
  ///
  /// In es, this message translates to:
  /// **'ID Odoo: {id}'**
  String idOdoo(String id);

  /// No description provided for @detalleDeLaSolicitud.
  ///
  /// In es, this message translates to:
  /// **'Detalle de la solicitud:'**
  String get detalleDeLaSolicitud;

  /// No description provided for @solicitudRegistradaAsignada.
  ///
  /// In es, this message translates to:
  /// **'Solicitud registrada y asignada al equipo ministerial.'**
  String get solicitudRegistradaAsignada;

  /// No description provided for @estadoCompletada.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get estadoCompletada;

  /// No description provided for @fechaDiezmoMock.
  ///
  /// In es, this message translates to:
  /// **'15 Oct 2026 · 10:30 a. m.'**
  String get fechaDiezmoMock;

  /// No description provided for @metodoTarjetaDebitoVisa.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta de débito (Visa)'**
  String get metodoTarjetaDebitoVisa;

  /// No description provided for @destinoFondoGeneralMinisterial.
  ///
  /// In es, this message translates to:
  /// **'Fondo General Ministerial'**
  String get destinoFondoGeneralMinisterial;

  /// No description provided for @detalleDiezmoMock.
  ///
  /// In es, this message translates to:
  /// **'Aporte de diezmo mensual para el sostenimiento del templo y ministerio pastoral.'**
  String get detalleDiezmoMock;

  /// No description provided for @fechaOfrendaMock.
  ///
  /// In es, this message translates to:
  /// **'08 Oct 2026 · 7:15 p. m.'**
  String get fechaOfrendaMock;

  /// No description provided for @metodoTransferenciaACH.
  ///
  /// In es, this message translates to:
  /// **'Transferencia ACH'**
  String get metodoTransferenciaACH;

  /// No description provided for @destinoCultoAdoracionDominical.
  ///
  /// In es, this message translates to:
  /// **'Culto de Adoración Dominical'**
  String get destinoCultoAdoracionDominical;

  /// No description provided for @detalleOfrendaMock.
  ///
  /// In es, this message translates to:
  /// **'Ofrenda voluntaria de gratitud y adoración durante el servicio de alabanza.'**
  String get detalleOfrendaMock;

  /// No description provided for @fechaCampanaMock.
  ///
  /// In es, this message translates to:
  /// **'28 Sep 2026 · 4:20 p. m.'**
  String get fechaCampanaMock;

  /// No description provided for @metodoTarjetaCreditoMastercard.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta de crédito (Mastercard)'**
  String get metodoTarjetaCreditoMastercard;

  /// No description provided for @destinoCampanaMock.
  ///
  /// In es, this message translates to:
  /// **'Campaña \"Construyendo Esperanza 2026\"'**
  String get destinoCampanaMock;

  /// No description provided for @detalleCampanaMock.
  ///
  /// In es, this message translates to:
  /// **'Aporte especial voluntario destinado a las obras de remodelación y mantenimiento del templo.'**
  String get detalleCampanaMock;

  /// No description provided for @fechaAyudaMock.
  ///
  /// In es, this message translates to:
  /// **'14 Sep 2026 · 11:00 a. m.'**
  String get fechaAyudaMock;

  /// No description provided for @metodoPayPalSaldoDigital.
  ///
  /// In es, this message translates to:
  /// **'PayPal / Saldo digital'**
  String get metodoPayPalSaldoDigital;

  /// No description provided for @destinoProgramaManosQueBendicen.
  ///
  /// In es, this message translates to:
  /// **'Programa \"Manos que Bendicen\"'**
  String get destinoProgramaManosQueBendicen;

  /// No description provided for @detalleAyudaMock.
  ///
  /// In es, this message translates to:
  /// **'Donación benéfica para canastas de alimentos básicos y medicinas para familias vulnerables.'**
  String get detalleAyudaMock;

  /// No description provided for @nuevaDonacion.
  ///
  /// In es, this message translates to:
  /// **'Nueva donación'**
  String get nuevaDonacion;

  /// No description provided for @montoAportado.
  ///
  /// In es, this message translates to:
  /// **'Monto aportado:'**
  String get montoAportado;

  /// No description provided for @fechaYHora.
  ///
  /// In es, this message translates to:
  /// **'Fecha y hora:'**
  String get fechaYHora;

  /// No description provided for @metodo.
  ///
  /// In es, this message translates to:
  /// **'Método:'**
  String get metodo;

  /// No description provided for @destino.
  ///
  /// In es, this message translates to:
  /// **'Destino:'**
  String get destino;

  /// No description provided for @detalleDelAporte.
  ///
  /// In es, this message translates to:
  /// **'Detalle del aporte:'**
  String get detalleDelAporte;

  /// No description provided for @aporteVoluntarioRegistrado.
  ///
  /// In es, this message translates to:
  /// **'Aporte voluntario registrado en ATRIO.'**
  String get aporteVoluntarioRegistrado;

  /// No description provided for @errorGuardarSeleccionLocal.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar la selección localmente.'**
  String get errorGuardarSeleccionLocal;

  /// No description provided for @queremosConocerte.
  ///
  /// In es, this message translates to:
  /// **'Queremos conocerte'**
  String get queremosConocerte;

  /// No description provided for @conCualTradicionTeIdentificas.
  ///
  /// In es, this message translates to:
  /// **'¿Con cuál tradición de fe te identificas?'**
  String get conCualTradicionTeIdentificas;

  /// No description provided for @continuar.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continuar;

  /// No description provided for @noDenominacional.
  ///
  /// In es, this message translates to:
  /// **'No denominacional'**
  String get noDenominacional;

  /// No description provided for @otra.
  ///
  /// In es, this message translates to:
  /// **'Otra'**
  String get otra;

  /// No description provided for @prefieroIndicarloDespues.
  ///
  /// In es, this message translates to:
  /// **'Prefiero indicarlo después'**
  String get prefieroIndicarloDespues;

  /// No description provided for @gpsDesactivadoMensaje.
  ///
  /// In es, this message translates to:
  /// **'El GPS está desactivado. Actívalo para encontrar iglesias cercanas a ti.'**
  String get gpsDesactivadoMensaje;

  /// No description provided for @permisoUbicacionNoConcedido.
  ///
  /// In es, this message translates to:
  /// **'Permiso de ubicación no concedido. Se mostrará ubicación predeterminada.'**
  String get permisoUbicacionNoConcedido;

  /// No description provided for @permisosUbicacionDenegadosPermanentemente.
  ///
  /// In es, this message translates to:
  /// **'Permisos de ubicación denegados permanentemente en los ajustes.'**
  String get permisosUbicacionDenegadosPermanentemente;

  /// Error al consultar servidor con código de estado
  ///
  /// In es, this message translates to:
  /// **'Error del servidor: {codigo}'**
  String errorServidorCodigo(int codigo);

  /// Mensaje cuando no se encuentran iglesias para la búsqueda
  ///
  /// In es, this message translates to:
  /// **'No se encontraron iglesias cercanas para \"{query}\".'**
  String noSeEncontraronIglesiasCercanas(String query);

  /// No description provided for @errorConexionInternet.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión. Verifica tu internet.'**
  String get errorConexionInternet;

  /// No description provided for @ubicacionExacta.
  ///
  /// In es, this message translates to:
  /// **'Ubicación exacta'**
  String get ubicacionExacta;

  /// No description provided for @seleccionaTuIglesia.
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu iglesia'**
  String get seleccionaTuIglesia;

  /// No description provided for @buscarIglesiaPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Buscar iglesia o denominación...'**
  String get buscarIglesiaPlaceholder;

  /// No description provided for @abiertoAhora.
  ///
  /// In es, this message translates to:
  /// **'Abierto ahora'**
  String get abiertoAhora;

  /// No description provided for @cerrado.
  ///
  /// In es, this message translates to:
  /// **'Cerrado'**
  String get cerrado;

  /// No description provided for @seleccionarIglesia.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar iglesia'**
  String get seleccionarIglesia;

  /// No description provided for @codigoPlusNoDisponible.
  ///
  /// In es, this message translates to:
  /// **'Código Plus no disponible'**
  String get codigoPlusNoDisponible;

  /// No description provided for @distanciaAproximadaDefault.
  ///
  /// In es, this message translates to:
  /// **'A 1.8 km'**
  String get distanciaAproximadaDefault;

  /// No description provided for @servicioDeBienvenida.
  ///
  /// In es, this message translates to:
  /// **'Servicio de Bienvenida'**
  String get servicioDeBienvenida;

  /// No description provided for @diaHoraDomingo10am.
  ///
  /// In es, this message translates to:
  /// **'Domingo · 10:00 a. m.'**
  String get diaHoraDomingo10am;

  /// No description provided for @estadoCerradoAbreDomingo.
  ///
  /// In es, this message translates to:
  /// **'Cerrado · Abre a las 10 a.m. del dom'**
  String get estadoCerradoAbreDomingo;

  /// No description provided for @diaDomingo.
  ///
  /// In es, this message translates to:
  /// **'Domingo'**
  String get diaDomingo;

  /// No description provided for @cultoDominical10am.
  ///
  /// In es, this message translates to:
  /// **'10:00 a. m. · Culto Dominical'**
  String get cultoDominical10am;

  /// No description provided for @diaMiercoles.
  ///
  /// In es, this message translates to:
  /// **'Miércoles'**
  String get diaMiercoles;

  /// No description provided for @estudioBiblico730pm.
  ///
  /// In es, this message translates to:
  /// **'7:30 p. m. · Estudio Bíblico'**
  String get estudioBiblico730pm;

  /// No description provided for @bienvenidoNuevaComunidad.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenido a tu nueva comunidad!'**
  String get bienvenidoNuevaComunidad;

  /// No description provided for @descripcionRegistroIglesia.
  ///
  /// In es, this message translates to:
  /// **'Te has registrado correctamente en esta iglesia a través de Atrio.'**
  String get descripcionRegistroIglesia;

  /// No description provided for @filtroTodas.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get filtroTodas;

  /// No description provided for @filtroNoLeidas.
  ///
  /// In es, this message translates to:
  /// **'No leídas'**
  String get filtroNoLeidas;

  /// No description provided for @categoriaEventos.
  ///
  /// In es, this message translates to:
  /// **'Eventos'**
  String get categoriaEventos;

  /// No description provided for @notiHorarioServicioTitulo.
  ///
  /// In es, this message translates to:
  /// **'Cambio de horario de servicio'**
  String get notiHorarioServicioTitulo;

  /// No description provided for @notiHorarioServicioResumen.
  ///
  /// In es, this message translates to:
  /// **'Miércoles de Oración · 7:00 p. m. en el Templo Principal.'**
  String get notiHorarioServicioResumen;

  /// No description provided for @notiHorarioServicioCuerpo.
  ///
  /// In es, this message translates to:
  /// **'Estimada congregación: Por motivos de la jornada pastoral y preparación para las actividades del mes, nuestro servicio de intercesión y estudio bíblico de este miércoles se adelantará 30 minutos, iniciando a las 7:00 p. m. Te invitamos a llegar temprano con tu familia.'**
  String get notiHorarioServicioCuerpo;

  /// No description provided for @notiRetiroTitulo.
  ///
  /// In es, this message translates to:
  /// **'Inscripciones abiertas: Retiro 2026'**
  String get notiRetiroTitulo;

  /// No description provided for @notiRetiroResumen.
  ///
  /// In es, this message translates to:
  /// **'Cupos limitados disponibles para jóvenes y familias.'**
  String get notiRetiroResumen;

  /// No description provided for @notiRetiroCuerpo.
  ///
  /// In es, this message translates to:
  /// **'¡Ya puedes apartar tu lugar! Se han abierto formalmente los registros para el Retiro Anual \"Vida & Fe 2026\" en el Campamento Los Pinos. Puedes realizar tu inscripción directamente desde la sección de Eventos en la app.'**
  String get notiRetiroCuerpo;

  /// No description provided for @notiCampanaTitulo.
  ///
  /// In es, this message translates to:
  /// **'Campaña solidaria \"Manos que Bendicen\"'**
  String get notiCampanaTitulo;

  /// No description provided for @notiCampanaResumen.
  ///
  /// In es, this message translates to:
  /// **'Recepción de víveres y donaciones este fin de semana.'**
  String get notiCampanaResumen;

  /// No description provided for @notiCampanaCuerpo.
  ///
  /// In es, this message translates to:
  /// **'Estaremos recolectando alimentos no perecibles, abrigos y kits de aseo en el vestíbulo principal antes de cada reunión dominical. Tu generosa colaboración bendecirá a más de 50 familias vulnerables en nuestra comunidad.'**
  String get notiCampanaCuerpo;

  /// No description provided for @fechaHoy.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get fechaHoy;

  /// No description provided for @fechaAyer.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get fechaAyer;

  /// No description provided for @fechaHace2Dias.
  ///
  /// In es, this message translates to:
  /// **'Hace 2 días'**
  String get fechaHace2Dias;

  /// No description provided for @hora1030am.
  ///
  /// In es, this message translates to:
  /// **'10:30 a. m.'**
  String get hora1030am;

  /// No description provided for @hora415pm.
  ///
  /// In es, this message translates to:
  /// **'4:15 p. m.'**
  String get hora415pm;

  /// No description provided for @hora900am.
  ///
  /// In es, this message translates to:
  /// **'9:00 a. m.'**
  String get hora900am;

  /// No description provided for @remitenteAdmin.
  ///
  /// In es, this message translates to:
  /// **'Administración ATRIO'**
  String get remitenteAdmin;

  /// No description provided for @remitenteEventos.
  ///
  /// In es, this message translates to:
  /// **'Comité de Eventos'**
  String get remitenteEventos;

  /// No description provided for @remitentePastoralSocial.
  ///
  /// In es, this message translates to:
  /// **'Pastoral Social'**
  String get remitentePastoralSocial;

  /// No description provided for @todasNotificacionesLeidas.
  ///
  /// In es, this message translates to:
  /// **'Todas las notificaciones han sido marcadas como leídas'**
  String get todasNotificacionesLeidas;

  /// Mensaje al eliminar una notificación
  ///
  /// In es, this message translates to:
  /// **'Notificación \"{titulo}\" eliminada'**
  String notificacionEliminada(String titulo);

  /// No description provided for @deshacer.
  ///
  /// In es, this message translates to:
  /// **'Deshacer'**
  String get deshacer;

  /// No description provided for @borrarAvisos.
  ///
  /// In es, this message translates to:
  /// **'Borrar avisos'**
  String get borrarAvisos;

  /// No description provided for @confirmarBorrarTodasMensaje.
  ///
  /// In es, this message translates to:
  /// **'¿Deseas eliminar todas las notificaciones recibidas? Podrás deshacer la acción inmediatamente si lo deseas.'**
  String get confirmarBorrarTodasMensaje;

  /// No description provided for @borrarTodas.
  ///
  /// In es, this message translates to:
  /// **'Borrar todas'**
  String get borrarTodas;

  /// No description provided for @todasNotificacionesEliminadas.
  ///
  /// In es, this message translates to:
  /// **'Todas las notificaciones han sido eliminadas'**
  String get todasNotificacionesEliminadas;

  /// No description provided for @avisosEjemploRestaurados.
  ///
  /// In es, this message translates to:
  /// **'Avisos de ejemplo restaurados'**
  String get avisosEjemploRestaurados;

  /// No description provided for @marcarTodasComoLeidas.
  ///
  /// In es, this message translates to:
  /// **'Marcar todas como leídas'**
  String get marcarTodasComoLeidas;

  /// No description provided for @buscarEnAvisosPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Buscar en avisos...'**
  String get buscarEnAvisosPlaceholder;

  /// No description provided for @avisosDeLaComunidad.
  ///
  /// In es, this message translates to:
  /// **'Avisos de la comunidad'**
  String get avisosDeLaComunidad;

  /// Conteo de notificaciones no leídas
  ///
  /// In es, this message translates to:
  /// **'{conteo} no leídas'**
  String conteoNoLeidas(int conteo);

  /// No description provided for @deslizaAvisoParaEliminar.
  ///
  /// In es, this message translates to:
  /// **'Desliza un aviso hacia la izquierda para eliminarlo'**
  String get deslizaAvisoParaEliminar;

  /// No description provided for @noHayAvisosMomento.
  ///
  /// In es, this message translates to:
  /// **'No hay avisos en este momento'**
  String get noHayAvisosMomento;

  /// No description provided for @avisosOdooApareceranAqui.
  ///
  /// In es, this message translates to:
  /// **'Los avisos publicados en Odoo aparecerán aquí.'**
  String get avisosOdooApareceranAqui;

  /// No description provided for @restaurarAvisosEjemplo.
  ///
  /// In es, this message translates to:
  /// **'Restaurar avisos de ejemplo'**
  String get restaurarAvisosEjemplo;

  /// No description provided for @eliminarAviso.
  ///
  /// In es, this message translates to:
  /// **'Eliminar aviso'**
  String get eliminarAviso;

  /// No description provided for @eliminarEsteAviso.
  ///
  /// In es, this message translates to:
  /// **'Eliminar este aviso'**
  String get eliminarEsteAviso;

  /// No description provided for @personalizaTuExperienciaAtrio.
  ///
  /// In es, this message translates to:
  /// **'Personaliza tu experiencia en ATRIO'**
  String get personalizaTuExperienciaAtrio;

  /// No description provided for @idiomaYRegion.
  ///
  /// In es, this message translates to:
  /// **'Idioma y Región'**
  String get idiomaYRegion;

  /// No description provided for @aparienciaYTema.
  ///
  /// In es, this message translates to:
  /// **'Apariencia y Tema'**
  String get aparienciaYTema;

  /// No description provided for @modoDeVisualizacion.
  ///
  /// In es, this message translates to:
  /// **'Modo de visualización'**
  String get modoDeVisualizacion;

  /// No description provided for @temaClaro.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get temaClaro;

  /// No description provided for @temaOscuro.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get temaOscuro;

  /// No description provided for @temaSistema.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get temaSistema;

  /// No description provided for @transicionDeNovedades.
  ///
  /// In es, this message translates to:
  /// **'Transición de Novedades'**
  String get transicionDeNovedades;

  /// No description provided for @bannerPrincipalHero.
  ///
  /// In es, this message translates to:
  /// **'Banner principal (HeroBannerCard)'**
  String get bannerPrincipalHero;

  /// Tiempo en segundos abreviado
  ///
  /// In es, this message translates to:
  /// **'{segundos} seg'**
  String segundosAbrev(int segundos);

  /// No description provided for @efectoDesvanecimientoBanner.
  ///
  /// In es, this message translates to:
  /// **'Efecto de desvanecimiento suave entre versículo, palabra y cultos.'**
  String get efectoDesvanecimientoBanner;

  /// No description provided for @segundosMinimo.
  ///
  /// In es, this message translates to:
  /// **'3 seg'**
  String get segundosMinimo;

  /// No description provided for @segundosPredeterminado.
  ///
  /// In es, this message translates to:
  /// **'5 seg (Predeterminado)'**
  String get segundosPredeterminado;

  /// No description provided for @segundosMaximo.
  ///
  /// In es, this message translates to:
  /// **'10 seg'**
  String get segundosMaximo;

  /// No description provided for @notificacionesYRecordatorios.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones y Recordatorios'**
  String get notificacionesYRecordatorios;

  /// No description provided for @recibePorcionBiblica.
  ///
  /// In es, this message translates to:
  /// **'Recibe una porción bíblica cada mañana'**
  String get recibePorcionBiblica;

  /// No description provided for @horaDelRecordatorio.
  ///
  /// In es, this message translates to:
  /// **'Hora del recordatorio'**
  String get horaDelRecordatorio;

  /// No description provided for @palabraDelDia.
  ///
  /// In es, this message translates to:
  /// **'Palabra del día'**
  String get palabraDelDia;

  /// No description provided for @reflexionDevocionalDiario.
  ///
  /// In es, this message translates to:
  /// **'Reflexión y devocional diario para tu fe'**
  String get reflexionDevocionalDiario;

  /// No description provided for @cultosEnVivo.
  ///
  /// In es, this message translates to:
  /// **'Cultos en vivo'**
  String get cultosEnVivo;

  /// No description provided for @alertaTransmisionDirecto.
  ///
  /// In es, this message translates to:
  /// **'Alerta cuando comience una transmisión en directo'**
  String get alertaTransmisionDirecto;

  /// No description provided for @anunciosEventosGlobales.
  ///
  /// In es, this message translates to:
  /// **'Anuncios y eventos globales'**
  String get anunciosEventosGlobales;

  /// No description provided for @conferenciasConciertosAvisos.
  ///
  /// In es, this message translates to:
  /// **'Conferencias, conciertos y avisos de iglesias'**
  String get conferenciasConciertosAvisos;

  /// No description provided for @lecturaDeLaBiblia.
  ///
  /// In es, this message translates to:
  /// **'Lectura de la Biblia'**
  String get lecturaDeLaBiblia;

  /// No description provided for @versionPredeterminada.
  ///
  /// In es, this message translates to:
  /// **'Versión predeterminada'**
  String get versionPredeterminada;

  /// No description provided for @tamanoTextoLectura.
  ///
  /// In es, this message translates to:
  /// **'Tamaño de texto en lectura'**
  String get tamanoTextoLectura;

  /// No description provided for @ejemploTextoBiblia.
  ///
  /// In es, this message translates to:
  /// **'«Lámpara es a mis pies tu palabra, y lumbrera a mi camino.» — Salmos 119:105'**
  String get ejemploTextoBiblia;

  /// No description provided for @mantenerPantallaEncendida.
  ///
  /// In es, this message translates to:
  /// **'Mantener pantalla encendida'**
  String get mantenerPantallaEncendida;

  /// No description provided for @evitaBloqueoTelefonoBiblia.
  ///
  /// In es, this message translates to:
  /// **'Evita que el teléfono se bloquee mientras lees la Biblia'**
  String get evitaBloqueoTelefonoBiblia;

  /// No description provided for @emisorasYTransmisiones.
  ///
  /// In es, this message translates to:
  /// **'Emisoras y Transmisiones'**
  String get emisorasYTransmisiones;

  /// No description provided for @reproduccionAutomatica.
  ///
  /// In es, this message translates to:
  /// **'Reproducción automática'**
  String get reproduccionAutomatica;

  /// No description provided for @iniciarRadioAlSintonizar.
  ///
  /// In es, this message translates to:
  /// **'Iniciar la radio al sintonizar la emisora'**
  String get iniciarRadioAlSintonizar;

  /// No description provided for @calidadAudioStreaming.
  ///
  /// In es, this message translates to:
  /// **'Calidad de audio streaming'**
  String get calidadAudioStreaming;

  /// No description provided for @calidadAudioBaja.
  ///
  /// In es, this message translates to:
  /// **'Baja (64 kbps)'**
  String get calidadAudioBaja;

  /// No description provided for @calidadAudioMedia.
  ///
  /// In es, this message translates to:
  /// **'Media (128 kbps)'**
  String get calidadAudioMedia;

  /// No description provided for @calidadAudioAlta.
  ///
  /// In es, this message translates to:
  /// **'Alta (256 kbps)'**
  String get calidadAudioAlta;

  /// No description provided for @ahorroDeDatosSoloWifi.
  ///
  /// In es, this message translates to:
  /// **'Ahorro de datos (Solo Wi-Fi)'**
  String get ahorroDeDatosSoloWifi;

  /// No description provided for @reproducirDescargarSoloWifi.
  ///
  /// In es, this message translates to:
  /// **'Reproducir y descargar en alta calidad solo con Wi-Fi'**
  String get reproducirDescargarSoloWifi;

  /// No description provided for @almacenamientoYMemoria.
  ///
  /// In es, this message translates to:
  /// **'Almacenamiento y Memoria'**
  String get almacenamientoYMemoria;

  /// No description provided for @limpiarMemoriaCache.
  ///
  /// In es, this message translates to:
  /// **'Limpiar memoria caché'**
  String get limpiarMemoriaCache;

  /// No description provided for @imagenesAudiosTemporales.
  ///
  /// In es, this message translates to:
  /// **'Imágenes y audios temporales (~18.4 MB)'**
  String get imagenesAudiosTemporales;

  /// No description provided for @limpiar.
  ///
  /// In es, this message translates to:
  /// **'Limpiar'**
  String get limpiar;

  /// No description provided for @limpiarCacheTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Limpiar memoria caché?'**
  String get limpiarCacheTitulo;

  /// No description provided for @limpiarCacheMensaje.
  ///
  /// In es, this message translates to:
  /// **'Se eliminarán imágenes y archivos temporales para liberar almacenamiento. No se borrarán tus notas ni favoritos bíblicos.'**
  String get limpiarCacheMensaje;

  /// No description provided for @memoriaCacheLiberadaExito.
  ///
  /// In es, this message translates to:
  /// **'Memoria caché liberada con éxito'**
  String get memoriaCacheLiberadaExito;

  /// No description provided for @limpiarAhora.
  ///
  /// In es, this message translates to:
  /// **'Limpiar ahora'**
  String get limpiarAhora;

  /// No description provided for @restablecerAjustesPredeterminados.
  ///
  /// In es, this message translates to:
  /// **'Restablecer ajustes predeterminados'**
  String get restablecerAjustesPredeterminados;

  /// No description provided for @restablecerConfiguracionTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Restablecer configuración?'**
  String get restablecerConfiguracionTitulo;

  /// No description provided for @restablecerConfiguracionMensaje.
  ///
  /// In es, this message translates to:
  /// **'Todos los ajustes de la app volverán a sus valores iniciales recomendados.'**
  String get restablecerConfiguracionMensaje;

  /// No description provided for @ajustesRestablecidosFabrica.
  ///
  /// In es, this message translates to:
  /// **'Ajustes restablecidos a valores de fábrica'**
  String get ajustesRestablecidosFabrica;

  /// No description provided for @restablecer.
  ///
  /// In es, this message translates to:
  /// **'Restablecer'**
  String get restablecer;

  /// No description provided for @idiomaEspanolLatino.
  ///
  /// In es, this message translates to:
  /// **'Español (Latinoamérica)'**
  String get idiomaEspanolLatino;

  /// No description provided for @idiomaInglesUSA.
  ///
  /// In es, this message translates to:
  /// **'English (United States)'**
  String get idiomaInglesUSA;

  /// No description provided for @politicaDePrivacidad.
  ///
  /// In es, this message translates to:
  /// **'Política de Privacidad'**
  String get politicaDePrivacidad;

  /// Introducción de la política de privacidad
  ///
  /// In es, this message translates to:
  /// **'Última actualización: {fecha}\n\nBienvenido a ATRIO (\"Vive tu Fe en comunidad\"). Respetamos tu privacidad y estamos profundamente comprometidos a proteger tus datos personales y tu experiencia espiritual.\n\nEsta política detalla cómo recopilamos, administramos, protegemos y salvaguardamos tu información.'**
  String politicaPrivacidadIntro(String fecha);

  /// No description provided for @seccionInfoQueRecopilamos.
  ///
  /// In es, this message translates to:
  /// **'1. Información que recopilamos'**
  String get seccionInfoQueRecopilamos;

  /// No description provided for @parrafoInfoQueRecopilamos.
  ///
  /// In es, this message translates to:
  /// **'• Datos de la cuenta: Al iniciar sesión o registrarte (correo electrónico, Google Sign-In o Apple ID), almacenamos de manera segura tu nombre y dirección de correo electrónico.\n\n• Datos comunitarios y de perfil: Número telefónico, tradición cristiana e iglesia o comunidad a la que estás vinculado voluntariamente para adaptar tu experiencia eclesiástica.\n\n• Almacenamiento Local en el Dispositivo: Tus notas de la Biblia, pasajes favoritos, configuraciones personales e historial de navegación se guardan localmente en SQLite. No compartimos tus reflexiones privadas con terceros.\n\n• Solicitudes y Donaciones: Registramos el estado de tus peticiones de oración, solicitudes pastorales y constancias de donaciones o aportes a proyectos solidarios para darte visibilidad y trazabilidad directa.'**
  String get parrafoInfoQueRecopilamos;

  /// No description provided for @seccionUsoServiciosTerceros.
  ///
  /// In es, this message translates to:
  /// **'2. Uso de servicios de terceros'**
  String get seccionUsoServiciosTerceros;

  /// No description provided for @parrafoUsoServiciosTerceros.
  ///
  /// In es, this message translates to:
  /// **'Nuestra plataforma se integra con tecnologías de confianza para ofrecer una funcionalidad completa:\n\n• Google Play Services, Google Sign-In y Sign in with Apple (Autenticación y seguridad).\n\n• Google Maps Platform (Para la localización geográfica precisa de templos, parroquias y eventos comunitarios en el mapa interactivo).\n\n• Pasarelas de Pago Seguras (Para la recepción confiable y encriptada de ofrendas, diezmos y aportes a causas solidarias).\n\n• YouTube y Reproductores de Transmisiones (Para servicios religiosos, eventos en vivo y programas radiales).'**
  String get parrafoUsoServiciosTerceros;

  /// No description provided for @seccionRetencionYEliminacion.
  ///
  /// In es, this message translates to:
  /// **'3. Retención y eliminación de datos'**
  String get seccionRetencionYEliminacion;

  /// No description provided for @parrafoRetencionYEliminacion.
  ///
  /// In es, this message translates to:
  /// **'Conservamos los datos de tu cuenta mientras esté activa. De acuerdo con las directrices de Apple App Store (5.1.1 v) y Google Play Console, tienes el derecho incondicional de solicitar la eliminación total y definitiva de tu cuenta y datos personales.\n\nPuedes realizar esta acción en cualquier momento desde la opción \"Eliminar cuenta y datos\" en la pantalla de Perfil, o enviando un correo a soporte@atrioapp.com con el asunto \"Eliminación de Cuenta\".\n\nTodos los registros locales en SQLite y vinculaciones en el backend serán purgados.'**
  String get parrafoRetencionYEliminacion;

  /// No description provided for @seccionPermisosDelDispositivo.
  ///
  /// In es, this message translates to:
  /// **'4. Permisos del dispositivo'**
  String get seccionPermisosDelDispositivo;

  /// No description provided for @parrafoPermisosDelDispositivo.
  ///
  /// In es, this message translates to:
  /// **'ATRIO solo solicita permisos estrictamente requeridos para su funcionamiento:\n\n• Ubicación (GPS): Únicamente utilizada cuando accedes al mapa para mostrarte iglesias y eventos en tu cercanía inmediata.\n\n• Acceso a Internet y Red: Para sincronizar solicitudes, consultar transmisiones en directo y validar aportes.\n\n• Notificaciones: Para recordatorios de servicios litúrgicos, eventos comunitarios y respuestas a solicitudes.'**
  String get parrafoPermisosDelDispositivo;

  /// No description provided for @terminosDeUsoTitulo.
  ///
  /// In es, this message translates to:
  /// **'Términos de Uso'**
  String get terminosDeUsoTitulo;

  /// No description provided for @parrafoTerminosDeUso.
  ///
  /// In es, this message translates to:
  /// **'1. Conducta y respeto comunitario: ATRIO es un espacio digital de comunión, edificación mutua y apoyo a las obras de la iglesia. Queda terminantemente prohibido el uso de lenguaje difamatorio, fraudulento o que atente contra la dignidad de la comunidad.\n\n2. Contenidos bíblicos y multimedia: Los textos bíblicos, transmisiones de emisoras y videos compartidos respetan los derechos de autor de sus respectivas entidades y ministerios emisores. Se prohíbe su explotación comercial indebida fuera de la plataforma.\n\n3. Donaciones y aportes: Los aportes realizados a través de ATRIO van dirigidos directamente a las comunidades religiosas y proyectos solidarios seleccionados. La app actúa como puente facilitador transparente y seguro.'**
  String get parrafoTerminosDeUso;

  /// No description provided for @aceptacionTerminosPoliticas.
  ///
  /// In es, this message translates to:
  /// **'Al usar ATRIO, aceptas estos términos y políticas de convivencia.'**
  String get aceptacionTerminosPoliticas;

  /// No description provided for @noSePudoCargarVersiculo.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el versículo.'**
  String get noSePudoCargarVersiculo;

  /// No description provided for @montoPersonalizado.
  ///
  /// In es, this message translates to:
  /// **'Monto personalizado'**
  String get montoPersonalizado;

  /// No description provided for @montoADonarMoneda.
  ///
  /// In es, this message translates to:
  /// **'Monto a donar (RD\$)'**
  String get montoADonarMoneda;

  /// No description provided for @ingresaUnMonto.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un monto'**
  String get ingresaUnMonto;

  /// No description provided for @montoInvalido.
  ///
  /// In es, this message translates to:
  /// **'Monto inválido'**
  String get montoInvalido;

  /// No description provided for @elMinimoEs500.
  ///
  /// In es, this message translates to:
  /// **'El mínimo es RD\$500'**
  String get elMinimoEs500;

  /// No description provided for @elMaximoEs1000000.
  ///
  /// In es, this message translates to:
  /// **'El máximo es RD\$1,000,000'**
  String get elMaximoEs1000000;

  /// No description provided for @confirmar.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirmar;

  /// No description provided for @confirmarSolicitudTitulo.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Solicitud'**
  String get confirmarSolicitudTitulo;

  /// No description provided for @solicitudEnviadaEquipoPastoral.
  ///
  /// In es, this message translates to:
  /// **'Tu solicitud será enviada al equipo pastoral de la iglesia.'**
  String get solicitudEnviadaEquipoPastoral;

  /// No description provided for @tipo.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get tipo;

  /// No description provided for @privada.
  ///
  /// In es, this message translates to:
  /// **'Privada'**
  String get privada;

  /// No description provided for @publica.
  ///
  /// In es, this message translates to:
  /// **'Pública'**
  String get publica;

  /// No description provided for @enviandoAOdoo.
  ///
  /// In es, this message translates to:
  /// **'Enviando a Odoo...'**
  String get enviandoAOdoo;

  /// No description provided for @registrandoSolicitudSistema.
  ///
  /// In es, this message translates to:
  /// **'Estamos registrando tu solicitud en el sistema.'**
  String get registrandoSolicitudSistema;

  /// No description provided for @solicitudEnviadaExito.
  ///
  /// In es, this message translates to:
  /// **'¡Solicitud Enviada!'**
  String get solicitudEnviadaExito;

  /// No description provided for @solicitudRegistradaCorrectamente.
  ///
  /// In es, this message translates to:
  /// **'Tu solicitud ha sido registrada correctamente. El equipo se pondrá en contacto contigo pronto.'**
  String get solicitudRegistradaCorrectamente;

  /// No description provided for @leerReflexion.
  ///
  /// In es, this message translates to:
  /// **'Leer reflexión'**
  String get leerReflexion;

  /// No description provided for @verVersiculo.
  ///
  /// In es, this message translates to:
  /// **'Ver versículo'**
  String get verVersiculo;

  /// No description provided for @enVivoAhora.
  ///
  /// In es, this message translates to:
  /// **'En vivo ahora'**
  String get enVivoAhora;

  /// No description provided for @enVivo.
  ///
  /// In es, this message translates to:
  /// **'EN VIVO'**
  String get enVivo;

  /// Cita bíblica base para la palabra del día
  ///
  /// In es, this message translates to:
  /// **'Cita base: {cita}'**
  String citaBase(String cita);

  /// No description provided for @entendidoAmen.
  ///
  /// In es, this message translates to:
  /// **'Entendido · Amén'**
  String get entendidoAmen;

  /// No description provided for @upgraderTitulo.
  ///
  /// In es, this message translates to:
  /// **'¿Actualizar la aplicación?'**
  String get upgraderTitulo;

  /// Cuerpo del mensaje de actualización para Upgrader
  ///
  /// In es, this message translates to:
  /// **'¡Una nueva versión de {appName} está disponible! La versión {currentAppStoreVersion} ya está disponible, tienes la versión {currentInstalledVersion}.'**
  String upgraderMensaje(
    String appName,
    String currentAppStoreVersion,
    String currentInstalledVersion,
  );

  /// No description provided for @upgraderPregunta.
  ///
  /// In es, this message translates to:
  /// **'¿Deseas actualizar ahora?'**
  String get upgraderPregunta;

  /// No description provided for @upgraderNotasVersion.
  ///
  /// In es, this message translates to:
  /// **'Novedades de la versión'**
  String get upgraderNotasVersion;

  /// No description provided for @upgraderBotonActualizar.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get upgraderBotonActualizar;

  /// No description provided for @upgraderBotonMasTarde.
  ///
  /// In es, this message translates to:
  /// **'Más tarde'**
  String get upgraderBotonMasTarde;

  /// No description provided for @upgraderBotonIgnorar.
  ///
  /// In es, this message translates to:
  /// **'Ignorar'**
  String get upgraderBotonIgnorar;

  /// No description provided for @busquedaPorRadio.
  ///
  /// In es, this message translates to:
  /// **'Por radio'**
  String get busquedaPorRadio;

  /// No description provided for @busquedaNacional.
  ///
  /// In es, this message translates to:
  /// **'Nacional'**
  String get busquedaNacional;

  /// No description provided for @cargandoMasIglesias.
  ///
  /// In es, this message translates to:
  /// **'Cargando más comunidades...'**
  String get cargandoMasIglesias;

  /// No description provided for @finDeResultados.
  ///
  /// In es, this message translates to:
  /// **'Has llegado al final de los resultados'**
  String get finDeResultados;

  /// No description provided for @escribeAlMenos3Caracteres.
  ///
  /// In es, this message translates to:
  /// **'Escribe al menos 3 caracteres'**
  String get escribeAlMenos3Caracteres;

  /// No description provided for @cambiarPais.
  ///
  /// In es, this message translates to:
  /// **'Cambiar país'**
  String get cambiarPais;

  /// No description provided for @todoElPais.
  ///
  /// In es, this message translates to:
  /// **'En todo el país'**
  String get todoElPais;

  /// No description provided for @iglesiasEnMapa.
  ///
  /// In es, this message translates to:
  /// **'Iglesias en mapa'**
  String get iglesiasEnMapa;

  /// Subtítulo de búsqueda por radio con país
  ///
  /// In es, this message translates to:
  /// **'Radio < {km} km en {pais}'**
  String radioKmEnPais(String km, String pais);

  /// Subtítulo de búsqueda nacional con bandera
  ///
  /// In es, this message translates to:
  /// **'Todo {pais} {bandera}'**
  String todoElPaisConBandera(String pais, String bandera);

  /// Texto descriptivo de búsqueda nacional
  ///
  /// In es, this message translates to:
  /// **'En todo {pais}'**
  String enTodoPais(String pais);

  /// Placeholder de búsqueda nacional por país
  ///
  /// In es, this message translates to:
  /// **'Buscar en {pais} (ej. Altagracia...)'**
  String buscarEnPaisPlaceholder(String pais);

  /// No description provided for @buscarEnRadioPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Buscar templo o denominación en radio...'**
  String get buscarEnRadioPlaceholder;

  /// Botón de paginación de 15 en 15 en el mapa
  ///
  /// In es, this message translates to:
  /// **'Ver 15 más ({mostradas} de {total})'**
  String verMasPaginacion(String mostradas, String total);

  /// Contador de iglesias renderizadas en el mapa
  ///
  /// In es, this message translates to:
  /// **'{total} iglesias en mapa'**
  String totalIglesiasEnMapa(String total);

  /// No description provided for @tuPais.
  ///
  /// In es, this message translates to:
  /// **'Tu país'**
  String get tuPais;

  /// Etiqueta que indica que la búsqueda está bloqueada al país actual
  ///
  /// In es, this message translates to:
  /// **'Búsqueda exclusiva en: {pais}'**
  String busquedaExclusivaEn(String pais);

  /// No description provided for @misPedidos.
  ///
  /// In es, this message translates to:
  /// **'Mis pedidos'**
  String get misPedidos;

  /// No description provided for @historialComprasTienda.
  ///
  /// In es, this message translates to:
  /// **'Historial de compras en la Tienda Atrio'**
  String get historialComprasTienda;

  /// No description provided for @pedidosActivos.
  ///
  /// In es, this message translates to:
  /// **'Activos'**
  String get pedidosActivos;

  /// Pestaña de pedidos activos con conteo
  ///
  /// In es, this message translates to:
  /// **'Activos ({count})'**
  String pedidosActivosConConteo(int count);

  /// No description provided for @pedidosHistorial.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get pedidosHistorial;

  /// Pestaña de historial de pedidos con conteo
  ///
  /// In es, this message translates to:
  /// **'Historial ({count})'**
  String pedidosHistorialConConteo(int count);

  /// No description provided for @explorarTienda.
  ///
  /// In es, this message translates to:
  /// **'Explorar Tienda'**
  String get explorarTienda;

  /// No description provided for @noTienesPedidosActivos.
  ///
  /// In es, this message translates to:
  /// **'No tienes pedidos activos'**
  String get noTienesPedidosActivos;

  /// No description provided for @noTienesPedidosAnteriores.
  ///
  /// In es, this message translates to:
  /// **'No tienes pedidos anteriores'**
  String get noTienesPedidosAnteriores;

  /// No description provided for @pedidosActivosDesc.
  ///
  /// In es, this message translates to:
  /// **'Tus compras recientes de la tienda ATRIO aparecerán aquí para que hagas seguimiento a su entrega.'**
  String get pedidosActivosDesc;

  /// No description provided for @pedidosAnterioresDesc.
  ///
  /// In es, this message translates to:
  /// **'Cuando tus pedidos sean completados o entregados, podrás consultarlos en este historial.'**
  String get pedidosAnterioresDesc;

  /// Título de tarjeta de pedido con su número
  ///
  /// In es, this message translates to:
  /// **'Pedido {nombre}'**
  String pedidoItemTitulo(String nombre);

  /// No description provided for @detalleDeOrden.
  ///
  /// In es, this message translates to:
  /// **'Detalle de Orden'**
  String get detalleDeOrden;

  /// No description provided for @referenciaOdooColon.
  ///
  /// In es, this message translates to:
  /// **'Referencia Odoo:'**
  String get referenciaOdooColon;

  /// No description provided for @fechaDelPedido.
  ///
  /// In es, this message translates to:
  /// **'Fecha del pedido:'**
  String get fechaDelPedido;

  /// No description provided for @totalAPagar.
  ///
  /// In es, this message translates to:
  /// **'Total a pagar:'**
  String get totalAPagar;

  /// No description provided for @articulosIncluidos.
  ///
  /// In es, this message translates to:
  /// **'Artículos incluidos:'**
  String get articulosIncluidos;

  /// Cantidad de unidades de un producto
  ///
  /// In es, this message translates to:
  /// **'{cantidad} ud(s).'**
  String unidadesProducto(int cantidad);

  /// No description provided for @verMisPedidos.
  ///
  /// In es, this message translates to:
  /// **'Ver Mis Pedidos'**
  String get verMisPedidos;

  /// No description provided for @estadoPagoEnVerificacion.
  ///
  /// In es, this message translates to:
  /// **'Pago en verificación'**
  String get estadoPagoEnVerificacion;

  /// No description provided for @estadoPedidoConfirmado.
  ///
  /// In es, this message translates to:
  /// **'Confirmado'**
  String get estadoPedidoConfirmado;

  /// No description provided for @estadoPedidoCompletado.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get estadoPedidoCompletado;

  /// No description provided for @estadoPedidoCancelado.
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get estadoPedidoCancelado;

  /// No description provided for @estadoPedidoBorrador.
  ///
  /// In es, this message translates to:
  /// **'Borrador'**
  String get estadoPedidoBorrador;

  /// No description provided for @estadoPedidoEnviado.
  ///
  /// In es, this message translates to:
  /// **'Enviado'**
  String get estadoPedidoEnviado;

  /// No description provided for @registroTitulo.
  ///
  /// In es, this message translates to:
  /// **'Registro'**
  String get registroTitulo;

  /// No description provided for @creaTuCuenta.
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta'**
  String get creaTuCuenta;

  /// No description provided for @creaTuCuentaSubtitulo.
  ///
  /// In es, this message translates to:
  /// **'Únete a una comunidad para vivir y compartir tu fe.'**
  String get creaTuCuentaSubtitulo;

  /// No description provided for @escribeTuNombre.
  ///
  /// In es, this message translates to:
  /// **'Escribe tu nombre'**
  String get escribeTuNombre;

  /// No description provided for @numeroTelefonoLabel.
  ///
  /// In es, this message translates to:
  /// **'Número de teléfono'**
  String get numeroTelefonoLabel;

  /// No description provided for @contrasenaLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get contrasenaLabel;

  /// No description provided for @confirmarContrasenaLabel.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get confirmarContrasenaLabel;

  /// No description provided for @aceptoLos.
  ///
  /// In es, this message translates to:
  /// **'Acepto los '**
  String get aceptoLos;

  /// No description provided for @yLa.
  ///
  /// In es, this message translates to:
  /// **' y la '**
  String get yLa;

  /// No description provided for @crearCuentaBoton.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get crearCuentaBoton;

  /// No description provided for @yaTienesCuenta.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes una cuenta? '**
  String get yaTienesCuenta;

  /// No description provided for @iniciarSesionEnlace.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get iniciarSesionEnlace;

  /// No description provided for @errorNombreRequerido.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa tu nombre completo.'**
  String get errorNombreRequerido;

  /// No description provided for @errorCorreoValido.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo electrónico válido.'**
  String get errorCorreoValido;

  /// No description provided for @errorTelefonoRequerido.
  ///
  /// In es, this message translates to:
  /// **'Por favor ingresa tu número de teléfono.'**
  String get errorTelefonoRequerido;

  /// No description provided for @errorContrasenaMinima.
  ///
  /// In es, this message translates to:
  /// **'La contraseña debe tener al menos 6 caracteres.'**
  String get errorContrasenaMinima;

  /// No description provided for @errorContrasenasNoCoinciden.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden.'**
  String get errorContrasenasNoCoinciden;

  /// No description provided for @errorAceptarTerminos.
  ///
  /// In es, this message translates to:
  /// **'Debes aceptar los Términos de uso y la Política de privacidad.'**
  String get errorAceptarTerminos;

  /// No description provided for @registroExitosoTitulo.
  ///
  /// In es, this message translates to:
  /// **'¡Cuenta Registrada!'**
  String get registroExitosoTitulo;

  /// No description provided for @registroExitosoMensaje.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta ha sido creada exitosamente en Odoo. El administrador de la iglesia validará tu membresía.'**
  String get registroExitosoMensaje;

  /// No description provided for @registroExitosoMensajeSinIglesia.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta ha sido creada exitosamente. Elige tu iglesia para comenzar.'**
  String get registroExitosoMensajeSinIglesia;

  /// No description provided for @iniciarSesionAhora.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión ahora'**
  String get iniciarSesionAhora;

  /// No description provided for @comprobanteTransferencia.
  ///
  /// In es, this message translates to:
  /// **'Comprobante de Transferencia'**
  String get comprobanteTransferencia;

  /// No description provided for @adjuntarComprobante.
  ///
  /// In es, this message translates to:
  /// **'Adjuntar Comprobante'**
  String get adjuntarComprobante;

  /// No description provided for @cambiarComprobante.
  ///
  /// In es, this message translates to:
  /// **'Cambiar comprobante'**
  String get cambiarComprobante;

  /// No description provided for @comprobanteAdjuntado.
  ///
  /// In es, this message translates to:
  /// **'Comprobante adjuntado con éxito'**
  String get comprobanteAdjuntado;

  /// No description provided for @subirComprobanteDesc.
  ///
  /// In es, this message translates to:
  /// **'Adjunta una foto o captura del comprobante bancario para validar tu aporte rápidamente.'**
  String get subirComprobanteDesc;

  /// No description provided for @tomarFoto.
  ///
  /// In es, this message translates to:
  /// **'Tomar foto'**
  String get tomarFoto;

  /// No description provided for @galeria.
  ///
  /// In es, this message translates to:
  /// **'Galería de fotos'**
  String get galeria;

  /// No description provided for @eliminarComprobante.
  ///
  /// In es, this message translates to:
  /// **'Quitar comprobante'**
  String get eliminarComprobante;

  /// No description provided for @redirigiendoPaypal.
  ///
  /// In es, this message translates to:
  /// **'Redirigiendo a la pasarela segura de PayPal...'**
  String get redirigiendoPaypal;

  /// No description provided for @donacionPendienteVerificacion.
  ///
  /// In es, this message translates to:
  /// **'Tu donación ha sido registrada en Odoo y está pendiente de verificación contable.'**
  String get donacionPendienteVerificacion;

  /// Mensaje de error al procesar la donación
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error al procesar la donación: {error}'**
  String errorProcesarDonacion(String error);

  /// No description provided for @publicacionesIglesia.
  ///
  /// In es, this message translates to:
  /// **'Publicaciones de la iglesia'**
  String get publicacionesIglesia;

  /// No description provided for @sinPublicacionesRecientes.
  ///
  /// In es, this message translates to:
  /// **'No hay publicaciones recientes de tu comunidad.'**
  String get sinPublicacionesRecientes;

  /// No description provided for @verPublicacion.
  ///
  /// In es, this message translates to:
  /// **'Ver publicación'**
  String get verPublicacion;

  /// No description provided for @cerrarPublicacion.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get cerrarPublicacion;

  /// No description provided for @novedadesComunidad.
  ///
  /// In es, this message translates to:
  /// **'Novedades y noticias de tu comunidad eclesial'**
  String get novedadesComunidad;

  /// No description provided for @sinNotificaciones.
  ///
  /// In es, this message translates to:
  /// **'No tienes notificaciones en este momento'**
  String get sinNotificaciones;

  /// No description provided for @sinNotificacionesDesc.
  ///
  /// In es, this message translates to:
  /// **'Aquí verás los avisos y comunicados que tu iglesia envíe a la congregación.'**
  String get sinNotificacionesDesc;

  /// No description provided for @cargandoPublicaciones.
  ///
  /// In es, this message translates to:
  /// **'Cargando publicaciones...'**
  String get cargandoPublicaciones;

  /// No description provided for @cargandoNotificaciones.
  ///
  /// In es, this message translates to:
  /// **'Cargando notificaciones...'**
  String get cargandoNotificaciones;

  /// No description provided for @publicidad.
  ///
  /// In es, this message translates to:
  /// **'Publicidad'**
  String get publicidad;

  /// No description provided for @verMas.
  ///
  /// In es, this message translates to:
  /// **'Ver más'**
  String get verMas;

  /// Subtítulo del encabezado para búsqueda nacional
  ///
  /// In es, this message translates to:
  /// **'Búsqueda en todo {pais} {bandera}'**
  String busquedaEnTodoPaisConBandera(String pais, String bandera);

  /// No description provided for @comunidadesCristianasCercanas.
  ///
  /// In es, this message translates to:
  /// **'Comunidades cristianas cercanas'**
  String get comunidadesCristianasCercanas;

  /// No description provided for @radioEtiqueta.
  ///
  /// In es, this message translates to:
  /// **'Radio:'**
  String get radioEtiqueta;

  /// No description provided for @exploraTemplosSubtitulo.
  ///
  /// In es, this message translates to:
  /// **'Explora templos, rutas y detalles en vivo'**
  String get exploraTemplosSubtitulo;

  /// Conteo de elementos mostrados sobre el total
  ///
  /// In es, this message translates to:
  /// **'{mostradas} de {total}'**
  String conteoResultadosDeTotal(String mostradas, String total);

  /// Indicador de radio en kilometros
  ///
  /// In es, this message translates to:
  /// **'Radio < {km} km'**
  String radioMenorQueKm(String km);

  /// Mensaje de estado vacío cuando se filtra por término
  ///
  /// In es, this message translates to:
  /// **'No se encontraron iglesias con \"{termino}\" en su nombre.'**
  String noSeEncontraronIglesiasConTermino(String termino);

  /// Mensaje de estado vacío en búsqueda por radio
  ///
  /// In es, this message translates to:
  /// **'No se encontraron iglesias a menos de {km} km en {pais}.'**
  String noSeEncontraronIglesiasRadioEnPais(String km, String pais);

  /// Mensaje de estado vacío en país
  ///
  /// In es, this message translates to:
  /// **'No se encontraron iglesias en {pais}.'**
  String noSeEncontraronIglesiasEnPais(String pais);

  /// No description provided for @noSePudieronCargarIglesias.
  ///
  /// In es, this message translates to:
  /// **'😕 No se pudieron cargar las iglesias.\nRevisa tu conexión a internet e inténtalo de nuevo.'**
  String get noSePudieronCargarIglesias;

  /// No description provided for @localizandoComunidades.
  ///
  /// In es, this message translates to:
  /// **'Localizando comunidades cristianas...'**
  String get localizandoComunidades;

  /// No description provided for @pedidosInvitadoDesc.
  ///
  /// In es, this message translates to:
  /// **'En modo invitado no se registran compras ni pedidos. Inicia sesión para consultar tus pedidos.'**
  String get pedidosInvitadoDesc;

  /// No description provided for @notificacionesInvitadoDesc.
  ///
  /// In es, this message translates to:
  /// **'En modo invitado no se reciben avisos ni notificaciones personales. Inicia sesión para mantenerte al día con tu comunidad.'**
  String get notificacionesInvitadoDesc;

  /// No description provided for @omitir.
  ///
  /// In es, this message translates to:
  /// **'Omitir'**
  String get omitir;

  /// No description provided for @errorConexionServidor.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión con el servidor'**
  String get errorConexionServidor;

  /// No description provided for @errorCargarSolicitudesDesc.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un problema temporal al consultar tus solicitudes en el servidor. Puedes intentar nuevamente.'**
  String get errorCargarSolicitudesDesc;

  /// No description provided for @reintentarConexionServidor.
  ///
  /// In es, this message translates to:
  /// **'Reintentar conexión con el servidor'**
  String get reintentarConexionServidor;

  /// No description provided for @modoLocalAviso.
  ///
  /// In es, this message translates to:
  /// **'Mostrando solicitudes guardadas en este dispositivo. Error al sincronizar con el servidor.'**
  String get modoLocalAviso;

  /// No description provided for @bienvenidaAtrio.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenido a ATRIO!'**
  String get bienvenidaAtrio;

  /// No description provided for @modalBienvenidaIglesiaMensaje.
  ///
  /// In es, this message translates to:
  /// **'Conéctate a tu iglesia local para acceder a devocionales, eventos, oraciones y la vida de tu comunidad'**
  String get modalBienvenidaIglesiaMensaje;

  /// Cantidad de iglesias en el mapa con formato plural
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{No hay iglesias en el mapa} =1{1 iglesia en el mapa} other{{count} iglesias en el mapa}}'**
  String conteoIglesiasEnMapa(num count);

  /// Saludo según género gramatical
  ///
  /// In es, this message translates to:
  /// **'{gender, select, female{Bienvenida} male{Bienvenido} other{Bienvenido(a)}}'**
  String bienvenidoSegunGenero(String gender);

  /// No description provided for @patrocinado.
  ///
  /// In es, this message translates to:
  /// **'Patrocinado'**
  String get patrocinado;

  /// No description provided for @anunciosYPublicidad.
  ///
  /// In es, this message translates to:
  /// **'Publicidad y Anuncios'**
  String get anunciosYPublicidad;

  /// No description provided for @gestionCampanasPublicitarias.
  ///
  /// In es, this message translates to:
  /// **'Gestión de Campañas Publicitarias'**
  String get gestionCampanasPublicitarias;

  /// No description provided for @subtituloGestionCampanas.
  ///
  /// In es, this message translates to:
  /// **'Crea, cotiza y mide tus campañas en la comunidad'**
  String get subtituloGestionCampanas;

  /// No description provided for @nuevaCampana.
  ///
  /// In es, this message translates to:
  /// **'Nueva Campaña'**
  String get nuevaCampana;

  /// No description provided for @sinCampanas.
  ///
  /// In es, this message translates to:
  /// **'No hay campañas registradas'**
  String get sinCampanas;

  /// No description provided for @sinCampanasSubtitulo.
  ///
  /// In es, this message translates to:
  /// **'Crea tu primera campaña para llegar a más iglesias y miembros.'**
  String get sinCampanasSubtitulo;

  /// No description provided for @filtroActivas.
  ///
  /// In es, this message translates to:
  /// **'Activas'**
  String get filtroActivas;

  /// No description provided for @filtroPorPagar.
  ///
  /// In es, this message translates to:
  /// **'Por Pagar'**
  String get filtroPorPagar;

  /// No description provided for @filtroEnRevision.
  ///
  /// In es, this message translates to:
  /// **'En Revisión'**
  String get filtroEnRevision;

  /// No description provided for @filtroFinalizadas.
  ///
  /// In es, this message translates to:
  /// **'Finalizadas'**
  String get filtroFinalizadas;

  /// No description provided for @estadoSolicitada.
  ///
  /// In es, this message translates to:
  /// **'En Revisión'**
  String get estadoSolicitada;

  /// No description provided for @estadoPorPagar.
  ///
  /// In es, this message translates to:
  /// **'Por Pagar'**
  String get estadoPorPagar;

  /// No description provided for @estadoComprobanteRevision.
  ///
  /// In es, this message translates to:
  /// **'Comprobante en Revisión'**
  String get estadoComprobanteRevision;

  /// No description provided for @estadoLista.
  ///
  /// In es, this message translates to:
  /// **'Lista para Salir'**
  String get estadoLista;

  /// No description provided for @estadoActiva.
  ///
  /// In es, this message translates to:
  /// **'Activa'**
  String get estadoActiva;

  /// No description provided for @estadoPausada.
  ///
  /// In es, this message translates to:
  /// **'Pausada'**
  String get estadoPausada;

  /// No description provided for @estadoFinalizada.
  ///
  /// In es, this message translates to:
  /// **'Finalizada'**
  String get estadoFinalizada;

  /// No description provided for @estadoRechazada.
  ///
  /// In es, this message translates to:
  /// **'Rechazada'**
  String get estadoRechazada;

  /// No description provided for @motivoRechazo.
  ///
  /// In es, this message translates to:
  /// **'Motivo de rechazo'**
  String get motivoRechazo;

  /// No description provided for @pagarCampana.
  ///
  /// In es, this message translates to:
  /// **'Pagar Campaña'**
  String get pagarCampana;

  /// No description provided for @verEstadisticas.
  ///
  /// In es, this message translates to:
  /// **'Ver Estadísticas'**
  String get verEstadisticas;

  /// No description provided for @cancelarCampana.
  ///
  /// In es, this message translates to:
  /// **'Cancelar Campaña'**
  String get cancelarCampana;

  /// No description provided for @confirmarCancelarCampana.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que deseas retirar esta solicitud de anuncio?'**
  String get confirmarCancelarCampana;

  /// No description provided for @nombreCampana.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la Campaña'**
  String get nombreCampana;

  /// No description provided for @nombreCampanaHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. Conferencia Anual de Jóvenes 2026'**
  String get nombreCampanaHint;

  /// No description provided for @descripcionCampana.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get descripcionCampana;

  /// No description provided for @descripcionCampanaHint.
  ///
  /// In es, this message translates to:
  /// **'Breve mensaje informativo'**
  String get descripcionCampanaHint;

  /// No description provided for @urlDestino.
  ///
  /// In es, this message translates to:
  /// **'URL de Destino (opcional)'**
  String get urlDestino;

  /// No description provided for @urlDestinoHint.
  ///
  /// In es, this message translates to:
  /// **'https://mi-iglesia.org/evento'**
  String get urlDestinoHint;

  /// No description provided for @ubicacionAnuncio.
  ///
  /// In es, this message translates to:
  /// **'Ubicación del Anuncio'**
  String get ubicacionAnuncio;

  /// No description provided for @ubicacionTodas.
  ///
  /// In es, this message translates to:
  /// **'Todas las ubicaciones'**
  String get ubicacionTodas;

  /// No description provided for @ubicacionFeed.
  ///
  /// In es, this message translates to:
  /// **'Feed de inicio'**
  String get ubicacionFeed;

  /// No description provided for @ubicacionNotificaciones.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get ubicacionNotificaciones;

  /// No description provided for @imagenCampana.
  ///
  /// In es, this message translates to:
  /// **'Imagen o Banner de la Campaña'**
  String get imagenCampana;

  /// No description provided for @seleccionarImagen.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar Imagen'**
  String get seleccionarImagen;

  /// No description provided for @cambiarImagen.
  ///
  /// In es, this message translates to:
  /// **'Cambiar Imagen'**
  String get cambiarImagen;

  /// No description provided for @duracionSemanas.
  ///
  /// In es, this message translates to:
  /// **'Duración de la Campaña'**
  String get duracionSemanas;

  /// Duración en semanas con plural
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 semana} other{{count} semanas}}'**
  String semanasPlural(num count);

  /// No description provided for @alcanceIglesias.
  ///
  /// In es, this message translates to:
  /// **'Alcance de Iglesias'**
  String get alcanceIglesias;

  /// Alcance en número de iglesias con plural
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 iglesia} other{{count} iglesias}}'**
  String iglesiasPlural(num count);

  /// No description provided for @resumenCotizacion.
  ///
  /// In es, this message translates to:
  /// **'Resumen de Cotización'**
  String get resumenCotizacion;

  /// No description provided for @precioBase.
  ///
  /// In es, this message translates to:
  /// **'Precio base'**
  String get precioBase;

  /// No description provided for @costoTotal.
  ///
  /// In es, this message translates to:
  /// **'Costo Total'**
  String get costoTotal;

  /// No description provided for @cotizando.
  ///
  /// In es, this message translates to:
  /// **'Calculando cotización...'**
  String get cotizando;

  /// No description provided for @enviarARevision.
  ///
  /// In es, this message translates to:
  /// **'Enviar a Revisión'**
  String get enviarARevision;

  /// No description provided for @campanaCreadaExito.
  ///
  /// In es, this message translates to:
  /// **'¡Campaña enviada a revisión con éxito!'**
  String get campanaCreadaExito;

  /// No description provided for @metodoPago.
  ///
  /// In es, this message translates to:
  /// **'Método de Pago'**
  String get metodoPago;

  /// No description provided for @pagarConPaypal.
  ///
  /// In es, this message translates to:
  /// **'Pagar con PayPal'**
  String get pagarConPaypal;

  /// No description provided for @transferenciaBancaria.
  ///
  /// In es, this message translates to:
  /// **'Transferencia Bancaria'**
  String get transferenciaBancaria;

  /// No description provided for @cuentasBancariasDisponibles.
  ///
  /// In es, this message translates to:
  /// **'Cuentas Bancarias Disponibles'**
  String get cuentasBancariasDisponibles;

  /// No description provided for @titularCuenta.
  ///
  /// In es, this message translates to:
  /// **'Titular'**
  String get titularCuenta;

  /// No description provided for @numeroCuenta.
  ///
  /// In es, this message translates to:
  /// **'Número'**
  String get numeroCuenta;

  /// No description provided for @tipoCuenta.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get tipoCuenta;

  /// No description provided for @rncCedula.
  ///
  /// In es, this message translates to:
  /// **'RNC / Cédula'**
  String get rncCedula;

  /// No description provided for @numeroCopiado.
  ///
  /// In es, this message translates to:
  /// **'Número de cuenta copiado al portapapeles'**
  String get numeroCopiado;

  /// No description provided for @referenciaBancaria.
  ///
  /// In es, this message translates to:
  /// **'Referencia Bancaria / Número de Depósito'**
  String get referenciaBancaria;

  /// No description provided for @referenciaBancariaHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. DEP-12345678'**
  String get referenciaBancariaHint;

  /// No description provided for @enviarComprobante.
  ///
  /// In es, this message translates to:
  /// **'Enviar Comprobante'**
  String get enviarComprobante;

  /// No description provided for @comprobanteEnviadoExito.
  ///
  /// In es, this message translates to:
  /// **'Comprobante enviado. Tu campaña pasará a revisión de pago.'**
  String get comprobanteEnviadoExito;

  /// No description provided for @rendimientoCampana.
  ///
  /// In es, this message translates to:
  /// **'Rendimiento de la Campaña'**
  String get rendimientoCampana;

  /// No description provided for @impresiones.
  ///
  /// In es, this message translates to:
  /// **'Impresiones'**
  String get impresiones;

  /// No description provided for @clics.
  ///
  /// In es, this message translates to:
  /// **'Clics'**
  String get clics;

  /// No description provided for @ctr.
  ///
  /// In es, this message translates to:
  /// **'CTR (Clics / Impresiones)'**
  String get ctr;

  /// No description provided for @evolucionDiaria.
  ///
  /// In es, this message translates to:
  /// **'Evolución Diaria'**
  String get evolucionDiaria;

  /// No description provided for @masInformacion.
  ///
  /// In es, this message translates to:
  /// **'Más información'**
  String get masInformacion;

  /// No description provided for @permisoRequeridoManageAds.
  ///
  /// In es, this message translates to:
  /// **'Se requiere el permiso de Administrador de Anuncios (manage_ads) para acceder a este módulo.'**
  String get permisoRequeridoManageAds;

  /// No description provided for @moderacionPlataforma.
  ///
  /// In es, this message translates to:
  /// **'Moderación de Plataforma'**
  String get moderacionPlataforma;

  /// No description provided for @centroModeracion.
  ///
  /// In es, this message translates to:
  /// **'Centro de Moderación'**
  String get centroModeracion;

  /// No description provided for @subtituloModeracion.
  ///
  /// In es, this message translates to:
  /// **'Audita y modera contenido público y administra palabras restringidas'**
  String get subtituloModeracion;

  /// No description provided for @resumenModeracion.
  ///
  /// In es, this message translates to:
  /// **'Resumen de Moderación'**
  String get resumenModeracion;

  /// No description provided for @marcados.
  ///
  /// In es, this message translates to:
  /// **'Marcados'**
  String get marcados;

  /// No description provided for @bloqueados.
  ///
  /// In es, this message translates to:
  /// **'Bloqueados'**
  String get bloqueados;

  /// No description provided for @publicaciones.
  ///
  /// In es, this message translates to:
  /// **'Publicaciones'**
  String get publicaciones;

  /// No description provided for @todosLosTipos.
  ///
  /// In es, this message translates to:
  /// **'Todos los tipos'**
  String get todosLosTipos;

  /// No description provided for @bloquearContenido.
  ///
  /// In es, this message translates to:
  /// **'Bloquear Contenido'**
  String get bloquearContenido;

  /// No description provided for @desbloquearContenido.
  ///
  /// In es, this message translates to:
  /// **'Desbloquear Contenido'**
  String get desbloquearContenido;

  /// No description provided for @motivoBloqueo.
  ///
  /// In es, this message translates to:
  /// **'Motivo del Bloqueo'**
  String get motivoBloqueo;

  /// No description provided for @motivoBloqueoHint.
  ///
  /// In es, this message translates to:
  /// **'Explica por qué este contenido es inapropiado (la iglesia lo verá)'**
  String get motivoBloqueoHint;

  /// No description provided for @motivoBloqueoObligatorio.
  ///
  /// In es, this message translates to:
  /// **'El motivo del bloqueo es obligatorio'**
  String get motivoBloqueoObligatorio;

  /// No description provided for @confirmarBloqueo.
  ///
  /// In es, this message translates to:
  /// **'Confirmar Bloqueo'**
  String get confirmarBloqueo;

  /// No description provided for @confirmarDesbloqueo.
  ///
  /// In es, this message translates to:
  /// **'¿Deseas desbloquear este contenido para que vuelva a estar visible en la comunidad?'**
  String get confirmarDesbloqueo;

  /// No description provided for @contenidoBloqueadoExito.
  ///
  /// In es, this message translates to:
  /// **'Contenido bloqueado exitosamente'**
  String get contenidoBloqueadoExito;

  /// No description provided for @contenidoDesbloqueadoExito.
  ///
  /// In es, this message translates to:
  /// **'Contenido desbloqueado exitosamente'**
  String get contenidoDesbloqueadoExito;

  /// No description provided for @palabrasRestringidas.
  ///
  /// In es, this message translates to:
  /// **'Palabras Restringidas'**
  String get palabrasRestringidas;

  /// No description provided for @subtituloPalabrasRestringidas.
  ///
  /// In es, this message translates to:
  /// **'Reglas léxicas para marcar o bloquear contenidos automáticamente'**
  String get subtituloPalabrasRestringidas;

  /// No description provided for @nuevaPalabra.
  ///
  /// In es, this message translates to:
  /// **'Nueva Palabra'**
  String get nuevaPalabra;

  /// No description provided for @palabraOFrase.
  ///
  /// In es, this message translates to:
  /// **'Palabra o Frase'**
  String get palabraOFrase;

  /// No description provided for @palabraOFraseHint.
  ///
  /// In es, this message translates to:
  /// **'Ej. grosería, término indebido'**
  String get palabraOFraseHint;

  /// No description provided for @modoPalabra.
  ///
  /// In es, this message translates to:
  /// **'Modo de Acción'**
  String get modoPalabra;

  /// No description provided for @modoFlag.
  ///
  /// In es, this message translates to:
  /// **'Marcar (Flag) - Guarda y alerta para revisión'**
  String get modoFlag;

  /// No description provided for @modoBlock.
  ///
  /// In es, this message translates to:
  /// **'Bloquear (Block) - Impide guardar'**
  String get modoBlock;

  /// No description provided for @palabraCompleta.
  ///
  /// In es, this message translates to:
  /// **'Coincidencia exacta de palabra completa'**
  String get palabraCompleta;

  /// No description provided for @palabraActiva.
  ///
  /// In es, this message translates to:
  /// **'Regla activa'**
  String get palabraActiva;

  /// No description provided for @notaInterna.
  ///
  /// In es, this message translates to:
  /// **'Nota Interna (opcional)'**
  String get notaInterna;

  /// No description provided for @notaInternaHint.
  ///
  /// In es, this message translates to:
  /// **'Razón o contexto de la restricción'**
  String get notaInternaHint;

  /// No description provided for @palabraGuardadaExito.
  ///
  /// In es, this message translates to:
  /// **'Palabra restringida guardada con éxito'**
  String get palabraGuardadaExito;

  /// No description provided for @eliminarPalabra.
  ///
  /// In es, this message translates to:
  /// **'Eliminar Palabra'**
  String get eliminarPalabra;

  /// No description provided for @confirmarEliminarPalabra.
  ///
  /// In es, this message translates to:
  /// **'¿Deseas eliminar esta palabra de la lista de restricciones?'**
  String get confirmarEliminarPalabra;

  /// No description provided for @palabraEliminadaExito.
  ///
  /// In es, this message translates to:
  /// **'Palabra eliminada con éxito'**
  String get palabraEliminadaExito;

  /// No description provided for @revisarTodoElContenido.
  ///
  /// In es, this message translates to:
  /// **'Revisar Todo el Contenido'**
  String get revisarTodoElContenido;

  /// No description provided for @confirmarRescan.
  ///
  /// In es, this message translates to:
  /// **'Se auditarán todas las publicaciones, eventos y notificaciones existentes en busca de palabras restringidas. Esta acción puede tomar unos momentos.'**
  String get confirmarRescan;

  /// No description provided for @iniciarRevision.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Revisión'**
  String get iniciarRevision;

  /// No description provided for @revisionCompletada.
  ///
  /// In es, this message translates to:
  /// **'Revisión completada'**
  String get revisionCompletada;

  /// Cantidad de elementos marcados durante el reescaneo
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{No se encontraron nuevos elementos marcados.} =1{Se marcó 1 elemento tras la revisión.} other{Se marcaron {count} elementos tras la revisión.}}'**
  String elementosMarcadosRescan(num count);

  /// No description provided for @permisoRequeridoSuperAdmin.
  ///
  /// In es, this message translates to:
  /// **'Acceso restringido: Se requiere el rol de Super Administrador de Plataforma (platform_admin) para acceder a este módulo.'**
  String get permisoRequeridoSuperAdmin;

  /// No description provided for @sinContenidoModerado.
  ///
  /// In es, this message translates to:
  /// **'No hay contenido en esta sección'**
  String get sinContenidoModerado;

  /// No description provided for @sinPalabrasRestringidas.
  ///
  /// In es, this message translates to:
  /// **'No hay palabras restringidas registradas'**
  String get sinPalabrasRestringidas;

  /// No description provided for @buscarPorTituloOIglesia.
  ///
  /// In es, this message translates to:
  /// **'Buscar por título o iglesia...'**
  String get buscarPorTituloOIglesia;

  /// No description provided for @buscarPalabra.
  ///
  /// In es, this message translates to:
  /// **'Buscar palabra...'**
  String get buscarPalabra;

  /// Muestra las palabras restringidas que fueron detectadas en el texto
  ///
  /// In es, this message translates to:
  /// **'Palabras detectadas: {words}'**
  String palabrasDetectadas(String words);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
