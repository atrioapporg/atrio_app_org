import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../modelos/iglesia_model.dart';
import '../providers/iglesia_provider.dart';
import '../providers/user_provider.dart';
import '../servicios/moderation_service.dart';
import '../widgets/church_qr_dialog.dart';
import 'donaciones_screen.dart';
import 'qr_join_scanner_screen.dart';
import 'seleccionar_iglesia_screen.dart';

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
  bool _avisoBloqueadoPorUgc = false;

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

  Future<void> _hacerLlamada(BuildContext context, String telefono) async {
    final l10n = AppLocalizations.of(context);
    final String numeroLimpio = telefono.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri telUri = Uri(scheme: 'tel', path: numeroLimpio);
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.noSePudoAbrirMarcador(telefono) ??
                'No se pudo abrir el marcador con el número $telefono',
          ),
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
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.noSePudoAbrirNavegacion ??
                  'No se pudo abrir la aplicación de navegación.',
            ),
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
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.noSePudoAbrirEnlace(url) ?? 'No se pudo abrir el enlace $url',
          ),
        ),
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
    final l10n = AppLocalizations.of(context);
    final plusCode = iglesia.plusCode;
    final mensaje =
        l10n?.compartirUbicacionMensaje(iglesia.nombre, plusCode) ??
        'Ubicación de ${iglesia.nombre}: $plusCode';
    await Clipboard.setData(ClipboardData(text: plusCode));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n?.plusCodeCopiadoSnack(plusCode) ??
              'Plus Code copiado: $plusCode',
        ),
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
                l10n?.compartirUbicacion ?? 'Compartir ubicación',
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
              l10n?.plusCodeCopiadoPregunta ?? 'El Plus Code ha sido copiado al portapapeles. ¿Deseas compartirlo directamente?',
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
                      l10n?.correo ?? 'Correo',
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
                          'subject':
                              l10n?.asuntoCorreoPlusCode(iglesia.nombre) ??
                              'Plus Code de ${iglesia.nombre}',
                          'body':
                              l10n?.cuerpoCorreoPlusCode(mensaje) ??
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
                l10n?.cerrar ?? 'Cerrar',
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
    final l10n = AppLocalizations.of(context);
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
                child: Text(
                  l10n?.reintentar ?? 'Reintentar',
                  style: const TextStyle(
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
      return _SinIglesiaSeleccionadaView(
        screenWidth: screenWidth,
        usableHeight: usableHeight,
      );
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
              _ChurchQrAvatar(
                iglesia: iglesia,
                screenWidth: screenWidth,
                usableHeight: usableHeight,
                azulFondo: azulFondo,
                amarilloOro: amarilloOro,
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
                          Tooltip(
                            message:
                                l10n?.iglesiaVerificadaTooltip ??
                                'Congregación verificada',
                            child: Icon(
                              Icons.verified_rounded,
                              color: amarilloOro,
                              size: screenWidth * 0.045,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.004),
                    Semantics(
                      label:
                          l10n?.resenasCalificacionSemantics(
                            iglesia.calificacion.toString(),
                            iglesia.totalResenas,
                          ) ??
                          'Calificación ${iglesia.calificacion} de 5',
                      child: Row(
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
                                      l10n?.cambiarDeIglesia ??
                                          'Cambiar de iglesia',
                                      style: TextStyle(
                                        color: azulFondo,
                                        fontWeight: FontWeight.bold,
                                        fontSize: screenWidth * 0.038,
                                      ),
                                    ),
                                    SizedBox(height: usableHeight * 0.002),
                                    Text(
                                      l10n?.exploraYSeleccionaComunidad ??
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
                    SizedBox(height: usableHeight * 0.012),
                    // Botón para Vincularse con Código QR
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pushNamed(
                          context,
                          QrJoinScannerScreen.routeName,
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
                              color: amarilloOro.withValues(alpha: 0.35),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: amarilloOro.withValues(alpha: 0.06),
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
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.025,
                                  ),
                                ),
                                child: Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: amarilloOro,
                                  size: screenWidth * 0.058,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.035),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n?.escanearQrIglesia ??
                                          'Escanear QR de Iglesia',
                                      style: TextStyle(
                                        color: azulFondo,
                                        fontWeight: FontWeight.bold,
                                        fontSize: screenWidth * 0.038,
                                      ),
                                    ),
                                    SizedBox(height: usableHeight * 0.002),
                                    Text(
                                      l10n?.unirseCongregacion ??
                                          'Unirme a esta congregación',
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
                          l10n?.llamar ?? 'Llamar',
                          () => _hacerLlamada(context, iglesia.telefono),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        _buildQuickAction(
                          screenWidth,
                          Icons.directions_outlined,
                          l10n?.comoLlegar ?? 'Cómo llegar',
                          () => _abrirNavegacion(iglesia),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        _buildQuickAction(
                          screenWidth,
                          Icons.language_outlined,
                          l10n?.sitioWeb ?? 'Sitio web',
                          () => _abrirSitioWeb(context, iglesia.sitioWeb),
                        ),
                      ],
                    ),
                    if (iglesia.puedeRecibirOfrendas &&
                        context.watch<UserProvider>().isChurchKycApproved) ...[
                      SizedBox(height: usableHeight * 0.018),
                      _OfferingVerifiedActionCard(
                        screenWidth: screenWidth,
                        usableHeight: usableHeight,
                        onTap: () => Navigator.pushNamed(
                          context,
                          DonacionesScreen.routeName,
                        ),
                      ),
                    ],
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
                              minimumSize: const Size(0, 44),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  screenWidth * 0.025,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
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
                              l10n?.verAhora ?? 'Ver ahora',
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
                      l10n?.horariosDeServicio ?? 'Horarios de servicio',
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
                      l10n?.ubicacionYContacto ?? 'Ubicación y contacto',
                      screenWidth,
                      usableHeight,
                    ),
                    _buildInfoCard(
                      [
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          label: l10n?.direccion ?? 'Dirección',
                          value: iglesia.direccion,
                          onTap: () => _abrirNavegacion(iglesia),
                        ),
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: l10n?.telefono ?? 'Teléfono',
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

                    if (!_avisoBloqueadoPorUgc) ...[
                      // Aviso actual
                      _sectionLabel(
                        l10n?.avisos ?? 'Avisos',
                        screenWidth,
                        usableHeight,
                      ),
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
                            _UgcSafetyMenuButton(
                              contentId: iglesia.id,
                              contentType: 'church_notice',
                              onAuthorBlocked: () {
                                setState(() {
                                  _avisoBloqueadoPorUgc = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _SinIglesiaSeleccionadaView extends StatelessWidget {
  final double screenWidth;
  final double usableHeight;

  const _SinIglesiaSeleccionadaView({
    required this.screenWidth,
    required this.usableHeight,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    return Container(
      color: azulFondo,
      width: screenWidth,
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: screenWidth * 0.22,
                height: screenWidth * 0.22,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: amarilloOro.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.church_outlined,
                  color: amarilloOro,
                  size: screenWidth * 0.11,
                ),
              ),
              SizedBox(height: usableHeight * 0.025),
              Text(
                l10n?.sinIglesiaSeleccionada ?? 'Sin iglesia seleccionada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.052,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: usableHeight * 0.012),
              Text(
                l10n?.modalBienvenidaIglesiaMensaje ?? 'Conéctate a tu iglesia local para acceder a devocionales, eventos, oraciones y la vida de tu comunidad',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: screenWidth * 0.035,
                  height: 1.4,
                ),
              ),
              SizedBox(height: usableHeight * 0.035),
              // Botón 1: Escanear Código QR
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: amarilloOro,
                    foregroundColor: azulFondo,
                    padding: EdgeInsets.symmetric(
                      vertical: usableHeight * 0.016,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.035),
                    ),
                    elevation: 3,
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: Text(
                    l10n?.escanearQrIglesia ?? 'Escanear QR de Iglesia',
                    style: TextStyle(
                      fontSize: screenWidth * 0.038,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, QrJoinScannerScreen.routeName);
                  },
                ),
              ),
              SizedBox(height: usableHeight * 0.015),
              // Botón 2: Explorar en el mapa
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding: EdgeInsets.symmetric(
                      vertical: usableHeight * 0.016,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.035),
                    ),
                  ),
                  icon: const Icon(Icons.map_outlined),
                  label: Text(
                    l10n?.explorarEnElMapa ?? 'Explorar en el mapa',
                    style: TextStyle(
                      fontSize: screenWidth * 0.038,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      SeleccionarIglesiaScreen.routeName,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de acceso rápido para ofrendar, visible exclusivamente cuando la
/// congregación tiene su verificación legal e institucional (KYC) en estado `approved`.
class _OfferingVerifiedActionCard extends StatelessWidget {
  final double screenWidth;
  final double usableHeight;
  final VoidCallback onTap;

  const _OfferingVerifiedActionCard({
    required this.screenWidth,
    required this.usableHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
        child: Container(
          width: double.infinity,
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: usableHeight * 0.015,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(screenWidth * 0.035),
            border: Border.all(
              color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsetsDirectional.all(screenWidth * 0.024),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                ),
                child: Icon(
                  Icons.volunteer_activism_rounded,
                  color: const Color(0xFF2E7D32),
                  size: screenWidth * 0.058,
                ),
              ),
              SizedBox(width: screenWidth * 0.035),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            l10n?.ofrendarACongregacion ??
                                'Ofrendar a la congregación',
                            style: TextStyle(
                              color: azulFondo,
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth * 0.038,
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.015),
                        Icon(
                          Icons.verified_rounded,
                          color: amarilloOro,
                          size: screenWidth * 0.042,
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.002),
                    Text(
                      l10n?.ofrendarSubtituloVerificado ??
                          'Aporte voluntario y diezmos (Entidad verificada)',
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
    );
  }
}

/// Menú contextual de seguridad UGC (Apple Guideline 1.2 / Google Play UGC)
/// que permite al feligrés reportar contenido inapropiado o bloquear inmediatamente al autor.
class _UgcSafetyMenuButton extends StatelessWidget {
  final int contentId;
  final String contentType;
  final VoidCallback onAuthorBlocked;

  const _UgcSafetyMenuButton({
    required this.contentId,
    required this.contentType,
    required this.onAuthorBlocked,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const Color azulFondo = Color(0xFF072B4F);

    return SizedBox(
      width: 48,
      height: 48,
      child: PopupMenuButton<String>(
        icon: const Icon(
          Icons.more_vert_rounded,
          color: Colors.black45,
          size: 22,
        ),
        padding: EdgeInsetsDirectional.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (value) async {
          if (value == 'report') {
            await _mostrarDialogoReporte(context, l10n, azulFondo);
          } else if (value == 'block') {
            final service = ModerationService(
              api: context.read<UserProvider>().api,
            );
            await service.blockUgcUser(
              targetId: contentId,
              targetType: contentType,
            );
            onAuthorBlocked();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n?.ugcUsuarioBloqueadoExito ?? 'Autor bloqueado. Sus publicaciones han sido ocultadas de tu vista inmediatamente.',
                  ),
                  backgroundColor: azulFondo,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        },
        itemBuilder: (ctx) => [
          PopupMenuItem<String>(
            value: 'report',
            child: Row(
              children: [
                const Icon(
                  Icons.flag_outlined,
                  color: Color(0xFFD97706),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n?.ugcReportarContenido ??
                        'Reportar contenido inapropiado',
                    style: const TextStyle(fontSize: 13.5),
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'block',
            child: Row(
              children: [
                const Icon(
                  Icons.block_rounded,
                  color: Color(0xFFDC2626),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n?.ugcBloquearUsuario ?? 'Bloquear autor / contenido',
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoReporte(
    BuildContext context,
    AppLocalizations? l10n,
    Color azulFondo,
  ) async {
    final reasons = <String>[
      l10n?.ugcMotivoOfensivo ?? 'Lenguaje ofensivo o inapropiado',
      l10n?.ugcMotivoSpam ?? 'Spam o información engañosa',
      l10n?.ugcMotivoAcoso ?? 'Acoso o conducta abusiva',
    ];

    final selectedReason = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n?.ugcMotivoReporteTitulo ?? 'Reportar contenido',
          style: TextStyle(
            color: azulFondo,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.ugcMotivoReporteSubtitulo ?? 'Selecciona el motivo por el cual deseas reportar esta publicación:',
              style: const TextStyle(fontSize: 13.5, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            ...reasons.map(
              (r) => ListTile(
                contentPadding: EdgeInsetsDirectional.zero,
                leading: const Icon(
                  Icons.report_problem_outlined,
                  color: Color(0xFFD97706),
                ),
                title: Text(r, style: const TextStyle(fontSize: 14)),
                onTap: () => Navigator.of(dialogCtx).pop(r),
              ),
            ),
          ],
        ),
      ),
    );

    if (selectedReason != null && context.mounted) {
      final service = ModerationService(api: context.read<UserProvider>().api);
      await service.reportUgcContent(
        contentType: contentType,
        contentId: contentId,
        reason: selectedReason,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.ugcReporteEnviadoExito ?? 'Reporte enviado. Nuestro equipo de moderación revisará el contenido en menos de 24 horas.',
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// Widget dedicado para mostrar el código QR oficial de la iglesia en el encabezado.
/// Consume el endpoint `GET /atrio/portal/api/church/qr.png` con `Authorization: Bearer <token>`.
/// Si el QR está disponible, lo muestra como imagen PNG enmarcada y permite al usuario
/// tocarlo para abrir un modal en alta resolución con el enlace canónico X-Atrio-Join-Url
/// para compartir o mostrar a nuevos feligreses.
class _ChurchQrAvatar extends StatefulWidget {
  final IglesiaModel iglesia;
  final double screenWidth;
  final double usableHeight;
  final Color azulFondo;
  final Color amarilloOro;

  const _ChurchQrAvatar({
    required this.iglesia,
    required this.screenWidth,
    required this.usableHeight,
    required this.azulFondo,
    required this.amarilloOro,
  });

  @override
  State<_ChurchQrAvatar> createState() => _ChurchQrAvatarState();
}

class _ChurchQrAvatarState extends State<_ChurchQrAvatar> {
  Uint8List? _qrBytes;
  String? _joinUrl;
  bool _isLoading = true;
  bool _hasFetched = false;
  int? _lastUserId;
  bool? _lastIsAuthenticated;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UserProvider>(context);
    final currentUserId = userProvider.currentUser?.id;
    final currentIsAuth = userProvider.isAuthenticated;

    if (!_hasFetched ||
        _lastUserId != currentUserId ||
        _lastIsAuthenticated != currentIsAuth) {
      _lastUserId = currentUserId;
      _lastIsAuthenticated = currentIsAuth;
      _hasFetched = true;
      _cargarQr();
    }
  }

  @override
  void didUpdateWidget(covariant _ChurchQrAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.iglesia.id != widget.iglesia.id) {
      _cargarQr();
    }
  }

  Future<void> _cargarQr() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final data = await ChurchQrManager.obtenerQr(
      context: context,
      churchId: widget.iglesia.id,
    );
    if (mounted) {
      setState(() {
        _qrBytes = data?.bytes;
        _joinUrl = data?.joinUrl;
        _isLoading = false;
      });
    }
  }

  void _abrirModalQr(BuildContext context) {
    ChurchQrManager.mostrarModal(
      context: context,
      churchName: widget.iglesia.nombre,
      denomination: widget.iglesia.denominacion,
      churchId: widget.iglesia.id,
      azulFondo: widget.azulFondo,
      amarilloOro: widget.amarilloOro,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = widget.screenWidth * 0.15;
    final height = widget.screenWidth * 0.19;
    final borderRadius = BorderRadius.circular(widget.screenWidth * 0.035);

    Widget contenido;
    if (_isLoading) {
      contenido = Center(
        child: SizedBox(
          width: widget.screenWidth * 0.05,
          height: widget.screenWidth * 0.05,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(widget.azulFondo),
          ),
        ),
      );
    } else if (_qrBytes != null) {
      contenido = Padding(
        padding: EdgeInsets.all(widget.screenWidth * 0.012),
        child: Image.memory(
          _qrBytes!,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.church_rounded,
            color: widget.azulFondo,
            size: widget.screenWidth * 0.08,
          ),
        ),
      );
    } else if (_joinUrl != null &&
        _joinUrl!.trim().isNotEmpty &&
        !_joinUrl!.toLowerCase().contains('/false')) {
      contenido = Padding(
        padding: EdgeInsets.all(widget.screenWidth * 0.012),
        child: QrImageView(
          data: _joinUrl!,
          version: QrVersions.auto,
          size: width,
          padding: EdgeInsets.zero,
          eyeStyle: QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: widget.azulFondo,
          ),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: widget.azulFondo,
          ),
        ),
      );
    } else {
      // Fallback seguro al icono de iglesia si el QR no está disponible (ej. offline o sin iglesia)
      contenido = Icon(
        Icons.church_rounded,
        color: widget.azulFondo,
        size: widget.screenWidth * 0.08,
      );
    }

    final card = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: contenido,
    );

    if (_qrBytes == null) {
      return card;
    }

    return Tooltip(
      message:
          l10n?.qrIglesiaTooltip ??
          'Código QR oficial de la congregación (toca para ampliar)',
      child: Semantics(
        label:
            l10n?.qrIglesiaTooltip ??
            'Código QR oficial de la congregación (toca para ampliar)',
        button: true,
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: () => _abrirModalQr(context),
            child: card,
          ),
        ),
      ),
    );
  }
}
