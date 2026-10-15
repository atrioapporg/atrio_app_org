class ProductoModel {
  final String id;
  final String nombre;
  final double precio;
  final String moneda;
  final String categoria;
  final String imageUrl;
  final String descripcion;
  final int stock;

  /// Disponibilidad según Odoo (`in_stock`). Puede ser true aunque `stock` sea 0
  /// (productos sin control de inventario).
  final bool enStock;
  bool esFavorito;
  final bool esDestacado;
  final double rating;

  ProductoModel({
    required this.id,
    required this.nombre,
    required this.precio,
    this.moneda = 'RD\$',
    required this.categoria,
    required this.imageUrl,
    this.descripcion = '',
    this.stock = 10,
    this.enStock = true,
    this.esFavorito = false,
    this.esDestacado = false,
    this.rating = 4.8,
  });

  String get precioFormateado => '$moneda${precio.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';

  /// URL base para resolver rutas relativas de imágenes servidas por Odoo.
  static const String _odooBaseUrl = 'https://atrioapp.odoo19rd.com';

  /// Deserializa respuestas JSON-RPC o REST provenientes del catálogo de Odoo 19.
  ///
  /// Formato real de `GET /store/products`:
  /// `currency` es un objeto `{code, symbol}`, `qty_available` es double,
  /// la categoría llega en `public_categories[0].name` y `image_url` puede ser
  /// nula o relativa.
  factory ProductoModel.fromJson(Map<String, dynamic> json) {
    // Moneda: objeto {code, symbol} (Odoo 19) o String (formato legado)
    final rawCurrency = json['currency'] ?? json['moneda'];
    String moneda = 'RD\$';
    if (rawCurrency is Map) {
      moneda = (rawCurrency['symbol'] ?? rawCurrency['code'] ?? 'RD\$').toString();
    } else if (rawCurrency is String && rawCurrency.isNotEmpty) {
      moneda = rawCurrency;
    }

    // Categoría: public_categories (Odoo 19) o category/categoria
    String categoria = 'General';
    final publicCats = json['public_categories'];
    if (publicCats is List && publicCats.isNotEmpty && publicCats.first is Map) {
      categoria = (publicCats.first['name'] ?? 'General').toString();
    } else if (json['category'] is String) {
      categoria = json['category'] as String;
    } else if (json['category'] is Map) {
      categoria = (json['category']['name'] ?? 'General').toString();
    } else if (json['categoria'] is String) {
      categoria = json['categoria'] as String;
    }

    // Imagen: resolver rutas relativas de Odoo
    String imageUrl = (json['image_url'] ?? json['imagen_url'] ?? '').toString();
    if (imageUrl.startsWith('/')) {
      imageUrl = '$_odooBaseUrl$imageUrl';
    }

    // Stock: Odoo devuelve double (0.0). Se tolera cualquier num.
    final rawStock = json['qty_available'] ?? json['stock'] ?? 0;
    final stock = rawStock is num ? rawStock.toInt() : int.tryParse('$rawStock') ?? 0;

    final rawPrice = json['list_price'] ?? json['precio'] ?? 0;
    final rawRating = json['rating'] ?? 4.8;

    return ProductoModel(
      id: json['id']?.toString() ?? '',
      nombre: (json['name'] ?? json['nombre'] ?? '').toString(),
      precio: rawPrice is num ? rawPrice.toDouble() : double.tryParse('$rawPrice') ?? 0.0,
      moneda: moneda,
      categoria: categoria,
      imageUrl: imageUrl,
      descripcion: (json['description'] ??
              json['description_sale'] ??
              json['descripcion'] ??
              '')
          .toString(),
      stock: stock,
      enStock: json['in_stock'] is bool ? json['in_stock'] as bool : stock > 0,
      esFavorito: json['is_favorite'] ?? json['es_favorito'] ?? false,
      esDestacado: json['is_featured'] ?? json['es_destacado'] ?? false,
      rating: rawRating is num ? rawRating.toDouble() : 4.8,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': nombre,
        'list_price': precio,
        'currency': moneda,
        'category': categoria,
        'image_url': imageUrl,
        'description_sale': descripcion,
        'qty_available': stock,
        'is_favorite': esFavorito,
        'is_featured': esDestacado,
        'rating': rating,
      };
}
