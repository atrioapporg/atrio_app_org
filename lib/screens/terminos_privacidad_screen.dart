import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/biblia_provider.dart';

class TerminosPrivacidadScreen extends StatefulWidget {
  static const routeName = 'terminos_privacidad_screen';

  const TerminosPrivacidadScreen({super.key});

  @override
  State<TerminosPrivacidadScreen> createState() =>
      _TerminosPrivacidadScreenState();
}

class _TerminosPrivacidadScreenState extends State<TerminosPrivacidadScreen> {
  // Lista de fuentes optimizadas para lectura
  static const List<String> _fuentesDisponibles = [
    'Inter',
    'Roboto',
    'Open Sans',
    'Noto Sans',
    'Source Sans 3',
    'IBM Plex Sans',
    'Merriweather',
  ];

  TextStyle _getFontStyle(TextStyle baseStyle, String fontName) {
    switch (fontName) {
      case 'Roboto':
        return GoogleFonts.roboto(textStyle: baseStyle);
      case 'Open Sans':
        return GoogleFonts.openSans(textStyle: baseStyle);
      case 'Noto Sans':
        return GoogleFonts.notoSans(textStyle: baseStyle);
      case 'Source Sans 3':
        return GoogleFonts.sourceSans3(textStyle: baseStyle);
      case 'IBM Plex Sans':
        return GoogleFonts.ibmPlexSans(textStyle: baseStyle);
      case 'Merriweather':
        return GoogleFonts.merriweather(textStyle: baseStyle);
      case 'Inter':
      default:
        return GoogleFonts.inter(textStyle: baseStyle);
    }
  }

