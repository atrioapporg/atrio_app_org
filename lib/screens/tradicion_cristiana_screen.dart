import 'package:atrio/data/atrio_database_helper.dart';
import 'package:atrio/providers/tradicion_cristiana_provider.dart';
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

  Future _continuarYGuardar(dynamic provider) async {
    final tradicion = provider.tradicionSeleccionada;
    if (tradicion == null || _isSaving) return;
    setState(() {
      _isSaving = true;
    });
    try {
      await AtrioDatabaseHelper.instance.guardarFeReligiosa(tradicion.titulo);
      debugPrint('[SQLITE] fe_religiosa guardada: ${tradicion.titulo}');
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        SeleccionarIglesiaScreen.routeName,
        arguments: {
          'tradicionId': tradicion.id,
          'tradicionTitulo': tradicion.titulo,
        },
      );
    } catch (e) {
      debugPrint('[SQLITE] Error al guardar tradición en atrio.db: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: const Text(
              'No se pudo guardar la selección localmente.',
              style: TextStyle(color: Colors.white),
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
                        'Queremos conocerte',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.056,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.02),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: screenWidth * 0.058,
                          ),
                        ),
                        Positioned(
                          top: screenWidth * 0.015,
                          right: screenWidth * 0.015,
                          child: Container(
                            width: screenWidth * 0.022,
                            height: screenWidth * 0.022,
                            decoration: const BoxDecoration(
                              color: amarilloOro,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
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
                                    'Continuar',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.048,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: usableHeight * 0.01),
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
              child: const Text(
                'Reintentar',
                style: TextStyle(color: Colors.white),
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
        return _buildTraditionCard(
          title: item.titulo,
          icon: _resolverIcono(item.iconoNombre),
          iconColor: Color(int.parse(item.colorHex)),
          isSelected: isSelected,
          screenWidth: screenWidth,
          usableHeight: usableHeight,
          onTap: () => provider.seleccionarTradicion(item),
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
