// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get bienvenida => 'Welcome to Atrio';

  @override
  String saludo(String nombre) {
    return 'Hello, $nombre';
  }

  @override
  String get appTitulo => 'ATRIO';

  @override
  String get lema => 'Live your Faith in community';

  @override
  String get subtituloBienvenida => 'A space to live and share your faith';

  @override
  String get accesoRapidoSeguro => 'Fast and Secure Access';

  @override
  String get ingresaUnToque => 'Sign in with a single tap';

  @override
  String get continuarConGoogle => 'Continue with Google';

  @override
  String get continuarConApple => 'Continue with Apple';

  @override
  String get explorarInvitado => 'Explore as guest';

  @override
  String get avisoPrivacidadOdoo =>
      'By continuing, you securely link your account with the ATRIO church server in Odoo ERP.';

  @override
  String get terminosDeUso => 'Terms of use';

  @override
  String get politicaPrivacidad => 'Privacy policy';

  @override
  String get privacidad => 'Privacy';

  @override
  String get eliminarMisDatos => 'Delete my data';

  @override
  String get eliminarCuentaYDatos => 'Delete account and data';

  @override
  String get solicitarEliminacion => 'Request deletion';

  @override
  String get opcionNoDisponible => 'Option not available';

  @override
  String get entendido => 'Understood';

  @override
  String get inicio => 'Home';

  @override
  String get perfil => 'Profile';

  @override
  String get biblia => 'Bible';

  @override
  String get eventos => 'Events';

  @override
  String get donaciones => 'Donations';

  @override
  String get solicitudes => 'Requests';

  @override
  String get notificaciones => 'Notifications';

  @override
  String get configuracion => 'Settings';

  @override
  String get ajustes => 'Settings';

  @override
  String get idiomaPreferido => 'Preferred language';

  @override
  String get seleccionarIdioma => 'Select Language';

  @override
  String get modoVisualizacion => 'Display mode';

  @override
  String get claro => 'Light';

  @override
  String get oscuro => 'Dark';

  @override
  String get sistema => 'System';

  @override
  String get guardar => 'Save';

  @override
  String get cancelar => 'Cancel';

  @override
  String get cerrar => 'Close';

  @override
  String get deseasSalirAtrio => 'Do you want to exit Atrio?';

  @override
  String get presionaSalirCerrar => 'Press \"Exit\" to close the application.';

  @override
  String get salir => 'Exit';

  @override
  String get iglesia => 'Church';

  @override
  String get explorar => 'Explore';

  @override
  String get radio => 'Radio';

  @override
  String get miIglesia => 'My Church';

  @override
  String get tocaParaCambiar => '· Tap to change';

  @override
  String get sinIglesiaSeleccionada => 'No church selected';

  @override
  String get proyectosSolidarios => 'Solidarity\nprojects';

  @override
  String get tienda => 'Store';

  @override
  String get libros => 'Books';

  @override
  String get videos => 'Videos';

  @override
  String get nuevoAviso => 'New notice';

  @override
  String get cambioHorarioAviso => 'Schedule change · Wednesday, 7:00 PM';

  @override
  String get categoriaServicios => 'Services';

  @override
  String get inscripcionesAbiertas => 'Open registrations';

  @override
  String get retiroAnualAviso => 'Annual Retreat 2026 · Limited spots';

  @override
  String get categoriaComunidad => 'Community';

  @override
  String get accionSolidaria => 'Solidarity action';

  @override
  String get campanaDonacionesAviso =>
      '\"Hands that Bless\" campaign · Donations';

  @override
  String get anunciosYConciertos => 'ANNOUNCEMENTS & CONCERTS';

  @override
  String get cargandoNovedades => 'Loading updates...';

  @override
  String infoArtistaEnviada(String artista) {
    return 'Information about \"$artista\" sent.';
  }

  @override
  String noSePudoAbrirMarcador(String telefono) {
    return 'Could not open dialer with number $telefono';
  }

  @override
  String get noSePudoAbrirNavegacion =>
      'Could not open navigation application.';

  @override
  String noSePudoAbrirEnlace(String url) {
    return 'Could not open link $url';
  }

  @override
  String get compartirUbicacion => 'Share location';

  @override
  String get plusCodeCopiadoPregunta =>
      'The Plus Code has been copied to the clipboard. Do you want to share it directly?';

  @override
  String plusCodeCopiadoSnack(String plusCode) {
    return 'Plus Code copied: $plusCode';
  }

  @override
  String get correo => 'Email';

  @override
  String get reintentar => 'Retry';

  @override
  String get cambiarDeIglesia => 'Change church';

  @override
  String get exploraYSeleccionaComunidad =>
      'Explore and select another community';

  @override
  String get llamar => 'Call';

  @override
  String get comoLlegar => 'Directions';

  @override
  String get sitioWeb => 'Website';

  @override
  String get verAhora => 'Watch now';

  @override
  String get horariosDeServicio => 'Service times';

  @override
  String get ubicacionYContacto => 'Location & contact';

  @override
  String get direccion => 'Address';

  @override
  String get telefono => 'Phone';

  @override
  String get avisos => 'Notices';

  @override
  String get encuentraTuFeEn10Km => 'Find your ideal Faith within 10 km';

  @override
  String get buscarIglesiasPlaceholder => 'E.g., Christian church, Baptist...';

  @override
  String get catolica => 'Catholic';

  @override
  String get evangelica => 'Evangelical';

  @override
  String get pentecostal => 'Pentecostal';

  @override
  String get bautista => 'Baptist';

  @override
  String get adventista => 'Adventist';

  @override
  String get visualizaIglesiasEnMapa => 'View churches on the Map';

  @override
  String get comunidadesSugeridas => 'Suggested communities';

  @override
  String get noSeEncontraronIglesias10km => 'No churches found within 10 km.';

  @override
  String get gpsDesactivado => 'GPS is disabled. Please turn it on.';

  @override
  String get permisosUbicacionDenegados => 'Location permissions denied.';

  @override
  String get permisosUbicacionPermanentemente =>
      'Location permissions permanently denied on your device.';

  @override
  String get obteniendoUbicacionEspera =>
      'Getting your location, please try again in a moment...';

  @override
  String get errorCargarMapa =>
      '😕 Oops! Could not load the Map\n\n📡 Check your internet connection and try again';

  @override
  String get sinNombre => 'Unnamed';

  @override
  String get comunidadCristiana => 'Christian community';

  @override
  String aDistanciaKm(String distancia) {
    return '$distancia km away';
  }

  @override
  String get emisorasCristianas => 'Christian Radio Stations';

  @override
  String get buscarEmisorasPlaceholder =>
      'Search by name, denomination, city...';

  @override
  String get todosLosPaises => 'All countries';

  @override
  String get otrosPaises => 'Other countries';

  @override
  String get todos => 'All';

  @override
  String get espanol => 'Spanish';

  @override
  String get ingles => 'English';

  @override
  String mostrandoSoloFavoritas(String total) {
    return 'Showing favorites only ($total)';
  }

  @override
  String get verTodas => 'View all';

  @override
  String sinFavoritasEnPais(String pais) {
    return 'You don\'t have any favorite stations saved in $pais.\n\nTap the heart button above to view all stations.';
  }

  @override
  String get sinFavoritasAun =>
      'You don\'t have any favorite stations saved yet.\n\nTap the heart button above to view all stations.';

  @override
  String noEmisorasCoincidencia(String busqueda) {
    return 'No stations found matching \"$busqueda\".';
  }

  @override
  String noEmisorasDisponiblesPais(String pais) {
    return 'No stations available for $pais.';
  }

  @override
  String get verTodasLasEmisoras => 'View all stations';

  @override
  String get sintonizandoAudio => 'Tuning audio...';

  @override
  String enVivoConDenominacion(String denominacion, String frecuencia) {
    return 'Live · $denominacion ($frecuencia)';
  }

  @override
  String enVivoFrecuencia(String frecuencia) {
    return 'Live · $frecuencia';
  }

  @override
  String get emisora => 'Station';

  @override
  String get errorEmisoraNoDisponible =>
      'Error: The station is not available at this moment.';

  @override
  String get sinInternetSintonizar =>
      'No internet connection to tune the station.';

  @override
  String get usuario => 'User';

  @override
  String get miActividad => 'My activity';

  @override
  String get cuenta => 'Account';

  @override
  String get soporte => 'Support';

  @override
  String get misSolicitudes => 'My requests';

  @override
  String get misDonaciones => 'My donations';

  @override
  String get misNotasDeLaBiblia => 'My Bible notes';

  @override
  String get misDatos => 'My personal data';

  @override
  String get ajustesDeLaApp => 'App settings';

  @override
  String get ayudaYSoporte => 'Help & support';

  @override
  String get terminosYPrivacidad => 'Terms & privacy';

  @override
  String get cerrarSesion => 'Log out';

  @override
  String get misDatosDePerfil => 'My profile details';

  @override
  String get nombreCompleto => 'Full name';

  @override
  String get ingresaUnNombre => 'Enter a name';

  @override
  String get correoElectronico => 'Email';

  @override
  String get ingresaUnCorreoValido => 'Enter a valid email';

  @override
  String get telefonoCelular => 'Mobile phone';

  @override
  String get iglesiaActual => 'Current church';

  @override
  String get helperCambiarIglesia =>
      'To change it, use the \"Change church\" option';

  @override
  String get guardarCambios => 'Save changes';

  @override
  String get datosActualizadosCorrectamente => 'Data updated successfully';

  @override
  String get seguroDeseasCerrarSesion => 'Are you sure you want to log out?';

  @override
  String get eliminarCuenta => 'Delete account';

  @override
  String get seguroEliminarCuenta =>
      'Are you sure you want to delete your account and all your personal data from ATRIO?';

  @override
  String get detalleEliminarCuenta =>
      'This action is final and irreversible. The following will be permanently deleted:\n• Your user profile and community connection.\n• All your personal Bible notes and saved favorites.\n• Your history of requests and local contributions.\n• Deactivation of your record in the Odoo ERP backend will be requested.';

  @override
  String get eliminarDefinitivamente => 'Delete permanently';

  @override
  String get cuentaEliminadaExito =>
      'Your account and personal data have been successfully deleted.';

  @override
  String get versionDeLaBiblia => 'Bible version';

  @override
  String get noSePudoAbrirWhatsApp => 'Could not open WhatsApp.';

  @override
  String get buscarBibliaPlaceholder => 'Search verse, word, or phrase...';

  @override
  String get buscar => 'Search';

  @override
  String get borrarTexto => 'Clear text';

  @override
  String buscandoEnVersion(String version) {
    return 'Searching in $version...';
  }

  @override
  String get versiculoDelDia => 'Verse of the day';

  @override
  String get compartirVersiculo => 'Share verse';

  @override
  String get errorCargarVersiculo => 'Could not load today\'s verse.';

  @override
  String get librosDeLaBiblia => 'Books of the Bible';

  @override
  String get antiguoYNuevoTestamento => 'Old and New Testament';

  @override
  String get continuarLeyendo => 'Continue reading';

  @override
  String capituloNumero(String numero) {
    return 'Chapter $numero';
  }

  @override
  String get escuchar => 'Listen';

  @override
  String get escuchaLaBibliaNarrada => 'Listen to the narrated Bible';

  @override
  String get favoritos => 'Favorites';

  @override
  String get pasajeGuardado => '1 saved passage';

  @override
  String pasajesGuardados(String total) {
    return '$total saved passages';
  }

  @override
  String get misNotas => 'My notes';

  @override
  String get notaSingular => '1 note';

  @override
  String notasPlural(String total) {
    return '$total notes';
  }

  @override
  String noVersiculosEncontrados(String consulta) {
    return 'No verses found for:\n\"$consulta\"';
  }

  @override
  String get pruebaPalabrasClave =>
      'Try using more general keywords or check your spelling.';

  @override
  String versiculosEncontrados(String total) {
    return '$total verses found';
  }

  @override
  String get cerrarBusqueda => 'Close search';

  @override
  String get buscarEventosPlaceholder =>
      'Search events, speakers, or venues...';

  @override
  String get categorias => 'Categories';

  @override
  String get categoriaTodos => 'All';

  @override
  String get categoriaLiderazgo => 'Leadership';

  @override
  String get categoriaAdoracion => 'Worship';

  @override
  String get categoriaJovenes => 'Youth';

  @override
  String get categoriaFamilias => 'Families';

  @override
  String get explorarEventos => 'Explore events';

  @override
  String get verTodos => 'See all';

  @override
  String get noEventosEnCategoria => 'No events found in this category';

  @override
  String get proximosEnAgenda => 'Upcoming on schedule';

  @override
  String get mostrandoCalendarioCompleto =>
      'Showing full schedule of activities...';

  @override
  String get verCalendario => 'View calendar';

  @override
  String get destacadoMayus => 'FEATURED';

  @override
  String get inscribirmeAhora => 'Register now';

  @override
  String eventoAnadidoACalendario(String titulo) {
    return 'Event \"$titulo\" added to your calendar.';
  }

  @override
  String get anadirACalendario => 'Add to calendar';

  @override
  String get miActividadAgendada => 'My scheduled activity';

  @override
  String porcentajeOcupacion(int porcentaje) {
    return '$porcentaje% capacity';
  }

  @override
  String get disponibilidadCupos => 'Seat availability';

  @override
  String get detallesDelEvento => 'Event details';

  @override
  String inscripcionConfirmada(String titulo) {
    return 'Registration confirmed for \"$titulo\". See you there!';
  }

  @override
  String get yaEstasInscrito => 'Already registered';

  @override
  String eventoAgregadoAgendaLocal(String titulo) {
    return 'Event \"$titulo\" added to your local calendar.';
  }

  @override
  String get mensajeWhatsAppAyuda => 'Hello, I need help with the ATRIO app.';

  @override
  String get errorAbrirWhatsAppDispositivo =>
      'Could not open WhatsApp on this device.';

  @override
  String get errorAbrirWhatsApp =>
      'An error occurred while trying to open WhatsApp.';

  @override
  String get asuntoCorreoSoporte => 'Support - ATRIO App';

  @override
  String get cuerpoCorreoSoporte =>
      'Describe your query or issue here:\n\n---\nApp version: 1.0.0';

  @override
  String get errorNoClienteCorreo => 'No email client configured.';

  @override
  String get errorAbrirCorreo =>
      'An error occurred while trying to open email.';

  @override
  String get modoClaroSuave => 'Soft Light Mode';

  @override
  String get modoLecturaNocturna => 'Night Reading Mode';

  @override
  String get modoPapiroCalido => 'Warm Papyrus Mode';

  @override
  String get ajustesDeLectura => 'Reading settings';

  @override
  String get tamanoDeLetra => 'Font size';

  @override
  String get tipoDeFuente => 'Font type';

  @override
  String get modoDeLectura => 'Reading mode';

  @override
  String get papiro => 'Papyrus';

  @override
  String get noche => 'Night';

  @override
  String get cambiarTonoLecturaTooltip => 'Change reading tone';

  @override
  String get comoPodemosAyudarte => 'How can we help you?';

  @override
  String get descripcionAyudaSoporte =>
      'Find quick answers or contact our ATRIO technical support team directly.';

  @override
  String get canalesDeAtencion => 'Support channels';

  @override
  String get chatDirecto => 'Direct chat';

  @override
  String get preguntasFrecuentes => 'Frequently asked questions';

  @override
  String get faq1Pregunta =>
      'How do I make an offering or donation to my church?';

  @override
  String get faq1Respuesta =>
      'Access the \"My donations\" section from your profile or tap the \"Give / Donate\" button on your church\'s screen. You will be able to select the mission project, enter the amount, and proceed securely.';

  @override
  String get faq2Pregunta =>
      'How do I send and check the status of my pastoral requests?';

  @override
  String get faq2Respuesta =>
      'Go to the \"My requests\" section in your profile or from your church menu. There you can submit prayer, counseling, or community support requests and check your community\'s response.';

  @override
  String get faq3Pregunta =>
      'Where can I explore nearby churches and view them on the map?';

  @override
  String get faq3Respuesta =>
      'From the home screen, tap \"Explore Churches\" or the interactive map. You can filter by Christian tradition, check service times, lead pastors, and get directions on the map.';

  @override
  String get faq4Pregunta =>
      'Can I read the Bible and save notes or favorites offline?';

  @override
  String get faq4Respuesta =>
      'Yes! The Bible text, your study notes, and highlighted verses are safely stored locally on your device via SQLite so you can enjoy them anytime.';

  @override
  String get faq5Pregunta =>
      'How do I update my profile details or switch churches?';

  @override
  String get faq5Respuesta =>
      'In the Profile tab, tap \"My details\" or the edit button to update your name, email, or mobile phone. If you want to affiliate with another community, tap \"Switch church\".';

  @override
  String atrioVersion(String version) {
    return 'ATRIO · Version $version';
  }

  @override
  String get todosLosDerechosReservados => 'All rights reserved';

  @override
  String get tiposDeSolicitud => 'Request types';

  @override
  String get peticionDeOracion => 'Prayer request';

  @override
  String get orientacionPastoral => 'Pastoral guidance';

  @override
  String get consejeriaFamiliar => 'Family counseling';

  @override
  String get visitaAEnfermos => 'Visit to the sick';

  @override
  String get ayudaComunitaria => 'Community assistance';

  @override
  String get otraSolicitud => 'Other request';

  @override
  String get volver => 'Back';

  @override
  String get comunidadVerificada => 'Verified community';

  @override
  String get diezmo => 'Tithe';

  @override
  String get ofrenda => 'Offering';

  @override
  String get campanaEspecial => 'Special campaign';

  @override
  String get otroAporte => 'Other contribution';

  @override
  String get historialYRecibos => 'History and receipts';

  @override
  String get proyectosSolidariosTitulo => 'Solidarity projects';

  @override
  String get lemaProyectosSolidarios => 'Together we can transform lives';

  @override
  String get noHayDatosDisponibles => 'No data available';

  @override
  String get masCampanas => 'More campaigns';

  @override
  String get metaPrefijo => 'Goal:';

  @override
  String get deMonto => 'of';

  @override
  String porcentajeAlcanzado(String porcentaje) {
    return '$porcentaje% reached';
  }

  @override
  String diasRestantes(String dias) {
    return '$dias days left';
  }

  @override
  String carritoCantidadProductos(String cantidad) {
    return 'You have $cantidad products in your shopping cart';
  }

  @override
  String get buscarProductosPlaceholder => 'Search Bibles, books, or gifts...';

  @override
  String get categoriaBiblias => 'Bibles';

  @override
  String get categoriaLibros => 'Books';

  @override
  String get categoriaRegalos => 'Gifts';

  @override
  String get recursosParaCrecerEnTuFe => 'Resources to\ngrow in your faith';

  @override
  String get verDestacados => 'View featured';

  @override
  String get catalogoDeProductos => 'Product catalog';

  @override
  String get noSeEncontraronProductosCategoria =>
      'No products found in this category';

  @override
  String get entregaORetiro => 'Delivery or pickup';

  @override
  String get envioADomicilio => 'Home delivery';

  @override
  String get retiroEnIglesia => 'Church pickup';

  @override
  String unidadesEnInventario(String cantidad) {
    return '$cantidad units in stock';
  }

  @override
  String get detallesDelProducto => 'Product details';

  @override
  String productoAgregadoAlCarrito(String nombre) {
    return '\"$nombre\" added to cart!';
  }

  @override
  String agregarAlCarritoConPrecio(String precio) {
    return 'Add to cart · $precio';
  }

  @override
  String get buscarLibrosPlaceholder => 'Search books or authors...';

  @override
  String get categoriaVidaCristiana => 'Christian life';

  @override
  String get categoriaCrecimiento => 'Growth';

  @override
  String get explorarLibros => 'Explore books';

  @override
  String get noSeEncontraronLibrosCategoria =>
      'No books found in this category';

  @override
  String get leerAhora => 'Read now';

  @override
  String get escucharMuestra => 'Listen to sample';

  @override
  String reproduciendoMuestra(String titulo) {
    return 'Playing sample of \"$titulo\"...';
  }

  @override
  String totalPaginas(String paginas) {
    return '$paginas pages';
  }

  @override
  String porcentajeLeido(String porcentaje) {
    return '$porcentaje% read';
  }

  @override
  String get sinopsis => 'Synopsis';

  @override
  String abriendoLibro(String titulo) {
    return 'Opening \"$titulo\"...';
  }

  @override
  String get videosYTransmisiones => 'Videos and streams';

  @override
  String get buscarVideosPlaceholder => 'Search sermons, channels or topics...';

  @override
  String get enVivoBadge => 'LIVE';

  @override
  String get categoriaEnVivo => 'Live';

  @override
  String get categoriaPredicas => 'Sermons';

  @override
  String get categoriaEstudios => 'Bible studies';

  @override
  String get categoriaMusica => 'Music';

  @override
  String get noSeEncontraronVideosCategoria =>
      'No videos found in this category';

  @override
  String get descripcion => 'Description';

  @override
  String conectandoTransmision(String titulo) {
    return 'Connecting to stream \"$titulo\"...';
  }

  @override
  String reproduciendoVideo(String titulo) {
    return 'Playing \"$titulo\"...';
  }

  @override
  String get verTransmisionEnVivo => 'Watch live stream';

  @override
  String get reproducirAhora => 'Play now';

  @override
  String enlaceCopiadoPortapapeles(String titulo) {
    return 'Link to \"$titulo\" copied to clipboard';
  }
}
