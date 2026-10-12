import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../modelos/proyecto_solidario_model.dart';
import '../providers/proyecto_solidario_provider.dart';
import 'aportar_a_proyecto_screen.dart';

class ProyectoSolidarioScreen extends StatefulWidget {
  static const routeName = 'proyecto_solidario_screen';

  const ProyectoSolidarioScreen({super.key});

  @override
  State<ProyectoSolidarioScreen> createState() =>
      _ProyectoSolidarioScreenState();
}

class _ProyectoSolidarioScreenState extends State<ProyectoSolidarioScreen> {
  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFE5E5E5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProyectoSolidarioProvider>(
        context,
        listen: false,
      );
      if (provider.data == null && !provider.isLoading) {
        provider.cargarProyectos();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Obtención de métricas dinámicas relativas (Flutter 3.22+)
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    final l10n = AppLocalizations.of(context);
    final provider = Provider.of<ProyectoSolidarioProvider>(context);
    final data = provider.data;

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: false,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight,
          child: Column(
            children: [
              // 2. Encabezado Superior
              Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: usableHeight * 0.01),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Tooltip(
                            message: l10n?.volver ?? 'Volver',
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
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Text(
                            l10n?.proyectosSolidariosTitulo ??
                                'Proyectos solidarios',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.065,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: usableHeight * 0.02),
                  ],
                ),
              ),

