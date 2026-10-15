class UserModel {
  final int id;
  final String nombre;
  final String email;
  final String? telefono;
  final String iglesiaActual;
  final String fechaRegistro;
  final String avatarIniciales;
  final bool esMiembroVerificado;

  // Objeto anidado de estadísticas
  final UserStats estadisticas;

  UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    this.telefono,
    required this.iglesiaActual,
    required this.fechaRegistro,
    required this.avatarIniciales,
    required this.esMiembroVerificado,
    required this.estadisticas,
  });

  // Constructor factory para convertir el Map (JSON) a nuestro objeto Dart
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      telefono: json['telefono'] as String?,
      iglesiaActual: json['iglesia_actual'] as String,
      fechaRegistro: json['fecha_registro'] as String,
      avatarIniciales: json['avatar_iniciales'] as String,
      esMiembroVerificado: json['es_miembro_verificado'] as bool,
      // Mapeo del objeto anidado
      estadisticas: UserStats.fromJson(
        json['estadisticas'] as Map<String, dynamic>,
      ),
    );
  }

  /// Constructor factory adaptado a la respuesta de Odoo (login y endpoint /me).
  factory UserModel.fromOdooJson(Map<String, dynamic> odooData) {
    final user = (odooData['user'] as Map<String, dynamic>?) ?? {};
    final member = (odooData['member'] as Map<String, dynamic>?) ?? {};
    final church = (odooData['church'] as Map<String, dynamic>?) ?? {};

    final id = (user['id'] ?? member['id'] ?? 0) as int;
    final nombre = (user['name'] ?? member['name'] ?? 'Usuario') as String;
    final email = (user['email'] ?? user['login'] ?? member['email'] ?? '') as String;
    final telefono = (member['phone'] ?? user['phone']) as String?;
    final iglesiaActual = (church['name'] ?? church['public_name'] ?? 'Iglesia Atrio') as String;
    final fechaRegistro = (user['create_date'] ?? DateTime.now().toIso8601String()) as String;

    final avatarIniciales = nombre.trim().isNotEmpty
        ? nombre.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'U';

    final statsMap = odooData['estadisticas'] as Map<String, dynamic>? ?? {};

    return UserModel(
      id: id,
      nombre: nombre,
      email: email,
      telefono: telefono,
      iglesiaActual: iglesiaActual,
      fechaRegistro: fechaRegistro,
      avatarIniciales: avatarIniciales,
      esMiembroVerificado: user['role'] == 'member' || member.isNotEmpty,
      estadisticas: UserStats.fromJson(statsMap),
    );
  }
}

// Sub-modelo para las estadísticas de actividad
class UserStats {
  final int solicitudesActivas;
  final int donacionesMes;
  final int notasBiblia;

  UserStats({
    required this.solicitudesActivas,
    required this.donacionesMes,
    required this.notasBiblia,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      solicitudesActivas: json['solicitudes_activas'] as int? ?? 0,
      donacionesMes: json['donaciones_mes'] as int? ?? 0,
      notasBiblia: json['notas_biblia'] as int? ?? 0,
    );
  }
}
