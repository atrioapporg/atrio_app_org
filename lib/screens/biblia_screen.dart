import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/atrio_database_helper.dart';
import '../l10n/app_localizations.dart';
import '../modelos/versiculo_dia.dart';
import '../providers/ajustes_provider.dart';
import '../providers/biblia_provider.dart';
import '../servicios/bible_service.dart';
import '../servicios/versiculo_service.dart';
import 'escuchar_libro_biblia_screen.dart';
import 'libros_de_biblia.dart';
import 'mis_favoritos_screen.dart';
import 'mis_notas_screen.dart';

class BibliaScreen extends StatefulWidget {
  static const routeName = 'biblia_screen';
  const BibliaScreen({super.key});

  @override
  State createState() => _BibliaScreenState();
}

class _BibliaScreenState extends State {
  final TextEditingController _searchController = TextEditingController();
  final VersiculoService _versiculoService = VersiculoService();
  late Future _versiculoFuture;

  String _ultimoLibro = 'Génesis';
  int _ultimoCapitulo = 1;
  int _ultimoTotalCapitulos = 50;

  int _totalNotas = 0;
  int _totalFavoritos = 0;

  late BibliaProvider _bibliaProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bibliaProvider = Provider.of<BibliaProvider>(context, listen: false);
    final ajustesProvider = Provider.of<AjustesProvider>(
      context,
      listen: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bibliaProvider.sincronizarIdioma(
        ajustesProvider.idiomaCodigo,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _cargarVersiculo();
    _cargarConteoLocal();
    _cargarUltimaLectura();
  }

  Future _cargarUltimaLectura() async {
    final data = await AtrioDatabaseHelper.instance.obtenerUltimaLectura();
    if (mounted) {
      setState(() {
        _ultimoLibro = data['libro'];
        _ultimoCapitulo = data['capitulo'];
        _ultimoTotalCapitulos = data['totalCapitulos'];
      });
    }
  }

  void _cargarVersiculo() {
    setState(() {
      _versiculoFuture = _versiculoService.obtenerVersiculoDelDia();
    });
  }

  Future _cargarConteoLocal() async {
    try {
      final notas = await AtrioDatabaseHelper.instance.contarNotas();
      final favoritos = await AtrioDatabaseHelper.instance.contarFavoritos();
      if (mounted) {
        setState(() {
          _totalNotas = notas;
          _totalFavoritos = favoritos;
        });
      }
    } catch (e) {
      debugPrint('Error al contar datos locales: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bibliaProvider.limpiarBusqueda(notificar: false);
    super.dispose();
  }

  void _mostrarSelectorVersiones(
    BuildContext context,
    BibliaProvider provider,
    double screenWidth,
    double usableHeight, {
    required String idiomaCodigo,
  }) {
    final l10n = AppLocalizations.of(context);
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    final bool esIngles = idiomaCodigo == 'en';
    final primaryGroup = esIngles
        ? BibliaProvider.versionesIngles
        : BibliaProvider.versionesEspanol;
    final secondaryGroup = esIngles
        ? BibliaProvider.versionesEspanol
        : BibliaProvider.versionesIngles;
    final String primaryHeader = esIngles
        ? (l10n?.ingles ?? 'Inglés')
        : (l10n?.espanol ?? 'Español');
    final String secondaryHeader = esIngles
        ? (l10n?.espanol ?? 'Español')
        : (l10n?.ingles ?? 'Inglés');

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFAF7F0),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.06),
        ),
      ),
      builder: (ctx) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: usableHeight * 0.70),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: usableHeight * 0.02,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n?.versionDeLaBiblia ?? 'Versión de la Biblia',
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.048,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: azulFondo),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: usableHeight * 0.006,
                    ),
                    child: Text(
                      primaryHeader.toUpperCase(),
                      style: TextStyle(
                        color: amarilloOro,
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.030,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  ...primaryGroup.entries.map(
                    (entry) => _buildVersionTile(
                      ctx,
                      provider,
                      entry.key,
                      entry.value,
                      screenWidth,
                      azulFondo,
                      amarilloOro,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.01),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: usableHeight * 0.006,
                    ),
                    child: Text(
                      secondaryHeader.toUpperCase(),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth * 0.030,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  ...secondaryGroup.entries.map(
                    (entry) => _buildVersionTile(
                      ctx,
                      provider,
                      entry.key,
                      entry.value,
                      screenWidth,
                      azulFondo,
                      amarilloOro,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVersionTile(
    BuildContext ctx,
    BibliaProvider provider,
    String codigo,
    String nombre,
    double screenWidth,
    Color azulFondo,
    Color amarilloOro,
  ) {
    final bool isSelected = codigo == provider.versionActual;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
      leading: Icon(
        Icons.menu_book_rounded,
        color: isSelected ? amarilloOro : azulFondo,
      ),
      title: Text(
        nombre,
        style: TextStyle(
          color: azulFondo,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: screenWidth * 0.038,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: amarilloOro)
          : null,
      onTap: () {
        provider.cambiarVersion(codigo);
        Navigator.pop(ctx);
      },
    );
  }

  Future _compartirVersiculo(VersiculoDia versiculo) async {
    final String texto = versiculo.texto.trim().isNotEmpty
        ? versiculo.texto.trim()
        : 'Todo lo puedo en Cristo que me fortalece.';
    final String referencia = versiculo.referencia.trim().isNotEmpty
        ? versiculo.referencia.trim()
        : 'Filipenses 4:13';
    final String mensaje = '"$texto"\n— $referencia';
    final String textoCodificado = Uri.encodeComponent(mensaje);
    final Uri uri = Uri.parse('whatsapp://send?text=$textoCodificado');
    final Uri uriWeb = Uri.parse(
      'https://api.whatsapp.com/send?text=$textoCodificado',
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(uriWeb)) {
        await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.noSePudoAbrirWhatsApp ?? 'No se pudo abrir WhatsApp.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al compartir versículo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);
    const Color grisBorde = Color(0xFFE5E5E5);

    final bibliaProvider = Provider.of<BibliaProvider>(context);
    final ajustesProvider = Provider.of<AjustesProvider>(context);

    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          _searchController.clear();
          bibliaProvider.limpiarBusqueda(notificar: false);
        }
      },
      child: Scaffold(
        backgroundColor: azulFondo,
        body: SafeArea(
          bottom: true,
          child: SizedBox(
            width: screenWidth,
            height: usableHeight,
            child: Column(
              children: [
                // =========================================================
                // ENCABEZADO MEJORADO (UX/UI PROFESIONAL)
                // =========================================================
                Container(
                  width: screenWidth,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: usableHeight * 0.012,
                  ),
                  child: Column(
                    children: [
                      // Fila 1: Regresar + Título + Selector de Versión
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              bibliaProvider.limpiarBusqueda(notificar: false);
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: EdgeInsets.all(screenWidth * 0.02),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chevron_left_rounded,
                                color: Colors.white,
                                size: screenWidth * 0.07,
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Text(
                            l10n?.biblia ?? 'Biblia',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.060,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Spacer(),

                          // Selector de Versión estilizado
                          GestureDetector(
                            onTap: () => _mostrarSelectorVersiones(
                              context,
                              bibliaProvider,
                              screenWidth,
                              usableHeight,
                              idiomaCodigo: ajustesProvider.idiomaCodigo,
                            ),
                            child: Container(
                              height: usableHeight * 0.044,
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.03,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                  screenWidth * 0.04,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_stories_rounded,
                                    color: amarilloOro,
                                    size: screenWidth * 0.045,
                                  ),
                                  SizedBox(width: screenWidth * 0.015),
                                  Text(
                                    bibliaProvider.nombreVersionActual,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.032,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white70,
                                    size: screenWidth * 0.045,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: usableHeight * 0.015),

                      // Fila 2: Buscador moderno y limpio
                      Container(
                        height: usableHeight * 0.054,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.035,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (value) {
                            FocusScope.of(context).unfocus();
                            bibliaProvider.ejecutarBusqueda(
                              value,
                              idiomaCodigo: ajustesProvider.idiomaCodigo,
                            );
                          },
                          onChanged: (val) {
                            setState(
                              () {},
                            ); // Actualiza visibilidad de la 'X' y botón buscar
                          },
                          style: TextStyle(
                            color: azulFondo,
                            fontSize: screenWidth * 0.037,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                l10n?.buscarBibliaPlaceholder ??
                                'Buscar versículo, palabra o frase...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: screenWidth * 0.034,
                            ),
                            prefixIcon: IconButton(
                              icon: Icon(
                                Icons.search_rounded,
                                color: azulFondo,
                                size: screenWidth * 0.055,
                              ),
                              tooltip: l10n?.buscar ?? 'Buscar',
                              onPressed: () {
                                FocusScope.of(context).unfocus();
                                bibliaProvider.ejecutarBusqueda(
                                  _searchController.text,
                                  idiomaCodigo: ajustesProvider.idiomaCodigo,
                                );
                              },
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_searchController.text.isNotEmpty)
                                  IconButton(
                                    icon: Icon(
                                      Icons.cancel_rounded,
                                      color: Colors.grey.shade400,
                                      size: screenWidth * 0.048,
                                    ),
                                    tooltip:
                                        l10n?.borrarTexto ?? 'Borrar texto',
                                    onPressed: () {
                                      _searchController.clear();
                                      bibliaProvider.limpiarBusqueda();
                                      setState(() {});
                                    },
                                  ),
                                if (_searchController.text.trim().isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      right: screenWidth * 0.02,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        FocusScope.of(context).unfocus();
                                        bibliaProvider.ejecutarBusqueda(
                                          _searchController.text,
                                          idiomaCodigo:
                                              ajustesProvider.idiomaCodigo,
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: screenWidth * 0.025,
                                          vertical: usableHeight * 0.007,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE5A023),
                                          borderRadius: BorderRadius.circular(
                                            screenWidth * 0.02,
                                          ),
                                        ),
                                        child: Text(
                                          l10n?.buscar ?? 'Buscar',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenWidth * 0.03,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: usableHeight * 0.012,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: usableHeight * 0.008),
                    ],
                  ),
                ),

                // =========================================================
                // CONTENEDOR BLANCO INFERIOR
                // =========================================================
                Expanded(
                  child: Container(
                    width: screenWidth,
                    decoration: BoxDecoration(
                      color: blancoFondo,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(screenWidth * 0.08),
                        topRight: Radius.circular(screenWidth * 0.08),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(screenWidth * 0.08),
                        topRight: Radius.circular(screenWidth * 0.08),
                      ),
                      child: bibliaProvider.isSearching
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                    color: amarilloOro,
                                  ),
                                  SizedBox(height: usableHeight * 0.02),
                                  Text(
                                    l10n?.buscandoEnVersion(
                                          bibliaProvider.nombreVersionActual,
                                        ) ??
                                        'Buscando en ${bibliaProvider.nombreVersionActual}...',
                                    style: TextStyle(
                                      color: azulFondo,
                                      fontSize: screenWidth * 0.036,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : bibliaProvider.busquedaRealizada
                          ? _buildResultadosBusqueda(
                              bibliaProvider,
                              screenWidth,
                              usableHeight,
                              azulFondo,
                              grisBorde,
                              idiomaCodigo: ajustesProvider.idiomaCodigo,
                            )
                          : SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.045,
                                vertical: usableHeight * 0.02,
                              ),
                              child: Column(
                                children: [
                                  _buildVerseOfDayBanner(
                                    screenWidth,
                                    usableHeight,
                                    azulFondo,
                                  ),
                                  SizedBox(height: usableHeight * 0.018),
                                  _buildOptionTile(
                                    icon: Icons.book_outlined,
                                    title:
                                        l10n?.librosDeLaBiblia ??
                                        'Libros de la Biblia',
                                    subtitle:
                                        l10n?.antiguoYNuevoTestamento ??
                                        'Antiguo y Nuevo Testamento',
                                    screenWidth: screenWidth,
                                    usableHeight: usableHeight,
                                    azulFondo: azulFondo,
                                    grisBorde: grisBorde,
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        LibrosDeBibliaScreen.routeName,
                                      );
                                    },
                                  ),
                                  SizedBox(height: usableHeight * 0.012),
                                  _buildOptionTile(
                                    icon: Icons.menu_book_outlined,
                                    title:
                                        l10n?.continuarLeyendo ??
                                        'Continuar leyendo',
                                    subtitle: '$_ultimoLibro $_ultimoCapitulo',
                                    screenWidth: screenWidth,
                                    usableHeight: usableHeight,
                                    azulFondo: azulFondo,
                                    grisBorde: grisBorde,
                                    onTap: () async {
                                      await Navigator.pushNamed(
                                        context,
                                        'lectura_capitulo_screen',
                                        arguments: {
                                          'nombre': _ultimoLibro,
                                          'capitulo': _ultimoCapitulo,
                                          'totalCapitulos':
                                              _ultimoTotalCapitulos,
                                          'subtitulo':
                                              l10n?.capituloNumero(
                                                _ultimoCapitulo.toString(),
                                              ) ??
                                              'Capítulo $_ultimoCapitulo',
                                        },
                                      );
                                      _cargarUltimaLectura();
                                      _cargarConteoLocal();
                                    },
                                  ),
                                  SizedBox(height: usableHeight * 0.012),
                                  _buildOptionTile(
                                    icon: Icons.headphones_outlined,
                                    title: l10n?.escuchar ?? 'Escuchar',
                                    subtitle:
                                        l10n?.escuchaLaBibliaNarrada ??
                                        'Escucha la Biblia narrada',
                                    screenWidth: screenWidth,
                                    usableHeight: usableHeight,
                                    azulFondo: azulFondo,
                                    grisBorde: grisBorde,
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        EscucharLibroBibliaScreen.routeName,
                                      );
                                    },
                                  ),
                                  SizedBox(height: usableHeight * 0.012),
                                  _buildOptionTile(
                                    icon: Icons.bookmark_border_rounded,
                                    title: l10n?.favoritos ?? 'Favoritos',
                                    subtitle: _totalFavoritos == 1
                                        ? (l10n?.pasajeGuardado ??
                                              '1 pasaje guardado')
                                        : (l10n?.pasajesGuardados(
                                                _totalFavoritos.toString(),
                                              ) ??
                                              '$_totalFavoritos pasajes guardados'),
                                    screenWidth: screenWidth,
                                    usableHeight: usableHeight,
                                    azulFondo: azulFondo,
                                    grisBorde: grisBorde,
                                    onTap: () async {
                                      await Navigator.pushNamed(
                                        context,
                                        MisFavoritosScreen.routeName,
                                      );
                                      _cargarConteoLocal();
                                    },
                                  ),
                                  SizedBox(height: usableHeight * 0.012),
                                  _buildOptionTile(
                                    icon: Icons.edit_note_outlined,
                                    title: l10n?.misNotas ?? 'Mis notas',
                                    subtitle: _totalNotas == 1
                                        ? (l10n?.notaSingular ?? '1 nota')
                                        : (l10n?.notasPlural(
                                                _totalNotas.toString(),
                                              ) ??
                                              '$_totalNotas notas'),
                                    screenWidth: screenWidth,
                                    usableHeight: usableHeight,
                                    azulFondo: azulFondo,
                                    grisBorde: grisBorde,
                                    onTap: () async {
                                      await Navigator.pushNamed(
                                        context,
                                        MisNotasScreen.routeName,
                                      );
                                      _cargarConteoLocal();
                                    },
                                  ),
                                  SizedBox(height: usableHeight * 0.02),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerseOfDayBanner(
    double screenWidth,
    double usableHeight,
    Color azulFondo,
  ) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder(
      future: _versiculoFuture,
      builder: (context, snapshot) {
        return Container(
          width: screenWidth,
          constraints: BoxConstraints(minHeight: usableHeight * 0.20),
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/images/biblia1.jpg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
            ),
            borderRadius: BorderRadius.circular(screenWidth * 0.045),
            gradient: LinearGradient(
              colors: [azulFondo, const Color(0xFF194A6E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: EdgeInsets.all(screenWidth * 0.045),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.wb_sunny_outlined,
                        color: Colors.white70,
                        size: screenWidth * 0.045,
                      ),
                      SizedBox(width: screenWidth * 0.015),
                      Text(
                        l10n?.versiculoDelDia ?? 'Versículo del día',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: screenWidth * 0.034,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (snapshot.hasData)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip:
                          l10n?.compartirVersiculo ?? 'Compartir versículo',
                      icon: Icon(
                        Icons.share_outlined,
                        color: Colors.white,
                        size: screenWidth * 0.055,
                      ),
                      onPressed: () => _compartirVersiculo(snapshot.data!),
                    )
                  else if (snapshot.hasError)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: l10n?.reintentar ?? 'Reintentar',
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _cargarVersiculo,
                    ),
                ],
              ),
              SizedBox(height: usableHeight * 0.015),
              if (snapshot.connectionState == ConnectionState.waiting) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ] else if (snapshot.hasError) ...[
                Padding(
                  padding: EdgeInsets.symmetric(vertical: usableHeight * 0.01),
                  child: Text(
                    l10n?.errorCargarVersiculo ??
                        'No se pudo cargar el versículo de hoy.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.038,
                    ),
                  ),
                ),
              ] else if (snapshot.hasData) ...[
                Text(
                  '"${snapshot.data!.texto}"',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.042,
                    fontWeight: FontWeight.bold,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: usableHeight * 0.012),
                Text(
                  snapshot.data!.referencia,
                  style: const TextStyle(
                    color: Color(0xFFE5A023),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultadosBusqueda(
    BibliaProvider provider,
    double screenWidth,
    double usableHeight,
    Color azulFondo,
    Color grisBorde, {
    required String idiomaCodigo,
  }) {
    final l10n = AppLocalizations.of(context);
    if (provider.searchErrorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: screenWidth * 0.14,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: usableHeight * 0.015),
              Text(
                provider.searchErrorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.038,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: usableHeight * 0.02),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE5A023),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: usableHeight * 0.012,
                  ),
                ),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  l10n?.reintentar ?? 'Reintentar',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  if (_searchController.text.trim().isNotEmpty) {
                    provider.ejecutarBusqueda(
                      _searchController.text,
                      idiomaCodigo: idiomaCodigo,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    if (provider.resultadosBusqueda.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: screenWidth * 0.14,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: usableHeight * 0.015),
              Text(
                l10n?.noVersiculosEncontrados(provider.ultimaConsulta) ??
                    'No se encontraron versículos para:\n"${provider.ultimaConsulta}"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.038,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: usableHeight * 0.01),
              Text(
                l10n?.pruebaPalabrasClave ?? 'Prueba usando palabras clave más generales o revisa la ortografía.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: screenWidth * 0.032,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Cabecera resumen de resultados
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: usableHeight * 0.012,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: grisBorde.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n?.versiculosEncontrados(
                        provider.resultadosBusqueda.length.toString(),
                      ) ??
                      '${provider.resultadosBusqueda.length} versículos encontrados',
                  style: TextStyle(
                    color: azulFondo,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.034,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  provider.limpiarBusqueda();
                  setState(() {});
                },
                child: Text(
                  l10n?.cerrarBusqueda ?? 'Cerrar búsqueda',
                  style: const TextStyle(
                    color: Color(0xFFE5A023),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Lista interactiva de versículos encontrados
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: usableHeight * 0.015,
            ),
            itemCount: provider.resultadosBusqueda.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: usableHeight * 0.012),
            itemBuilder: (context, index) {
              final item = provider.resultadosBusqueda[index];
              final String nombreLibro = provider.obtenerNombreLibro(
                item['book'] as int,
                idiomaCodigo: idiomaCodigo,
              );
              final int capitulo = item['chapter'] as int;
              final int versiculo = item['verse'] as int;
              final String referencia = '$nombreLibro $capitulo:$versiculo';
              final String texto = BibleService.limpiarTextoVerso(
                item['text'] as String?,
              );

              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                child: InkWell(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  onTap: () async {
                    FocusScope.of(context).unfocus();
                    await Navigator.pushNamed(
                      context,
                      'lectura_capitulo_screen',
                      arguments: {
                        'id': item['book'] as int,
                        'nombre': nombreLibro,
                        'capitulo': capitulo,
                        'verso': versiculo,
                        'subtitulo':
                            l10n?.capituloNumero(capitulo.toString()) ??
                            'Capítulo $capitulo',
                      },
                    );
                    _cargarUltimaLectura();
                    _cargarConteoLocal();
                  },
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.035),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      border: Border.all(color: grisBorde),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                referencia,
                                style: TextStyle(
                                  color: const Color(0xFFE5A023),
                                  fontWeight: FontWeight.bold,
                                  fontSize: screenWidth * 0.038,
                                ),
                              ),
                              SizedBox(height: usableHeight * 0.005),
                              Text(
                                texto,
                                style: TextStyle(
                                  color: azulFondo,
                                  fontSize: screenWidth * 0.037,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey.shade400,
                          size: screenWidth * 0.05,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color grisBorde,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: usableHeight * 0.082,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          border: Border.all(color: grisBorde),
        ),
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: Row(
          children: [
            Icon(icon, color: azulFondo, size: screenWidth * 0.075),
            SizedBox(width: screenWidth * 0.04),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.038,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: usableHeight * 0.002),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: screenWidth * 0.032,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: azulFondo,
              size: screenWidth * 0.055,
            ),
          ],
        ),
      ),
    );
  }
}
