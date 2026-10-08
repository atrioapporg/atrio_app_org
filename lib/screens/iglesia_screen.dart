import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../modelos/iglesia_model.dart';
import '../providers/iglesia_provider.dart';

class IglesiaScreen extends StatefulWidget {
  const IglesiaScreen({super.key});

  @override
  State<IglesiaScreen> createState() => _IglesiaScreenState();
}

class _IglesiaScreenState extends State<IglesiaScreen> {
  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFEFEFEF);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<IglesiaProvider>(context, listen: false);
      if (provider.iglesiaActual == null && !provider.isLoading) {
        provider.cargarIglesiaSeleccionada();
      }
    });
  }

  // 1. Acción: Llamar por teléfono
  Future<void> _hacerLlamada(BuildContext context, String telefono) async {
    final String numeroLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri telUri = Uri(scheme: 'tel', path: numeroLimpio);
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir el marcador con el número $telefono'),
        ),
      );
    }
  }

  // 2. Acción: Cómo llegar (Exactamente igual a IglesiasEnMapaScreen)
  Future<void> _abrirNavegacion(IglesiaModel iglesia) async {
    final String query = iglesia.direccion.isNotEmpty
        ? iglesia.direccion
        : iglesia.nombre;

    // Esquema universal nativo para abrir Google Maps, Waze u otras apps instaladas
    final Uri uriNativa = Uri.parse(
      'geo:0,0?q=${Uri.encodeComponent("${iglesia.nombre}, $query")}',
    );

    // Respaldo Web directo a Google Maps
    final Uri uriWeb = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent("${iglesia.nombre}, $query")}',
    );

    try {
      if (await canLaunchUrl(uriNativa)) {
        await launchUrl(uriNativa, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(uriWeb)) {
        await launchUrl(uriWeb, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir la aplicación de navegación.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error abriendo mapa: $e');
    }
  }

  // 3. Acción: Abrir sitio web oficial
  Future<void> _abrirSitioWeb(BuildContext context, String url) async {
    String urlFormateada = url.trim();
    if (!urlFormateada.startsWith('http://') &&
        !urlFormateada.startsWith('https://')) {
      urlFormateada = 'https://$urlFormateada';
    }
    final Uri webUri = Uri.parse(urlFormateada);
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el enlace $url')),
      );
    }
  }

  // 4. Copia el Plus Code y abre el cuadro de diálogo
  Future<void> _gestionarPlusCode(
    BuildContext context,
    IglesiaModel iglesia,
    double screenWidth,
    double usableHeight,
  ) async {
    final plusCode = iglesia.plusCode;
    final mensaje = 'Ubicación de ${iglesia.nombre}: $plusCode';
    await Clipboard.setData(ClipboardData(text: plusCode));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Plus Code copiado: $plusCode'),
        duration: const Duration(seconds: 2),
      ),
    );
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.045),
        ),
        titlePadding: EdgeInsets.fromLTRB(
          screenWidth * 0.06,
          usableHeight * 0.025,
          screenWidth * 0.06,
          usableHeight * 0.01,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
        actionsPadding: EdgeInsets.fromLTRB(
          screenWidth * 0.06,
          usableHeight * 0.015,
          screenWidth * 0.06,
          usableHeight * 0.02,
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.025),
              decoration: BoxDecoration(
                color: azulFondo.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.share_rounded,
                color: azulFondo,
                size: screenWidth * 0.06,
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: Text(
                'Compartir ubicación',
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.046,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: usableHeight * 0.008),
            Text(
              'El Plus Code ha sido copiado al portapapeles. ¿Deseas compartirlo directamente?',
              style: TextStyle(
                color: Colors.black87,
                fontSize: screenWidth * 0.035,
                height: 1.35,
              ),
            ),
            SizedBox(height: usableHeight * 0.015),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03,
                vertical: usableHeight * 0.01,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
                border: Border.all(color: grisBorde),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.pin_drop_rounded,
                    color: amarilloOro,
                    size: screenWidth * 0.045,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Expanded(
                    child: Text(
                      plusCode,
                      style: TextStyle(
                        color: azulFondo,
                        fontSize: screenWidth * 0.034,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green.shade600,
                    size: screenWidth * 0.045,
                  ),
                ],
              ),
            ),
            SizedBox(height: usableHeight * 0.02),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        vertical: usableHeight * 0.012,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.028,
                        ),
                      ),
                    ),
                    icon: FaIcon(
                      FontAwesomeIcons.whatsapp,
                      size: screenWidth * 0.048,
                    ),
                    label: Text(
                      'WhatsApp',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      final Uri whatsappUri = Uri.parse(
                        'https://wa.me/?text=${Uri.encodeComponent(mensaje)}',
                      );
                      if (await canLaunchUrl(whatsappUri)) {
                        await launchUrl(
                          whatsappUri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                  ),
                ),
                SizedBox(width: screenWidth * 0.025),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azulFondo,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        vertical: usableHeight * 0.012,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.028,
                        ),
                      ),
                    ),
                    icon: Icon(Icons.email_outlined, size: screenWidth * 0.048),
                    label: Text(
                      'Correo',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      final Uri emailUri = Uri(
                        scheme: 'mailto',
                        queryParameters: {
                          'subject': 'Plus Code de ${iglesia.nombre}',
                          'body':
                              '$mensaje\n\nPuedes buscar este código directamente en Google Maps.',
                        },
                      );
                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'Cerrar',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: screenWidth * 0.038,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    final iglesiaProvider = Provider.of<IglesiaProvider>(context);
    final iglesia = iglesiaProvider.iglesiaActual;

    if (iglesiaProvider.isLoading) {
      return Container(
        color: azulFondo,
        child: const Center(
          child: CircularProgressIndicator(color: amarilloOro),
        ),
      );
    }

    if (iglesiaProvider.errorMessage != null) {
      return Container(
        color: azulFondo,
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade300,
                size: screenWidth * 0.12,
              ),
              SizedBox(height: usableHeight * 0.02),
              Text(
                iglesiaProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.035,
                ),
              ),
              SizedBox(height: usableHeight * 0.02),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: amarilloOro),
                onPressed: () => iglesiaProvider.cargarIglesiaSeleccionada(),
                child: const Text(
                  'Reintentar',
                  style: TextStyle(
                    color: azulFondo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (iglesia == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Encabezado
        Container(
          width: screenWidth,
          padding: EdgeInsets.fromLTRB(
            screenWidth * 0.05,
            usableHeight * 0.01,
            screenWidth * 0.05,
            usableHeight * 0.02,
          ),
          child: Row(
            children: [
              Container(
                width: screenWidth * 0.15,
                height: screenWidth * 0.19,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(screenWidth * 0.035),
                ),
                child: Icon(
                  Icons.church_rounded,
                  color: azulFondo,
                  size: screenWidth * 0.08,
                ),
              ),
              SizedBox(width: screenWidth * 0.035),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            maxLines: 2,
                            iglesia.nombre,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.048,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (iglesia.esVerificada) ...[
                          SizedBox(width: screenWidth * 0.015),
                          Icon(
                            Icons.verified_rounded,
                            color: amarilloOro,
                            size: screenWidth * 0.045,
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.004),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: amarilloOro,
                          size: screenWidth * 0.038,
                        ),
                        SizedBox(width: screenWidth * 0.01),
                        Text(
                          '${iglesia.calificacion} (${iglesia.totalResenas}) · ',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: screenWidth * 0.03,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '${iglesia.denominacion} · ${iglesia.distancia}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: screenWidth * 0.03,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Contenedor blanco desplazable
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.022,
                  vertical: usableHeight * 0.022,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Botón elegante y moderno para Cambiar de iglesia
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pushNamed(
                          context,
                          'tradicion_cristiana_screen',
                        ),
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.035,
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: usableHeight * 0.014,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.035,
                            ),
                            border: Border.all(
                              color: azulFondo.withValues(alpha: 0.12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: azulFondo.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(screenWidth * 0.024),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4ED),
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.025,
                                  ),
                                ),
                                child: Icon(
                                  Icons.swap_horiz_rounded,
                                  color: const Color(0xFFE65100),
                                  size: screenWidth * 0.058,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.035),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cambiar de iglesia',
                                      style: TextStyle(
                                        color: azulFondo,
                                        fontWeight: FontWeight.bold,
                                        fontSize: screenWidth * 0.038,
                                      ),
                                    ),
                                    SizedBox(height: usableHeight * 0.002),
                                    Text(
                                      'Explora y selecciona otra comunidad',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: screenWidth * 0.029,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.black38,
                                size: screenWidth * 0.055,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.02),
                    // Acciones rápidas (Cómo llegar conectado a _abrirNavegacion)
                    Row(
                      children: [
                        _buildQuickAction(
                          screenWidth,
                          Icons.call_outlined,
                          'Llamar',
                          () => _hacerLlamada(context, iglesia.telefono),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        _buildQuickAction(
                          screenWidth,
                          Icons.directions_outlined,
                          'Cómo llegar',
                          () => _abrirNavegacion(iglesia),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        _buildQuickAction(
                          screenWidth,
                          Icons.language_outlined,
                          'Sitio web',
                          () => _abrirSitioWeb(context, iglesia.sitioWeb),
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.025),

                    // Tarjeta próximo culto
                    Container(
                      width: screenWidth,
                      padding: EdgeInsets.all(screenWidth * 0.045),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.045,
                        ),
                        gradient: const LinearGradient(
                          colors: [azulFondo, Color(0xFF1B4965)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(screenWidth * 0.025),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.028,
                              ),
                            ),
                            child: Icon(
                              Icons.live_tv_rounded,
                              color: amarilloOro,
                              size: screenWidth * 0.065,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.035),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  iglesia.proximoCulto.titulo,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: usableHeight * 0.004),
                                Text(
                                  iglesia.proximoCulto.diaHora,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: screenWidth * 0.031,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: amarilloOro,
                              foregroundColor: azulFondo,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  screenWidth * 0.025,
                                ),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.035,
                                vertical: usableHeight * 0.009,
                              ),
                            ),
                            onPressed: () => Navigator.pushNamed(
                              context,
                              'videos_transmisiones_screen',
                            ),
                            icon: Icon(
                              Icons.play_arrow_rounded,
                              size: screenWidth * 0.045,
                            ),
                            label: Text(
                              'Ver ahora',
                              style: TextStyle(
                                fontSize: screenWidth * 0.032,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.025),

                    // Horarios
                    _sectionLabel(
                      'Horarios de servicio',
                      screenWidth,
                      usableHeight,
                    ),
                    _buildInfoCard(
                      iglesia.horarios
                          .map(
                            (h) => _InfoRow(
                              icon: Icons.access_time_rounded,
                              label: h.dia,
                              value: h.detalle,
                            ),
                          )
                          .toList(),
                      screenWidth,
                      usableHeight,
                    ),
                    SizedBox(height: usableHeight * 0.025),

                    // Ubicación y Contacto
                    _sectionLabel(
                      'Ubicación y contacto',
                      screenWidth,
                      usableHeight,
                    ),
                    _buildInfoCard(
                      [
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: 'Dirección',
                          value: iglesia.direccion,
                          onTap: () => _abrirNavegacion(iglesia),
                        ),
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Teléfono',
                          value: iglesia.telefono,
                          onTap: () => _hacerLlamada(context, iglesia.telefono),
                        ),
                        _InfoRow(
                          icon: Icons.pin_drop_outlined,
                          label: 'Plus Code',
                          value: iglesia.plusCode,
                          trailingIcon: Icons.copy_rounded,
                          onTap: () => _gestionarPlusCode(
                            context,
                            iglesia,
                            screenWidth,
                            usableHeight,
                          ),
                        ),
                      ],
                      screenWidth,
                      usableHeight,
                    ),
                    SizedBox(height: usableHeight * 0.025),

                    // Aviso actual
                    _sectionLabel('Avisos', screenWidth, usableHeight),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: usableHeight * 0.015,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.035,
                        ),
                        border: Border.all(
                          color: const Color(0xFF0F4C81)
                              .withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(screenWidth * 0.022),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F1F5),
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.025,
                              ),
                            ),
                            child: Icon(
                              Icons.campaign_rounded,
                              color: azulFondo,
                              size: screenWidth * 0.058,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.035),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  iglesia.avisoActual.titulo,
                                  style: TextStyle(
                                    color: azulFondo,
                                    fontSize: screenWidth * 0.036,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: usableHeight * 0.004),
                                Text(
                                  iglesia.avisoActual.descripcion,
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: screenWidth * 0.032,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.03),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    double screenWidth,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: screenWidth * 0.035),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.035),
              border: Border.all(color: grisBorde),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.022),
                  decoration: BoxDecoration(
                    color: azulFondo.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: azulFondo,
                    size: screenWidth * 0.058,
                  ),
                ),
                SizedBox(height: screenWidth * 0.015),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: azulFondo,
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, double screenWidth, double usableHeight) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: usableHeight * 0.01,
        left: screenWidth * 0.01,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: azulFondo,
          fontSize: screenWidth * 0.035,
          fontWeight: FontWeight.bold,
          letterSpacing: screenWidth * 0.001,
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    List<_InfoRow> rows,
    double screenWidth,
    double usableHeight,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
        border: Border.all(color: grisBorde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(rows.length, (index) {
          final row = rows[index];
          final isLast = index == rows.length - 1;
          return InkWell(
            onTap: row.onTap,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: usableHeight * 0.015,
              ),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(bottom: BorderSide(color: grisBorde)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(row.icon, color: azulFondo, size: screenWidth * 0.055),
                  SizedBox(width: screenWidth * 0.03),
                  Text(
                    row.label,
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.036,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            row.value,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              color: row.onTap != null
                                  ? azulFondo
                                  : Colors.grey.shade700,
                              fontWeight: row.onTap != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: screenWidth * 0.034,
                            ),
                          ),
                        ),
                        if (row.trailingIcon != null) ...[
                          SizedBox(width: screenWidth * 0.015),
                          Icon(
                            row.trailingIcon,
                            color: amarilloOro,
                            size: screenWidth * 0.045,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  final IconData? trailingIcon;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailingIcon,
    this.onTap,
  });
}
