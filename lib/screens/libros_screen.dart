import 'package:flutter/material.dart';

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
    'Vida cristiana',
    'Crecimiento',
    'Familia',
    'Liderazgo',
    'Más',
  ];

  final List<Map<String, String>> _exploreBooks = [
    {
      'title': 'El poder de\nla oración',
      'author': 'R. A. Torrey',
      'coverBg': '0xFFD8CCA3',
      'textColor': '0xFF4A3B2C',
    },
    {
      'title': 'Líder de\n360°',
      'author': 'John C. Maxwell',
      'coverBg': '0xFF47584A',
      'textColor': '0xFFEFEFEF',
    },
    {
      'title': 'La batalla\npertenece\na Jehová',
      'author': 'Joyce Meyer',
      'coverBg': '0xFFD5D2CA',
      'textColor': '0xFF222222',
    },
    {
      'title': 'El camino\nestrecho',
      'author': 'A. W. Tozer',
      'coverBg': '0xFF2A2A2A',
      'textColor': '0xFFF1F1F1',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
                    SizedBox(height: usableHeight * 0.01),
                    // Fila superior: Logo y Campana
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: screenWidth * 0.075,
                              height: usableHeight * 0.04,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: amarilloOro,
                                  width: screenWidth * 0.004,
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(screenWidth * 0.035),
                                  topRight: Radius.circular(
                                    screenWidth * 0.035,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.add,
                                  color: amarilloOro,
                                  size: screenWidth * 0.045,
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              'A T R I O',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.028,
                                letterSpacing: screenWidth * 0.008,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        // Campana con punto de alerta
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              color: Colors.white,
                              size: screenWidth * 0.075,
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: screenWidth * 0.025,
                                height: screenWidth * 0.025,
                                decoration: const BoxDecoration(
                                  color: amarilloOro,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.012),

                    // Título de la pantalla con botón de retroceso (Back <-)
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: screenWidth * 0.085,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.01),
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

                    // Buscador de libros
                    Container(
                      height: usableHeight * 0.052,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar libros',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: screenWidth * 0.035,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade600,
                            size: screenWidth * 0.05,
                          ),
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
                          // Banner Hero: Libro Destacado "Una vida con propósito"
                          _buildFeaturedBookHero(
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            amarilloOro: amarilloOro,
                            grisBorde: grisBorde,
                          ),
                          SizedBox(height: usableHeight * 0.011),

                          // Tarjeta "Continuar leyendo"
                          _buildContinueReadingCard(
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            amarilloOro: amarilloOro,
                            grisBorde: grisBorde,
                            onTap: () {},
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

                          // Pastillas de Categorías
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
                              GestureDetector(
                                onTap: () {},
                                child: Text(
                                  'Ver todo',
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

                          // Carrusel Horizontal de Libros
                          SizedBox(
                            height: usableHeight * 0.23,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _exploreBooks.length,
                              separatorBuilder: (context, index) =>
                                  SizedBox(width: screenWidth * 0.03),
                              itemBuilder: (context, index) {
                                final book = _exploreBooks[index];
                                return _buildBookCarouselItem(
                                  title: book['title']!,
                                  author: book['author']!,
                                  coverBg: Color(int.parse(book['coverBg']!)),
                                  textColor: Color(
                                    int.parse(book['textColor']!),
                                  ),
                                  screenWidth: screenWidth,
                                  usableHeight: usableHeight,
                                  azulFondo: azulFondo,
                                  onTap: () {},
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

  // Componente: Hero del libro destacado
  Widget _buildFeaturedBookHero({
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color amarilloOro,
    required Color grisBorde,
  }) {
    return Container(
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
          // Portada del libro
          Container(
            width: screenWidth * 0.32,
            height: usableHeight * 0.22,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2E3D),
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(2, 3),
                ),
              ],
            ),
            padding: EdgeInsets.all(screenWidth * 0.025),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'UNA VIDA\nCON\nPROPÓSITO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFE8D3A7),
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Icon(
                  Icons.park_rounded,
                  color: const Color(0xFFE8D3A7).withValues(alpha: 0.8),
                  size: screenWidth * 0.08,
                ),
                Text(
                  'RICK WARREN',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: screenWidth * 0.022,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: screenWidth * 0.04),

          // Información y acciones
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Una vida\ncon propósito',
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.052,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: usableHeight * 0.004),
                Text(
                  'Rick Warren',
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
                    onPressed: () {},
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
                    onPressed: () {},
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
    );
  }

  // Componente: Tarjeta "Continuar leyendo"
  Widget _buildContinueReadingCard({
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
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          border: Border.all(color: grisBorde),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  color: azulFondo,
                  size: screenWidth * 0.08,
                ),
                SizedBox(width: screenWidth * 0.035),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Continuar leyendo',
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: usableHeight * 0.002),
                      Text(
                        'Una vida con propósito',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: screenWidth * 0.045,
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
                      value: 0.65,
                      minHeight: usableHeight * 0.006,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(amarilloOro),
                    ),
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Text(
                  '65%',
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

  // Componente: Ítem del carrusel horizontal de libros
  Widget _buildBookCarouselItem({
    required String title,
    required String author,
    required Color coverBg,
    required Color textColor,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required VoidCallback onTap,
  }) {
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
                color: coverBg,
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
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
            ),
            SizedBox(height: usableHeight * 0.008),

            // Título
            Text(
              title.replaceAll('\n', ' '),
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
            //

            // Autor
            Text(
              author,
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
}
