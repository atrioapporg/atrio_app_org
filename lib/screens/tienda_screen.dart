import 'package:flutter/material.dart';

class TiendaScreen extends StatefulWidget {
  static const routeName = 'tienda_screen';

  const TiendaScreen({super.key});

  @override
  State<TiendaScreen> createState() => _TiendaScreenState();
}

class _TiendaScreenState extends State<TiendaScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;
  int _selectedDeliveryOption = 0;

  final List<String> _categories = ['Libros', 'Biblias', 'Regalos'];

  final List<Map<String, dynamic>> _featuredProducts = [
    {
      'title': 'Biblia de estudio',
      'price': 'RD\$2,200',
      'icon': Icons.menu_book_rounded,
      'isFavorite': false,
    },
    {
      'title': 'Devocional diario',
      'price': 'RD\$650',
      'icon': Icons.auto_stories_rounded,
      'isFavorite': false,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Obtención de métricas dinámicas relativas (Flutter 3.22+)
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
              // 2. Encabezado Superior (Logo + Carrito + Título + Buscador)
              Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: usableHeight * 0.01),
                    // Fila superior: Logo y Carrito con contador
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
                        // Carrito con badge (2)
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              color: Colors.white,
                              size: screenWidth * 0.075,
                            ),
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: EdgeInsets.all(screenWidth * 0.008),
                                decoration: const BoxDecoration(
                                  color: amarilloOro,
                                  shape: BoxShape.circle,
                                ),
                                constraints: BoxConstraints(
                                  minWidth: screenWidth * 0.045,
                                  minHeight: screenWidth * 0.045,
                                ),
                                child: Center(
                                  child: Text(
                                    '2',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.026,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
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
                          'Tienda',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.068,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.015),

                    // Buscador de productos
                    Container(
                      height: usableHeight * 0.052,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar productos...',
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

              // 3. Contenedor Blanco Inferior con Catálogo y Opciones
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
                          // Filtros de categoría en pastillas (Pills)
                          SizedBox(
                            height: usableHeight * 0.045,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _categories.length,
                              separatorBuilder: (context, index) =>
                                  SizedBox(width: screenWidth * 0.03),
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
                                      horizontal: screenWidth * 0.055,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? amarilloOro
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        screenWidth * 0.05,
                                      ),
                                      border: Border.all(
                                        color: isSelected
                                            ? amarilloOro
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
                                          fontSize: screenWidth * 0.034,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.02),

                          // Banner Hero Promocional
                          _buildPromoBanner(
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            azulFondo: azulFondo,
                            amarilloOro: amarilloOro,
                            onTap: () {},
                          ),
                          SizedBox(height: usableHeight * 0.025),

                          // Encabezado de Productos destacados
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Productos destacados',
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
                                    color: const Color(0xFF0055A5),
                                    fontSize: screenWidth * 0.034,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: usableHeight * 0.015),

                          // Grid de Productos Destacados
                          Row(
                            children: List.generate(_featuredProducts.length, (
                              index,
                            ) {
                              final item = _featuredProducts[index];
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: index == 0 ? screenWidth * 0.025 : 0,
                                    left: index == 1 ? screenWidth * 0.025 : 0,
                                  ),
                                  child: _buildProductCard(
                                    title: item['title'] as String,
                                    price: item['price'] as String,
                                    icon: item['icon'] as IconData,
                                    isFavorite: item['isFavorite'] as bool,
                                    screenWidth: screenWidth,
                                    usableHeight: usableHeight,
                                    azulFondo: azulFondo,
                                    grisBorde: grisBorde,
                                    onFavoriteTap: () {
                                      setState(() {
                                        item['isFavorite'] =
                                            !(item['isFavorite'] as bool);
                                      });
                                    },
                                  ),
                                ),
                              );
                            }),
                          ),
                          SizedBox(height: usableHeight * 0.025),

                          // Título "Entrega o retiro"
                          Text(
                            'Entrega o retiro',
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: usableHeight * 0.015),

                          // Opciones de Entrega y Retiro
                          Row(
                            children: [
                              Expanded(
                                child: _buildDeliveryOption(
                                  title: 'Envío a domicilio',
                                  icon: Icons.local_shipping_outlined,
                                  isSelected: _selectedDeliveryOption == 0,
                                  screenWidth: screenWidth,
                                  usableHeight: usableHeight,
                                  azulFondo: azulFondo,
                                  amarilloOro: amarilloOro,
                                  grisBorde: grisBorde,
                                  onTap: () {
                                    setState(() {
                                      _selectedDeliveryOption = 0;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Expanded(
                                child: _buildDeliveryOption(
                                  title: 'Retiro en iglesia',
                                  icon: Icons.church_outlined,
                                  isSelected: _selectedDeliveryOption == 1,
                                  screenWidth: screenWidth,
                                  usableHeight: usableHeight,
                                  azulFondo: azulFondo,
                                  amarilloOro: amarilloOro,
                                  grisBorde: grisBorde,
                                  onTap: () {
                                    setState(() {
                                      _selectedDeliveryOption = 1;
                                    });
                                  },
                                ),
                              ),
                            ],
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
    );
  }

  // Componente: Banner Hero Promocional
  Widget _buildPromoBanner({
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color amarilloOro,
    required VoidCallback onTap,
  }) {
    return Container(
      width: screenWidth,
      height: usableHeight * 0.22,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(screenWidth * 0.045),
        gradient: const LinearGradient(
          colors: [Color(0xFF2C1F16), Color(0xFF4A3423)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(screenWidth * 0.045),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Recursos para\ncrecer en tu fe',
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.055,
              fontWeight: FontWeight.bold,
              height: 1.15,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: amarilloOro,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: usableHeight * 0.01,
              ),
            ),
            onPressed: onTap,
            child: Text(
              'Ver destacados',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Componente: Tarjeta de Producto
  Widget _buildProductCard({
    required String title,
    required String price,
    required IconData icon,
    required bool isFavorite,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color grisBorde,
    required VoidCallback onFavoriteTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        border: Border.all(color: grisBorde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen / Placeholder del producto con botón de favorito
          Container(
            height: usableHeight * 0.14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF2ECE4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(screenWidth * 0.04),
                topRight: Radius.circular(screenWidth * 0.04),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    icon,
                    size: screenWidth * 0.16,
                    color: const Color(0xFF6E5642),
                  ),
                ),
                Positioned(
                  top: usableHeight * 0.01,
                  right: screenWidth * 0.02,
                  child: GestureDetector(
                    onTap: onFavoriteTap,
                    child: Container(
                      padding: EdgeInsets.all(screenWidth * 0.015),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border_rounded,
                        color: isFavorite
                            ? Colors.red
                            : const Color(0xFF0055A5),
                        size: screenWidth * 0.045,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Información del producto (Título + Precio)
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.035),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.034,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: usableHeight * 0.003),
                Text(
                  price,
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.034,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Componente: Botón de Opción de Entrega
  Widget _buildDeliveryOption({
    required String title,
    required IconData icon,
    required bool isSelected,
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
        height: usableHeight * 0.065,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          border: Border.all(
            color: isSelected ? amarilloOro : grisBorde,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? amarilloOro : azulFondo,
              size: screenWidth * 0.055,
            ),
            SizedBox(width: screenWidth * 0.02),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? amarilloOro : azulFondo,
                  fontSize: screenWidth * 0.03,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
