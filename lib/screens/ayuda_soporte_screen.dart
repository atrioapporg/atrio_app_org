import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../providers/biblia_provider.dart';

class AyudaSoporteScreen extends StatefulWidget {
  static const routeName = 'ayuda_soporte_screen';

  const AyudaSoporteScreen({super.key});

  @override
  State<AyudaSoporteScreen> createState() => _AyudaSoporteScreenState();
}

class _AyudaSoporteScreenState extends State<AyudaSoporteScreen> {
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

  List<Map<String, String>> _getFaqs(AppLocalizations? l10n) => [
    {
      'pregunta':
          l10n?.faq1Pregunta ??
          '¿Cómo realizar una ofrenda o donación a mi iglesia?',
      'respuesta': l10n?.faq1Respuesta ?? 'Accede a la sección "Mis donaciones" desde tu perfil o pulsa el botón "Ofrendar / Aportar" en la pantalla de tu iglesia. Podrás seleccionar el proyecto solidario, ingresar el monto y proceder con total seguridad.',
    },
    {
      'pregunta':
          l10n?.faq2Pregunta ??
          '¿Cómo enviar y consultar el estado de mis solicitudes pastorales?',
      'respuesta': l10n?.faq2Respuesta ?? 'Dirígete a la sección "Mis solicitudes" en tu perfil o desde el menú de tu iglesia. Allí podrás enviar peticiones de oración, consejería o apoyo social y verificar el seguimiento de respuesta de tu comunidad.',
    },
    {
      'pregunta':
          l10n?.faq3Pregunta ??
          '¿Dónde puedo explorar iglesias cercanas y verlas en el mapa?',
      'respuesta': l10n?.faq3Respuesta ?? 'Desde la pantalla principal pulsa sobre "Explorar Iglesias" o el mapa interactivo. Podrás filtrar por tradición cristiana, conocer horarios de servicios, pastores encargados y obtener la ruta en el mapa.',
    },
    {
      'pregunta':
          l10n?.faq4Pregunta ??
          '¿Puedo leer la Biblia y guardar notas o favoritos sin conexión?',
      'respuesta': l10n?.faq4Respuesta ?? '¡Sí! El texto bíblico, tus notas de estudio y los versículos destacados quedan almacenados de manera segura y local en tu dispositivo mediante SQLite para que los disfrutes en todo momento.',
    },
    {
      'pregunta':
          l10n?.faq5Pregunta ??
          '¿Cómo actualizar mis datos de perfil o cambiar de iglesia?',
      'respuesta': l10n?.faq5Respuesta ?? 'En la pestaña Perfil, presiona "Mis datos" o el botón de edición para actualizar tu nombre, correo o teléfono celular. Si deseas afiliarte a otra comunidad, pulsa "Cambiar de iglesia".',
    },
  ];

