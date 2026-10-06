import 'package:flutter/material.dart';

import '../modelos/producto_model.dart';

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
  int _cartItemCount = 2;

  final List<String> _categories = ['Todos', 'Biblias', 'Libros', 'Regalos'];

  // Catálogo inicial de 5 productos reales (preparado para Odoo 19)
  late final List<ProductoModel> _productsList = [
    ProductoModel(
      id: '1',
      nombre: 'Biblia de Estudio LBLA',
      precio: 2200.0,
      categoria: 'Biblias',
      imageUrl:
          'https://imagessl7.casadellibro.com/a/l/t7/60/9780829768060.jpg',
      descripcion: 'Edición de tapa dura con más de 14,000 notas explicativas, mapas a color, concordancia y tablas cronológicas para el estudio profundo.',
      stock: 14,
      esFavorito: false,
      esDestacado: true,
      rating: 4.9,
    ),
    ProductoModel(
      id: '2',
      nombre: 'Jesús te llama',
      precio: 650.0,
      categoria: 'Libros',
      imageUrl:
          'https://imagessl7.casadellibro.com/a/l/t7/91/9781602554191.jpg',
      descripcion: '365 lecturas devocionales llenas de paz y aliento escritas por Sarah Young para experimentar la presencia de Dios día a día.',
      stock: 25,
      esFavorito: true,
      esDestacado: true,
      rating: 4.8,
    ),
    ProductoModel(
      id: '3',
      nombre: 'RVR 1960 Vida Plena',
      precio: 1850.0,
      categoria: 'Biblias',
      imageUrl:
          'https://imagessl7.casadellibro.com/a/l/t7/02/9780829719802.jpg',
      descripcion: 'Biblia de estudio enfocada en la obra del Espíritu Santo en el creyente. Incluye notas teológicas, introducciones y referencias temáticas.',
      stock: 8,
      esFavorito: false,
      esDestacado: false,
      rating: 4.7,
    ),
    ProductoModel(
      id: '4',
      nombre: 'Taza Cerámica Filipenses',
      precio: 450.0,
      categoria: 'Regalos',
      imageUrl: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=640&q=80',
      descripcion: 'Taza de cerámica de 11 oz con diseño inspirador "Todo lo puedo en Cristo", apta para microondas y lavavajillas. Excelente obsequio.',
      stock: 30,
      esFavorito: false,
      esDestacado: false,
      rating: 4.6,
    ),
    ProductoModel(
      id: '5',
      nombre: 'Cuaderno Diario de Oración',
      precio: 550.0,
      categoria: 'Regalos',
      imageUrl: 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?auto=format&fit=crop&w=640&q=80',
      descripcion: 'Diario de tapa dura con 160 páginas con versículos y guía práctica para registrar motivos de oración, agradecimientos y respuestas.',
      stock: 18,
      esFavorito: false,
      esDestacado: false,
      rating: 4.8,
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

  // Filtrado reactivo por categorías y búsqueda
  List<ProductoModel> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    final selectedCategory = _categories[_selectedCategoryIndex];

    return _productsList.where((product) {
      final matchesCategory =
          selectedCategory == 'Todos' ||
          product.categoria.toLowerCase() == selectedCategory.toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          product.nombre.toLowerCase().contains(query) ||
          product.descripcion.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
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
              // 2. Encabezado Superior (Carrito + Título + Buscador)
              Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: usableHeight * 0.01),
                    // Fila superior: Carrito con badge dinámico
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Tienes $_cartItemCount productos en tu carrito de compras',
                                ),
                                backgroundColor: azulFondo,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Stack(
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
                                      '$_cartItemCount',
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

                    // Buscador reactivo de productos
                    Container(
                      height: usableHeight * 0.052,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar biblias, libros o regalos...',
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
                                      horizontal: screenWidth * 0.05,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? azulFondo
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        screenWidth * 0.03,
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

                          // Banner Hero Promocional interactivo
                          _buildPromoBanner(
                            screenWidth: screenWidth,
                            usableHeight: usableHeight,
                            amarilloOro: amarilloOro,
                            onTap: () {
                              _showProductDetailsModal(
                                context,
                                _productsList.first,
                              );
                            },
                          ),
                          SizedBox(height: usableHeight * 0.025),

                          // Encabezado de Productos destacados
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Catálogo de productos',
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

                          // Grid / Lista de Productos con imágenes reales
                          _filteredProducts.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: usableHeight * 0.04,
                                    ),
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
                                          'No se encontraron productos en esta categoría',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: screenWidth * 0.03,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _filteredProducts.length,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: usableHeight * 0.018,
                                        crossAxisSpacing: screenWidth * 0.03,
                                        childAspectRatio: 0.72,
                                      ),
                                  itemBuilder: (context, index) {
                                    final item = _filteredProducts[index];
                                    return _buildProductCard(
                                      producto: item,
                                      screenWidth: screenWidth,
                                      usableHeight: usableHeight,
                                      azulFondo: azulFondo,
                                      grisBorde: grisBorde,
                                      amarilloOro: amarilloOro,
                                      onTap: () => _showProductDetailsModal(
                                        context,
                                        item,
                                      ),
                                      onFavoriteTap: () {
                                        setState(() {
                                          item.esFavorito = !item.esFavorito;
                                        });
                                      },
                                    );
                                  },
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
    required Color amarilloOro,
    required VoidCallback onTap,
  }) {
    return Container(
      width: screenWidth,
      height: usableHeight * 0.20,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(screenWidth * 0.045),
        gradient: const LinearGradient(
          colors: [Color(0xFF2C1F16), Color(0xFF4A3423)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(screenWidth * 0.045),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recursos para\ncrecer en tu fe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.052,
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
                      borderRadius: BorderRadius.circular(screenWidth * 0.025),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: usableHeight * 0.008,
                    ),
                  ),
                  onPressed: onTap,
                  child: Text(
                    'Ver destacados',
                    style: TextStyle(
                      fontSize: screenWidth * 0.032,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Miniatura decorativa destacada
          Container(
            width: screenWidth * 0.22,
            height: usableHeight * 0.14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(1, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
              child: Image.network(
                'https://imagessl7.casadellibro.com/a/l/t7/60/9780829768060.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF1E2D3D),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Componente: Tarjeta de Producto con Fotografía Real y Shimmer
  Widget _buildProductCard({
    required ProductoModel producto,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color grisBorde,
    required Color amarilloOro,
    required VoidCallback onTap,
    required VoidCallback onFavoriteTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          border: Border.all(color: grisBorde),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fotografía real del producto con botón flotante de favorito
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(screenWidth * 0.04),
                  topRight: Radius.circular(screenWidth * 0.04),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      producto.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return _ShimmerPlaceholder(
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: 0,
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFF2ECE4),
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          size: screenWidth * 0.12,
                          color: const Color(0xFF6E5642),
                        ),
                      ),
                    ),
                    // Botón flotante de favorito
                    Positioned(
                      top: usableHeight * 0.01,
                      right: screenWidth * 0.02,
                      child: GestureDetector(
                        onTap: onFavoriteTap,
                        child: Container(
                          padding: EdgeInsets.all(screenWidth * 0.015),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            producto.esFavorito
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: producto.esFavorito
                                ? const Color(0xFFE53935)
                                : Colors.grey.shade600,
                            size: screenWidth * 0.045,
                          ),
                        ),
                      ),
                    ),
                    // Badge de categoría
                    Positioned(
                      bottom: usableHeight * 0.008,
                      left: screenWidth * 0.02,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.02,
                          vertical: usableHeight * 0.002,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.01,
                          ),
                        ),
                        child: Text(
                          producto.categoria,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.022,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Información del producto (Título + Precio + Calificación)
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.032,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: usableHeight * 0.004),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        producto.precioFormateado,
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.036,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: screenWidth * 0.035,
                            color: amarilloOro,
                          ),
                          SizedBox(width: screenWidth * 0.005),
                          Text(
                            '${producto.rating}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: screenWidth * 0.026,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modal Inferior de Detalle de Producto y Compra (Bottom Sheet)
  void _showProductDetailsModal(BuildContext context, ProductoModel producto) {
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
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                  // Barra de arrastre superior
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

                  // Cabecera: Imagen del producto y detalles principales
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fotografía del producto
                      Container(
                        width: screenWidth * 0.30,
                        height: usableHeight * 0.18,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.03,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(1, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.03,
                          ),
                          child: Image.network(
                            producto.imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return _ShimmerPlaceholder(
                                width: screenWidth * 0.30,
                                height: usableHeight * 0.18,
                                borderRadius: screenWidth * 0.03,
                              );
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: const Color(0xFFF2ECE4),
                                  child: const Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 36,
                                    color: Color(0xFF6E5642),
                                  ),
                                ),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.045),

                      // Datos: Categoría, Nombre, Precio, Stock
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    producto.categoria,
                                    style: TextStyle(
                                      color: azulFondo,
                                      fontSize: screenWidth * 0.028,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: screenWidth * 0.04,
                                      color: amarilloOro,
                                    ),
                                    SizedBox(width: screenWidth * 0.005),
                                    Text(
                                      '${producto.rating}',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: screenWidth * 0.028,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: usableHeight * 0.008),
                            Text(
                              producto.nombre,
                              style: TextStyle(
                                color: azulFondo,
                                fontSize: screenWidth * 0.046,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: usableHeight * 0.006),
                            Text(
                              producto.precioFormateado,
                              style: TextStyle(
                                color: amarilloOro,
                                fontSize: screenWidth * 0.055,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: usableHeight * 0.004),
                            Text(
                              '${producto.stock} unidades en inventario',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: screenWidth * 0.026,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.02),

                  // Descripción del producto
                  if (producto.descripcion.isNotEmpty) ...[
                    Text(
                      'Detalles del producto',
                      style: TextStyle(
                        color: azulFondo,
                        fontSize: screenWidth * 0.038,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.005),
                    Text(
                      producto.descripcion,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: screenWidth * 0.031,
                        height: 1.35,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: usableHeight * 0.02),
                  ],

                  // Botón Agregar al Carrito
                  SizedBox(
                    width: double.infinity,
                    height: usableHeight * 0.052,
                    child: ElevatedButton.icon(
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
                      onPressed: () {
                        Navigator.pop(modalContext);
                        setState(() {
                          _cartItemCount += 1;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '¡"${producto.nombre}" agregado al carrito!',
                            ),
                            backgroundColor: azulFondo,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.add_shopping_cart_rounded,
                        size: screenWidth * 0.05,
                      ),
                      label: Text(
                        'Agregar al carrito · ${producto.precioFormateado}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
              Icons.shopping_bag_outlined,
              color: Color(0xFFC4CBD4),
              size: 26,
            ),
          ),
        );
      },
    );
  }
}
