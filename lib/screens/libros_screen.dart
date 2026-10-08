import 'package:flutter/material.dart';

import '../modelos/libro_model.dart';

class LibrosScreen extends StatefulWidget {
  static const routeName = 'libros_screen';

  const LibrosScreen({super.key});

  @override
  State<LibrosScreen> createState() => _LibrosScreenState();
}

class _LibrosScreenState extends State<LibrosScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;

  final List<String> _categories = [
    'Todos',
    'Vida cristiana',
    'Crecimiento',
    'Liderazgo',
  ];

  // Libro destacado (preparado con campos Odoo 19)
  final LibroModel _featuredBook = LibroModel(
    id: '1',
    titulo: 'Una vida con propósito',
    autor: 'Rick Warren',
    portadaUrl:
        'https://imagessl7.casadellibro.com/a/l/t7/17/9788417216917.jpg',
    categoria: 'Vida cristiana',
    sinopsis: 'Descubre el plan de Dios para tu vida a través de una jornada de 40 días que transformará tu manera de pensar y actuar con significado eterno.',
    progreso: 0.65,
    esDestacado: true,
    totalPaginas: 334,
    fallbackBgColor: '0xFF1E2E3D',
    fallbackTextColor: '0xFFE8D3A7',
  );

  // Catálogo inicial de 4 libros en carrusel (total 5 libros con el destacado)
  late final List<LibroModel> _booksList = [
    LibroModel(
      id: '2',
      titulo: 'El poder de la oración',
      autor: 'R. A. Torrey',
      portadaUrl: 'https://m.media-amazon.com/images/I/51HppGT3+ML.jpg',
      categoria: 'Vida cristiana',
      sinopsis: 'Un manual clásico e inspirador que desentraña los secretos bíblicos para orar con eficacia, constancia y fe inquebrantable.',
      progreso: 0.15,
      totalPaginas: 220,
      fallbackBgColor: '0xFFD8CCA3',
      fallbackTextColor: '0xFF4A3B2C',
    ),
    LibroModel(
      id: '3',
      titulo: 'Líder de 360°',
      autor: 'John C. Maxwell',
      portadaUrl:
          'https://imagessl7.casadellibro.com/a/l/t7/37/9780881139037.jpg',
      categoria: 'Liderazgo',
      sinopsis: 'Aprende a ejercer una influencia positiva en todas las direcciones dentro de una organización, sin importar tu jerarquía o posición formal.',
      progreso: 0.0,
      totalPaginas: 368,
      fallbackBgColor: '0xFF47584A',
      fallbackTextColor: '0xFFEFEFEF',
    ),
    LibroModel(
      id: '4',
      titulo: 'La batalla es del Señor',
      autor: 'Joyce Meyer',
      portadaUrl: 'https://image.cdn1.buscalibre.com/3431037.RS500x500.jpg',
      categoria: 'Crecimiento',
      sinopsis: 'Estrategias espirituales basadas en la alabanza y la adoración para vencer la ansiedad, el desánimo y las batallas cotidianas.',
      progreso: 0.40,
      totalPaginas: 240,
      fallbackBgColor: '0xFFD5D2CA',
      fallbackTextColor: '0xFF222222',
    ),
    LibroModel(
      id: '5',
      titulo: 'La búsqueda de Dios',
      autor: 'A. W. Tozer',
      portadaUrl: 'https://www.portavoz.com/media/catalog/product/cache/b4446cef9e6aa9616220953f699739fa/9/7/9781600661211_3.jpg',
      categoria: 'Vida cristiana',
      sinopsis: 'Un llamado urgente e íntimo a profundizar en la comunión personal con Dios, superando la religiosidad superficial.',
      progreso: 0.0,
      totalPaginas: 128,
      fallbackBgColor: '0xFF2A2A2A',
      fallbackTextColor: '0xFFF1F1F1',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filtrado reactivo por categoría y texto de búsqueda
  List<LibroModel> get _filteredBooks {
    final query = _searchController.text.trim().toLowerCase();
    final selectedCategory = _categories[_selectedCategoryIndex];

    return _booksList.where((book) {
      final matchesCategory =
          selectedCategory == 'Todos' ||
          book.categoria.toLowerCase() == selectedCategory.toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          book.titulo.toLowerCase().contains(query) ||
          book.autor.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Métricas relativas dinámicas (Flutter 3.22+)
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    // Paleta de diseño Atrio
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);
    const Color grisBorde = Color(0xFFE5E5E5);

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: true,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight,
          child: Column(
            children: [
              // 2. Encabezado Superior (Logo + Campana + Título con Volver + Buscador)
              Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título de la pantalla con botón de retroceso (Back <-)
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
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
                          'Libros',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.068,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.015),

                    // Buscador reactivo de libros
                    Container(
                      height: usableHeight * 0.052,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar libros o autores...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: screenWidth * 0.035,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade600,
                            size: screenWidth * 0.05,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    size: screenWidth * 0.045,
                                    color: Colors.grey.shade600,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: usableHeight * 0.013,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.015),
                  ],
                ),
              ),

              // 3. Contenedor Blanco Inferior Scrollable
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
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: usableHeight * 0.02,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Banner Hero: Libro Destacado
                          _buildFeaturedBookHero(
                            libro: _featuredBook,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            amarilloOro: amarilloOro,
                            grisBorde: grisBorde,
                            onTap: () =>
                                _showBookDetailsModal(context, _featuredBook),
                          ),
                          SizedBox(height: usableHeight * 0.011),

                          // Tarjeta "Continuar leyendo" con miniatura real
                          _buildContinueReadingCard(
                            book: _featuredBook,
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            amarilloOro: amarilloOro,
                            grisBorde: grisBorde,
                            onTap: () =>
                                _showBookDetailsModal(context, _featuredBook),
                          ),
                          SizedBox(height: usableHeight * 0.020),

                          // Sección Categorías
                          Text(
                            'Categorías',
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.012),

                          // Pastillas de Categorías interactivas
                          SizedBox(
                            height: usableHeight * 0.045,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _categories.length,
                              separatorBuilder: (context, index) =>
                                  SizedBox(width: screenWidth * 0.025),
                              itemBuilder: (context, index) {
                                final isSelected =
                                    _selectedCategoryIndex == index;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategoryIndex = index;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.04,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? azulFondo
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        screenWidth * 0.025,
                                      ),
                                      border: Border.all(
                                        color: isSelected
                                            ? azulFondo
                                            : grisBorde,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _categories[index],
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : azulFondo,
                                          fontSize: screenWidth * 0.032,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.031),

                          // Encabezado "Explorar libros"
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Explorar libros',
                                style: TextStyle(
                                  color: azulFondo,
                                  fontSize: screenWidth * 0.045,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_selectedCategoryIndex != 0)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategoryIndex = 0;
                                    });
                                  },
                                  child: Text(
                                    'Ver todos',
                                    style: TextStyle(
                                      color: amarilloOro,
                                      fontSize: screenWidth * 0.034,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: usableHeight * 0.015),

                          // Carrusel Horizontal de Libros filtrado reactivamente
                          SizedBox(
                            height: usableHeight * 0.23,
                            child: _filteredBooks.isEmpty
                                ? Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search_off_rounded,
                                          color: Colors.grey.shade500,
                                          size: screenWidth * 0.05,
                                        ),
                                        SizedBox(width: screenWidth * 0.02),
                                        Text(
                                          'No se encontraron libros en esta categoría',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: screenWidth * 0.03,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: _filteredBooks.length,
                                    separatorBuilder: (context, index) =>
                                        SizedBox(width: screenWidth * 0.03),
                                    itemBuilder: (context, index) {
                                      final book = _filteredBooks[index];
                                      return _buildBookCarouselItem(
                                        libro: book,
                                        screenWidth: screenWidth,
                                        usableHeight: usableHeight,
                                        azulFondo: azulFondo,
                                        onTap: () => _showBookDetailsModal(
                                          context,
                                          book,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          SizedBox(height: usableHeight * 0.025),
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
    );
  }

  // Componente: Hero del libro destacado con portada real y shimmer
  Widget _buildFeaturedBookHero({
    required LibroModel libro,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color amarilloOro,
    required Color grisBorde,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: screenWidth,
        padding: EdgeInsets.all(screenWidth * 0.035),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.045),
          border: Border.all(color: grisBorde),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portada con imagen real y shimmer
            Container(
              width: screenWidth * 0.32,
              height: usableHeight * 0.22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                child: Image.network(
                  libro.portadaUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _ShimmerPlaceholder(
                      width: screenWidth * 0.32,
                      height: usableHeight * 0.22,
                      borderRadius: screenWidth * 0.025,
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Color(int.parse(libro.fallbackBgColor)),
                    padding: EdgeInsets.all(screenWidth * 0.025),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          libro.titulo.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(int.parse(libro.fallbackTextColor)),
                            fontSize: screenWidth * 0.042,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Icon(
                          Icons.park_rounded,
                          color: Color(int.parse(libro.fallbackTextColor))
                              .withValues(alpha: 0.8),
                          size: screenWidth * 0.08,
                        ),
                        Text(
                          libro.autor.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: screenWidth * 0.022,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.04),

            // Información y acciones
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    libro.titulo,
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.052,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.004),
                  Text(
                    libro.autor,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.02),

                  // Botón Leer ahora
                  SizedBox(
                    width: double.infinity,
                    height: usableHeight * 0.045,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: amarilloOro,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.025,
                          ),
                        ),
                      ),
                      onPressed: onTap,
                      child: Text(
                        'Leer ahora',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.01),

                  // Botón Escuchar muestra
                  SizedBox(
                    width: double.infinity,
                    height: usableHeight * 0.045,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: azulFondo,
                        side: BorderSide(color: azulFondo),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.025,
                          ),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Reproduciendo muestra de "${libro.titulo}"...',
                            ),
                            backgroundColor: azulFondo,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.headphones_outlined,
                        size: screenWidth * 0.045,
                        color: azulFondo,
                      ),
                      label: Text(
                        'Escuchar muestra',
                        style: TextStyle(
                          fontSize: screenWidth * 0.032,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Componente: Tarjeta "Continuar leyendo" con miniatura real
  Widget _buildContinueReadingCard({
    required LibroModel book,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color amarilloOro,
    required Color grisBorde,
    required VoidCallback onTap,
  }) {
    final progressPercent = (book.progreso * 100).toInt();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.035),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          border: Border.all(color: grisBorde),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Miniatura real de portada
                Container(
                  width: screenWidth * 0.11,
                  height: usableHeight * 0.065,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(screenWidth * 0.015),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4,
                        offset: const Offset(1, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.015),
                    child: Image.network(
                      book.portadaUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _ShimmerPlaceholder(
                          width: screenWidth * 0.11,
                          height: usableHeight * 0.065,
                          borderRadius: screenWidth * 0.015,
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: azulFondo,
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: screenWidth * 0.05,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.035),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            size: screenWidth * 0.036,
                            color: amarilloOro,
                          ),
                          SizedBox(width: screenWidth * 0.015),
                          Text(
                            'Continuar leyendo',
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.038,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: usableHeight * 0.002),
                      Text(
                        book.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: screenWidth * 0.034,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        book.autor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: screenWidth * 0.026,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: azulFondo,
                  size: screenWidth * 0.06,
                ),
              ],
            ),
            SizedBox(height: usableHeight * 0.012),

            // Barra de progreso y porcentaje
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    child: LinearProgressIndicator(
                      value: book.progreso,
                      minHeight: usableHeight * 0.006,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(amarilloOro),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Text(
                  '$progressPercent%',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: screenWidth * 0.032,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Componente: Ítem del carrusel horizontal de libros con Shimmer y fallback
  Widget _buildBookCarouselItem({
    required LibroModel libro,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required VoidCallback onTap,
  }) {
    final coverBg = Color(int.parse(libro.fallbackBgColor));
    final textColor = Color(int.parse(libro.fallbackTextColor));

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: screenWidth * 0.25,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portada
            Container(
              width: screenWidth * 0.25,
              height: usableHeight * 0.15,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 5,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                child: libro.portadaUrl.isNotEmpty
                    ? Image.network(
                        libro.portadaUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _ShimmerPlaceholder(
                            width: screenWidth * 0.25,
                            height: usableHeight * 0.15,
                            borderRadius: screenWidth * 0.02,
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackCover(
                              title: libro.titulo,
                              textColor: textColor,
                              coverBg: coverBg,
                              screenWidth: screenWidth,
                            ),
                      )
                    : _buildFallbackCover(
                        title: libro.titulo,
                        textColor: textColor,
                        coverBg: coverBg,
                        screenWidth: screenWidth,
                      ),
              ),
            ),
            SizedBox(height: usableHeight * 0.008),

            // Título
            Text(
              libro.titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: azulFondo,
                fontSize: screenWidth * 0.028,
                fontWeight: FontWeight.bold,
                height: 1.15,
              ),
            ),
            SizedBox(height: usableHeight * 0.002),

            // Autor
            Text(
              libro.autor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: screenWidth * 0.024,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fallback visual si falla la carga de red
  Widget _buildFallbackCover({
    required String title,
    required Color textColor,
    required Color coverBg,
    required double screenWidth,
  }) {
    return Container(
      color: coverBg,
      padding: EdgeInsets.all(screenWidth * 0.02),
      child: Center(
        child: Text(
          title.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: screenWidth * 0.022,
            fontWeight: FontWeight.bold,
            height: 1.1,
          ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // Modal Inferior de Detalle Rápido del Libro (Bottom Sheet moderno)
  void _showBookDetailsModal(BuildContext context, LibroModel libro) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final usableHeight = screenHeight - MediaQuery.of(context).padding.top;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Container(
          decoration: BoxDecoration(
            color: blancoFondo,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(screenWidth * 0.06),
              topRight: Radius.circular(screenWidth * 0.06),
            ),
          ),
          padding: EdgeInsets.only(
            left: screenWidth * 0.06,
            right: screenWidth * 0.06,
            top: usableHeight * 0.018,
            bottom:
                MediaQuery.of(modalContext).padding.bottom +
                usableHeight * 0.02,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicador superior de arrastre
              Center(
                child: Container(
                  width: screenWidth * 0.12,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: usableHeight * 0.02),

              // Cabecera: Portada 3D + Datos principales
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Portada amplia
                  Container(
                    width: screenWidth * 0.28,
                    height: usableHeight * 0.19,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(screenWidth * 0.025),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(2, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.025),
                      child: Image.network(
                        libro.portadaUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return _ShimmerPlaceholder(
                            width: screenWidth * 0.28,
                            height: usableHeight * 0.19,
                            borderRadius: screenWidth * 0.025,
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Color(int.parse(libro.fallbackBgColor)),
                          padding: const EdgeInsets.all(8),
                          child: Center(
                            child: Text(
                              libro.titulo,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(
                                  int.parse(libro.fallbackTextColor),
                                ),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.045),

                  // Título, Autor, Categoría, Páginas
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.025,
                            vertical: usableHeight * 0.004,
                          ),
                          decoration: BoxDecoration(
                            color: azulFondo.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.015,
                            ),
                          ),
                          child: Text(
                            libro.categoria,
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.028,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(height: usableHeight * 0.008),
                        Text(
                          libro.titulo,
                          style: TextStyle(
                            color: azulFondo,
                            fontSize: screenWidth * 0.048,
                            fontWeight: FontWeight.bold,
                            height: 1.15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: usableHeight * 0.004),
                        Text(
                          libro.autor,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: screenWidth * 0.034,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (libro.totalPaginas > 0) ...[
                          SizedBox(height: usableHeight * 0.008),
                          Row(
                            children: [
                              Icon(
                                Icons.auto_stories_outlined,
                                size: screenWidth * 0.036,
                                color: Colors.grey.shade600,
                              ),
                              SizedBox(width: screenWidth * 0.015),
                              Text(
                                '${libro.totalPaginas} páginas',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: screenWidth * 0.028,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (libro.progreso > 0) ...[
                          SizedBox(height: usableHeight * 0.008),
                          Row(
                            children: [
                              Icon(
                                Icons.timelapse_rounded,
                                size: screenWidth * 0.036,
                                color: amarilloOro,
                              ),
                              SizedBox(width: screenWidth * 0.015),
                              Text(
                                '${(libro.progreso * 100).toInt()}% leído',
                                style: TextStyle(
                                  color: amarilloOro,
                                  fontSize: screenWidth * 0.028,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: usableHeight * 0.02),

              // Sinopsis
              if (libro.sinopsis.isNotEmpty) ...[
                Text(
                  'Sinopsis',
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: usableHeight * 0.006),
                Text(
                  libro.sinopsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: screenWidth * 0.032,
                    height: 1.35,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: usableHeight * 0.02),
              ],

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: amarilloOro,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          vertical: usableHeight * 0.015,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.025,
                          ),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(modalContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Abriendo "${libro.titulo}"...'),
                            backgroundColor: azulFondo,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.menu_book_rounded,
                        size: screenWidth * 0.045,
                      ),
                      label: Text(
                        libro.progreso > 0 ? 'Continuar leyendo' : 'Leer ahora',
                        style: TextStyle(
                          fontSize: screenWidth * 0.034,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: azulFondo,
                      side: BorderSide(color: azulFondo, width: 1.2),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: usableHeight * 0.015,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.025,
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(modalContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Reproduciendo muestra de "${libro.titulo}"...',
                          ),
                          backgroundColor: azulFondo,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.headphones_rounded,
                      size: screenWidth * 0.05,
                      color: azulFondo,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// Widget Shimmer animado para efecto de carga elegante sin dependencias externas
class _ShimmerPlaceholder extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerPlaceholder({
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-2.0 + (_controller.value * 4), -0.5),
              end: Alignment(-0.5 + (_controller.value * 4), 0.5),
              colors: const [
                Color(0xFFE2E6EC),
                Color(0xFFF2F4F8),
                Color(0xFFE2E6EC),
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.menu_book_rounded,
              color: Color(0xFFC4CBD4),
              size: 24,
            ),
          ),
        );
      },
    );
  }
}
