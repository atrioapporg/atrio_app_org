/// Ciclo de vida de verificación institucional (KYC) de una congregación en Odoo 19
/// conforme a las directrices de cumplimiento para organizaciones sin fines de lucro
/// (RD: RNC ISFL Ley 122-05 | HN: Personería Jurídica y RTN).
enum ChurchKycStatus {
  /// Creación inicial del perfil por el `church_admin`: El botón "Ofrendar" permanece oculto.
  draft,

  /// Carga de RNC/RTN y cuenta bancaria institucional: "Validación en curso" en Dashboard Pastoral.
  pendingKyc,

  /// Validación manual aprobada por el equipo legal de ATRIO: Botón de ofrenda y pasarela activos.
  approved,

  /// Disputas o inconsistencias legales detectadas: Desactivación inmediata de la recaudación.
  suspended;

  static ChurchKycStatus fromString(
    String? raw, {
    bool fallbackVerified = false,
  }) {
    if (raw == null || raw.trim().isEmpty) {
      return fallbackVerified
          ? ChurchKycStatus.pendingKyc
          : ChurchKycStatus.draft;
    }
    switch (raw.trim().toLowerCase()) {
      case 'draft':
      case 'borrador':
      case 'unverified':
        return ChurchKycStatus.draft;
      case 'pending_kyc':
      case 'pending':
      case 'in_review':
      case 'en_revision':
        return ChurchKycStatus.pendingKyc;
      case 'approved':
      case 'verified':
      case 'aprobado':
      case 'verificada':
        return ChurchKycStatus.approved;
      case 'suspended':
      case 'rejected':
      case 'suspendida':
      case 'rechazada':
        return ChurchKycStatus.suspended;
      default:
        return fallbackVerified
            ? ChurchKycStatus.pendingKyc
            : ChurchKycStatus.draft;
    }
  }

  String toOdooString() {
    switch (this) {
      case ChurchKycStatus.draft:
        return 'draft';
      case ChurchKycStatus.pendingKyc:
        return 'pending_kyc';
      case ChurchKycStatus.approved:
        return 'approved';
      case ChurchKycStatus.suspended:
        return 'suspended';
    }
  }
}

class IglesiaModel {
  final int id;
  final String nombre;
  final String denominacion;
  final double calificacion;
  final int totalResenas;
  final String distancia;
  final bool esVerificada;
  final ChurchKycStatus kycStatus;
  final String direccion;
  final String plusCode;
  final String telefono;
  final String sitioWeb;
  final ProximoCulto proximoCulto;
  final List<HorarioServicio> horarios;
  final AvisoIglesia avisoActual;

  IglesiaModel({
    required this.id,
    required this.nombre,
    required this.denominacion,
    required this.calificacion,
    required this.totalResenas,
    required this.distancia,
    required this.esVerificada,
    this.kycStatus = ChurchKycStatus.pendingKyc,
    required this.direccion,
    required this.plusCode,
    required this.telefono,
    required this.sitioWeb,
    required this.proximoCulto,
    required this.horarios,
    required this.avisoActual,
  });

  /// Indica si la congregación tiene la validación legal e institucional (KYC) aprobada
  /// para mostrar el botón "Ofrendar" y recibir donaciones.
  bool get puedeRecibirOfrendas => kycStatus == ChurchKycStatus.approved;

  factory IglesiaModel.fromJson(Map<String, dynamic> json) {
    final bool verified = json['es_verificada'] as bool? ?? false;
    final String? rawKyc =
        (json['kyc_status'] ?? json['verification_status']) as String?;
    return IglesiaModel(
      id: json['id'] as int,
      nombre: json['nombre'] as String,
      denominacion: json['denominacion'] as String,
      calificacion: (json['calificacion'] as num).toDouble(),
      totalResenas: json['total_resenas'] as int,
      distancia: json['distancia'] as String,
      esVerificada: verified,
      kycStatus: ChurchKycStatus.fromString(
        rawKyc,
        fallbackVerified: verified,
      ),
      direccion: json['direccion'] as String,
      plusCode: json['plus_code'] as String,
      telefono: json['telefono'] as String,
      sitioWeb: json['sitio_web'] as String,
      proximoCulto: ProximoCulto.fromJson(
        json['proximo_culto'] as Map<String, dynamic>,
      ),
      horarios: (json['horarios'] as List<dynamic>)
          .map((item) => HorarioServicio.fromJson(item as Map<String, dynamic>))
          .toList(),
      avisoActual: AvisoIglesia.fromJson(
        json['aviso_actual'] as Map<String, dynamic>,
      ),
    );
  }
}

class ProximoCulto {
  final String titulo;
  final String diaHora;
  final String estado;

  ProximoCulto({
    required this.titulo,
    required this.diaHora,
    required this.estado,
  });

  factory ProximoCulto.fromJson(Map<String, dynamic> json) {
    return ProximoCulto(
      titulo: json['titulo'] as String,
      diaHora: json['dia_hora'] as String,
      estado: json['estado'] as String,
    );
  }
}

class HorarioServicio {
  final String dia;
  final String detalle;
  final String tipo;

  HorarioServicio({
    required this.dia,
    required this.detalle,
    required this.tipo,
  });

  factory HorarioServicio.fromJson(Map<String, dynamic> json) {
    return HorarioServicio(
      dia: json['dia'] as String,
      detalle: json['detalle'] as String,
      tipo: json['tipo'] as String,
    );
  }
}

class AvisoIglesia {
  final String titulo;
  final String descripcion;

  AvisoIglesia({required this.titulo, required this.descripcion});

  factory AvisoIglesia.fromJson(Map<String, dynamic> json) {
    return AvisoIglesia(
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String,
    );
  }
}
