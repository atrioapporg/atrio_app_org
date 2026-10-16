class PedidoItemModel {
  final String nombre;
  final double cantidad;

  const PedidoItemModel({
    required this.nombre,
    required this.cantidad,
  });

  factory PedidoItemModel.fromJson(Map<String, dynamic> json) {
    return PedidoItemModel(
      nombre: (json['name'] ?? json['nombre'] ?? 'Producto').toString(),
      cantidad: (json['quantity'] ?? json['qty'] ?? 1.0) is num
          ? (json['quantity'] ?? json['qty'] ?? 1.0).toDouble()
          : (double.tryParse((json['quantity'] ?? 1).toString()) ?? 1.0),
    );
  }
}

class PedidoModel {
  final int id;
  final String nombre;
  final String fecha;
  final double total;
  final String simboloMoneda;
  final String estado;
  final String estadoEtiqueta;
  final String colorEstado;
  final int cantidadArticulos;
  final List<PedidoItemModel> items;
  final String? portalUrl;

  const PedidoModel({
    required this.id,
    required this.nombre,
    required this.fecha,
    required this.total,
    required this.simboloMoneda,
    required this.estado,
    required this.estadoEtiqueta,
    required this.colorEstado,
    required this.cantidadArticulos,
    required this.items,
    this.portalUrl,
  });

  factory PedidoModel.fromJson(Map<String, dynamic> json) {
    final currency = json['currency'];
    String simbolo = 'RD\$';
    if (currency is Map) {
      simbolo = (currency['symbol'] ?? currency['code'] ?? 'RD\$').toString();
    }

    final rawItems = json['items'];
    final List<PedidoItemModel> parsedItems = rawItems is List
        ? rawItems
            .whereType<Map<String, dynamic>>()
            .map(PedidoItemModel.fromJson)
            .toList()
        : [];

    final rawTotal = json['amount_total'] ?? json['total'] ?? 0.0;
    final total = rawTotal is num
        ? rawTotal.toDouble()
        : (double.tryParse(rawTotal.toString()) ?? 0.0);

    return PedidoModel(
      id: json['id'] is int ? json['id'] as int : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      nombre: (json['name'] ?? json['reference'] ?? 'S00000').toString(),
      fecha: (json['date_order'] ?? json['date'] ?? '').toString(),
      total: total,
      simboloMoneda: simbolo,
      estado: (json['status'] ?? json['state'] ?? 'draft').toString(),
      estadoEtiqueta: (json['status_label'] ?? json['state_label'] ?? 'Pendiente').toString(),
      colorEstado: (json['status_color'] ?? 'orange').toString(),
      cantidadArticulos: (json['item_count'] is int)
          ? json['item_count'] as int
          : (parsedItems.isNotEmpty ? parsedItems.length : 1),
      items: parsedItems,
      portalUrl: json['portal_url']?.toString(),
    );
  }

  String get totalFormateado {
    final formatted = total.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
    return '$simboloMoneda $formatted';
  }

  String formatearFecha({bool isEnglish = false}) {
    if (fecha.isEmpty) return isEnglish ? 'Recent' : 'Reciente';
    try {
      final dt = DateTime.parse(fecha).toLocal();
      const mesesEs = [
        'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
      ];
      const mesesEn = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final mes = isEnglish ? mesesEn[dt.month - 1] : mesesEs[dt.month - 1];
      final hora = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final amPm = isEnglish
          ? (dt.hour >= 12 ? 'PM' : 'AM')
          : (dt.hour >= 12 ? 'p. m.' : 'a. m.');
      final min = dt.minute.toString().padLeft(2, '0');
      return isEnglish
          ? '$mes ${dt.day}, ${dt.year} · $hora:$min $amPm'
          : '${dt.day} $mes ${dt.year} · $hora:$min $amPm';
    } catch (_) {
      return fecha.split('T').first;
    }
  }

  String get fechaFormateada => formatearFecha(isEnglish: false);
}
