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
        backgroundColor: blancoFondo,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
        ),
        title: Row(
          children: [
            Icon(
              Icons.share_outlined,
              color: azulFondo,
              size: screenWidth * 0.075,
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              'Compartir ubicación',
              style: TextStyle(
                color: azulFondo,
                fontSize: screenWidth * 0.042,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'El Plus Code se ha copiado al portapapeles. ¿Deseas enviarlo ahora por WhatsApp o Correo electrónico?',
          style: TextStyle(
            color: Colors.black87,
            fontSize: screenWidth * 0.045,
          ),
        ),
        actions: [
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.pop(dialogCtx),
              icon: Icon(Icons.copy_rounded, color: azulFondo),
              label: Text(
                'Copiado',
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'Cerrar',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: screenWidth * 0.055,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: usableHeight * 0.025),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                ),
              ),
              icon: FaIcon(
                FontAwesomeIcons.whatsapp,
                size: screenWidth * 0.065,
              ),
              label: const Text('WhatsApp'),
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
          SizedBox(height: usableHeight * 0.015),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: azulFondo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                ),
              ),
              icon: Icon(Icons.email_outlined, size: screenWidth * 0.065),
              label: const Text('Correo'),
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
                    // TradicionCristianaScreen
                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          'tradicion_cristiana_screen',
                        ),
                        icon: Icon(
                          Icons.swap_horiz_rounded,
                          color: const Color.fromARGB(255, 243, 74, 36),
                          size: screenWidth * 0.085,
                        ),
                        label: Text(
                          'Cambiar de iglesia',
                          style: TextStyle(
                            color: azulFondo,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.055,
                          ),
                        ),
                      ),
                    ),
                    //
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  iglesia.proximoCulto.titulo,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.042,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: usableHeight * 0.004),
                                Text(
                                  iglesia.proximoCulto.diaHora,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: screenWidth * 0.032,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
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
                                horizontal: screenWidth * 0.045,
                                vertical: usableHeight * 0.009,
                              ),
                            ),
                            onPressed: () => Navigator.pushNamed(
                              context,
                              'videos_transmisiones_screen',
                            ),
                            child: Text(
                              'Ver ahora',
                              style: TextStyle(
                                fontSize: screenWidth * 0.033,
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
                        vertical: usableHeight * 0.014,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1F5),
                        borderRadius: BorderRadius.circular(
                          screenWidth * 0.035,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active_outlined,
                            color: azulFondo,
                            size: screenWidth * 0.065,
                          ),
                          SizedBox(width: screenWidth * 0.03),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  iglesia.avisoActual.titulo,
                                  style: TextStyle(
                                    color: azulFondo,
                                    fontSize: screenWidth * 0.034,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: usableHeight * 0.003),
                                Text(
                                  iglesia.avisoActual.descripcion,
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: screenWidth * 0.03,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: usableHeight * 0.025),

                    // Cambiar de iglesia
                    // TradicionCristianaScreen
                    Center(
                      child: TextButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          'tradicion_cristiana_screen',
                        ),
                        icon: Icon(
                          Icons.swap_horiz_rounded,
                          color: const Color.fromARGB(255, 243, 74, 36),
                          size: screenWidth * 0.085,
                        ),
                        label: Text(
                          'Cambiar de iglesia',
                          style: TextStyle(
                            color: azulFondo,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.055,
                          ),
                        ),
                      ),
                    ),
                    //
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
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
            border: Border.all(color: grisBorde),
          ),
          child: Column(
            children: [
              Icon(icon, color: azulFondo, size: screenWidth * 0.06),
              SizedBox(height: screenWidth * 0.01),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.028,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
      ),
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
