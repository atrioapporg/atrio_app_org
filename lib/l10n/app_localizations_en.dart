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
  String get usuarioGoogle => 'Google User';

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
  String get entendido => 'Got it';

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
  String get terminosYPrivacidad => 'Terms and Privacy';

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
  String get buscarPorFecha => 'Search by date';

  @override
  String get buscarEventosPorFechaTitulo => 'SEARCH EVENTS BY DATE';

  @override
  String eventosFechaEncabezado(String fecha) {
    return 'Events: $fecha';
  }

  @override
  String get noEventosParaFecha => 'No events scheduled for the selected date';

  @override
  String get mostrarTodosLosEventos => 'Show all events';

  @override
  String get destacadoMayus => 'FEATURED';

  @override
  String get inscribirmeAhora => 'Register now';

  @override
  String get cancelarInscripcion => 'Cancel registration';

  @override
  String get rolAdministradorIglesia => 'Church Administrator';

  @override
  String get rolSuperAdmin => 'Super Administrator';

  @override
  String get rolMiembro => 'Active Member';

  @override
  String get rolUsuario => 'User';

  @override
  String get modoSoloLectura => 'Read-only';

  @override
  String get administracionPastoral => 'Pastoral Administration';

  @override
  String get gestionAvisos => 'Congregational announcements';

  @override
  String get gestionGrupos => 'Audiences and groups';

  @override
  String get accionRestringidaSoloLectura =>
      'Action not available in read-only mode';

  @override
  String get permisoRequerido => 'Requires administrator permissions';

  @override
  String get moderacionPeticiones => 'Prayer request moderation';

  @override
  String get metricasComunidad => 'Community analytics';

  @override
  String get publicarAviso => 'Post announcement';

  @override
  String get tituloAviso => 'Announcement title';

  @override
  String get contenidoAviso => 'Announcement content';

  @override
  String get fijarAviso => 'Pin to top';

  @override
  String get seleccionarAudiencia => 'Audience / Group';

  @override
  String get todasLasAudiencias => 'Entire congregation';

  @override
  String get publicar => 'Publish';

  @override
  String get avisoPublicadoExito => 'Announcement published successfully';

  @override
  String get campoRequerido => 'This field is required';

  @override
  String get errorPublicarAviso => 'Could not publish announcement';

  @override
  String get peticionesPendientes => 'Pending requests';

  @override
  String get aprobar => 'Approve';

  @override
  String get rechazar => 'Reject';

  @override
  String get peticionAprobada => 'Request approved';

  @override
  String get peticionRechazada => 'Request rejected';

  @override
  String get totalMiembros => 'Total members';

  @override
  String get nuevosMiembrosMes => 'New members this month';

  @override
  String get totalOfrendas => 'Recorded offerings';

  @override
  String get inscripcionesEventos => 'Event registrations';

  @override
  String get sinPeticionesPendientes => 'No prayer requests pending moderation';

  @override
  String get sinAvisosActivos => 'No congregational announcements published';

  @override
  String get motivoRechazoOpcional => 'Optional reason for rejection';

  @override
  String get bannerModoSoloLectura =>
      'Read-only mode active. Publishing and registration features are disabled.';

  @override
  String get avisoModeracionOracion =>
      'Pastoral notice: Your prayer request will be reviewed by the pastoral team before being visible to the congregation.';

  @override
  String get iglesiaRequeridaParaSolicitud =>
      'You must be assigned to a church to submit pastoral requests.';

  @override
  String get seleccionarIglesiaAccion => 'Select church';

  @override
  String get solicitudRequiereSesion =>
      'You must sign in with your account to submit requests or pastoral petitions to your congregation.';

  @override
  String get solicitudRequiereMembresia =>
      'Your account is pending congregation membership assignment or approval to submit requests.';

  @override
  String get donacionRequiereSesion =>
      'You must sign in with a member account to make donations and offerings.';

  @override
  String get donacionRequiereMembresia =>
      'Your account is registered but pending congregation membership assignment or approval. Only active members can make donations.';

  @override
  String get donacionRequiereIglesia =>
      'You must belong to an assigned congregation to make donations.';

  @override
  String get inicioSesionRequerido => 'Sign in required';

  @override
  String get tiendaRequiereSesion =>
      'You must sign in with your account to add items and make purchases in the store.';

  @override
  String get librosRequiereSesion =>
      'You must sign in with your account to read or listen to books in the library.';

  @override
  String get proyectoRequiereSesion =>
      'You must sign in with your account to collaborate and contribute to solidarity projects.';

  @override
  String get sesionRequeridaGenerica =>
      'You must sign in with your account to access this feature.';

  @override
  String get membresiaPendiente => 'Membership pending approval';

  @override
  String get iniciarSesion => 'Sign in';

  @override
  String get modoInvitado => 'Guest mode';

  @override
  String get usuarioInvitado => 'Guest user';

  @override
  String get perfilInvitadoDesc =>
      'You are browsing as a guest. Sign in to access your history, requests, and donations.';

  @override
  String get sinSolicitudesRegistradas => 'No requests registered';

  @override
  String get solicitudesInvitadoDesc =>
      'In guest mode, requests are not recorded or displayed. Sign in to create and track pastoral requests.';

  @override
  String get sinDonacionesRegistradas => 'No donations registered';

  @override
  String get donacionesInvitadoDesc =>
      'In guest mode, donations are not recorded. Sign in to contribute and view your donation history.';

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

  @override
  String get filtrarPorNombreDeLibro => 'Filter by book name...';

  @override
  String get antiguoTestamento => 'Old Testament';

  @override
  String get nuevoTestamento => 'New Testament';

  @override
  String get noSeEncontraronLibros => 'No books found';

  @override
  String get unCapitulo => '1 chapter';

  @override
  String totalCapitulos(String total) {
    return '$total chapters';
  }

  @override
  String get libroGenesis => 'Genesis';

  @override
  String get libroExodo => 'Exodus';

  @override
  String get libroLevitico => 'Leviticus';

  @override
  String get libroNumeros => 'Numbers';

  @override
  String get libroDeuteronomio => 'Deuteronomy';

  @override
  String get libroJosue => 'Joshua';

  @override
  String get libroJueces => 'Judges';

  @override
  String get libroRut => 'Ruth';

  @override
  String get libro1Samuel => '1 Samuel';

  @override
  String get libro2Samuel => '2 Samuel';

  @override
  String get libro1Reyes => '1 Kings';

  @override
  String get libro2Reyes => '2 Kings';

  @override
  String get libro1Cronicas => '1 Chronicles';

  @override
  String get libro2Cronicas => '2 Chronicles';

  @override
  String get libroEsdras => 'Ezra';

  @override
  String get libroNehemias => 'Nehemiah';

  @override
  String get libroEster => 'Esther';

  @override
  String get libroJob => 'Job';

  @override
  String get libroSalmos => 'Psalms';

  @override
  String get libroProverbios => 'Proverbs';

  @override
  String get libroEclesiastes => 'Ecclesiastes';

  @override
  String get libroCantares => 'Song of Songs';

  @override
  String get libroIsaias => 'Isaiah';

  @override
  String get libroJeremias => 'Jeremiah';

  @override
  String get libroLamentaciones => 'Lamentations';

  @override
  String get libroEzequiel => 'Ezekiel';

  @override
  String get libroDaniel => 'Daniel';

  @override
  String get libroOseas => 'Hosea';

  @override
  String get libroJoel => 'Joel';

  @override
  String get libroAmos => 'Amos';

  @override
  String get libroAbdias => 'Obadiah';

  @override
  String get libroJonas => 'Jonah';

  @override
  String get libroMiqueas => 'Micah';

  @override
  String get libroNahum => 'Nahum';

  @override
  String get libroHabacuc => 'Habakkuk';

  @override
  String get libroSofonias => 'Zephaniah';

  @override
  String get libroHageo => 'Haggai';

  @override
  String get libroZacarias => 'Zechariah';

  @override
  String get libroMalaquias => 'Malachi';

  @override
  String get libroMateo => 'Matthew';

  @override
  String get libroMarcos => 'Mark';

  @override
  String get libroLucas => 'Luke';

  @override
  String get libroJuan => 'John';

  @override
  String get libroHechos => 'Acts';

  @override
  String get libroRomanos => 'Romans';

  @override
  String get libro1Corintios => '1 Corinthians';

  @override
  String get libro2Corintios => '2 Corinthians';

  @override
  String get libroGalatas => 'Galatians';

  @override
  String get libroEfesios => 'Ephesians';

  @override
  String get libroFilipenses => 'Philippians';

  @override
  String get libroColosenses => 'Colossians';

  @override
  String get libro1Tesalonicenses => '1 Thessalonians';

  @override
  String get libro2Tesalonicenses => '2 Thessalonians';

  @override
  String get libro1Timoteo => '1 Timothy';

  @override
  String get libro2Timoteo => '2 Timothy';

  @override
  String get libroTito => 'Titus';

  @override
  String get libroFilemon => 'Philemon';

  @override
  String get libroHebreos => 'Hebrews';

  @override
  String get libroSantiago => 'James';

  @override
  String get libro1Pedro => '1 Peter';

  @override
  String get libro2Pedro => '2 Peter';

  @override
  String get libro1Juan => '1 John';

  @override
  String get libro2Juan => '2 John';

  @override
  String get libro3Juan => '3 John';

  @override
  String get libroJudas => 'Jude';

  @override
  String get libroApocalipsis => 'Revelation';

  @override
  String get capitulosTab => 'Chapters';

  @override
  String get informacionTab => 'Information';

  @override
  String get acercaDelLibro => 'About the book';

  @override
  String get errorCargarInfoLibro => 'Could not load book information.';

  @override
  String get escucharBiblia => 'Listen to the Bible';

  @override
  String get sinInternetAudio => 'No internet connection to play the audio.';

  @override
  String audioDramatizadoProximamente(String nombre) {
    return 'The dramatized audio of $nombre will be available soon.';
  }

  @override
  String finLecturaAudio(String libro, String capitulo) {
    return 'End of audio reading for $libro $capitulo';
  }

  @override
  String audioCapituloTitulo(String libro, String capitulo) {
    return '$libro $capitulo (Audio)';
  }

  @override
  String get eliminadoDeFavoritos => 'Removed from favorites';

  @override
  String get sinFavoritos => 'No favorites';

  @override
  String get sinFavoritosDesc =>
      'Tap the bookmark icon on any chapter to save it here and access it quickly.';

  @override
  String guardadoEl(String fecha) {
    return 'Saved on $fecha';
  }

  @override
  String get desdeFavoritos => 'From Favorites';

  @override
  String get eliminarNotaTitulo => 'Delete note';

  @override
  String get seguroEliminarNota =>
      'Are you sure you want to permanently delete this note?';

  @override
  String get eliminar => 'Delete';

  @override
  String get notaEliminadaCorrectamente => 'Note deleted successfully';

  @override
  String get aunNoTienesNotas => 'You don\'t have any notes yet';

  @override
  String get aunNoTienesNotasDesc =>
      'Your biblical reflections and notes will appear here. Open any chapter and tap the Note icon to start.';

  @override
  String get nuevaSolicitud => 'New request';

  @override
  String get tipoSolicitudLabel => 'Request type';

  @override
  String get seleccionaUnaOpcion => 'Select an option';

  @override
  String get asunto => 'Subject';

  @override
  String get asuntoPlaceholder => 'Write a brief subject';

  @override
  String get asuntoObligatorio => 'Subject is required';

  @override
  String get describeComoAyudarte => 'Describe how we can help you';

  @override
  String get descripcionObligatoria => 'Description is required';

  @override
  String get detallesSolicitudPlaceholder =>
      'Tell us the details of your request';

  @override
  String get telefonoObligatorio => 'Phone number is required';

  @override
  String get telefonoInvalido => 'Enter a valid phone number';

  @override
  String get solicitudPrivada => 'Private request';

  @override
  String get solicitudPrivadaDesc =>
      'Only the pastoral team will be able to see it';

  @override
  String get general => 'General';

  @override
  String get completaCamposObligatorios =>
      'Please complete all required fields.';

  @override
  String get enviarSolicitud => 'Send Request';

  @override
  String get realizaTuAporte => 'Make your contribution';

  @override
  String get errorCargarDatos => 'Error loading data';

  @override
  String get tipoDonacion => 'Donation type';

  @override
  String get seleccionaElMonto => 'Select the amount';

  @override
  String get otroMonto => 'Other amount';

  @override
  String get frecuencia => 'Frequency';

  @override
  String get frecuenciaUnaSolaVez => 'One-time';

  @override
  String get frecuenciaMensual => 'Monthly';

  @override
  String get metodoDePago => 'Payment method';

  @override
  String get transferencia => 'Bank transfer';

  @override
  String get donacionAnonima => 'Anonymous donation';

  @override
  String get donacionAnonimaDesc =>
      'Your name will not be visible in listings.';

  @override
  String get continuarDeFormaSegura => 'Continue securely';

  @override
  String get cuentaCopiadaPortapapeles => 'Account copied to clipboard!';

  @override
  String get metodosTitulo => 'PAYMENT';

  @override
  String get dePagoTitulo => 'methods';

  @override
  String get viaTransferencia => 'VIA BANK TRANSFER';

  @override
  String get aceptamosTransferenciasDesc =>
      'We accept bank transfers from\nany bank in the Dominican Republic.';

  @override
  String get tuPagoEstaSeguro => 'YOUR PAYMENT IS SECURE';

  @override
  String get tuPagoSeguroDesc =>
      'Trust, speed, and security in every transaction.';

  @override
  String get revisaTuDonacion => 'Review your donation';

  @override
  String get resumenDeTuDonacion => 'Donation summary';

  @override
  String get para => 'To';

  @override
  String get concepto => 'Purpose';

  @override
  String get monto => 'Amount';

  @override
  String get tuDonacionEsSegura => 'Your donation is secure';

  @override
  String get conexionCifradaProteccion =>
      'We use an encrypted connection to protect\nyour information and your contribution.';

  @override
  String get confirmarDonacion => 'Confirm donation';

  @override
  String get confirmarTransaccion => 'Confirm Transaction';

  @override
  String get transaccionValidaraOdoo =>
      'The transaction will be validated through the secure Odoo gateway.';

  @override
  String get totalAProcesar => 'Total to process';

  @override
  String get pagarYValidar => 'Pay and Validate';

  @override
  String get validandoConOdoo => 'Validating with Odoo...';

  @override
  String get registrandoOrdenConfirmandoPago =>
      'We are registering your order and confirming payment.';

  @override
  String get aporteExitoso => 'Contribution Successful!';

  @override
  String referenciaOdoo(String orden) {
    return 'Odoo Reference: $orden';
  }

  @override
  String get contribucionValidadaRecibo =>
      'Your contribution has been validated and the digital receipt was sent to your email.';

  @override
  String get finalizar => 'Finish';

  @override
  String get realizarUnAporte => 'Make a contribution';

  @override
  String get cuantoDeseasAportar => 'How much do you wish to contribute?';

  @override
  String get mensajeDeApoyo => 'Support message';

  @override
  String get escribeMensajeOpcional => 'Write an optional message...';

  @override
  String get mostrarAporteAnonimo => 'Show my contribution as anonymous';

  @override
  String get continuarConElAporte => 'Continue with contribution';

  @override
  String get proyectoTag => 'PROJECT';

  @override
  String conceptoProyecto(String titulo) {
    return 'Project: $titulo';
  }

  @override
  String get estadoProgramada => 'Scheduled';

  @override
  String get estadoRecibida => 'Received';

  @override
  String get estadoEnRevision => 'Under review';

  @override
  String get estadoConfirmada => 'Confirmed';

  @override
  String get estadoEnProceso => 'In process';

  @override
  String get fechaMartesHora => 'Tuesday · 4:00 PM';

  @override
  String get fechaJuevesHora => 'Thursday · 5:30 PM';

  @override
  String get fechaViernesHora => 'Friday · 10:00 AM';

  @override
  String get detalleOrientacionPastoral =>
      'Spiritual accompaniment and in-person pastoral guidance appointment with the head pastor.';

  @override
  String get detallePeticionOracion =>
      'Intercession request for speedy recovery of health and family well-being in prayer service.';

  @override
  String get detalleAyudaComunitaria =>
      'Request for a basic food basket and solidarity support for a family in need.';

  @override
  String get detalleConsejeriaFamiliar =>
      'Family counseling session and guided dialogue by the church ministerial team.';

  @override
  String get detalleVisitaEnfermos =>
      'Home visit from the pastoral visitation team for ministration and prayer for healing.';

  @override
  String idOdoo(String id) {
    return 'Odoo ID: $id';
  }

  @override
  String get detalleDeLaSolicitud => 'Request details:';

  @override
  String get solicitudRegistradaAsignada =>
      'Request registered and assigned to ministerial team.';

  @override
  String get estadoCompletada => 'Completed';

  @override
  String get fechaDiezmoMock => 'Oct 15, 2026 · 10:30 AM';

  @override
  String get metodoTarjetaDebitoVisa => 'Debit card (Visa)';

  @override
  String get destinoFondoGeneralMinisterial => 'General Ministerial Fund';

  @override
  String get detalleDiezmoMock =>
      'Monthly tithe contribution for church and pastoral ministry support.';

  @override
  String get fechaOfrendaMock => 'Oct 08, 2026 · 7:15 PM';

  @override
  String get metodoTransferenciaACH => 'ACH Transfer';

  @override
  String get destinoCultoAdoracionDominical => 'Sunday Worship Service';

  @override
  String get detalleOfrendaMock =>
      'Voluntary offering of gratitude and worship during praise service.';

  @override
  String get fechaCampanaMock => 'Sep 28, 2026 · 4:20 PM';

  @override
  String get metodoTarjetaCreditoMastercard => 'Credit card (Mastercard)';

  @override
  String get destinoCampanaMock => 'Campaign \"Building Hope 2026\"';

  @override
  String get detalleCampanaMock =>
      'Special voluntary contribution for church remodeling and maintenance works.';

  @override
  String get fechaAyudaMock => 'Sep 14, 2026 · 11:00 AM';

  @override
  String get metodoPayPalSaldoDigital => 'PayPal / Digital balance';

  @override
  String get destinoProgramaManosQueBendicen => 'Program \"Hands that Bless\"';

  @override
  String get detalleAyudaMock =>
      'Charitable donation for basic food baskets and medicine for vulnerable families.';

  @override
  String get nuevaDonacion => 'New donation';

  @override
  String get montoAportado => 'Amount contributed:';

  @override
  String get fechaYHora => 'Date and time:';

  @override
  String get metodo => 'Method:';

  @override
  String get destino => 'Destination:';

  @override
  String get detalleDelAporte => 'Contribution details:';

  @override
  String get aporteVoluntarioRegistrado =>
      'Voluntary contribution registered in ATRIO.';

  @override
  String get errorGuardarSeleccionLocal => 'Could not save selection locally.';

  @override
  String get queremosConocerte => 'We want to know you';

  @override
  String get conCualTradicionTeIdentificas =>
      'Which faith tradition do you identify with?';

  @override
  String get continuar => 'Continue';

  @override
  String get noDenominacional => 'Non-denominational';

  @override
  String get otra => 'Other';

  @override
  String get prefieroIndicarloDespues => 'I prefer to indicate later';

  @override
  String get gpsDesactivadoMensaje =>
      'GPS is turned off. Turn it on to find churches near you.';

  @override
  String get permisoUbicacionNoConcedido =>
      'Location permission not granted. Default location will be shown.';

  @override
  String get permisosUbicacionDenegadosPermanentemente =>
      'Location permissions permanently denied in settings.';

  @override
  String errorServidorCodigo(int codigo) {
    return 'Server error: $codigo';
  }

  @override
  String noSeEncontraronIglesiasCercanas(String query) {
    return 'No nearby churches found for \"$query\".';
  }

  @override
  String get errorConexionInternet =>
      'Connection error. Please check your internet.';

  @override
  String get ubicacionExacta => 'Exact location';

  @override
  String get seleccionaTuIglesia => 'Select your church';

  @override
  String get buscarIglesiaPlaceholder => 'Search church or denomination...';

  @override
  String get abiertoAhora => 'Open now';

  @override
  String get cerrado => 'Closed';

  @override
  String get seleccionarIglesia => 'Select church';

  @override
  String get codigoPlusNoDisponible => 'Plus Code not available';

  @override
  String get distanciaAproximadaDefault => '1.8 km away';

  @override
  String get servicioDeBienvenida => 'Welcome Service';

  @override
  String get diaHoraDomingo10am => 'Sunday · 10:00 AM';

  @override
  String get estadoCerradoAbreDomingo => 'Closed · Opens Sunday at 10 AM';

  @override
  String get diaDomingo => 'Sunday';

  @override
  String get cultoDominical10am => '10:00 AM · Sunday Worship';

  @override
  String get diaMiercoles => 'Wednesday';

  @override
  String get estudioBiblico730pm => '7:30 PM · Bible Study';

  @override
  String get bienvenidoNuevaComunidad => 'Welcome to your new community!';

  @override
  String get descripcionRegistroIglesia =>
      'You have successfully registered in this church through ATRIO.';

  @override
  String get filtroTodas => 'All';

  @override
  String get filtroNoLeidas => 'Unread';

  @override
  String get categoriaEventos => 'Events';

  @override
  String get notiHorarioServicioTitulo => 'Service time change';

  @override
  String get notiHorarioServicioResumen =>
      'Prayer Wednesday · 7:00 PM in the Main Sanctuary.';

  @override
  String get notiHorarioServicioCuerpo =>
      'Dear congregation: Due to pastoral work and preparations for this month\'s activities, our intercession and Bible study service this Wednesday will start 30 minutes earlier, beginning at 7:00 PM. We invite you to arrive early with your family.';

  @override
  String get notiRetiroTitulo => 'Registrations open: Retreat 2026';

  @override
  String get notiRetiroResumen =>
      'Limited spots available for youth and families.';

  @override
  String get notiRetiroCuerpo =>
      'Reserve your spot now! Registrations have officially opened for the Annual Retreat \"Life & Faith 2026\" at Los Pinos Camp. You can register directly from the Events section in the app.';

  @override
  String get notiCampanaTitulo => 'Solidarity campaign \"Hands that Bless\"';

  @override
  String get notiCampanaResumen =>
      'Receipt of food supplies and donations this weekend.';

  @override
  String get notiCampanaCuerpo =>
      'We will be collecting non-perishable food, coats, and hygiene kits in the main lobby before each Sunday service. Your generous contribution will bless more than 50 vulnerable families in our community.';

  @override
  String get fechaHoy => 'Today';

  @override
  String get fechaAyer => 'Yesterday';

  @override
  String get fechaHace2Dias => '2 days ago';

  @override
  String get hora1030am => '10:30 AM';

  @override
  String get hora415pm => '4:15 PM';

  @override
  String get hora900am => '9:00 AM';

  @override
  String get remitenteAdmin => 'ATRIO Administration';

  @override
  String get remitenteEventos => 'Events Committee';

  @override
  String get remitentePastoralSocial => 'Social Ministry';

  @override
  String get todasNotificacionesLeidas =>
      'All notifications have been marked as read';

  @override
  String notificacionEliminada(String titulo) {
    return 'Notification \"$titulo\" deleted';
  }

  @override
  String get deshacer => 'Undo';

  @override
  String get borrarAvisos => 'Delete notices';

  @override
  String get confirmarBorrarTodasMensaje =>
      'Do you want to delete all received notifications? You can undo this action immediately if you wish.';

  @override
  String get borrarTodas => 'Delete all';

  @override
  String get todasNotificacionesEliminadas =>
      'All notifications have been deleted';

  @override
  String get avisosEjemploRestaurados => 'Sample notices restored';

  @override
  String get marcarTodasComoLeidas => 'Mark all as read';

  @override
  String get buscarEnAvisosPlaceholder => 'Search notices...';

  @override
  String get avisosDeLaComunidad => 'Community notices';

  @override
  String conteoNoLeidas(int conteo) {
    return '$conteo unread';
  }

  @override
  String get deslizaAvisoParaEliminar =>
      'Swipe a notice to the left to delete it';

  @override
  String get noHayAvisosMomento => 'No notices at this time';

  @override
  String get avisosOdooApareceranAqui =>
      'Notices published in Odoo will appear here.';

  @override
  String get restaurarAvisosEjemplo => 'Restore sample notices';

  @override
  String get eliminarAviso => 'Delete notice';

  @override
  String get eliminarEsteAviso => 'Delete this notice';

  @override
  String get personalizaTuExperienciaAtrio =>
      'Customize your experience in ATRIO';

  @override
  String get idiomaYRegion => 'Language and Region';

  @override
  String get aparienciaYTema => 'Appearance and Theme';

  @override
  String get modoDeVisualizacion => 'Display mode';

  @override
  String get temaClaro => 'Light';

  @override
  String get temaOscuro => 'Dark';

  @override
  String get temaSistema => 'System';

  @override
  String get transicionDeNovedades => 'News Transition';

  @override
  String get bannerPrincipalHero => 'Main banner (HeroBannerCard)';

  @override
  String segundosAbrev(int segundos) {
    return '$segundos sec';
  }

  @override
  String get efectoDesvanecimientoBanner =>
      'Smooth fade effect between verse, word, and worship services.';

  @override
  String get segundosMinimo => '3 sec';

  @override
  String get segundosPredeterminado => '5 sec (Default)';

  @override
  String get segundosMaximo => '10 sec';

  @override
  String get notificacionesYRecordatorios => 'Notifications and Reminders';

  @override
  String get recibePorcionBiblica => 'Receive a biblical portion every morning';

  @override
  String get horaDelRecordatorio => 'Reminder time';

  @override
  String get palabraDelDia => 'Word of the day';

  @override
  String get reflexionDevocionalDiario =>
      'Daily reflection and devotional for your faith';

  @override
  String get cultosEnVivo => 'Live worship services';

  @override
  String get alertaTransmisionDirecto => 'Alert when a live broadcast starts';

  @override
  String get anunciosEventosGlobales => 'Global announcements and events';

  @override
  String get conferenciasConciertosAvisos =>
      'Conferences, concerts, and church notices';

  @override
  String get lecturaDeLaBiblia => 'Bible Reading';

  @override
  String get versionPredeterminada => 'Default version';

  @override
  String get tamanoTextoLectura => 'Reading text size';

  @override
  String get ejemploTextoBiblia =>
      '\"Your word is a lamp to my feet and a light to my path.\" — Psalm 119:105';

  @override
  String get mantenerPantallaEncendida => 'Keep screen on';

  @override
  String get evitaBloqueoTelefonoBiblia =>
      'Prevents phone from locking while reading the Bible';

  @override
  String get emisorasYTransmisiones => 'Stations and Broadcasts';

  @override
  String get reproduccionAutomatica => 'Autoplay';

  @override
  String get iniciarRadioAlSintonizar => 'Start radio upon tuning into station';

  @override
  String get calidadAudioStreaming => 'Audio streaming quality';

  @override
  String get calidadAudioBaja => 'Low (64 kbps)';

  @override
  String get calidadAudioMedia => 'Medium (128 kbps)';

  @override
  String get calidadAudioAlta => 'High (256 kbps)';

  @override
  String get ahorroDeDatosSoloWifi => 'Data saver (Wi-Fi only)';

  @override
  String get reproducirDescargarSoloWifi =>
      'Play and download in high quality only with Wi-Fi';

  @override
  String get almacenamientoYMemoria => 'Storage and Memory';

  @override
  String get limpiarMemoriaCache => 'Clear cache memory';

  @override
  String get imagenesAudiosTemporales =>
      'Temporary images and audio (~18.4 MB)';

  @override
  String get limpiar => 'Clear';

  @override
  String get limpiarCacheTitulo => 'Clear cache memory?';

  @override
  String get limpiarCacheMensaje =>
      'Temporary images and files will be removed to free up storage. Your personal Bible notes and favorites will not be deleted.';

  @override
  String get memoriaCacheLiberadaExito => 'Cache memory successfully cleared';

  @override
  String get limpiarAhora => 'Clear now';

  @override
  String get restablecerAjustesPredeterminados => 'Reset default settings';

  @override
  String get restablecerConfiguracionTitulo => 'Reset settings?';

  @override
  String get restablecerConfiguracionMensaje =>
      'All app settings will return to their recommended initial values.';

  @override
  String get ajustesRestablecidosFabrica =>
      'Settings reset to factory defaults';

  @override
  String get restablecer => 'Reset';

  @override
  String get idiomaEspanolLatino => 'Spanish (Latin America)';

  @override
  String get idiomaInglesUSA => 'English (United States)';

  @override
  String get politicaDePrivacidad => 'Privacy Policy';

  @override
  String politicaPrivacidadIntro(String fecha) {
    return 'Last updated: $fecha\n\nWelcome to ATRIO (\"Live your Faith in community\"). We respect your privacy and are deeply committed to protecting your personal data and your spiritual journey.\n\nThis policy outlines how we collect, manage, protect, and safeguard your information.';
  }

  @override
  String get seccionInfoQueRecopilamos => '1. Information We Collect';

  @override
  String get parrafoInfoQueRecopilamos =>
      '• Account Data: When signing in or registering (email, Google Sign-In, or Apple ID), we securely store your name and email address.\n\n• Community and Profile Data: Phone number, Christian tradition, and church or community to which you are voluntarily linked to customize your church experience.\n\n• Local Device Storage: Your Bible study notes, favorite passages, personal settings, and browsing history are stored locally in SQLite. We do not share your private reflections with third parties.\n\n• Requests and Donations: We record the status of your prayer requests, pastoral inquiries, and donation or contribution receipts for solidarity projects to provide you with direct visibility and traceability.';

  @override
  String get seccionUsoServiciosTerceros => '2. Use of Third-Party Services';

  @override
  String get parrafoUsoServiciosTerceros =>
      'Our platform integrates with trusted technologies to deliver full functionality:\n\n• Google Play Services, Google Sign-In, and Sign in with Apple (Authentication and security).\n\n• Google Maps Platform (For accurate geographic location of churches, parishes, and community events on the interactive map).\n\n• Secure Payment Gateways (For reliable and encrypted receipt of offerings, tithes, and solidarity contributions).\n\n• YouTube and Broadcast Streamers (For religious services, live events, and radio broadcasts).';

  @override
  String get seccionRetencionYEliminacion => '3. Data Retention and Deletion';

  @override
  String get parrafoRetencionYEliminacion =>
      'We retain your account data while it remains active. In accordance with Apple App Store (5.1.1 v) and Google Play Console guidelines, you have an unconditional right to request the complete and permanent deletion of your account and personal data.\n\nYou can perform this action at any time using the \"Delete account and data\" option on the Profile screen, or by emailing soporte@atrioapp.com with the subject \"Account Deletion\".\n\nAll local SQLite records and backend associations will be permanently purged.';

  @override
  String get seccionPermisosDelDispositivo => '4. Device Permissions';

  @override
  String get parrafoPermisosDelDispositivo =>
      'ATRIO only requests permissions strictly required for its operation:\n\n• Location (GPS): Only used when accessing the map to show nearby churches and events.\n\n• Internet and Network Access: To synchronize requests, view live broadcasts, and validate contributions.\n\n• Notifications: For reminders of liturgical services, community events, and responses to requests.';

  @override
  String get terminosDeUsoTitulo => 'Terms of Use';

  @override
  String get parrafoTerminosDeUso =>
      '1. Conduct and community respect: ATRIO is a digital space of fellowship, mutual edification, and support for church ministries. The use of defamatory, fraudulent, or disrespectful language is strictly prohibited.\n\n2. Biblical and multimedia content: Biblical texts, station broadcasts, and shared videos respect the copyrights of their respective entities and ministries. Commercial exploitation outside the platform is prohibited.\n\n3. Donations and contributions: Contributions made through ATRIO go directly to the selected religious communities and solidarity projects. The app acts as a transparent and secure facilitating bridge.';

  @override
  String get aceptacionTerminosPoliticas =>
      'By using ATRIO, you accept these terms and community guidelines.';

  @override
  String get noSePudoCargarVersiculo => 'Could not load the verse.';

  @override
  String get montoPersonalizado => 'Custom amount';

  @override
  String get montoADonarMoneda => 'Amount to donate (RD\$)';

  @override
  String get ingresaUnMonto => 'Enter an amount';

  @override
  String get montoInvalido => 'Invalid amount';

  @override
  String get elMinimoEs500 => 'The minimum is RD\$500';

  @override
  String get elMaximoEs1000000 => 'The maximum is RD\$1,000,000';

  @override
  String get confirmar => 'Confirm';

  @override
  String get confirmarSolicitudTitulo => 'Confirm Request';

  @override
  String get solicitudEnviadaEquipoPastoral =>
      'Your request will be sent to the church\'s pastoral team.';

  @override
  String get tipo => 'Type';

  @override
  String get privada => 'Private';

  @override
  String get publica => 'Public';

  @override
  String get enviandoAOdoo => 'Sending to Odoo...';

  @override
  String get registrandoSolicitudSistema =>
      'We are registering your request in the system.';

  @override
  String get solicitudEnviadaExito => 'Request Sent!';

  @override
  String get solicitudRegistradaCorrectamente =>
      'Your request has been successfully registered. The team will contact you soon.';

  @override
  String get leerReflexion => 'Read reflection';

  @override
  String get verVersiculo => 'View verse';

  @override
  String get enVivoAhora => 'Live now';

  @override
  String get enVivo => 'LIVE';

  @override
  String citaBase(String cita) {
    return 'Base verse: $cita';
  }

  @override
  String get entendidoAmen => 'Understood · Amen';

  @override
  String get upgraderTitulo => 'Update App?';

  @override
  String upgraderMensaje(
    String appName,
    String currentAppStoreVersion,
    String currentInstalledVersion,
  ) {
    return 'A new version of $appName is available! Version $currentAppStoreVersion is now available-you have $currentInstalledVersion.';
  }

  @override
  String get upgraderPregunta => 'Would you like to update it now?';

  @override
  String get upgraderNotasVersion => 'Release Notes';

  @override
  String get upgraderBotonActualizar => 'Update Now';

  @override
  String get upgraderBotonMasTarde => 'Later';

  @override
  String get upgraderBotonIgnorar => 'Ignore';

  @override
  String get busquedaPorRadio => 'By radius';

  @override
  String get busquedaNacional => 'National';

  @override
  String get cargandoMasIglesias => 'Loading more communities...';

  @override
  String get finDeResultados => 'You have reached the end of results';

  @override
  String get escribeAlMenos3Caracteres => 'Type at least 3 characters';

  @override
  String get cambiarPais => 'Change country';

  @override
  String get todoElPais => 'Across the country';

  @override
  String get iglesiasEnMapa => 'Churches on Map';

  @override
  String radioKmEnPais(String km, String pais) {
    return 'Radius < $km km in $pais';
  }

  @override
  String todoElPaisConBandera(String pais, String bandera) {
    return 'All $pais $bandera';
  }

  @override
  String enTodoPais(String pais) {
    return 'Across $pais';
  }

  @override
  String buscarEnPaisPlaceholder(String pais) {
    return 'Search in $pais (e.g. Cathedral...)';
  }

  @override
  String get buscarEnRadioPlaceholder =>
      'Search church or denomination in radius...';

  @override
  String verMasPaginacion(String mostradas, String total) {
    return 'See 15 more ($mostradas of $total)';
  }

  @override
  String totalIglesiasEnMapa(String total) {
    return '$total churches on map';
  }

  @override
  String get tuPais => 'Your country';

  @override
  String busquedaExclusivaEn(String pais) {
    return 'Exclusive search in: $pais';
  }

  @override
  String get misPedidos => 'My Orders';

  @override
  String get historialComprasTienda => 'Purchase history in the Atrio Store';

  @override
  String get pedidosActivos => 'Active';

  @override
  String pedidosActivosConConteo(int count) {
    return 'Active ($count)';
  }

  @override
  String get pedidosHistorial => 'History';

  @override
  String pedidosHistorialConConteo(int count) {
    return 'History ($count)';
  }

  @override
  String get explorarTienda => 'Explore Store';

  @override
  String get noTienesPedidosActivos => 'You have no active orders';

  @override
  String get noTienesPedidosAnteriores => 'You have no previous orders';

  @override
  String get pedidosActivosDesc =>
      'Your recent purchases from the ATRIO store will appear here so you can track delivery.';

  @override
  String get pedidosAnterioresDesc =>
      'When your orders are completed or delivered, you will be able to check them in this history.';

  @override
  String pedidoItemTitulo(String nombre) {
    return 'Order $nombre';
  }

  @override
  String get detalleDeOrden => 'Order Details';

  @override
  String get referenciaOdooColon => 'Odoo Reference:';

  @override
  String get fechaDelPedido => 'Order date:';

  @override
  String get totalAPagar => 'Total amount:';

  @override
  String get articulosIncluidos => 'Included items:';

  @override
  String unidadesProducto(int cantidad) {
    return '$cantidad unit(s).';
  }

  @override
  String get verMisPedidos => 'View My Orders';

  @override
  String get estadoPagoEnVerificacion => 'Payment in verification';

  @override
  String get estadoPedidoConfirmado => 'Confirmed';

  @override
  String get estadoPedidoCompletado => 'Completed';

  @override
  String get estadoPedidoCancelado => 'Cancelled';

  @override
  String get estadoPedidoBorrador => 'Draft';

  @override
  String get estadoPedidoEnviado => 'Sent';

  @override
  String get registroTitulo => 'Register';

  @override
  String get creaTuCuenta => 'Create your account';

  @override
  String get creaTuCuentaSubtitulo =>
      'Join a community to live and share your faith.';

  @override
  String get escribeTuNombre => 'Enter your full name';

  @override
  String get numeroTelefonoLabel => 'Phone number';

  @override
  String get contrasenaLabel => 'Password';

  @override
  String get confirmarContrasenaLabel => 'Confirm password';

  @override
  String get aceptoLos => 'I accept the ';

  @override
  String get yLa => ' and the ';

  @override
  String get crearCuentaBoton => 'Create account';

  @override
  String get yaTienesCuenta => 'Already have an account? ';

  @override
  String get iniciarSesionEnlace => 'Log in';

  @override
  String get errorNombreRequerido => 'Please enter your full name.';

  @override
  String get errorCorreoValido => 'Please enter a valid email address.';

  @override
  String get errorTelefonoRequerido => 'Please enter your phone number.';

  @override
  String get errorContrasenaMinima =>
      'Password must be at least 6 characters long.';

  @override
  String get errorContrasenasNoCoinciden => 'Passwords do not match.';

  @override
  String get errorAceptarTerminos =>
      'You must accept the Terms of Use and Privacy Policy.';

  @override
  String get registroExitosoTitulo => 'Account Registered!';

  @override
  String get registroExitosoMensaje =>
      'Your account has been created successfully in Odoo. The church administrator will validate your membership.';

  @override
  String get iniciarSesionAhora => 'Log in now';

  @override
  String get comprobanteTransferencia => 'Transfer receipt';

  @override
  String get adjuntarComprobante => 'Attach receipt';

  @override
  String get cambiarComprobante => 'Change receipt';

  @override
  String get comprobanteAdjuntado => 'Receipt attached successfully';

  @override
  String get subirComprobanteDesc =>
      'Attach a photo or screenshot of your bank receipt to validate your contribution quickly.';

  @override
  String get tomarFoto => 'Take photo';

  @override
  String get galeria => 'Photo gallery';

  @override
  String get eliminarComprobante => 'Remove receipt';

  @override
  String get redirigiendoPaypal => 'Redirecting to secure PayPal gateway...';

  @override
  String get donacionPendienteVerificacion =>
      'Your donation has been recorded in Odoo and is pending accounting verification.';

  @override
  String errorProcesarDonacion(String error) {
    return 'An error occurred while processing donation: $error';
  }

  @override
  String get publicacionesIglesia => 'Church Publications';

  @override
  String get sinPublicacionesRecientes =>
      'There are no recent publications from your community.';

  @override
  String get verPublicacion => 'View publication';

  @override
  String get cerrarPublicacion => 'Close';

  @override
  String get novedadesComunidad =>
      'News and updates from your church community';

  @override
  String get sinNotificaciones => 'You have no notifications at this time';

  @override
  String get sinNotificacionesDesc =>
      'Here you will see announcements sent by your church to the congregation.';

  @override
  String get cargandoPublicaciones => 'Loading publications...';

  @override
  String get cargandoNotificaciones => 'Loading notifications...';

  @override
  String get publicidad => 'Sponsored';

  @override
  String get verMas => 'See more';

  @override
  String busquedaEnTodoPaisConBandera(String pais, String bandera) {
    return 'Search across $pais $bandera';
  }

  @override
  String get comunidadesCristianasCercanas => 'Nearby Christian communities';

  @override
  String get radioEtiqueta => 'Radius:';

  @override
  String get exploraTemplosSubtitulo =>
      'Explore churches, routes and live details';

  @override
  String conteoResultadosDeTotal(String mostradas, String total) {
    return '$mostradas of $total';
  }

  @override
  String radioMenorQueKm(String km) {
    return 'Radius < $km km';
  }

  @override
  String noSeEncontraronIglesiasConTermino(String termino) {
    return 'No churches found with \"$termino\" in their name.';
  }

  @override
  String noSeEncontraronIglesiasRadioEnPais(String km, String pais) {
    return 'No churches found within $km km in $pais.';
  }

  @override
  String noSeEncontraronIglesiasEnPais(String pais) {
    return 'No churches found in $pais.';
  }

  @override
  String get noSePudieronCargarIglesias =>
      '😕 Could not load churches.\nCheck your internet connection and try again.';

  @override
  String get localizandoComunidades => 'Locating Christian communities...';

  @override
  String get pedidosInvitadoDesc =>
      'In guest mode, orders are not recorded. Sign in to view your order history.';

  @override
  String get notificacionesInvitadoDesc =>
      'In guest mode, personal notices and notifications are not available. Sign in to stay up to date with your community.';

  @override
  String get omitir => 'Skip';

  @override
  String get errorConexionServidor => 'Server connection error';

  @override
  String get errorCargarSolicitudesDesc =>
      'A temporary issue occurred while retrieving your requests from the server. You can try again.';

  @override
  String get reintentarConexionServidor => 'Retry server connection';

  @override
  String get modoLocalAviso =>
      'Showing requests saved on this device. Failed to sync with the server.';
}
