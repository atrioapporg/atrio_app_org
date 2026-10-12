import 'package:flutter/material.dart';

import '../data/atrio_database_helper.dart';
import '../l10n/app_localizations.dart';

// Asegúrate de importar tu pantalla de lectura

class MisFavoritosScreen extends StatefulWidget {
  static const routeName = 'mis_favoritos_screen';

  const MisFavoritosScreen({super.key});

  @override
  State<MisFavoritosScreen> createState() => _MisFavoritosScreenState();
}

class _MisFavoritosScreenState extends State<MisFavoritosScreen> {
  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFE5E5E5);

  bool _isLoading = true;
  List<Map<String, dynamic>> _favoritos = [];

  @override
  void initState() {
    super.initState();
    _cargarFavoritos();
  }

  Future<void> _cargarFavoritos() async {
    setState(() => _isLoading = true);
    try {
      final favoritosData = await AtrioDatabaseHelper.instance
          .obtenerFavoritos();
      if (mounted) {
        setState(() {
          _favoritos = favoritosData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar favoritos: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _eliminarFavorito(
    String libro,
    int capitulo,
    int versiculo,
  ) async {
    await AtrioDatabaseHelper.instance.toggleFavorito(
      libro: libro,
      capitulo: capitulo,
      versiculo: versiculo,
    );
    await _cargarFavoritos();

    if (mounted) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.eliminadoDeFavoritos ?? 'Eliminado de favoritos',
          ),
          backgroundColor: azulFondo,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatearFecha(String isoDate) {
    try {
      final DateTime dt = DateTime.parse(isoDate);
      final String dia = dt.day.toString().padLeft(2, '0');
      final String mes = dt.month.toString().padLeft(2, '0');
      final String anio = dt.year.toString();
      return '$dia/$mes/$anio';
    } catch (e) {
      return '';
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

    return Scaffold(
      backgroundColor: azulFondo,
      body: SafeArea(
        bottom: false,
        child: SizedBox(
          width: screenWidth,
          height: usableHeight,
          child: Column(
            children: [
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
                    Text(
                      l10n?.favoritos ?? 'Favoritos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.065,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: usableHeight * 0.01),
              Expanded(
                child: Container(
                  width: screenWidth,
                  decoration: const BoxDecoration(
                    color: blancoFondo,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: amarilloOro,
                            ),
                          )
                        : _favoritos.isEmpty
                        ? _buildEmptyState(screenWidth, usableHeight, l10n)
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05,
                              vertical: usableHeight * 0.03,
                            ),
                            itemCount: _favoritos.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(height: usableHeight * 0.015),
                            itemBuilder: (context, index) {
                              final fav = _favoritos[index];
                              return _buildFavoritoCard(
                                fav: fav,
                                screenWidth: screenWidth,
                                usableHeight: usableHeight,
                                l10n: l10n,
                              );
                            },
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

  Widget _buildEmptyState(
    double screenWidth,
    double usableHeight,
    AppLocalizations? l10n,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            color: Colors.grey.shade300,
            size: screenWidth * 0.25,
          ),
          SizedBox(height: usableHeight * 0.02),
          Text(
            l10n?.sinFavoritos ?? 'Sin favoritos',
            style: TextStyle(
              color: azulFondo,
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: usableHeight * 0.01),
          Text(
            l10n?.sinFavoritosDesc ??
                'Toca el ícono de marcador en cualquier capítulo para guardarlo aquí y acceder rápidamente.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: screenWidth * 0.038,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritoCard({
    required Map<String, dynamic> fav,
    required double screenWidth,
    required double usableHeight,
    required AppLocalizations? l10n,
  }) {
    final String libro = fav['libro'] ?? '';
    final int capitulo = fav['capitulo'] ?? 1;
    final int versiculo = fav['versiculo'] ?? 1;
    final String resumen = fav['texto_resumen'] ?? '';
    final String fecha = _formatearFecha(fav['fecha_guardado'] ?? '');

    return InkWell(
      onTap: () async {
        // Redirige al capítulo directamente
        await Navigator.pushNamed(
          context,
          'lectura_capitulo_screen', // Usa LecturaCapituloScreenCopy.routeName si lo llamaste distinto
          arguments: {
            'nombre': libro,
            'capitulo': capitulo,
            'totalCapitulos': 150, // Pasa el total real si lo tienes a mano, o déjalo en genérico
            'subtitulo': l10n?.desdeFavoritos ?? 'Desde Favoritos',
          },
        );
        // Refresca al volver por si lo eliminó desde la lectura
        _cargarFavoritos();
      },
      borderRadius: BorderRadius.circular(screenWidth * 0.04),
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          border: Border.all(color: grisBorde),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.03),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6), // Fondo sutil amarillento
                borderRadius: BorderRadius.circular(screenWidth * 0.025),
              ),
              child: Icon(
                Icons.bookmark_rounded,
                color: amarilloOro,
                size: screenWidth * 0.06,
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resumen,
                    style: TextStyle(
                      color: azulFondo,
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: usableHeight * 0.005),
                  Text(
                    l10n?.guardadoEl(fecha) ?? 'Guardado el $fecha',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: screenWidth * 0.032,
                    ),
                  ),
                ],
              ),
            ),
            //
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Colors.red.shade300,
                size: screenWidth * 0.06,
              ),
              onPressed: () => _eliminarFavorito(libro, capitulo, versiculo),
            ),
          ],
        ),
      ),
    );
  }
}
