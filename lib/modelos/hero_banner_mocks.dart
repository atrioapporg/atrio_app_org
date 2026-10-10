import 'package:atrio/modelos/palabra_dia_model.dart';
import 'package:atrio/modelos/video_model.dart';

/// 3 Datos temporales para "La palabra del día" (Devocionales / Reflexiones)
final List<PalabraDelDiaModel> palabrasDelDiaMock = [
  const PalabraDelDiaModel(
    id: 'palabra_01',
    titulo: 'Paz en medio de la tormenta',
    autor: 'Pastor Carlos Méndez',
    textoBreve:
        'La paz de Dios no depende de que cese el viento, sino de confiar en Aquel que camina sobre las aguas junto a ti.',
    contenidoCompleto:
        'A menudo esperamos que Dios calme las circunstancias antes de experimentar tranquilidad. Sin embargo, la verdadera paz que sobrepasa todo entendimiento es un ancla interna que sostiene tu corazón firme, aún en el día más difícil.\n\nHoy recuerda: no tienes que enfrentar este desafío con tus propias fuerzas. Entrega tus cargas en oración y permite que el Príncipe de Paz tome el timón de tu vida.',
    citaBiblica: 'Filipenses 4:6-7',
    imagenFondo: 'assets/images/biblia3.jpg',
  ),
  const PalabraDelDiaModel(
    id: 'palabra_02',
    titulo: 'Fuerzas renovadas para hoy',
    autor: 'Pastora Elena Gómez',
    textoBreve:
        'El cansancio no es el final de tu camino; es la invitación para descansar en la gracia inagotable del Señor.',
    contenidoCompleto:
        'Los que esperan en el Señor renovarán sus fuerzas; volarán con alas como las águilas. Cuando sientas que tus recursos se han agotado, recuerda que el poder de Dios se perfecciona en tu debilidad.\n\nToma un momento de silencio en su presencia. Su aliento de vida es suficiente para levantarte y recordarte que Su fidelidad es nueva cada mañana.',
    citaBiblica: 'Isaías 40:29-31',
    imagenFondo: 'assets/images/biblia1.jpg',
  ),
  const PalabraDelDiaModel(
    id: 'palabra_03',
    titulo: 'Un paso de fe a la vez',
    autor: 'Ministerio Pastoral ATRIO',
    textoBreve:
        'No necesitas ver el panorama completo para avanzar; solo necesitas obedecer la dirección de Dios hoy.',
    contenidoCompleto:
        'Caminar por fe significa confiar en el carácter de Dios antes de ver los resultados visibles. Cada gran victoria bíblica comenzó con una decisión valiente de dar el primer paso.\n\nAunque el camino parezca incierto, la lámpara de Su palabra iluminará exactamente el siguiente paso que debes dar. Confía, avanza y contempla Su respaldo.',
    citaBiblica: '2 Corintios 5:7',
    imagenFondo: 'assets/images/biblia2.jpg',
  ),
];

/// 3 Datos temporales para "Culto en vivo"
final List<VideoModel> cultosEnVivoMock = [
  VideoModel(
    id: 'culto_en_vivo_01',
    titulo: 'Culto Dominical de Celebración',
    canalOIglesia: 'Iglesia Central ATRIO',
    predicador: 'Pastor Principal',
    thumbnailUrl: 'assets/images/culto2.jpg',
    videoUrl: 'https://ejemplo.com/stream/culto_central.m3u8',
    categoria: 'Culto en vivo',
    sinopsis:
        'Transmisión en vivo del servicio congregacional: adoración, alabanza y mensaje de la Palabra.',
    esEnVivo: true,
    horario: 'Domingo · En transmisión en directo',
    estadisticas: '380 congregados en vivo',
    esDestacado: true,
  ),
  VideoModel(
    id: 'culto_en_vivo_02',
    titulo: 'Noche de Alabanza y Milagros',
    canalOIglesia: 'Comunidad ATRIO Jóvenes',
    predicador: 'Equipo de Adoración ATRIO',
    thumbnailUrl: 'assets/images/culto2.jpg',
    videoUrl: 'https://ejemplo.com/stream/noche_alabanza.m3u8',
    categoria: 'Culto en vivo',
    sinopsis:
        'Tiempo especial de intercesión comunitaria, testimonio y adoración viva.',
    esEnVivo: true,
    horario: 'Viernes · 7:30 p. m. En vivo',
    estadisticas: '215 personas conectadas',
    esDestacado: true,
  ),
  VideoModel(
    id: 'culto_en_vivo_03',
    titulo: 'Servicio de Intercesión Matutina',
    canalOIglesia: 'Red de Oración ATRIO',
    predicador: 'Equipo Pastoral',
    thumbnailUrl: 'assets/images/culto2.jpg',
    videoUrl: 'https://ejemplo.com/stream/oracion_matutina.m3u8',
    categoria: 'Culto en vivo',
    sinopsis:
        'Comenzando la jornada buscando la presencia del Señor y clamando por nuestras familias.',
    esEnVivo: true,
    horario: 'Sábado · 6:00 a. m. En directo',
    estadisticas: '110 personas en sintonía',
    esDestacado: true,
  ),
];
