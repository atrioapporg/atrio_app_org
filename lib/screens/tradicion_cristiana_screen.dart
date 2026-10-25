import 'package:atrio/data/atrio_database_helper.dart';
import 'package:atrio/l10n/app_localizations.dart';
import 'package:atrio/modelos/tradicion_cristiana_model.dart';
import 'package:atrio/providers/explorar_provider.dart';
import 'package:atrio/providers/tradicion_cristiana_provider.dart';
import 'package:atrio/screens/inicio_atrio_screen.dart';
import 'package:atrio/screens/seleccionar_iglesia_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TradicionCristianaScreen extends StatefulWidget {
  static const routeName = 'tradicion_cristiana_screen';
  const TradicionCristianaScreen({super.key});

  @override
  State createState() => _TradicionCristianaScreenState();
}

class _TradicionCristianaScreenState extends State {
  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFE5E5E5);
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TradicionCristianaProvider>(
        context,
        listen: false,
      );

      if (provider.tradiciones.isEmpty && !provider.isLoading) {
        provider.cargarTradiciones();
      }
    });
  }

  IconData _resolverIcono(String iconoNombre) {
    switch (iconoNombre) {
      case 'spa':
        return Icons.spa_outlined;
      case 'church':
        return Icons.church_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'more':
        return Icons.more_horiz_rounded;
      case 'time':
        return Icons.access_time_rounded;
      case 'add':
      default:
        return Icons.add;
    }
  }

  String _resolverTituloTradicion(
    AppLocalizations? l10n,
    TradicionCristianaModel item,
  ) {
    switch (item.id) {
      case 'trad_catolica':
        return l10n?.catolica ?? item.titulo;
      case 'trad_evangelica':
        return l10n?.evangelica ?? item.titulo;
      case 'trad_pentecostal':
        return l10n?.pentecostal ?? item.titulo;
      case 'trad_bautista':
        return l10n?.bautista ?? item.titulo;
      case 'trad_adventista':
        return l10n?.adventista ?? item.titulo;
      case 'trad_no_denominacional':
        return l10n?.noDenominacional ?? item.titulo;
      case 'trad_otra':
        return l10n?.otra ?? item.titulo;
      case 'trad_despues':
        return l10n?.prefieroIndicarloDespues ?? item.titulo;
      default:
        return item.titulo;
    }
  }

  /// Omite la selección de tradición e iglesia y navega directamente a la pantalla de inicio
  Future<void> _omitirEIrAInicio() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });
    try {
      final l10n = mounted ? AppLocalizations.of(context) : null;
      final String titulo =
          l10n?.prefieroIndicarloDespues ?? 'Prefiero indicarlo después';
      await AtrioDatabaseHelper.instance.guardarFeReligiosa(titulo);
      debugPrint('[SQLITE] Fe religiosa guardada como: $titulo');

      // Si el usuario no tiene iglesia registrada aún, dejamos el indicador claro
      final usuario = await AtrioDatabaseHelper.instance.getUsuario();
      if (usuario == null ||
          usuario['iglesia_nombre'] == null ||
          usuario['iglesia_nombre'].toString().trim().isEmpty) {
        await AtrioDatabaseHelper.instance.guardarIglesiaNombre(
          'Sin iglesia seleccionada',
        );
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        InicioAtrioScreen.routeName,
        (route) => false,
      );
    } catch (e) {
      debugPrint('[TRADICION] Error al omitir e ir a inicio: $e');
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          InicioAtrioScreen.routeName,
          (route) => false,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future _continuarYGuardar(dynamic provider) async {
    final tradicion = provider.tradicionSeleccionada;
    if (tradicion == null || _isSaving) return;

    // Si el usuario seleccionó "Prefiero indicarlo después", ir directamente al inicio
    if (tradicion.id == 'trad_despues' ||
        tradicion.id == 'prefiero_indicarlo_despues' ||
        tradicion.titulo.toLowerCase().contains('después') ||
        tradicion.titulo.toLowerCase().contains('despues')) {
      await _omitirEIrAInicio();
      return;
    }

    setState(() {
      _isSaving = true;
    });
    try {
      final l10n = mounted ? AppLocalizations.of(context) : null;
      final tituloResuelto = _resolverTituloTradicion(l10n, tradicion);
      await AtrioDatabaseHelper.instance.guardarFeReligiosa(tituloResuelto);
      debugPrint('[SQLITE] fe_religiosa guardada: $tituloResuelto');

      // Sincronizar inmediatamente el filtro de denominación en ExplorarProvider
      if (mounted) {
        try {
          final explorarProvider = context.read<ExplorarProvider>();
          final int filtroIdx = provider is TradicionCristianaProvider
              ? provider.denominacionFiltroIndex
              : 0;
          if (filtroIdx > 0) {
            explorarProvider.cambiarDenominacion(filtroIdx, recargar: false);
          }
        } catch (e) {
          debugPrint('[ExplorarProvider] Error sincronizando denominación: $e');
        }
      }

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        SeleccionarIglesiaScreen.routeName,
        arguments: {
          'tradicionId': tradicion.id,
          'tradicionTitulo': tituloResuelto,
        },
      );
    } catch (e) {
      debugPrint('[SQLITE] Error al guardar tradición en atrio.db: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(
              l10n?.errorGuardarSeleccionLocal ??
                  'No se pudo guardar la selección localmente.',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom;
    final provider = Provider.of<TradicionCristianaProvider>(context);

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: true,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight,
          child: Column(
            children: [
              // Encabezado Superior (Botón Volver + Título + Notificaciones)
              Container(
                width: screenWidth,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: usableHeight * 0.015,
                ),
                child: Row(
                  children: [
                    GestureDetector(
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
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Text(
                        l10n?.queremosConocerte ?? 'Queremos conocerte',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.056,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _isSaving ? null : _omitirEIrAInicio,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.035,
                          vertical: usableHeight * 0.008,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.04,
                          ),
                          border: Border.all(
                            color: amarilloOro.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          l10n?.omitir ?? 'Omitir',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contenedor Blanco Inferior
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
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.06,
                      vertical: usableHeight * 0.025,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            l10n?.conCualTradicionTeIdentificas ??
                                '¿Con cuál tradición de fe te identificas?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: azulFondo,
                              fontSize: screenWidth * 0.042,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: usableHeight * 0.02),
                        Expanded(
                          child: _buildListaTradiciones(
                            provider,
                            screenWidth,
                            usableHeight,
                            l10n,
                          ),
                        ),
                        SizedBox(height: usableHeight * 0.015),
                        SizedBox(
                          width: screenWidth,
                          height: usableHeight * 0.058,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: amarilloOro,
                              foregroundColor: azulFondo,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  screenWidth * 0.03,
                                ),
                              ),
                            ),
                            onPressed:
                                (provider.tradicionSeleccionada == null ||
                                    _isSaving)
                                ? null
                                : () => _continuarYGuardar(provider),
                            child: _isSaving
                                ? SizedBox(
                                    width: screenWidth * 0.055,
                                    height: screenWidth * 0.055,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: azulFondo,
                                    ),
                                  )
                                : Text(
                                    l10n?.continuar ?? 'Continuar',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.048,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: usableHeight * 0.008),
                        Center(
                          child: TextButton(
                            onPressed: _isSaving ? null : _omitirEIrAInicio,
                            style: TextButton.styleFrom(
                              foregroundColor: azulFondo,
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.03,
                                vertical: usableHeight * 0.005,
                              ),
                            ),
                            child: Text(
                              l10n?.prefieroIndicarloDespues ??
                                  'Prefiero indicarlo después',
                              style: TextStyle(
                                fontSize: screenWidth * 0.038,
                                fontWeight: FontWeight.w600,
                                color: azulFondo.withValues(alpha: 0.85),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: usableHeight * 0.005),
                      ],
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

  Widget _buildListaTradiciones(
    TradicionCristianaProvider provider,
    double screenWidth,
    double usableHeight,
    AppLocalizations? l10n,
  ) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: amarilloOro));
    }
    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: azulFondo, fontSize: screenWidth * 0.035),
            ),
            SizedBox(height: usableHeight * 0.015),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: azulFondo),
              onPressed: () => provider.cargarTradiciones(),
              child: Text(
                l10n?.reintentar ?? 'Reintentar',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: provider.tradiciones.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: usableHeight * 0.018),
      itemBuilder: (context, index) {
        final item = provider.tradiciones[index];
        final isSelected = provider.tradicionSeleccionada?.id == item.id;
        final bool esIndicarDespues =
            item.id == 'trad_despues' ||
            item.id == 'prefiero_indicarlo_despues';
        return _buildTraditionCard(
          title: _resolverTituloTradicion(l10n, item),
          icon: _resolverIcono(item.iconoNombre),
          iconColor: Color(int.parse(item.colorHex)),
          isSelected: isSelected,
          screenWidth: screenWidth,
          usableHeight: usableHeight,
          onTap: () async {
            provider.seleccionarTradicion(item);
            if (esIndicarDespues) {
              await _omitirEIrAInicio();
            }
          },
        );
      },
    );
  }

  Widget _buildTraditionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required double screenWidth,
    required double usableHeight,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: usableHeight * 0.075,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.035),
          border: Border.all(
            color: isSelected ? amarilloOro : grisBorde,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: amarilloOro.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: Row(
          children: [
            Container(
              width: screenWidth * 0.10,
              height: screenWidth * 0.10,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
              ),
              child: Icon(icon, color: iconColor, size: screenWidth * 0.058),
            ),
            SizedBox(width: screenWidth * 0.035),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: azulFondo,
                  fontSize: screenWidth * 0.042,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              color: isSelected ? amarilloOro : Colors.grey.shade400,
              size: screenWidth * 0.055,
            ),
          ],
        ),
      ),
    );
  }
}
