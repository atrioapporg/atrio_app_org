import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/ajustes_provider.dart';

class ConfiguracionScreen extends StatelessWidget {
  static const routeName = 'configuracion_screen';

  const ConfiguracionScreen({super.key});

  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFE6E8EC);
  static const Color grisFondo = Color(0xFFF4F6F9);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;

    final provider = context.watch<AjustesProvider>();

    return Scaffold(
      backgroundColor: blancoFondo,
      appBar: AppBar(
        backgroundColor: azulFondo,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.ajustesDeLaApp,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.046,
              ),
            ),
            Text(
              l10n.personalizaTuExperienciaAtrio,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white70,
                fontSize: screenWidth * 0.028,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.035),
            child: Center(
              child: _buildBotonSelectorIdioma(
                context: context,
                provider: provider,
                screenWidth: screenWidth,
                usableHeight: usableHeight,
              ),
            ),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: amarilloOro))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.045,
                vertical: usableHeight * 0.02,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Idioma y Región
                  _buildSectionHeader(
                    icon: Icons.language_rounded,
                    title: l10n.idiomaYRegion,
                    screenWidth: screenWidth,
                  ),
                  _buildCardContainer(
                    screenWidth: screenWidth,
                    children: [
                      _buildIdiomaTile(context, provider, screenWidth),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          screenWidth * 0.035,
                          0,
                          screenWidth * 0.035,
                          screenWidth * 0.035,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildBotonOpcionIdioma(
                                context: context,
                                provider: provider,
                                codigo: 'es',
                                region: 'DO',
                                nombre: 'Español',
                                bandera: '🇩🇴',
                                screenWidth: screenWidth,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.025),
                            Expanded(
                              child: _buildBotonOpcionIdioma(
                                context: context,
                                provider: provider,
                                codigo: 'en',
                                region: 'US',
                                nombre: 'English',
                                bandera: '🇺🇸',
                                screenWidth: screenWidth,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.025),

                  // 2. Apariencia y Tema
                  _buildSectionHeader(
                    icon: Icons.palette_outlined,
                    title: l10n.aparienciaYTema,
                    screenWidth: screenWidth,
                  ),
                  _buildCardContainer(
                    screenWidth: screenWidth,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(screenWidth * 0.035),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.modoDeVisualizacion,
                              style: TextStyle(
                                color: azulFondo,
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.038,
                              ),
                            ),
                            SizedBox(height: usableHeight * 0.012),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildThemeOptionCard(
                                    label: l10n.temaClaro,
                                    icon: Icons.light_mode_rounded,
                                    isSelected: provider.temaModo == 'claro',
                                    onTap: () => provider.cambiarTema('claro'),
                                    screenWidth: screenWidth,
                                    usableHeight: usableHeight,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.025),
                                Expanded(
                                  child: _buildThemeOptionCard(
                                    label: l10n.temaOscuro,
                                    icon: Icons.dark_mode_rounded,
                                    isSelected: provider.temaModo == 'oscuro',
                                    onTap: () => provider.cambiarTema('oscuro'),
                                    screenWidth: screenWidth,
                                    usableHeight: usableHeight,
                                  ),
                                ),
                                SizedBox(width: screenWidth * 0.025),
                                Expanded(
                                  child: _buildThemeOptionCard(
                                    label: l10n.temaSistema,
                                    icon: Icons.settings_suggest_rounded,
                                    isSelected: provider.temaModo == 'sistema',
                                    onTap: () =>
                                        provider.cambiarTema('sistema'),
                                    screenWidth: screenWidth,
                                    usableHeight: usableHeight,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: EdgeInsets.all(screenWidth * 0.035),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(
                                        screenWidth * 0.02,
                                      ),
                                      decoration: BoxDecoration(
                                        color: amarilloOro.withValues(
                                          alpha: 0.15,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.auto_awesome_motion_rounded,
                                        color: const Color(0xFFC78408),
                                        size: screenWidth * 0.045,
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.025),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.transicionDeNovedades,
                                          style: TextStyle(
                                            color: azulFondo,
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenWidth * 0.037,
                                          ),
                                        ),
                                        Text(
                                          l10n.bannerPrincipalHero,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: screenWidth * 0.028,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.028,
                                    vertical: usableHeight * 0.005,
                                  ),
                                  decoration: BoxDecoration(
                                    color: azulFondo,
                                    borderRadius: BorderRadius.circular(
                                      screenWidth * 0.025,
                                    ),
                                  ),
                                  child: Text(
                                    l10n.segundosAbrev(
                                      provider.tiempoTransicionBannerSegundos,
                                    ),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: screenWidth * 0.033,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: usableHeight * 0.012),
                            Text(
                              l10n.efectoDesvanecimientoBanner,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: screenWidth * 0.030,
                              ),
                            ),
                            SizedBox(height: usableHeight * 0.004),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: amarilloOro,
                                inactiveTrackColor: Colors.grey.shade300,
                                thumbColor: azulFondo,
                                overlayColor: amarilloOro.withValues(
                                  alpha: 0.2,
                                ),
                                valueIndicatorColor: azulFondo,
                                valueIndicatorTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              child: Slider(
                                value: provider
                                    .tiempoTransicionBannerSegundos
                                    .toDouble(),
                                min: 3.0,
                                max: 10.0,
                                divisions: 7,
                                label:
                                    '${provider.tiempoTransicionBannerSegundos}s',
                                onChanged: (val) {
                                  provider.cambiarTiempoTransicionBanner(
                                    val.round(),
                                  );
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.segundosMinimo,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: screenWidth * 0.027,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  l10n.segundosPredeterminado,
                                  style: TextStyle(
                                    color: amarilloOro,
                                    fontSize: screenWidth * 0.027,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  l10n.segundosMaximo,
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: screenWidth * 0.027,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.025),

                  // 3. Notificaciones y Devocional
                  _buildSectionHeader(
                    icon: Icons.notifications_active_outlined,
                    title: l10n.notificacionesYRecordatorios,
                    screenWidth: screenWidth,
                  ),
                  _buildCardContainer(
                    screenWidth: screenWidth,
                    children: [
                      _buildSwitchTile(
                        title: l10n.versiculoDelDia,
                        subtitle: l10n.recibePorcionBiblica,
                        value: provider.notifVersiculoDia,
                        onChanged: (val) =>
                            provider.toggleNotificacion('versiculo', val),
                        screenWidth: screenWidth,
                      ),
                      if (provider.notifVersiculoDia) ...[
                        const Divider(height: 1),
                        _buildTimePickerTile(
                          context: context,
                          provider: provider,
                          screenWidth: screenWidth,
                        ),
                      ],
                      const Divider(height: 1),
                      _buildSwitchTile(
                        title: l10n.palabraDelDia,
                        subtitle: l10n.reflexionDevocionalDiario,
                        value: provider.notifPalabraDia,
                        onChanged: (val) =>
                            provider.toggleNotificacion('palabra', val),
                        screenWidth: screenWidth,
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        title: l10n.cultosEnVivo,
                        subtitle: l10n.alertaTransmisionDirecto,
                        value: provider.notifCultosEnVivo,
                        onChanged: (val) =>
                            provider.toggleNotificacion('cultos', val),
                        screenWidth: screenWidth,
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        title: l10n.anunciosEventosGlobales,
                        subtitle: l10n.conferenciasConciertosAvisos,
                        value: provider.notifAnunciosEventos,
                        onChanged: (val) =>
                            provider.toggleNotificacion('anuncios', val),
                        screenWidth: screenWidth,
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.025),

                  // 4. Lectura Bíblica
                  _buildSectionHeader(
                    icon: Icons.menu_book_rounded,
                    title: l10n.lecturaDeLaBiblia,
                    screenWidth: screenWidth,
                  ),
                  _buildCardContainer(
                    screenWidth: screenWidth,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(screenWidth * 0.038),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.versionPredeterminada,
                              style: TextStyle(
                                color: azulFondo,
                                fontWeight: FontWeight.bold,
                                fontSize: screenWidth * 0.036,
                              ),
                            ),
                            SizedBox(height: usableHeight * 0.01),
                            Row(
                              children: [
                                _buildVersionChip(
                                  label: 'RVR1960',
                                  provider: provider,
                                  screenWidth: screenWidth,
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                _buildVersionChip(
                                  label: 'NVI',
                                  provider: provider,
                                  screenWidth: screenWidth,
                                ),
                                SizedBox(width: screenWidth * 0.02),
                                _buildVersionChip(
                                  label: 'DHH',
                                  provider: provider,
                                  screenWidth: screenWidth,
                                ),
                              ],
                            ),
                            SizedBox(height: usableHeight * 0.02),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.tamanoTextoLectura,
                                  style: TextStyle(
                                    color: azulFondo,
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.036,
                                  ),
                                ),
                                Text(
                                  '${(provider.tamanoFuenteLectura * 100).toInt()}%',
                                  style: TextStyle(
                                    color: amarilloOro,
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.035,
                                  ),
                                ),
                              ],
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: amarilloOro,
                                thumbColor: azulFondo,
                                inactiveTrackColor: Colors.grey.shade300,
                              ),
                              child: Slider(
                                value: provider.tamanoFuenteLectura,
                                min: 0.8,
                                max: 1.4,
                                divisions: 6,
                                onChanged: (val) =>
                                    provider.cambiarTamanoFuente(val),
                              ),
                            ),
                            // Vista previa interactiva de texto
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(screenWidth * 0.03),
                              decoration: BoxDecoration(
                                color: grisFondo,
                                borderRadius: BorderRadius.circular(
                                  screenWidth * 0.025,
                                ),
                                border: Border.all(color: grisBorde),
                              ),
                              child: Text(
                                l10n.ejemploTextoBiblia,
                                style: TextStyle(
                                  fontSize:
                                      screenWidth *
                                      0.036 *
                                      provider.tamanoFuenteLectura,
                                  color: azulFondo,
                                  fontStyle: FontStyle.italic,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        title: l10n.mantenerPantallaEncendida,
                        subtitle: l10n.evitaBloqueoTelefonoBiblia,
                        value: provider.mantenerPantallaActiva,
                        onChanged: (val) =>
                            provider.toggleMantenerPantalla(val),
                        screenWidth: screenWidth,
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.025),

                  // 5. Audio y Emisoras
                  _buildSectionHeader(
                    icon: Icons.radio_rounded,
                    title: l10n.emisorasYTransmisiones,
                    screenWidth: screenWidth,
                  ),
                  _buildCardContainer(
                    screenWidth: screenWidth,
                    children: [
                      _buildSwitchTile(
                        title: l10n.reproduccionAutomatica,
                        subtitle: l10n.iniciarRadioAlSintonizar,
                        value: provider.reproduccionAutomaticaRadio,
                        onChanged: (val) => provider.toggleAutoplayRadio(val),
                        screenWidth: screenWidth,
                      ),
                      const Divider(height: 1),
                      _buildCalidadAudioTile(context, provider, screenWidth),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        title: l10n.ahorroDeDatosSoloWifi,
                        subtitle: l10n.reproducirDescargarSoloWifi,
                        value: provider.soloDescargarConWifi,
                        onChanged: (val) => provider.toggleSoloWifi(val),
                        screenWidth: screenWidth,
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.025),

                  // 6. Almacenamiento y Caché
                  _buildSectionHeader(
                    icon: Icons.cleaning_services_rounded,
                    title: l10n.almacenamientoYMemoria,
                    screenWidth: screenWidth,
                  ),
                  _buildCardContainer(
                    screenWidth: screenWidth,
                    children: [
                      ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(screenWidth * 0.022),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.cached_rounded,
                            color: Colors.orange.shade800,
                            size: screenWidth * 0.055,
                          ),
                        ),
                        title: Text(
                          l10n.limpiarMemoriaCache,
                          style: TextStyle(
                            color: azulFondo,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.038,
                          ),
                        ),
                        subtitle: Text(
                          l10n.imagenesAudiosTemporales,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: screenWidth * 0.03,
                          ),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.035,
                              vertical: usableHeight * 0.008,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.025,
                              ),
                            ),
                          ),
                          onPressed: () => _limpiarCache(context),
                          child: Text(l10n.limpiar),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.025),

                  // 7. Restablecer valores
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                      ),
                      icon: const Icon(Icons.restore_rounded),
                      label: Text(
                        l10n.restablecerAjustesPredeterminados,
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => _confirmarRestablecer(context, provider),
                    ),
                  ),

                  SizedBox(height: usableHeight * 0.02),
                  Center(
                    child: Text(
                      'ATRIO · v1.0.0 (Build 3)',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: screenWidth * 0.03,
                      ),
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.03),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required double screenWidth,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: screenWidth * 0.02,
        bottom: screenWidth * 0.02,
      ),
      child: Row(
        children: [
          Icon(icon, color: azulFondo, size: screenWidth * 0.05),
          SizedBox(width: screenWidth * 0.02),
          Text(
            title,
            style: TextStyle(
              color: azulFondo,
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.042,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer({
    required double screenWidth,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
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
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.035),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required double screenWidth,
  }) {
    return SwitchListTile.adaptive(
      activeThumbColor: amarilloOro,
      activeTrackColor: amarilloOro.withValues(alpha: 0.4),
      title: Text(
        title,
        style: TextStyle(
          color: azulFondo,
          fontWeight: FontWeight.w600,
          fontSize: screenWidth * 0.036,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: screenWidth * 0.03,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildIdiomaTile(
    BuildContext context,
    AjustesProvider provider,
    double screenWidth,
  ) {
    final l10n = AppLocalizations.of(context)!;
    String idiomaNombre = l10n.idiomaEspanolLatino;
    String bandera = '🇩🇴';

    if (provider.idiomaCodigo == 'en') {
      idiomaNombre = l10n.idiomaInglesUSA;
      bandera = '🇺🇸';
    }

    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(screenWidth * 0.02),
        decoration: BoxDecoration(
          color: azulFondo.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Text(bandera, style: TextStyle(fontSize: screenWidth * 0.055)),
      ),
      title: Text(
        l10n.idiomaPreferido,
        style: TextStyle(
          color: azulFondo,
          fontWeight: FontWeight.bold,
          fontSize: screenWidth * 0.037,
        ),
      ),
      subtitle: Text(
        idiomaNombre,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: screenWidth * 0.031,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.025,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: amarilloOro.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
            ),
            child: Text(
              provider.idiomaCodigo.toUpperCase(),
              style: TextStyle(
                color: azulFondo,
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.03,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ],
      ),
      onTap: () => _mostrarSelectorIdioma(context, provider, screenWidth),
    );
  }

  // ============================================================================
  // GESTIÓN Y SELECTOR DE IDIOMA (flutter_localizations)
  // ============================================================================
  String _obtenerNombreIdioma(String codigo) {
    switch (codigo) {
      case 'en':
        return 'English';
      case 'es':
      default:
        return 'Español';
    }
  }

  /// Botón idéntico al de InicioSesionScreen para cambio de idioma
  Widget _buildBotonSelectorIdioma({
    required BuildContext context,
    required AjustesProvider provider,
    required double screenWidth,
    required double usableHeight,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        onTap: () => _mostrarSelectorIdioma(context, provider, screenWidth),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.025,
            vertical: usableHeight * 0.006,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            border: Border.all(color: Colors.white38),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language,
                color: Colors.white,
                size: screenWidth * 0.04,
              ),
              SizedBox(width: screenWidth * 0.015),
              Text(
                _obtenerNombreIdioma(provider.idiomaCodigo),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.03,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: screenWidth * 0.04,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Botón de cambio directo entre opciones principales de idioma
  Widget _buildBotonOpcionIdioma({
    required BuildContext context,
    required AjustesProvider provider,
    required String codigo,
    required String region,
    required String nombre,
    required String bandera,
    required double screenWidth,
  }) {
    final isSelected = provider.idiomaCodigo == codigo;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => provider.cambiarIdioma(codigo, region: region),
        borderRadius: BorderRadius.circular(screenWidth * 0.025),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.03,
            vertical: screenWidth * 0.025,
          ),
          decoration: BoxDecoration(
            color: isSelected ? azulFondo : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(screenWidth * 0.025),
            border: Border.all(
              color: isSelected ? azulFondo : grisBorde,
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: azulFondo.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                bandera,
                style: TextStyle(fontSize: screenWidth * 0.042),
              ),
              SizedBox(width: screenWidth * 0.02),
              Text(
                nombre,
                style: TextStyle(
                  color: isSelected ? Colors.white : azulFondo,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: screenWidth * 0.032,
                ),
              ),
              if (isSelected) ...[
                SizedBox(width: screenWidth * 0.015),
                Icon(
                  Icons.check_circle_rounded,
                  color: amarilloOro,
                  size: screenWidth * 0.038,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarSelectorIdioma(
    BuildContext context,
    AjustesProvider provider,
    double screenWidth,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final opciones = [
      {
        'codigo': 'es',
        'region': 'DO',
        'nombre': l10n.idiomaEspanolLatino,
        'bandera': '🇩🇴',
      },
      {
        'codigo': 'en',
        'region': 'US',
        'nombre': l10n.idiomaInglesUSA,
        'bandera': '🇺🇸',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.06),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenWidth * 0.04,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.translate_rounded, color: azulFondo),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    l10n.seleccionarIdioma,
                    style: TextStyle(
                      color: azulFondo,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.045,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              ...opciones.map((opcion) {
                final isSelected = provider.idiomaCodigo == opcion['codigo'];
                return ListTile(
                  leading: Text(
                    opcion['bandera']!,
                    style: TextStyle(fontSize: screenWidth * 0.06),
                  ),
                  title: Text(
                    opcion['nombre']!,
                    style: TextStyle(
                      color: isSelected ? azulFondo : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: screenWidth * 0.038,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: amarilloOro,
                        )
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                  ),
                  tileColor: isSelected
                      ? azulFondo.withValues(alpha: 0.05)
                      : Colors.transparent,
                  onTap: () {
                    provider.cambiarIdioma(
                      opcion['codigo']!,
                      region: opcion['region'],
                    );
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOptionCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required double screenWidth,
    required double usableHeight,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: usableHeight * 0.015),
        decoration: BoxDecoration(
          color: isSelected ? amarilloOro.withValues(alpha: 0.15) : grisFondo,
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          border: Border.all(
            color: isSelected ? amarilloOro : grisBorde,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? azulFondo : Colors.grey.shade600,
              size: screenWidth * 0.065,
            ),
            SizedBox(height: usableHeight * 0.006),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? azulFondo : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: screenWidth * 0.032,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerTile({
    required BuildContext context,
    required AjustesProvider provider,
    required double screenWidth,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(screenWidth * 0.02),
        decoration: BoxDecoration(
          color: amarilloOro.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.alarm_rounded,
          color: amarilloOro,
          size: screenWidth * 0.05,
        ),
      ),
      title: Text(
        l10n.horaDelRecordatorio,
        style: TextStyle(
          color: azulFondo,
          fontSize: screenWidth * 0.035,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: azulFondo.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
        ),
        child: Text(
          provider.horaNotifDevocional,
          style: TextStyle(
            color: azulFondo,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.035,
          ),
        ),
      ),
      onTap: () async {
        final partes = provider.horaNotifDevocional.split(':');
        final horaActual = TimeOfDay(
          hour: int.tryParse(partes[0]) ?? 7,
          minute: partes.length > 1 ? int.tryParse(partes[1]) ?? 0 : 0,
        );

        final seleccion = await showTimePicker(
          context: context,
          initialTime: horaActual,
        );

        if (seleccion != null) {
          final horaStr =
              '${seleccion.hour.toString().padLeft(2, '0')}:${seleccion.minute.toString().padLeft(2, '0')}';
          provider.cambiarHoraDevocional(horaStr);
        }
      },
    );
  }

  Widget _buildVersionChip({
    required String label,
    required AjustesProvider provider,
    required double screenWidth,
  }) {
    final isSelected = provider.bibliaVersionPredeterminada == label;
    return GestureDetector(
      onTap: () => provider.cambiarVersionBiblia(label),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? azulFondo : grisFondo,
          borderRadius: BorderRadius.circular(screenWidth * 0.025),
          border: Border.all(color: isSelected ? azulFondo : grisBorde),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: screenWidth * 0.033,
          ),
        ),
      ),
    );
  }

  Widget _buildCalidadAudioTile(
    BuildContext context,
    AjustesProvider provider,
    double screenWidth,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(screenWidth * 0.02),
        decoration: BoxDecoration(
          color: azulFondo.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.graphic_eq_rounded,
          color: azulFondo,
          size: screenWidth * 0.05,
        ),
      ),
      title: Text(
        l10n.calidadAudioStreaming,
        style: TextStyle(
          color: azulFondo,
          fontWeight: FontWeight.w600,
          fontSize: screenWidth * 0.036,
        ),
      ),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: provider.calidadAudioStreaming,
          dropdownColor: Colors.white,
          items: [
            DropdownMenuItem(value: 'baja', child: Text(l10n.calidadAudioBaja)),
            DropdownMenuItem(value: 'media', child: Text(l10n.calidadAudioMedia)),
            DropdownMenuItem(value: 'alta', child: Text(l10n.calidadAudioAlta)),
          ],
          onChanged: (val) {
            if (val != null) provider.cambiarCalidadAudio(val);
          },
        ),
      ),
    );
  }

  void _limpiarCache(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(l10n.limpiarCacheTitulo),
        content: Text(
          l10n.limpiarCacheMensaje,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancelar),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: azulFondo,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ ${l10n.memoriaCacheLiberadaExito}'),
                  backgroundColor: const Color(0xFF2E7D32),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(l10n.limpiarAhora),
          ),
        ],
      ),
    );
  }

  void _confirmarRestablecer(BuildContext context, AjustesProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(l10n.restablecerConfiguracionTitulo),
        content: Text(
          l10n.restablecerConfiguracionMensaje,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancelar),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              provider.restaurarValoresPredeterminados();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.ajustesRestablecidosFabrica),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(l10n.restablecer),
          ),
        ],
      ),
    );
  }
}