  Future<void> _abrirWhatsApp(Color azulFondo) async {
    final l10n = AppLocalizations.of(context);
    const String telefono = '+18099587028';
    final String mensaje =
        l10n?.mensajeWhatsAppAyuda ?? 'Hola, necesito ayuda con la app ATRIO.';
    final Uri url = Uri.parse(
      'whatsapp://send?phone=$telefono&text=${Uri.encodeComponent(mensaje)}',
    );
    final Uri urlWeb = Uri.parse(
      'https://wa.me/$telefono?text=${Uri.encodeComponent(mensaje)}',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(urlWeb)) {
        await launchUrl(urlWeb, mode: LaunchMode.externalApplication);
      } else {
        _mostrarAlerta(
          l10n?.errorAbrirWhatsAppDispositivo ??
              'No se pudo abrir WhatsApp en este dispositivo.',
          azulFondo,
        );
      }
    } catch (_) {
      _mostrarAlerta(
        l10n?.errorAbrirWhatsApp ??
            'Ocurrió un error al intentar abrir WhatsApp.',
        azulFondo,
      );
    }
  }

  Future<void> _abrirCorreo(Color azulFondo) async {
    final l10n = AppLocalizations.of(context);
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'soporte@atrioapp.com',
      queryParameters: {
        'subject': l10n?.asuntoCorreoSoporte ?? 'Soporte - App ATRIO',
        'body': l10n?.cuerpoCorreoSoporte ?? 'Describe aquí tu consulta o inconveniente:\n\n---\nVersión de la app: 1.0.0',
      },
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        _mostrarAlerta(
          l10n?.errorNoClienteCorreo ??
              'No se encontró un cliente de correo configurado.',
          azulFondo,
        );
      }
    } catch (_) {
      _mostrarAlerta(
        l10n?.errorAbrirCorreo ??
            'Ocurrió un error al intentar abrir el correo.',
        azulFondo,
      );
    }
  }

  void _mostrarAlerta(String mensaje, Color fondo) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: fondo,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Text(mensaje, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  void _cambiarModoLectura(BibliaProvider provider) {
    final l10n = AppLocalizations.of(context);
    switch (provider.modoLectura) {
      case ModoLectura.calido:
        provider.actualizarModoLectura(ModoLectura.suave);
        _mostrarMensaje(l10n?.modoClaroSuave ?? 'Modo Claro Suave');
        break;
      case ModoLectura.suave:
        provider.actualizarModoLectura(ModoLectura.noche);
        _mostrarMensaje(l10n?.modoLecturaNocturna ?? 'Modo Lectura Nocturna');
        break;
      case ModoLectura.noche:
        provider.actualizarModoLectura(ModoLectura.calido);
        _mostrarMensaje(l10n?.modoPapiroCalido ?? 'Modo Papiro Cálido');
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
        final l10n = AppLocalizations.of(ctx);

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
                        l10n?.ajustesDeLectura ?? 'Ajustes de lectura',
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
                    l10n?.tamanoDeLetra ?? 'Tamaño de letra',
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
                    l10n?.tipoDeFuente ?? 'Tipo de fuente',
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
                    l10n?.modoDeLectura ?? 'Modo de lectura',
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
                          label: Text(l10n?.papiro ?? 'Papiro'),
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
                              _mostrarMensaje(
                                l10n?.modoPapiroCalido ?? 'Modo Papiro Cálido',
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Icon(Icons.wb_sunny_rounded, size: 18),
                          label: Text(l10n?.claro ?? 'Claro'),
                          selected: provider.modoLectura == ModoLectura.suave,
                          selectedColor: const Color(0xFF0F4C81)
                              .withValues(alpha: 0.2),
                          backgroundColor: Colors.white,
                          onSelected: (selected) {
                            if (selected) {
                              provider.actualizarModoLectura(ModoLectura.suave);
                              Navigator.pop(ctx);
                              _mostrarMensaje(
                                l10n?.modoClaroSuave ?? 'Modo Claro Suave',
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Icon(Icons.nightlight_round, size: 18),
                          label: Text(l10n?.noche ?? 'Noche'),
                          selected: provider.modoLectura == ModoLectura.noche,
                          selectedColor: const Color(0xFFF59E0B)
                              .withValues(alpha: 0.25),
                          backgroundColor: Colors.white,
                          onSelected: (selected) {
                            if (selected) {
                              provider.actualizarModoLectura(ModoLectura.noche);
                              Navigator.pop(ctx);
                              _mostrarMensaje(
                                l10n?.modoLecturaNocturna ??
                                    'Modo Lectura Nocturna',
                              );
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
    final l10n = AppLocalizations.of(context);
    final faqs = _getFaqs(l10n);

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
    final Color colorTarjeta;
    final Color colorTextoPrincipal;
    final Color colorTextoSecundario;
    final Color colorAcento;
    final Color colorBorde;
    final Color colorHeader;
    final Color colorHeaderTexto;

    switch (provider.modoLectura) {
      case ModoLectura.calido:
        colorFondo = const Color(0xFFFAF7F0);
        colorTarjeta = const Color(0xFFF9F5EC);
        colorTextoPrincipal = const Color(0xFF26211C);
        colorTextoSecundario = const Color(0xFF5D5347);
        colorAcento = const Color(0xFFC28518);
        colorBorde = const Color(0xFFE9E0CF);
        colorHeader = const Color(0xFF072B4F);
        colorHeaderTexto = Colors.white;
        break;
      case ModoLectura.suave:
        colorFondo = const Color(0xFFF8FAFC);
        colorTarjeta = Colors.white;
        colorTextoPrincipal = const Color(0xFF1E293B);
        colorTextoSecundario = const Color(0xFF64748B);
        colorAcento = const Color(0xFFE5A023);
        colorBorde = const Color(0xFFE2E8F0);
        colorHeader = const Color(0xFF072B4F);
        colorHeaderTexto = Colors.white;
        break;
      case ModoLectura.noche:
        colorFondo = const Color(0xFF0A1017);
        colorTarjeta = const Color(0xFF162231);
        colorTextoPrincipal = const Color(0xFFE2E8F0);
        colorTextoSecundario = const Color(0xFF94A3B8);
        colorAcento = const Color(0xFFF59E0B);
        colorBorde = const Color(0xFF27384E);
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
          l10n?.ayudaYSoporte ?? 'Ayuda y soporte',
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
            tooltip:
                l10n?.cambiarTonoLecturaTooltip ?? 'Cambiar tono de lectura',
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
            tooltip: l10n?.ajustesDeLectura ?? 'Ajustes de lectura',
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
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenHeight * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner de Asistencia
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(screenWidth * 0.05),
              decoration: BoxDecoration(
                color: esNoche ? colorTarjeta : colorHeader,
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
                border: esNoche ? Border.all(color: colorBorde) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorAcento,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.support_agent_rounded,
                          color: esNoche
                              ? const Color(0xFF0A1017)
                              : colorHeader,
                          size: 26,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: Text(
                          l10n?.comoPodemosAyudarte ??
                              '¿Cómo podemos ayudarte?',
                          style: _getFontStyle(
                            TextStyle(
                              color: Colors.white,
                              fontSize: (screenWidth * 0.045) * fontScale,
                              fontWeight: FontWeight.bold,
                            ),
                            selectedFont,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.012),
                  Text(
                    l10n?.descripcionAyudaSoporte ?? 'Encuentra respuestas rápidas o comunícate directamente con nuestro equipo de asistencia técnica de ATRIO.',
                    style: _getFontStyle(
                      TextStyle(
                        color: Colors.white70,
                        fontSize: (screenWidth * 0.034) * fontScale,
                        height: 1.4,
                      ),
                      selectedFont,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.025),

            // Canales de Contacto Directo
            _sectionTitle(
              l10n?.canalesDeAtencion ?? 'Canales de atención',
              screenWidth,
              colorTextoPrincipal,
              fontScale,
              selectedFont,
            ),
            SizedBox(height: screenHeight * 0.012),
            Row(
              children: [
                Expanded(
                  child: _buildContactCard(
                    title: 'WhatsApp',
                    subtitle: l10n?.chatDirecto ?? 'Chat directo',
                    faIcon: FontAwesomeIcons.whatsapp,
                    colorIcon: const Color(0xFF25D366),
                    onTap: () => _abrirWhatsApp(colorHeader),
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    colorTarjeta: colorTarjeta,
                    colorBorde: colorBorde,
                    colorTextoPrincipal: colorTextoPrincipal,
                    colorTextoSecundario: colorTextoSecundario,
                    fontScale: fontScale,
                    selectedFont: selectedFont,
                  ),
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: _buildContactCard(
                    title: l10n?.correo ?? 'Correo',
                    subtitle: 'soporte@atrioapp.com',
                    icon: Icons.mail_outline_rounded,
                    colorIcon: colorAcento,
                    onTap: () => _abrirCorreo(colorHeader),
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    colorTarjeta: colorTarjeta,
                    colorBorde: colorBorde,
                    colorTextoPrincipal: colorTextoPrincipal,
                    colorTextoSecundario: colorTextoSecundario,
                    fontScale: fontScale,
                    selectedFont: selectedFont,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.03),

            // Preguntas Frecuentes
            _sectionTitle(
              l10n?.preguntasFrecuentes ?? 'Preguntas frecuentes',
              screenWidth,
              colorTextoPrincipal,
              fontScale,
              selectedFont,
            ),
            SizedBox(height: screenHeight * 0.012),
            Material(
              color: colorTarjeta,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: colorBorde),
                borderRadius: BorderRadius.circular(screenWidth * 0.035),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: List.generate(faqs.length, (index) {
                  final faq = faqs[index];
                  final isLast = index == faqs.length - 1;
                  return Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: Container(
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : Border(bottom: BorderSide(color: colorBorde)),
                      ),
                      child: ExpansionTile(
                        iconColor: colorAcento,
                        collapsedIconColor: colorTextoSecundario,
                        tilePadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: 2,
                        ),
                        title: Text(
                          faq['pregunta']!,
                          style: _getFontStyle(
                            TextStyle(
                              color: colorTextoPrincipal,
                              fontSize: (screenWidth * 0.038) * fontScale,
                              fontWeight: FontWeight.w600,
                            ),
                            selectedFont,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              screenWidth * 0.04,
                              0,
                              screenWidth * 0.04,
                              screenHeight * 0.018,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                faq['respuesta']!,
                                style: _getFontStyle(
                                  TextStyle(
                                    color: colorTextoSecundario,
                                    fontSize: (screenWidth * 0.034) * fontScale,
                                    height: 1.45,
                                  ),
                                  selectedFont,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: screenHeight * 0.03),

            // Información de versión
            Center(
              child: Column(
                children: [
                  Text(
                    l10n?.atrioVersion('1.0.0') ?? 'ATRIO · Versión 1.0.0',
                    style: _getFontStyle(
                      TextStyle(
                        color: colorTextoSecundario,
                        fontSize: (screenWidth * 0.03) * fontScale,
                      ),
                      selectedFont,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    l10n?.todosLosDerechosReservados ??
                        'Todos los derechos reservados',
                    style: _getFontStyle(
                      TextStyle(
                        color: colorTextoSecundario.withValues(alpha: 0.7),
                        fontSize: (screenWidth * 0.028) * fontScale,
                      ),
                      selectedFont,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(
    String title,
    double screenWidth,
    Color colorTexto,
    double fontScale,
    String selectedFont,
  ) {
    return Text(
      title,
      style: _getFontStyle(
        TextStyle(
          color: colorTexto,
          fontSize: (screenWidth * 0.042) * fontScale,
          fontWeight: FontWeight.bold,
        ),
        selectedFont,
      ),
    );
  }

  Widget _buildContactCard({
    required String title,
    required String subtitle,
    IconData? icon,
    FaIconData? faIcon,
    required Color colorIcon,
    required VoidCallback onTap,
    required double screenWidth,
    required double screenHeight,
    required Color colorTarjeta,
    required Color colorBorde,
    required Color colorTextoPrincipal,
    required Color colorTextoSecundario,
    required double fontScale,
    required String selectedFont,
  }) {
    return Material(
      color: colorTarjeta,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorBorde),
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.035,
            vertical: screenHeight * 0.018,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: screenWidth * 0.05,
                backgroundColor: colorIcon.withValues(alpha: 0.12),
                child: faIcon != null
                    ? FaIcon(faIcon, color: colorIcon, size: screenWidth * 0.055)
                    : (icon != null
                        ? Icon(icon, color: colorIcon, size: screenWidth * 0.055)
                        : const SizedBox.shrink()),
              ),
              SizedBox(width: screenWidth * 0.025),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: _getFontStyle(
                        TextStyle(
                          color: colorTextoPrincipal,
                          fontSize: (screenWidth * 0.036) * fontScale,
                          fontWeight: FontWeight.bold,
                        ),
                        selectedFont,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _getFontStyle(
                        TextStyle(
                          color: colorTextoSecundario,
                          fontSize: (screenWidth * 0.028) * fontScale,
                        ),
                        selectedFont,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