              // 3. Contenedor Blanco Inferior
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
                    child: _buildBodyContent(
                      provider,
                      data,
                      screenWidth,
                      usableHeight,
                      l10n,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent(
    ProyectoSolidarioProvider provider,
    ProyectosSolidariosData? data,
    double screenWidth,
    double usableHeight,
    AppLocalizations? l10n,
  ) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: amarilloOro));
    }

    if (provider.errorMessage != null || data == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade400,
                size: screenWidth * 0.12,
              ),
              SizedBox(height: usableHeight * 0.015),
              Text(
                provider.errorMessage ??
                    (l10n?.noHayDatosDisponibles ?? 'No hay datos disponibles'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.035,
                ),
              ),
              SizedBox(height: usableHeight * 0.02),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: azulFondo),
                onPressed: () => provider.cargarProyectos(),
                child: Text(
                  l10n?.reintentar ?? 'Reintentar',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: usableHeight * 0.025,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.lema == 'Juntos podemos transformar vidas'
                ? (l10n?.lemaProyectosSolidarios ?? data.lema)
                : data.lema,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: screenWidth * 0.040,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: usableHeight * 0.02),

          // Tarjeta Destacada (Pasa los datos del proyecto destacado)
          _buildFeaturedProjectCard(
            proyecto: data.proyectoDestacado,
            screenWidth: screenWidth,
            usableHeight: usableHeight,
            l10n: l10n,
            onTap: () {
              Navigator.pushNamed(
                context,
                AportarAProyectoScreen.routeName,
                arguments: {
                  'titulo': data.proyectoDestacado.titulo,
                  'subtitulo': data.proyectoDestacado.subtitulo,
                },
              );
            },
          ),
          SizedBox(height: usableHeight * 0.03),

          Text(
            l10n?.masCampanas ?? 'Más campañas',
            style: TextStyle(
              color: azulFondo,
              fontSize: screenWidth * 0.055,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: usableHeight * 0.015),

          // Lista dinámica de otras campañas (Pasa los datos de cada campaña)
          ...data.otrasCampanas.map(
            (campana) => Padding(
              padding: EdgeInsets.only(bottom: usableHeight * 0.015),
              child: _buildCampaignCard(
                campana: campana,
                screenWidth: screenWidth,
                usableHeight: usableHeight,
                l10n: l10n,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AportarAProyectoScreen.routeName,
                    arguments: {
                      'titulo': campana.titulo,
                      'subtitulo':
                          '${campana.categoria} · ${l10n?.metaPrefijo ?? 'Meta:'} RD\$ ${NumberFormat("#,##0", "en_US").format(campana.metaMonto)}',
                    },
                  );
                },
              ),
            ),
          ),
          SizedBox(height: usableHeight * 0.02),
        ],
      ),
    );
  }

  Widget _buildFeaturedProjectCard({
    required ProyectoModel proyecto,
    required double screenWidth,
    required double usableHeight,
    required AppLocalizations? l10n,
    required VoidCallback onTap,
  }) {
    final formatCurrency = NumberFormat("#,##0", "en_US");

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: screenWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.045),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: usableHeight * 0.16,
              width: screenWidth,
              decoration: BoxDecoration(
                color: const Color(0xFF94BAA7),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(screenWidth * 0.045),
                  topRight: Radius.circular(screenWidth * 0.045),
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.maps_home_work_outlined,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: screenWidth * 0.16,
                    ),
                  ),
                  if (proyecto.esDestacado)
                    Positioned(
                      top: usableHeight * 0.015,
                      left: screenWidth * 0.04,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: usableHeight * 0.005,
                        ),
                        decoration: BoxDecoration(
                          color: amarilloOro,
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.03,
                          ),
                        ),
                        child: Text(
                          l10n?.destacadoMayus ?? 'DESTACADO',
                          style: TextStyle(
                            color: azulFondo,
                            fontSize: screenWidth * 0.026,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    proyecto.titulo,
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.048,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.005),
                  Text(
                    proyecto.subtitulo,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.02),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    child: LinearProgressIndicator(
                      value: proyecto.porcentajeProgreso,
                      minHeight: usableHeight * 0.01,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        amarilloOro,
                      ),
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.015),
                  Row(
                    children: [
                      Text(
                        'RD\$ ${formatCurrency.format(proyecto.montoRecaudado)}',
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.040,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ' ${l10n?.deMonto ?? 'de'} RD\$ ${formatCurrency.format(proyecto.metaMonto)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: screenWidth * 0.036,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.005),
                  Text(
                    '${l10n?.porcentajeAlcanzado(proyecto.porcentajeEntero.toString()) ?? '${proyecto.porcentajeEntero}% alcanzado'} · ${l10n?.diasRestantes(proyecto.diasRestantes.toString()) ?? '${proyecto.diasRestantes} días restantes'}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: screenWidth * 0.032,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignCard({
    required CampanaSecundariaModel campana,
    required double screenWidth,
    required double usableHeight,
    required AppLocalizations? l10n,
    required VoidCallback onTap,
  }) {
    final Color bgColor = Color(int.parse(campana.colorFondoHex));
    final Color barColor = Color(int.parse(campana.colorBarraHex));

    IconData iconData;
    switch (campana.iconoNombre) {
      case 'medical':
        iconData = Icons.medical_services_outlined;
        break;
      case 'school':
        iconData = Icons.school_outlined;
        break;
      case 'favorite':
      default:
        iconData = Icons.favorite_border_rounded;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          border: Border.all(color: grisBorde),
        ),
        child: Row(
          children: [
            Container(
              width: screenWidth * 0.14,
              height: screenWidth * 0.14,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
              ),
              child: Icon(iconData, color: azulFondo, size: screenWidth * 0.07),
            ),
            SizedBox(width: screenWidth * 0.035),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campana.titulo,
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.038,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.004),
                  Text(
                    '${campana.categoria} · ${l10n?.porcentajeAlcanzado(campana.porcentajeEntero.toString()) ?? '${campana.porcentajeEntero}% alcanzado'}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: screenWidth * 0.031,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.008),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    child: LinearProgressIndicator(
                      value: campana.progreso,
                      minHeight: usableHeight * 0.006,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(barColor),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Icon(
              Icons.chevron_right_rounded,
              color: azulFondo,
              size: screenWidth * 0.055,
            ),
          ],
        ),
      ),
    );
  }
}
