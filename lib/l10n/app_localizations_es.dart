// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get bienvenida => 'Bienvenido a Atrio';

  @override
  String saludo(String nombre) {
    return 'Hola, $nombre';
  }

  @override
  String get appTitulo => 'ATRIO';

  @override
  String get lema => 'Vive tu Fe en comunidad';

  @override
  String get subtituloBienvenida => 'Un espacio para vivir y compartir tu fe';

  @override
  String get accesoRapidoSeguro => 'Acceso Rápido y Seguro';

  @override
  String get ingresaUnToque => 'Ingresa en un solo toque';

  @override
  String get continuarConGoogle => 'Continuar con Google';

  @override
  String get continuarConApple => 'Continuar con Apple';

  @override
  String get explorarInvitado => 'Explorar como invitado';

  @override
  String get avisoPrivacidadOdoo =>
      'Al continuar, vinculas tu cuenta de forma segura con el servidor eclesial de ATRIO en Odoo ERP.';

  @override
  String get terminosDeUso => 'Términos de uso';

  @override
  String get politicaPrivacidad => 'Política de privacidad';

  @override
  String get privacidad => 'Privacidad';

  @override
  String get eliminarMisDatos => 'Eliminar mis datos';

  @override
  String get eliminarCuentaYDatos => 'Eliminar cuenta y datos';

  @override
  String get solicitarEliminacion => 'Solicitar eliminación';

  @override
  String get opcionNoDisponible => 'Opción no disponible';

  @override
  String get entendido => 'Entendido';

  @override
  String get inicio => 'Inicio';

  @override
  String get perfil => 'Perfil';

  @override
  String get biblia => 'Biblia';

  @override
  String get eventos => 'Eventos';

  @override
  String get donaciones => 'Donaciones';

  @override
  String get solicitudes => 'Solicitudes';

  @override
  String get notificaciones => 'Notificaciones';

  @override
  String get configuracion => 'Configuración';

  @override
  String get ajustes => 'Ajustes';

  @override
  String get idiomaPreferido => 'Idioma preferido';

  @override
  String get seleccionarIdioma => 'Seleccionar Idioma';

  @override
  String get modoVisualizacion => 'Modo de visualización';

  @override
  String get claro => 'Claro';

  @override
  String get oscuro => 'Oscuro';

  @override
  String get sistema => 'Sistema';

  @override
  String get guardar => 'Guardar';

  @override
  String get cancelar => 'Cancelar';

  @override
  String get cerrar => 'Cerrar';

  @override
  String get deseasSalirAtrio => '¿Deseas salir de atrio?';

  @override
  String get presionaSalirCerrar =>
      'Presiona \"Salir\" para cerrar la aplicación.';

  @override
  String get salir => 'Salir';

  @override
  String get iglesia => 'Iglesia';

  @override
  String get explorar => 'Explorar';

  @override
  String get radio => 'Radio';

  @override
  String get miIglesia => 'Mi Iglesia';

  @override
  String get tocaParaCambiar => '· Toca para cambiar';

  @override
  String get sinIglesiaSeleccionada => 'Sin iglesia seleccionada';

  @override
  String get proyectosSolidarios => 'Proyectos\nsolidarios';

  @override
  String get tienda => 'Tienda';

  @override
  String get libros => 'Libros';

  @override
  String get videos => 'Videos';

  @override
  String get nuevoAviso => 'Nuevo aviso';

  @override
  String get cambioHorarioAviso => 'Cambio de horario · Miércoles, 7:00 p. m.';

  @override
  String get categoriaServicios => 'Servicios';

  @override
  String get inscripcionesAbiertas => 'Inscripciones abiertas';

  @override
  String get retiroAnualAviso => 'Retiro Anual 2026 · Cupos limitados';

  @override
  String get categoriaComunidad => 'Comunidad';

  @override
  String get accionSolidaria => 'Acción solidaria';

  @override
  String get campanaDonacionesAviso =>
      'Campaña \"Manos que Bendicen\" · Donaciones';

  @override
  String get anunciosYConciertos => 'ANUNCIOS & CONCIERTOS';

  @override
  String get cargandoNovedades => 'Cargando novedades...';

  @override
  String infoArtistaEnviada(String artista) {
    return 'Información sobre \"$artista\" enviada.';
  }

  @override
  String noSePudoAbrirMarcador(String telefono) {
    return 'No se pudo abrir el marcador con el número $telefono';
  }

  @override
  String get noSePudoAbrirNavegacion =>
      'No se pudo abrir la aplicación de navegación.';

  @override
  String noSePudoAbrirEnlace(String url) {
    return 'No se pudo abrir el enlace $url';
  }

  @override
  String get compartirUbicacion => 'Compartir ubicación';

  @override
  String get plusCodeCopiadoPregunta =>
      'El Plus Code ha sido copiado al portapapeles. ¿Deseas compartirlo directamente?';

  @override
  String plusCodeCopiadoSnack(String plusCode) {
    return 'Plus Code copiado: $plusCode';
  }

  @override
  String get correo => 'Correo';

  @override
  String get reintentar => 'Reintentar';

  @override
  String get cambiarDeIglesia => 'Cambiar de iglesia';

  @override
  String get exploraYSeleccionaComunidad =>
      'Explora y selecciona otra comunidad';

  @override
  String get llamar => 'Llamar';

  @override
  String get comoLlegar => 'Cómo llegar';

  @override
  String get sitioWeb => 'Sitio web';

  @override
  String get verAhora => 'Ver ahora';

  @override
  String get horariosDeServicio => 'Horarios de servicio';

  @override
  String get ubicacionYContacto => 'Ubicación y contacto';

  @override
  String get direccion => 'Dirección';

  @override
  String get telefono => 'Teléfono';

  @override
  String get avisos => 'Avisos';

  @override
  String get encuentraTuFeEn10Km => 'Encuentra tu Fe ideal en 10 km';

  @override
  String get buscarIglesiasPlaceholder => 'Ej. Iglesia cristiana, Bautista...';

  @override
  String get catolica => 'Católica';

  @override
  String get evangelica => 'Evangélica';

  @override
  String get pentecostal => 'Pentecostal';

  @override
  String get bautista => 'Bautista';

  @override
  String get adventista => 'Adventista';

  @override
  String get visualizaIglesiasEnMapa => 'Visualiza las iglesias en el Mapa';

  @override
  String get comunidadesSugeridas => 'Comunidades sugeridas';

  @override
  String get noSeEncontraronIglesias10km =>
      'No se encontraron iglesias a menos de 10 km.';

  @override
  String get gpsDesactivado =>
      'El GPS está desactivado. Por favor, enciéndelo.';

  @override
  String get permisosUbicacionDenegados => 'Permisos de ubicación denegados.';

  @override
  String get permisosUbicacionPermanentemente =>
      'Permisos de ubicación denegados permanentemente en tu dispositivo.';

  @override
  String get obteniendoUbicacionEspera =>
      'Obteniendo tu ubicación, por favor intenta en un momento...';

  @override
  String get errorCargarMapa =>
      '😕 ¡Ups! No se pudo cargar el Mapa\n\n📡 Revisa tu conexión a internet e inténtalo de nuevo';

  @override
  String get sinNombre => 'Sin nombre';

  @override
  String get comunidadCristiana => 'Comunidad cristiana';

  @override
  String aDistanciaKm(String distancia) {
    return 'A $distancia km';
  }

  @override
  String get emisorasCristianas => 'Emisoras Cristianas';

  @override
  String get buscarEmisorasPlaceholder =>
      'Buscar por nombre, denominación, ciudad...';

  @override
  String get todosLosPaises => 'Todos los países';

  @override
  String get otrosPaises => 'Otros países';

  @override
  String get todos => 'Todos';

  @override
  String get espanol => 'Español';

  @override
  String get ingles => 'Inglés';

  @override
  String mostrandoSoloFavoritas(String total) {
    return 'Mostrando solo favoritas ($total)';
  }

  @override
  String get verTodas => 'Ver todas';

  @override
  String sinFavoritasEnPais(String pais) {
    return 'No tienes emisoras favoritas guardadas en $pais.\n\nToca el botón de corazón arriba para ver todas las emisoras.';
  }

  @override
  String get sinFavoritasAun =>
      'No tienes emisoras favoritas guardadas todavía.\n\nToca el botón de corazón arriba para ver todas las emisoras.';

  @override
  String noEmisorasCoincidencia(String busqueda) {
    return 'No se encontraron emisoras que coincidan con \"$busqueda\".';
  }

  @override
  String noEmisorasDisponiblesPais(String pais) {
    return 'No se encontraron emisoras disponibles para $pais.';
  }

  @override
  String get verTodasLasEmisoras => 'Ver todas las emisoras';

  @override
  String get sintonizandoAudio => 'Sintonizando audio...';

  @override
  String enVivoConDenominacion(String denominacion, String frecuencia) {
    return 'En vivo · $denominacion ($frecuencia)';
  }

  @override
  String enVivoFrecuencia(String frecuencia) {
    return 'En vivo · $frecuencia';
  }

  @override
  String get emisora => 'Emisora';

  @override
  String get errorEmisoraNoDisponible =>
      'Error: La emisora no está disponible en este momento.';

  @override
  String get sinInternetSintonizar =>
      'No hay conexión a internet para sintonizar la emisora.';

  @override
  String get usuario => 'Usuario';

  @override
  String get miActividad => 'Mi actividad';

  @override
  String get cuenta => 'Cuenta';

  @override
  String get soporte => 'Soporte';

  @override
  String get misSolicitudes => 'Mis solicitudes';

  @override
  String get misDonaciones => 'Mis donaciones';

  @override
  String get misNotasDeLaBiblia => 'Mis notas de la Biblia';

  @override
  String get misDatos => 'Mis datos';

  @override
  String get ajustesDeLaApp => 'Ajustes de la app';

  @override
  String get ayudaYSoporte => 'Ayuda y soporte';

  @override
  String get terminosYPrivacidad => 'Términos y privacidad';

  @override
  String get cerrarSesion => 'Cerrar sesión';

  @override
  String get misDatosDePerfil => 'Mis datos de perfil';

  @override
  String get nombreCompleto => 'Nombre completo';

  @override
  String get ingresaUnNombre => 'Ingresa un nombre';

  @override
  String get correoElectronico => 'Correo electrónico';

  @override
  String get ingresaUnCorreoValido => 'Ingresa un correo válido';

  @override
  String get telefonoCelular => 'Teléfono celular';

  @override
  String get iglesiaActual => 'Iglesia actual';

  @override
  String get helperCambiarIglesia =>
      'Para cambiarla usa la opción \"Cambiar de iglesia\"';

  @override
  String get guardarCambios => 'Guardar cambios';

  @override
  String get datosActualizadosCorrectamente =>
      'Datos actualizados correctamente';

  @override
  String get seguroDeseasCerrarSesion => '¿Seguro que deseas cerrar sesión?';

  @override
  String get eliminarCuenta => 'Eliminar cuenta';

  @override
  String get seguroEliminarCuenta =>
      '¿Estás seguro de que deseas eliminar tu cuenta y todos tus datos personales de ATRIO?';

  @override
  String get detalleEliminarCuenta =>
      'Esta acción es definitiva e irreversible. Se eliminarán permanentemente:\n• Tu perfil de usuario y vinculación comunitaria.\n• Todas tus notas personales de la Biblia y favoritos guardados.\n• Tu historial de solicitudes y aportes locales.\n• Se solicitará la desactivación de tu registro en el backend Odoo ERP.';

  @override
  String get eliminarDefinitivamente => 'Eliminar definitivamente';

  @override
  String get cuentaEliminadaExito =>
      'Tu cuenta y datos personales han sido eliminados satisfactoriamente.';

  @override
  String get versionDeLaBiblia => 'Versión de la Biblia';

  @override
  String get noSePudoAbrirWhatsApp => 'No se pudo abrir WhatsApp.';

  @override
  String get buscarBibliaPlaceholder => 'Buscar versículo, palabra o frase...';

  @override
  String get buscar => 'Buscar';

  @override
  String get borrarTexto => 'Borrar texto';

  @override
  String buscandoEnVersion(String version) {
    return 'Buscando en $version...';
  }

  @override
  String get versiculoDelDia => 'Versículo del día';

  @override
  String get compartirVersiculo => 'Compartir versículo';

  @override
  String get errorCargarVersiculo => 'No se pudo cargar el versículo de hoy.';

  @override
  String get librosDeLaBiblia => 'Libros de la Biblia';

  @override
  String get antiguoYNuevoTestamento => 'Antiguo y Nuevo Testamento';

  @override
  String get continuarLeyendo => 'Continuar leyendo';

  @override
  String capituloNumero(String numero) {
    return 'Capítulo $numero';
  }

  @override
  String get escuchar => 'Escuchar';

  @override
  String get escuchaLaBibliaNarrada => 'Escucha la Biblia narrada';

  @override
  String get favoritos => 'Favoritos';

  @override
  String get pasajeGuardado => '1 pasaje guardado';

  @override
  String pasajesGuardados(String total) {
    return '$total pasajes guardados';
  }

  @override
  String get misNotas => 'Mis notas';

  @override
  String get notaSingular => '1 nota';

  @override
  String notasPlural(String total) {
    return '$total notas';
  }

  @override
  String noVersiculosEncontrados(String consulta) {
    return 'No se encontraron versículos para:\n\"$consulta\"';
  }

  @override
  String get pruebaPalabrasClave =>
      'Prueba usando palabras clave más generales o revisa la ortografía.';

  @override
  String versiculosEncontrados(String total) {
    return '$total versículos encontrados';
  }

  @override
  String get cerrarBusqueda => 'Cerrar búsqueda';

  @override
  String get buscarEventosPlaceholder =>
      'Buscar eventos, expositores o lugares...';

  @override
  String get categorias => 'Categorías';

  @override
  String get categoriaTodos => 'Todos';

  @override
  String get categoriaLiderazgo => 'Liderazgo';

  @override
  String get categoriaAdoracion => 'Adoración';

  @override
  String get categoriaJovenes => 'Jóvenes';

  @override
  String get categoriaFamilias => 'Familias';

  @override
  String get explorarEventos => 'Explorar eventos';

  @override
  String get verTodos => 'Ver todos';

  @override
  String get noEventosEnCategoria =>
      'No se encontraron eventos en esta categoría';

  @override
  String get proximosEnAgenda => 'Próximos en agenda';

  @override
  String get mostrandoCalendarioCompleto =>
      'Mostrando calendario completo de actividades...';

  @override
  String get verCalendario => 'Ver calendario';

  @override
  String get destacadoMayus => 'DESTACADO';

  @override
  String get inscribirmeAhora => 'Inscribirme ahora';

  @override
  String eventoAnadidoACalendario(String titulo) {
    return 'Evento \"$titulo\" añadido a tu calendario.';
  }

  @override
  String get anadirACalendario => 'Añadir a calendario';

  @override
  String get miActividadAgendada => 'Mi actividad agendada';

  @override
  String porcentajeOcupacion(int porcentaje) {
    return '$porcentaje% ocupación';
  }

  @override
  String get disponibilidadCupos => 'Disponibilidad de cupos';

  @override
  String get detallesDelEvento => 'Detalles del evento';

  @override
  String inscripcionConfirmada(String titulo) {
    return 'Inscripción confirmada para \"$titulo\". ¡Te esperamos!';
  }

  @override
  String get yaEstasInscrito => 'Ya estás inscrito';

  @override
  String eventoAgregadoAgendaLocal(String titulo) {
    return 'Evento \"$titulo\" agregado a tu agenda local.';
  }

  @override
  String get mensajeWhatsAppAyuda => 'Hola, necesito ayuda con la app ATRIO.';

  @override
  String get errorAbrirWhatsAppDispositivo =>
      'No se pudo abrir WhatsApp en este dispositivo.';

  @override
  String get errorAbrirWhatsApp =>
      'Ocurrió un error al intentar abrir WhatsApp.';

  @override
  String get asuntoCorreoSoporte => 'Soporte - App ATRIO';

  @override
  String get cuerpoCorreoSoporte =>
      'Describe aquí tu consulta o inconveniente:\n\n---\nVersión de la app: 1.0.0';

  @override
  String get errorNoClienteCorreo =>
      'No se encontró un cliente de correo configurado.';

  @override
  String get errorAbrirCorreo =>
      'Ocurrió un error al intentar abrir el correo.';

  @override
  String get modoClaroSuave => 'Modo Claro Suave';

  @override
  String get modoLecturaNocturna => 'Modo Lectura Nocturna';

  @override
  String get modoPapiroCalido => 'Modo Papiro Cálido';

  @override
  String get ajustesDeLectura => 'Ajustes de lectura';

  @override
  String get tamanoDeLetra => 'Tamaño de letra';

  @override
  String get tipoDeFuente => 'Tipo de fuente';

  @override
  String get modoDeLectura => 'Modo de lectura';

  @override
  String get papiro => 'Papiro';

  @override
  String get noche => 'Noche';

  @override
  String get cambiarTonoLecturaTooltip => 'Cambiar tono de lectura';

  @override
  String get comoPodemosAyudarte => '¿Cómo podemos ayudarte?';

  @override
  String get descripcionAyudaSoporte =>
      'Encuentra respuestas rápidas o comunícate directamente con nuestro equipo de asistencia técnica de ATRIO.';

  @override
  String get canalesDeAtencion => 'Canales de atención';

  @override
  String get chatDirecto => 'Chat directo';

  @override
  String get preguntasFrecuentes => 'Preguntas frecuentes';

  @override
  String get faq1Pregunta =>
      '¿Cómo realizar una ofrenda o donación a mi iglesia?';

  @override
  String get faq1Respuesta =>
      'Accede a la sección \"Mis donaciones\" desde tu perfil o pulsa el botón \"Ofrendar / Aportar\" en la pantalla de tu iglesia. Podrás seleccionar el proyecto solidario, ingresar el monto y proceder con total seguridad.';

  @override
  String get faq2Pregunta =>
      '¿Cómo enviar y consultar el estado de mis solicitudes pastorales?';

  @override
  String get faq2Respuesta =>
      'Dirígete a la sección \"Mis solicitudes\" en tu perfil o desde el menú de tu iglesia. Allí podrás enviar peticiones de oración, consejería o apoyo social y verificar el seguimiento de respuesta de tu comunidad.';

  @override
  String get faq3Pregunta =>
      '¿Dónde puedo explorar iglesias cercanas y verlas en el mapa?';

  @override
  String get faq3Respuesta =>
      'Desde la pantalla principal pulsa sobre \"Explorar Iglesias\" o el mapa interactivo. Podrás filtrar por tradición cristiana, conocer horarios de servicios, pastores encargados y obtener la ruta en el mapa.';

  @override
  String get faq4Pregunta =>
      '¿Puedo leer la Biblia y guardar notas o favoritos sin conexión?';

  @override
  String get faq4Respuesta =>
      '¡Sí! El texto bíblico, tus notas de estudio y los versículos destacados quedan almacenados de manera segura y local en tu dispositivo mediante SQLite para que los disfrutes en todo momento.';

  @override
  String get faq5Pregunta =>
      '¿Cómo actualizar mis datos de perfil o cambiar de iglesia?';

  @override
  String get faq5Respuesta =>
      'En la pestaña Perfil, presiona \"Mis datos\" o el botón de edición para actualizar tu nombre, correo o teléfono celular. Si deseas afiliarte a otra comunidad, pulsa \"Cambiar de iglesia\".';

  @override
  String atrioVersion(String version) {
    return 'ATRIO · Versión $version';
  }

  @override
  String get todosLosDerechosReservados => 'Todos los derechos reservados';

  @override
  String get tiposDeSolicitud => 'Tipos de solicitud';

  @override
  String get peticionDeOracion => 'Petición de oración';

  @override
  String get orientacionPastoral => 'Orientación pastoral';

  @override
  String get consejeriaFamiliar => 'Consejería familiar';

  @override
  String get visitaAEnfermos => 'Visita a enfermos';

  @override
  String get ayudaComunitaria => 'Ayuda comunitaria';

  @override
  String get otraSolicitud => 'Otra solicitud';

  @override
  String get volver => 'Volver';

  @override
  String get comunidadVerificada => 'Comunidad verificada';

  @override
  String get diezmo => 'Diezmo';

  @override
  String get ofrenda => 'Ofrenda';

  @override
  String get campanaEspecial => 'Campaña especial';

  @override
  String get otroAporte => 'Otro aporte';

  @override
  String get historialYRecibos => 'Historial y recibos';

  @override
  String get proyectosSolidariosTitulo => 'Proyectos solidarios';

  @override
  String get lemaProyectosSolidarios => 'Juntos podemos transformar vidas';

  @override
  String get noHayDatosDisponibles => 'No hay datos disponibles';

  @override
  String get masCampanas => 'Más campañas';

  @override
  String get metaPrefijo => 'Meta:';

  @override
  String get deMonto => 'de';

  @override
  String porcentajeAlcanzado(String porcentaje) {
    return '$porcentaje% alcanzado';
  }

  @override
  String diasRestantes(String dias) {
    return '$dias días restantes';
  }

  @override
  String carritoCantidadProductos(String cantidad) {
    return 'Tienes $cantidad productos en tu carrito de compras';
  }

  @override
  String get buscarProductosPlaceholder =>
      'Buscar biblias, libros o regalos...';

  @override
  String get categoriaBiblias => 'Biblias';

  @override
  String get categoriaLibros => 'Libros';

  @override
  String get categoriaRegalos => 'Regalos';

  @override
  String get recursosParaCrecerEnTuFe => 'Recursos para\ncrecer en tu fe';

  @override
  String get verDestacados => 'Ver destacados';

  @override
  String get catalogoDeProductos => 'Catálogo de productos';

  @override
  String get noSeEncontraronProductosCategoria =>
      'No se encontraron productos en esta categoría';

  @override
  String get entregaORetiro => 'Entrega o retiro';

  @override
  String get envioADomicilio => 'Envío a domicilio';

  @override
  String get retiroEnIglesia => 'Retiro en iglesia';

  @override
  String unidadesEnInventario(String cantidad) {
    return '$cantidad unidades en inventario';
  }

  @override
  String get detallesDelProducto => 'Detalles del producto';

  @override
  String productoAgregadoAlCarrito(String nombre) {
    return '¡\"$nombre\" agregado al carrito!';
  }

  @override
  String agregarAlCarritoConPrecio(String precio) {
    return 'Agregar al carrito · $precio';
  }

  @override
  String get buscarLibrosPlaceholder => 'Buscar libros o autores...';

  @override
  String get categoriaVidaCristiana => 'Vida cristiana';

  @override
  String get categoriaCrecimiento => 'Crecimiento';

  @override
  String get explorarLibros => 'Explorar libros';

  @override
  String get noSeEncontraronLibrosCategoria =>
      'No se encontraron libros en esta categoría';

  @override
  String get leerAhora => 'Leer ahora';

  @override
  String get escucharMuestra => 'Escuchar muestra';

  @override
  String reproduciendoMuestra(String titulo) {
    return 'Reproduciendo muestra de \"$titulo\"...';
  }

  @override
  String totalPaginas(String paginas) {
    return '$paginas páginas';
  }

  @override
  String porcentajeLeido(String porcentaje) {
    return '$porcentaje% leído';
  }

  @override
  String get sinopsis => 'Sinopsis';

  @override
  String abriendoLibro(String titulo) {
    return 'Abriendo \"$titulo\"...';
  }

  @override
  String get videosYTransmisiones => 'Videos y transmisiones';

  @override
  String get buscarVideosPlaceholder => 'Buscar prédicas, canales o temas...';

  @override
  String get enVivoBadge => 'EN VIVO';

  @override
  String get categoriaEnVivo => 'En vivo';

  @override
  String get categoriaPredicas => 'Prédicas';

  @override
  String get categoriaEstudios => 'Estudios';

  @override
  String get categoriaMusica => 'Música';

  @override
  String get noSeEncontraronVideosCategoria =>
      'No se encontraron videos en esta categoría';

  @override
  String get descripcion => 'Descripción';

  @override
  String conectandoTransmision(String titulo) {
    return 'Conectando a transmisión \"$titulo\"...';
  }

  @override
  String reproduciendoVideo(String titulo) {
    return 'Reproduciendo \"$titulo\"...';
  }

  @override
  String get verTransmisionEnVivo => 'Ver transmisión en vivo';

  @override
  String get reproducirAhora => 'Reproducir ahora';

  @override
  String enlaceCopiadoPortapapeles(String titulo) {
    return 'Enlace de \"$titulo\" copiado al portapapeles';
  }
}
