class ProductoModel {
  final String id;
  final String nombre;
  final double precio;
  final String moneda;
  final String categoria;
  final String imageUrl;
  final String descripcion;
  final int stock;
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
    this.esFavorito = false,
    this.esDestacado = false,
    this.rating = 4.8,
  });

  String get precioFormateado => '$moneda${precio.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';

  /// Deserializa respuestas JSON-RPC o REST provenientes del catálogo de Odoo 19
  factory ProductoModel.fromJson(Map<String, dynamic> json) => ProductoModel(
        id: json['id']?.toString() ?? '',
        nombre: json['name'] ?? json['nombre'] ?? '',
        precio: ((json['list_price'] ?? json['precio'] ?? 0.0) as num).toDouble(),
        moneda: json['currency'] ?? json['moneda'] ?? 'RD\$',
        categoria: json['category'] ?? json['categoria'] ?? 'Libros',
        imageUrl: json['image_url'] ?? json['imagen_url'] ?? '',
        descripcion: json['description_sale'] ?? json['descripcion'] ?? '',
        stock: (json['qty_available'] ?? json['stock'] ?? 10) as int,
        esFavorito: json['is_favorite'] ?? json['es_favorito'] ?? false,
        esDestacado: json['is_featured'] ?? json['es_destacado'] ?? false,
        rating: ((json['rating'] ?? 4.8) as num).toDouble(),
      );

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
