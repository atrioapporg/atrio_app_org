import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';

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
    Locale('fr'),
    Locale('pt'),
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
  /// **'¿Deseas salir de atrio?'**
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

  /// Etiqueta de distancia en kilómetros
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
  /// **'Términos y privacidad'**
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
      <String>['en', 'es', 'fr', 'pt'].contains(locale.languageCode);

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
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
