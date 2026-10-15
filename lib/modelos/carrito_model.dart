/// Modelo del carrito de compras de la Tienda ATRIO (Odoo 19).
///
/// Formato real de `GET/POST/PUT/DELETE /store/cart*`:
/// ```json
/// {"cart": {"id": 2, "currency": {"code": "DOP", "symbol": "RD$", "position": "before"},
///   "item_count": 2, "amount_untaxed": 1180.0, "amount_tax": 0.0, "amount_total": 1180.0,
///   "lines": [{"id": 2, "product_id": 38, "name": "Adoración", "quantity": 2,
///              "price_unit": 590.0, "price_subtotal": 1180.0, "price_total": 1180.0,
///              "image_url": null}]}}
/// ```
class CarritoModel {
  final int? id;
  final String simboloMoneda;
  final bool simboloAntes;
  final int cantidadArticulos;
  final double subtotal;
  final double impuestos;
  final double total;
  final List<LineaCarritoModel> lineas;

  const CarritoModel({
    this.id,
    this.simboloMoneda = 'RD\$',
    this.simboloAntes = true,
    this.cantidadArticulos = 0,
    this.subtotal = 0,
    this.impuestos = 0,
    this.total = 0,
    this.lineas = const [],
  });

  static const CarritoModel vacio = CarritoModel();

  bool get estaVacio => lineas.isEmpty;

  /// Acepta tanto la respuesta completa `{"cart": {...}}` como el objeto interno.
  factory CarritoModel.fromResponse(Map<String, dynamic> data) {
    final raw = data['cart'] is Map<String, dynamic>
        ? data['cart'] as Map<String, dynamic>
        : data;
    return CarritoModel.fromJson(raw);
  }

  factory CarritoModel.fromJson(Map<String, dynamic> json) {
    final currency = json['currency'];
    String simbolo = 'RD\$';
    bool antes = true;
    if (currency is Map) {
      simbolo = (currency['symbol'] ?? currency['code'] ?? 'RD\$').toString();
      antes = (currency['position'] ?? 'before') != 'after';
    }

    final rawLines = json['lines'];
    final lineas = rawLines is List
        ? rawLines
            .whereType<Map<String, dynamic>>()
            .map(LineaCarritoModel.fromJson)
            .toList()
        : <LineaCarritoModel>[];

    return CarritoModel(
      id: json['id'] is int ? json['id'] as int : null,
      simboloMoneda: simbolo,
      simboloAntes: antes,
      cantidadArticulos: _toInt(json['item_count']),
      subtotal: _toDouble(json['amount_untaxed']),
      impuestos: _toDouble(json['amount_tax']),
      total: _toDouble(json['amount_total']),
      lineas: lineas,
    );
  }

  /// Formatea un monto con separador de miles y el símbolo de la moneda del carrito.
  String formatear(double monto) {
    final numero = monto.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return simboloAntes ? '$simboloMoneda$numero' : '$numero $simboloMoneda';
  }
}

class LineaCarritoModel {
  final int id;
  final int productoId;
  final String nombre;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final double total;
  final String imageUrl;

  const LineaCarritoModel({
    required this.id,
    required this.productoId,
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    required this.total,
    this.imageUrl = '',
  });

  factory LineaCarritoModel.fromJson(Map<String, dynamic> json) {
    String img = (json['image_url'] ?? '').toString();
    if (img.startsWith('/')) {
      img = 'https://atrioapp.odoo19rd.com$img';
    }
    return LineaCarritoModel(
      id: _toInt(json['id']),
      productoId: _toInt(json['product_id']),
      nombre: (json['name'] ?? '').toString(),
      cantidad: _toInt(json['quantity']),
      precioUnitario: _toDouble(json['price_unit']),
      subtotal: _toDouble(json['price_subtotal']),
      total: _toDouble(json['price_total']),
      imageUrl: img,
    );
  }
}

int _toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
double _toDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0;
