import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../atrio_api.dart';
import '../l10n/app_localizations.dart';
import '../modelos/carrito_model.dart';
import '../modelos/producto_model.dart';
import '../providers/user_provider.dart';

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
  bool _isLoadingProducts = false;

  /// Carrito real sincronizado con Odoo (GET/POST/PUT/DELETE /store/cart*).
  CarritoModel _carrito = CarritoModel.vacio;
  bool _procesandoCarrito = false;

  /// Indica si el catálogo mostrado proviene de Odoo (y no del respaldo local).
  /// Solo los productos de Odoo pueden enviarse al carrito del servidor.
  bool _catalogoDesdeOdoo = false;

  int get _cartItemCount => _carrito.cantidadArticulos;

  /// 'Todos' + categorías públicas de Odoo (GET /store/categories).
  List<String> _categories = ['Todos', 'Biblias', 'Libros', 'Regalos'];

  String _getLocalizedCategory(String category, AppLocalizations? l10n) {
    switch (category.toLowerCase()) {
      case 'todos':
        return l10n?.categoriaTodos ?? 'Todos';
      case 'biblias':
        return l10n?.categoriaBiblias ?? 'Biblias';
      case 'libros':
        return l10n?.categoriaLibros ?? 'Libros';
      case 'regalos':
        return l10n?.categoriaRegalos ?? 'Regalos';
      default:
        return category;
    }
  }

  // Catálogo inicial de 5 productos reales (preparado para Odoo 19)
  final List<ProductoModel> _productsList = [
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sincronizarTienda();
    });
  }

  /// Sincroniza catálogo, categorías y carrito con Odoo en paralelo.
  /// Se usa al abrir la pantalla y en el pull-to-refresh.
  Future<void> _sincronizarTienda() async {
    await Future.wait([
      _cargarProductosOdoo(),
      _cargarCategoriasOdoo(),
      _cargarCarrito(),
    ]);
  }

  /// Carga los productos reales desde el catálogo de la tienda en Odoo (GET /store/products)
  Future<void> _cargarProductosOdoo() async {
    if (!mounted) return;
    setState(() => _isLoadingProducts = true);

    try {
      final api = context.read<UserProvider>().api;
      final data = await api.storeProducts(limit: 50);
      final dynamic raw = data['products'] ?? data['items'] ?? data['data'];

      if (raw is List && raw.isNotEmpty && mounted) {
        final List<ProductoModel> loaded = raw
            .map((p) => ProductoModel.fromJson(p as Map<String, dynamic>))
            .toList();

        setState(() {
          _productsList
            ..clear()
            ..addAll(loaded);
          _catalogoDesdeOdoo = true;
        });
      }
    } catch (e) {
      debugPrint('[TIENDA] Fallback catálogo local activo: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProducts = false);
    }
  }

  /// Carga las categorías públicas de la tienda (GET /store/categories)
  Future<void> _cargarCategoriasOdoo() async {
    try {
      final api = context.read<UserProvider>().api;
      final data = await api.storeCategories();
      final raw = data['categories'];
      if (raw is List && raw.isNotEmpty && mounted) {
        final nombres = raw
            .whereType<Map<String, dynamic>>()
            .map((c) => (c['name'] ?? '').toString())
            .where((n) => n.isNotEmpty)
            .toList();
        setState(() {
          _categories = ['Todos', ...nombres];
          if (_selectedCategoryIndex >= _categories.length) {
            _selectedCategoryIndex = 0;
          }
        });
      }
    } catch (e) {
      debugPrint('[TIENDA] Categorías locales activas: $e');
    }
  }

  /// Obtiene el carrito actual del usuario desde Odoo (GET /store/cart)
  Future<void> _cargarCarrito() async {
    try {
      final api = context.read<UserProvider>().api;
      final data = await api.cart();
      if (mounted) {
        setState(() => _carrito = CarritoModel.fromResponse(data));
      }
    } catch (e) {
      debugPrint('[CARRITO] No se pudo obtener el carrito: $e');
    }
  }

  /// Ejecuta una operación de carrito contra Odoo, actualiza el estado con el
  /// carrito devuelto por el servidor y muestra errores tipados de la API.
  /// Retorna true si la operación fue exitosa.
  Future<bool> _operarCarrito(
    Future<Map<String, dynamic>> Function(AtrioApi api) operacion,
  ) async {
    if (_procesandoCarrito) return false;
    final api = context.read<UserProvider>().api;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _procesandoCarrito = true);
    try {
      final data = await operacion(api);
      if (!mounted) return false;
      setState(() => _carrito = CarritoModel.fromResponse(data));
      return true;
    } on AtrioApiException catch (e) {
      debugPrint('[CARRITO] $e');
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return false;
    } catch (e) {
      debugPrint('[CARRITO] Error inesperado: $e');
      messenger.showSnackBar(
        SnackBar(
          content: const Text('No se pudo conectar con la tienda. Intenta de nuevo.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return false;
    } finally {
      if (mounted) setState(() => _procesandoCarrito = false);
    }
  }

  /// Agrega un producto al carrito de Odoo (POST /store/cart/items)
  Future<void> _agregarAlCarrito(ProductoModel producto) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final productId = int.tryParse(producto.id);

    if (!_catalogoDesdeOdoo || productId == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'El catálogo no está sincronizado con la tienda. Desliza hacia abajo para actualizar.',
          ),
        ),
      );
      return;
    }

    final ok = await _operarCarrito((api) => api.addToCart(productId));
    if (ok && mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n?.productoAgregadoAlCarrito(producto.nombre) ??
                '¡"${producto.nombre}" agregado al carrito!',
          ),
          backgroundColor: const Color(0xFF072B4F),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Modifica la cantidad de un producto en el carrito (PUT /store/cart/items/:id)
  Future<void> _modificarCantidad(int productId, int nuevaCantidad) async {
    if (nuevaCantidad <= 0) {
      await _eliminarDelCarrito(productId);
    } else {
      await _operarCarrito((api) => api.updateCartItem(productId, nuevaCantidad));
    }
  }

  /// Elimina un producto del carrito (DELETE /store/cart/items/:id)
  Future<void> _eliminarDelCarrito(int productId) async {
    await _operarCarrito((api) => api.removeFromCart(productId));
  }

  /// Vacía todo el carrito (DELETE /store/cart)
  Future<void> _vaciarCarrito() async {
    await _operarCarrito((api) => api.clearCart());
  }

  /// Confirma el pedido en Odoo (POST /store/checkout)
  Future<void> _confirmarPedido(BuildContext modalContext) async {
    if (_carrito.estaVacio) return;
    final api = context.read<UserProvider>().api;
    final messenger = ScaffoldMessenger.of(context);

    final confirmar = await showDialog<bool>(
      context: modalContext,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmar Pedido'),
        content: Text(
          '¿Deseas confirmar la compra de ${_carrito.cantidadArticulos} artículo(s) por un total de ${_carrito.formatear(_carrito.total)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF072B4F),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar Pedido'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _procesandoCarrito = true);
    try {
      final res = await api.checkout({
        'delivery_method': _selectedDeliveryOption == 0 ? 'delivery' : 'pickup',
      });

      if (modalContext.mounted) {
        Navigator.pop(modalContext);
      }

      setState(() {
        _carrito = CarritoModel.vacio;
      });

      if (!mounted) return;

      final order = res['order'] as Map<String, dynamic>?;
      final ref = order?['name'] ?? res['reference'] ?? 'S00000';
      final estado = order?['status_label'] ?? 'Pago en verificación';
      final total = order?['amount_total'] != null
          ? 'RD\$${order!['amount_total']}'
          : _carrito.formatear(_carrito.total);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 56),
          title: Text(
            '¡Pedido $ref Registrado!',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tu orden se ha generado en Odoo exitosamente.'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Referencia Odoo: $ref', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('• Estado: $estado'),
                    const SizedBox(height: 4),
                    Text('• Total: $total', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF072B4F))),
                    const SizedBox(height: 4),
                    Text(
                      '• Modalidad: ${_selectedDeliveryOption == 0 ? "Envío a domicilio" : "Retiro en iglesia"}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Puedes realizar el pago mediante transferencia bancaria o en efectivo en las oficinas de la iglesia.',
                style: TextStyle(fontSize: 12, color: Colors.black87),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF072B4F),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } on AtrioApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al procesar el pedido: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _procesandoCarrito = false);
    }
  }

  /// Despliega el modal interactivo del Carrito de Compras
  void _mostrarCarritoModal(BuildContext context) {
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
              constraints: BoxConstraints(maxHeight: usableHeight * 0.85),
              decoration: BoxDecoration(
                color: blancoFondo,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(screenWidth * 0.06),
                  topRight: Radius.circular(screenWidth * 0.06),
                ),
              ),
              padding: EdgeInsets.only(
                left: screenWidth * 0.05,
                right: screenWidth * 0.05,
                top: usableHeight * 0.018,
                bottom: MediaQuery.of(modalContext).padding.bottom + usableHeight * 0.02,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra superior
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
                  SizedBox(height: usableHeight * 0.015),

                  // Cabecera: Título e ícono
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shopping_cart_rounded, color: azulFondo, size: screenWidth * 0.06),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            'Carrito de Compras',
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.046,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (!_carrito.estaVacio)
                        TextButton.icon(
                          onPressed: _procesandoCarrito
                              ? null
                              : () async {
                                  await _vaciarCarrito();
                                  setModalState(() {});
                                },
                          icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: Colors.red),
                          label: const Text(
                            'Vaciar',
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        )
                      else
                        IconButton(
                          onPressed: () => Navigator.pop(modalContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                    ],
                  ),
                  const Divider(),

                  if (_procesandoCarrito)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: LinearProgressIndicator(color: amarilloOro, backgroundColor: Colors.transparent),
                    ),

                  // Si el carrito está vacío
                  if (_carrito.estaVacio) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: usableHeight * 0.06),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.remove_shopping_cart_outlined,
                              size: screenWidth * 0.18,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: usableHeight * 0.015),
                            Text(
                              'Tu carrito está vacío',
                              style: TextStyle(
                                color: azulFondo,
                                fontSize: screenWidth * 0.042,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: usableHeight * 0.008),
                            Text(
                              'Explora nuestro catálogo y agrega tus productos favoritos.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: screenWidth * 0.032,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Lista de artículos
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _carrito.lineas.length,
                        separatorBuilder: (_, index) => const Divider(height: 1),
                        itemBuilder: (ctx, idx) {
                          final item = _carrito.lineas[idx];
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: usableHeight * 0.01),
                            child: Row(
                              children: [
                                Container(
                                  width: screenWidth * 0.12,
                                  height: screenWidth * 0.12,
                                  decoration: BoxDecoration(
                                    color: azulFondo.withValues(alpha: 0.07),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.shopping_bag_outlined,
                                    color: azulFondo,
                                    size: screenWidth * 0.06,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.03),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.nombre,
                                        style: TextStyle(
                                          color: azulFondo,
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenWidth * 0.034,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: usableHeight * 0.003),
                                      Text(
                                        '${_carrito.simboloMoneda}${item.precioUnitario.toStringAsFixed(0)} c/u',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: screenWidth * 0.028,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Row(
                                  children: [
                                    InkWell(
                                      onTap: _procesandoCarrito
                                          ? null
                                          : () async {
                                              await _modificarCantidad(
                                                item.productoId,
                                                item.cantidad - 1,
                                              );
                                              setModalState(() {});
                                            },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.remove, size: 16),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        '${item.cantidad}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: screenWidth * 0.034,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: _procesandoCarrito
                                          ? null
                                          : () async {
                                              await _modificarCantidad(
                                                item.productoId,
                                                item.cantidad + 1,
                                              );
                                              setModalState(() {});
                                            },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: amarilloOro,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.add, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: screenWidth * 0.02),

                                Text(
                                  '${_carrito.simboloMoneda}${item.subtotal.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: azulFondo,
                                    fontSize: screenWidth * 0.034,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const Divider(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total a pagar:',
                          style: TextStyle(
                            color: azulFondo,
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _carrito.formatear(_carrito.total),
                          style: TextStyle(
                            color: amarilloOro,
                            fontSize: screenWidth * 0.048,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.015),

                    SizedBox(
                      width: double.infinity,
                      height: usableHeight * 0.052,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: amarilloOro,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.025),
                          ),
                        ),
                        onPressed: _procesandoCarrito ? null : () => _confirmarPedido(modalContext),
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: Text(
                          'Confirmar Pedido · ${_carrito.formatear(_carrito.total)}',
                          style: TextStyle(
                            fontSize: screenWidth * 0.036,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
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

    final l10n = AppLocalizations.of(context);

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
                          onTap: () => _mostrarCarritoModal(context),
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
                          child: Tooltip(
                            message: l10n?.volver ?? 'Volver',
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
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Text(
                          l10n?.tienda ?? 'Tienda',
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
                          hintText: l10n?.buscarProductosPlaceholder ??
                              'Buscar biblias, libros o regalos...',
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
                    child: RefreshIndicator(
                      onRefresh: _cargarProductosOdoo,
                      color: amarilloOro,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: usableHeight * 0.02,
                        ),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isLoadingProducts)
                            Padding(
                              padding: EdgeInsets.only(bottom: usableHeight * 0.01),
                              child: const LinearProgressIndicator(
                                color: amarilloOro,
                                backgroundColor: Colors.transparent,
                              ),
                            ),
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
                                        _getLocalizedCategory(
                                          _categories[index],
                                          l10n,
                                        ),
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
                            l10n: l10n,
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
                                l10n?.catalogoDeProductos ??
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
                                    l10n?.verTodos ?? 'Ver todos',
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
                                          l10n?.noSeEncontraronProductosCategoria ??
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
                                      l10n: l10n,
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
                            l10n?.entregaORetiro ?? 'Entrega o retiro',
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
                                  title: l10n?.envioADomicilio ??
                                      'Envío a domicilio',
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
                                  title: l10n?.retiroEnIglesia ??
                                      'Retiro en iglesia',
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
    required AppLocalizations? l10n,
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
                  l10n?.recursosParaCrecerEnTuFe ??
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
                    l10n?.verDestacados ?? 'Ver destacados',
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

  IconData _getCategoryIcon(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'biblias':
        return Icons.menu_book_rounded;
      case 'libros':
        return Icons.auto_stories_rounded;
      case 'música':
      case 'musica':
        return Icons.headphones_rounded;
      case 'artículos de fe':
      case 'articulos de fe':
        return Icons.church_rounded;
      case 'regalos':
        return Icons.card_giftcard_rounded;
      case 'ropa y accesorios':
        return Icons.checkroom_rounded;
      case 'papelería':
      case 'papeleria':
        return Icons.edit_note_rounded;
      case 'paquetes':
        return Icons.inventory_2_rounded;
      default:
        return Icons.shopping_bag_outlined;
    }
  }

  Widget _buildFallbackProductIcon(String categoria, double iconSize) {
    return Container(
      color: const Color(0xFFF2ECE4),
      child: Center(
        child: Icon(
          _getCategoryIcon(categoria),
          size: iconSize,
          color: const Color(0xFF6E5642),
        ),
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
    required AppLocalizations? l10n,
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
                    if (producto.imageUrl.isNotEmpty &&
                        producto.imageUrl.startsWith('http'))
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
                        errorBuilder: (context, error, stackTrace) =>
                            _buildFallbackProductIcon(
                              producto.categoria,
                              screenWidth * 0.12,
                            ),
                      )
                    else
                      _buildFallbackProductIcon(
                        producto.categoria,
                        screenWidth * 0.12,
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
                          _getLocalizedCategory(producto.categoria, l10n),
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
    final l10n = AppLocalizations.of(context);

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
                          child: (producto.imageUrl.isNotEmpty &&
                                  producto.imageUrl.startsWith('http'))
                              ? Image.network(
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
                                      _buildFallbackProductIcon(
                                        producto.categoria,
                                        screenWidth * 0.10,
                                      ),
                                )
                              : _buildFallbackProductIcon(
                                  producto.categoria,
                                  screenWidth * 0.10,
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
                                    _getLocalizedCategory(
                                      producto.categoria,
                                      l10n,
                                    ),
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
                              l10n?.unidadesEnInventario(
                                    producto.stock.toString(),
                                  ) ??
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
                      l10n?.detallesDelProducto ?? 'Detalles del producto',
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
                        _agregarAlCarrito(producto);
                      },
                      icon: Icon(
                        Icons.add_shopping_cart_rounded,
                        size: screenWidth * 0.05,
                      ),
                      label: Text(
                        l10n?.agregarAlCarritoConPrecio(
                              producto.precioFormateado,
                            ) ??
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
