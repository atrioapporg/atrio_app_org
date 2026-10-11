import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
              'Ajustes de la App',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.05,
              ),
            ),
            Text(
              'Personaliza tu experiencia en ATRIO',
              style: TextStyle(
                color: Colors.white70,
                fontSize: screenWidth * 0.03,
              ),
            ),
          ],
        ),
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
                    title: 'Idioma y Región',
                    screenWidth: screenWidth,
                  ),
                  _buildCardContainer(
                    screenWidth: screenWidth,
                    children: [
                      _buildIdiomaTile(context, provider, screenWidth),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.025),

                  // 2. Apariencia y Tema
                  _buildSectionHeader(
                    icon: Icons.palette_outlined,
                    title: 'Apariencia y Tema',
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
                              'Modo de visualización',
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
                                    label: 'Claro',
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
                                    label: 'Oscuro',
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
                                    label: 'Sistema',
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
                                          'Transición de Novedades',
                                          style: TextStyle(
                                            color: azulFondo,
                                            fontWeight: FontWeight.bold,
                                            fontSize: screenWidth * 0.037,
                                          ),
                                        ),
                                        Text(
                                          'Banner principal (HeroBannerCard)',
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
                                    '${provider.tiempoTransicionBannerSegundos} seg',
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
                              'Efecto de desvanecimiento suave entre versículo, palabra y cultos.',
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
                                  '3 seg',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: screenWidth * 0.027,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '5 seg (Predeterminado)',
                                  style: TextStyle(
                                    color: amarilloOro,
                                    fontSize: screenWidth * 0.027,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '10 seg',
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
                    title: 'Notificaciones y Recordatorios',
                    screenWidth: screenWidth,
                  ),
                  _buildCardContainer(
                    screenWidth: screenWidth,
                    children: [
                      _buildSwitchTile(
                        title: 'Versículo del día',
                        subtitle: 'Recibe una porción bíblica cada mañana',
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
                        title: 'Palabra del día',
                        subtitle: 'Reflexión y devocional diario para tu fe',
                        value: provider.notifPalabraDia,
                        onChanged: (val) =>
                            provider.toggleNotificacion('palabra', val),
                        screenWidth: screenWidth,
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        title: 'Cultos en vivo',
                        subtitle:
                            'Alerta cuando comience una transmisión en directo',
                        value: provider.notifCultosEnVivo,
                        onChanged: (val) =>
                            provider.toggleNotificacion('cultos', val),
                        screenWidth: screenWidth,
                      ),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        title: 'Anuncios y eventos globales',
                        subtitle:
                            'Conferencias, conciertos y avisos de iglesias',
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
                    title: 'Lectura de la Biblia',
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
                              'Versión predeterminada',
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
                                  'Tamaño de texto en lectura',
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
                                '«Lámpara es a mis pies tu palabra, y lumbrera a mi camino.» — Salmos 119:105',
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
                        title: 'Mantener pantalla encendida',
                        subtitle: 'Evita que el teléfono se bloquee mientras lees la Biblia',
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
                    title: 'Emisoras y Transmisiones',
                    screenWidth: screenWidth,
                  ),
                  _buildCardContainer(
                    screenWidth: screenWidth,
                    children: [
                      _buildSwitchTile(
                        title: 'Reproducción automática',
                        subtitle: 'Iniciar la radio al sintonizar la emisora',
                        value: provider.reproduccionAutomaticaRadio,
                        onChanged: (val) => provider.toggleAutoplayRadio(val),
                        screenWidth: screenWidth,
                      ),
                      const Divider(height: 1),
                      _buildCalidadAudioTile(context, provider, screenWidth),
                      const Divider(height: 1),
                      _buildSwitchTile(
                        title: 'Ahorro de datos (Solo Wi-Fi)',
                        subtitle: 'Reproducir y descargar en alta calidad solo con Wi-Fi',
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
                    title: 'Almacenamiento y Memoria',
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
                          'Limpiar memoria caché',
                          style: TextStyle(
                            color: azulFondo,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.038,
                          ),
                        ),
                        subtitle: Text(
                          'Imágenes y audios temporales (~18.4 MB)',
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
                          child: const Text('Limpiar'),
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
                        'Restablecer ajustes predeterminados',
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
    String idiomaNombre = 'Español (Latinoamérica)';
    String bandera = '🇩🇴';

    switch (provider.idiomaCodigo) {
      case 'en':
        idiomaNombre = 'English (United States)';
        bandera = '🇺🇸';
        break;
      case 'pt':
        idiomaNombre = 'Português (Brasil)';
        bandera = '🇧🇷';
        break;
      case 'fr':
        idiomaNombre = 'Français';
        bandera = '🇫🇷';
        break;
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
        'Idioma preferido',
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

  void _mostrarSelectorIdioma(
    BuildContext context,
    AjustesProvider provider,
    double screenWidth,
  ) {
    final opciones = [
      {'codigo': 'es', 'region': 'DO', 'nombre': 'Español', 'bandera': '🇩🇴'},
      {'codigo': 'en', 'region': 'US', 'nombre': 'English', 'bandera': '🇺🇸'},
      {
        'codigo': 'pt',
        'region': 'BR',
        'nombre': 'Português',
        'bandera': '🇧🇷',
      },
      {'codigo': 'fr', 'region': 'FR', 'nombre': 'Français', 'bandera': '🇫🇷'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.06),
        ),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.translate_rounded, color: azulFondo),
                SizedBox(width: screenWidth * 0.02),
                Text(
                  'Seleccionar Idioma',
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
                    color: azulFondo,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: amarilloOro)
                    : null,
                onTap: () {
                  provider.cambiarIdioma(
                    opcion['codigo']!,
                    region: opcion['region'],
                  );
                  Navigator.pop(ctx);
                },
              );
            }),
            SizedBox(height: screenWidth * 0.04),
          ],
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
        'Hora del recordatorio',
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
        'Calidad de audio streaming',
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
          items: const [
            DropdownMenuItem(value: 'baja', child: Text('Baja (64 kbps)')),
            DropdownMenuItem(value: 'media', child: Text('Media (128 kbps)')),
            DropdownMenuItem(value: 'alta', child: Text('Alta (256 kbps)')),
          ],
          onChanged: (val) {
            if (val != null) provider.cambiarCalidadAudio(val);
          },
        ),
      ),
    );
  }

  void _limpiarCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('¿Limpiar memoria caché?'),
        content: const Text(
          'Se eliminarán imágenes y archivos temporales para liberar almacenamiento. No se borrarán tus notas ni favoritos bíblicos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: azulFondo,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Memoria caché liberada con éxito'),
                  backgroundColor: Color(0xFF2E7D32),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Limpiar ahora'),
          ),
        ],
      ),
    );
  }

  void _confirmarRestablecer(BuildContext context, AjustesProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('¿Restablecer configuración?'),
        content: const Text(
          'Todos los ajustes de la app volverán a sus valores iniciales recomendados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
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
                const SnackBar(
                  content: Text('Ajustes restablecidos a valores de fábrica'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );
  }
}