  void _cambiarModoLectura(BibliaProvider provider) {
    switch (provider.modoLectura) {
      case ModoLectura.calido:
        provider.actualizarModoLectura(ModoLectura.suave);
        _mostrarMensaje('Modo Claro Suave');
        break;
      case ModoLectura.suave:
        provider.actualizarModoLectura(ModoLectura.noche);
        _mostrarMensaje('Modo Lectura Nocturna');
        break;
      case ModoLectura.noche:
        provider.actualizarModoLectura(ModoLectura.calido);
        _mostrarMensaje('Modo Papiro Cálido');
        break;
    }
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          texto,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        width: 220,
      ),
    );
  }

  // =========================================================
  // MODAL DE AJUSTES DE LECTURA (SINCRONIZADO CON PROVIDER)
  // =========================================================
  void _mostrarOpcionesDeLectura(
    double screenWidth,
    double usableHeight,
    Color azulFondo,
    Color amarilloOro,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFAF7F0),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.06),
        ),
      ),
      builder: (ctx) {
        return Consumer<BibliaProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: screenWidth * 0.06,
                right: screenWidth * 0.06,
                top: usableHeight * 0.025,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ajustes de lectura',
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: azulFondo,
                          size: screenWidth * 0.06,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.02),
                  Text(
                    'Tamaño de letra',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.01),
                  Row(
                    children: [
                      Text(
                        'A',
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: provider.fontScale,
                          min: 0.8,
                          max: 2.0,
                          divisions: 12,
                          activeColor: amarilloOro,
                          inactiveColor: Colors.grey.shade300,
                          onChanged: (val) {
                            provider.actualizarAjustesVisuales(
                              val,
                              provider.selectedFont,
                            );
                          },
                        ),
                      ),
                      Text(
                        'A',
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.07,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.02),
                  Text(
                    'Tipo de fuente',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.015),
                  Wrap(
                    spacing: screenWidth * 0.02,
                    runSpacing: usableHeight * 0.01,
                    children: _fuentesDisponibles.map((font) {
                      final isSelected = provider.selectedFont == font;
                      return ChoiceChip(
                        label: Text(
                          font,
                          style: TextStyle(
                            color: isSelected
                                ? azulFondo
                                : Colors.grey.shade700,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: amarilloOro.withValues(alpha: 0.3),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.03,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? amarilloOro
                                : Colors.grey.shade300,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            provider.actualizarAjustesVisuales(
                              provider.fontScale,
                              font,
                            );
                          }
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: usableHeight * 0.02),
                  Text(
                    'Modo de lectura',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.015),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Icon(
                            Icons.wb_incandescent_outlined,
                            size: 18,
                          ),
                          label: const Text('Papiro'),
                          selected: provider.modoLectura == ModoLectura.calido,
                          selectedColor: const Color(0xFFC28518)
                              .withValues(alpha: 0.25),
                          backgroundColor: Colors.white,
                          onSelected: (selected) {
                            if (selected) {
                              provider.actualizarModoLectura(
                                ModoLectura.calido,
                              );
                              Navigator.pop(ctx);
                              _mostrarMensaje('Modo Papiro Cálido');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Icon(Icons.wb_sunny_rounded, size: 18),
                          label: const Text('Claro'),
                          selected: provider.modoLectura == ModoLectura.suave,
                          selectedColor: const Color(0xFF0F4C81)
                              .withValues(alpha: 0.2),
                          backgroundColor: Colors.white,
                          onSelected: (selected) {
                            if (selected) {
                              provider.actualizarModoLectura(ModoLectura.suave);
                              Navigator.pop(ctx);
                              _mostrarMensaje('Modo Claro Suave');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Icon(Icons.nightlight_round, size: 18),
                          label: const Text('Noche'),
                          selected: provider.modoLectura == ModoLectura.noche,
                          selectedColor: const Color(0xFFF59E0B)
                              .withValues(alpha: 0.25),
                          backgroundColor: Colors.white,
                          onSelected: (selected) {
                            if (selected) {
                              provider.actualizarModoLectura(ModoLectura.noche);
                              Navigator.pop(ctx);
                              _mostrarMensaje('Modo Lectura Nocturna');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.04),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BibliaProvider>(context);
    final double fontScale = provider.fontScale;
    final String selectedFont = provider.selectedFont;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    // Configuración cromática idéntica a LecturaCapituloScreen
    final Color colorFondo;
    final Color colorTextoPrincipal;
    final Color colorTextoSecundario;
    final Color colorAcento;
    final Color colorHeader;
    final Color colorHeaderTexto;

    switch (provider.modoLectura) {
      case ModoLectura.calido:
        colorFondo = const Color(0xFFFAF7F0);
        colorTextoPrincipal = const Color(0xFF26211C);
        colorTextoSecundario = const Color(0xFF5D5347);
        colorAcento = const Color(0xFFC28518);
        colorHeader = const Color(0xFF072B4F);
        colorHeaderTexto = Colors.white;
        break;
      case ModoLectura.suave:
        colorFondo = const Color(0xFFF8FAFC);
        colorTextoPrincipal = const Color(0xFF1E293B);
        colorTextoSecundario = const Color(0xFF64748B);
        colorAcento = const Color(0xFFE5A023);
        colorHeader = const Color(0xFF072B4F);
        colorHeaderTexto = Colors.white;
        break;
      case ModoLectura.noche:
        colorFondo = const Color(0xFF0A1017);
        colorTextoPrincipal = const Color(0xFFE2E8F0);
        colorTextoSecundario = const Color(0xFF94A3B8);
        colorAcento = const Color(0xFFF59E0B);
        colorHeader = const Color(0xFF162231);
        colorHeaderTexto = const Color(0xFFE2E8F0);
        break;
    }

    final bool esNoche = provider.modoLectura == ModoLectura.noche;

    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        backgroundColor: colorHeader,
        elevation: 0,
        leading: Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
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
        title: Text(
          'Términos y Privacidad',
          style: _getFontStyle(
            TextStyle(
              color: colorHeaderTexto,
              fontSize: (screenWidth * 0.048) * fontScale.clamp(0.9, 1.2),
              fontWeight: FontWeight.bold,
            ),
            selectedFont,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Cambiar tono de lectura',
            icon: Icon(
              esNoche
                  ? Icons.nightlight_round
                  : (provider.modoLectura == ModoLectura.calido
                        ? Icons.wb_incandescent_outlined
                        : Icons.wb_sunny_rounded),
              color: colorAcento,
              size: 22,
            ),
            onPressed: () => _cambiarModoLectura(provider),
          ),
          IconButton(
            tooltip: 'Ajustes de lectura',
            icon: Icon(
              Icons.text_format_rounded,
              color: colorHeaderTexto,
              size: 24,
            ),
            onPressed: () => _mostrarOpcionesDeLectura(
              screenWidth,
              usableHeight,
              colorHeader,
              colorAcento,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitulo(
              'Política de Privacidad',
              screenWidth,
              esNoche ? colorHeaderTexto : colorHeader,
              fontScale,
              selectedFont,
            ),
            _buildParrafo(
              'Última actualización: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}\n\n'
              'Bienvenido a ATRIO ("Vive tu Fe en comunidad"). Respetamos tu privacidad y estamos profundamente comprometidos a proteger tus datos personales y tu experiencia espiritual. Esta política detalla cómo recopilamos, administramos, protegemos y salvaguardamos tu información.',
              screenWidth,
              colorTextoPrincipal,
              fontScale,
              selectedFont,
            ),
            _buildSubtitulo(
              '1. Información que recopilamos',
              screenWidth,
              colorAcento,
              fontScale,
              selectedFont,
            ),
            _buildParrafo(
              '• Datos de la cuenta: Al iniciar sesión o registrarte (correo electrónico, Google Sign-In o Apple ID), almacenamos de manera segura tu nombre y dirección de correo electrónico.\n'
              '• Datos comunitarios y de perfil: Número telefónico, tradición cristiana e iglesia o comunidad a la que estás vinculado voluntariamente para adaptar tu experiencia eclesiástica.\n'
              '• Almacenamiento Local en el Dispositivo: Tus notas de la Biblia, pasajes favoritos, configuraciones personales e historial de navegación se guardan localmente en SQLite. No compartimos tus reflexiones privadas con terceros.\n'
              '• Solicitudes y Donaciones: Registramos el estado de tus peticiones de oración, solicitudes pastorales y constancias de donaciones o aportes a proyectos solidarios para darte visibilidad y trazabilidad directa.',
              screenWidth,
              colorTextoPrincipal,
              fontScale,
              selectedFont,
            ),
            _buildSubtitulo(
              '2. Uso de servicios de terceros',
              screenWidth,
              colorAcento,
              fontScale,
              selectedFont,
            ),
            _buildParrafo(
              'Nuestra plataforma se integra con tecnologías de confianza para ofrecer una funcionalidad completa:\n'
              '• Google Play Services, Google Sign-In y Sign in with Apple (Autenticación y seguridad).\n'
              '• Google Maps Platform (Para la localización geográfica precisa de templos, parroquias y eventos comunitarios en el mapa interactivo).\n'
              '• Pasarelas de Pago Seguras (Para la recepción confiable y encriptada de ofrendas, diezmos y aportes a causas solidarias).\n'
              '• YouTube y Reproductores de Transmisiones (Para servicios religiosos, eventos en vivo y programas radiales).',
              screenWidth,
              colorTextoPrincipal,
              fontScale,
              selectedFont,
            ),
            _buildSubtitulo(
              '3. Retención y eliminación de datos',
              screenWidth,
              colorAcento,
              fontScale,
              selectedFont,
            ),
            _buildParrafo(
              'Conservamos los datos de tu cuenta mientras esté activa. De acuerdo con las directrices de Apple App Store (5.1.1 v) y Google Play Console, tienes el derecho incondicional de solicitar la eliminación total y definitiva de tu cuenta y datos personales.\n\n'
              'Puedes realizar esta acción en cualquier momento desde la opción "Eliminar cuenta y datos" en la pantalla de Perfil, o enviando un correo a soporte@atrioapp.com con el asunto "Eliminación de Cuenta". Todos los registros locales en SQLite y vinculaciones en el backend serán purgados.',
              screenWidth,
              colorTextoPrincipal,
              fontScale,
              selectedFont,
            ),
            _buildSubtitulo(
              '4. Permisos del dispositivo',
              screenWidth,
              colorAcento,
              fontScale,
              selectedFont,
            ),
            _buildParrafo(
              'ATRIO solo solicita permisos estrictamente requeridos para su funcionamiento:\n'
              '• Ubicación (GPS): Únicamente utilizada cuando accedes al mapa para mostrarte iglesias y eventos en tu cercanía inmediata.\n'
              '• Acceso a Internet y Red: Para sincronizar solicitudes, consultar transmisiones en directo y validar aportes.\n'
              '• Notificaciones: Para recordatorios de servicios litúrgicos, eventos comunitarios y respuestas a solicitudes.',
              screenWidth,
              colorTextoPrincipal,
              fontScale,
              selectedFont,
            ),
            _buildTitulo(
              'Términos de Uso',
              screenWidth,
              esNoche ? colorHeaderTexto : colorHeader,
              fontScale,
              selectedFont,
            ),
            _buildParrafo(
              '1. Conducta y respeto comunitario: ATRIO es un espacio digital de comunión, edificación mutua y apoyo a las obras de la iglesia. Queda terminantemente prohibido el uso de lenguaje difamatorio, fraudulento o que atente contra la dignidad de la comunidad.\n\n'
              '2. Contenidos bíblicos y multimedia: Los textos bíblicos, transmisiones de emisoras y videos compartidos respetan los derechos de autor de sus respectivas entidades y ministerios emisores. Se prohíbe su explotación comercial indebida fuera de la plataforma.\n\n'
              '3. Donaciones y aportes: Los aportes realizados a través de ATRIO van dirigidos directamente a las comunidades religiosas y proyectos solidarios seleccionados. La app actúa como puente facilitador transparente y seguro.',
              screenWidth,
              colorTextoPrincipal,
              fontScale,
              selectedFont,
            ),
            const SizedBox(height: 30),
            Center(
              child: Text(
                'Al usar ATRIO, aceptas estos términos y políticas de convivencia.',
                textAlign: TextAlign.center,
                style: _getFontStyle(
                  TextStyle(
                    color: colorAcento,
                    fontSize: (screenWidth * 0.035) * fontScale,
                    fontWeight: FontWeight.bold,
                  ),
                  selectedFont,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'ATRIO · Versión 1.0.0',
                style: _getFontStyle(
                  TextStyle(
                    color: colorTextoSecundario,
                    fontSize: (screenWidth * 0.03) * fontScale,
                  ),
                  selectedFont,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTitulo(
    String texto,
    double screenWidth,
    Color color,
    double fontScale,
    String selectedFont,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 20),
      child: Text(
        texto,
        style: _getFontStyle(
          TextStyle(
            color: color,
            fontSize: (screenWidth * 0.055) * fontScale,
            fontWeight: FontWeight.w900,
          ),
          selectedFont,
        ),
      ),
    );
  }

  Widget _buildSubtitulo(
    String texto,
    double screenWidth,
    Color color,
    double fontScale,
    String selectedFont,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        texto,
        style: _getFontStyle(
          TextStyle(
            color: color,
            fontSize: (screenWidth * 0.042) * fontScale,
            fontWeight: FontWeight.bold,
          ),
          selectedFont,
        ),
      ),
    );
  }

  Widget _buildParrafo(
    String texto,
    double screenWidth,
    Color color,
    double fontScale,
    String selectedFont,
  ) {
    return Text(
      texto,
      style: _getFontStyle(
        TextStyle(
          color: color,
          fontSize: (screenWidth * 0.038) * fontScale,
          height: 1.5,
        ),
        selectedFont,
      ),
    );
  }
}
