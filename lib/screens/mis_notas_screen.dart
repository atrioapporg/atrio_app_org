import 'package:flutter/material.dart';

import '../data/atrio_database_helper.dart';
import '../l10n/app_localizations.dart';

class MisNotasScreen extends StatefulWidget {
  static const routeName = 'mis_notas_screen';

  const MisNotasScreen({super.key});

  @override
  State<MisNotasScreen> createState() => _MisNotasScreenState();
}

class _MisNotasScreenState extends State<MisNotasScreen> {
  static const Color azulFondo = Color(0xFF072B4F);
  static const Color amarilloOro = Color(0xFFE5A023);
  static const Color blancoFondo = Color(0xFFFAF7F0);
  static const Color grisBorde = Color(0xFFE5E5E5);

  bool _isLoading = true;
  List<Map<String, dynamic>> _notas = [];

  @override
  void initState() {
    super.initState();
    _cargarNotas();
  }

  Future<void> _cargarNotas() async {
    setState(() => _isLoading = true);
    try {
      final notasData = await AtrioDatabaseHelper.instance.obtenerNotas();
      if (mounted) {
        setState(() {
          _notas = notasData;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar notas: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _eliminarNota(int id) async {
    final l10n = AppLocalizations.of(context);
    // Diálogo de confirmación antes de eliminar
    final bool confirmar =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: blancoFondo,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              l10n?.eliminarNotaTitulo ?? 'Eliminar nota',
              style: const TextStyle(color: azulFondo, fontWeight: FontWeight.bold),
            ),
            content: Text(
              l10n?.seguroEliminarNota ??
                  '¿Estás seguro de que deseas eliminar esta nota de forma permanente?',
              style: const TextStyle(color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  l10n?.cancelar ?? 'Cancelar',
                  style: const TextStyle(color: azulFondo),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC0392B),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(l10n?.eliminar ?? 'Eliminar'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmar) {
      await AtrioDatabaseHelper.instance.eliminarNota(id);
      await _cargarNotas(); // Refrescar la lista

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.notaEliminadaCorrectamente ??
                  'Nota eliminada correctamente',
            ),
            backgroundColor: azulFondo,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _mostrarNotaCompleta(
    Map<String, dynamic> nota,
    double screenWidth,
    double usableHeight,
  ) {
    final String titulo = nota['titulo'] ?? '';
    final String contenido = nota['contenido'] ?? '';
    final String fecha = _formatearFecha(nota['fecha_creacion'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: blancoFondo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.06),
        ),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5, // Ocupa la mitad de la pantalla al inicio
          minChildSize: 0.4,
          maxChildSize: 0.9, // Puede expandirse casi hasta arriba
          expand: false,
          builder: (_, controller) {
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical: usableHeight * 0.02,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pequeña barra superior para indicar que se puede deslizar
                  Center(
                    child: Container(
                      width: screenWidth * 0.12,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          titulo,
                          style: TextStyle(
                            color: azulFondo,
                            fontSize: screenWidth * 0.055,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close_rounded, color: azulFondo),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  SizedBox(height: usableHeight * 0.005),
                  Text(
                    fecha,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: screenWidth * 0.035,
                    ),
                  ),
                  SizedBox(height: usableHeight * 0.02),
                  const Divider(color: grisBorde, height: 1),
                  SizedBox(height: usableHeight * 0.02),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        contenido,
                        style: TextStyle(
                          color: const Color(0xFF222222),
                          fontSize: screenWidth * 0.042,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
              // HEADER
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
                      l10n?.misNotas ?? 'Mis Notas',
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

              // CUERPO PRINCIPAL BLANCO
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
                        : _notas.isEmpty
                        ? _buildEmptyState(screenWidth, usableHeight, l10n)
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05,
                              vertical: usableHeight * 0.03,
                            ),
                            itemCount: _notas.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(height: usableHeight * 0.015),
                            itemBuilder: (context, index) {
                              final nota = _notas[index];
                              return _buildNotaCard(
                                nota: nota,
                                screenWidth: screenWidth,
                                usableHeight: usableHeight,
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
            Icons.edit_note_rounded,
            color: Colors.grey.shade300,
            size: screenWidth * 0.25,
          ),
          SizedBox(height: usableHeight * 0.02),
          Text(
            l10n?.aunNoTienesNotas ?? 'Aún no tienes notas',
            style: TextStyle(
              color: azulFondo,
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: usableHeight * 0.01),
          Text(
            l10n?.aunNoTienesNotasDesc ??
                'Tus reflexiones y apuntes bíblicos aparecerán aquí. Abre cualquier capítulo y toca el ícono de Nota para empezar.',
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

  Widget _buildNotaCard({
    required Map<String, dynamic> nota,
    required double screenWidth,
    required double usableHeight,
  }) {
    final int id = nota['id'];
    final String titulo = nota['titulo'] ?? '';
    final String contenido = nota['contenido'] ?? '';
    final String fecha = _formatearFecha(nota['fecha_creacion'] ?? '');

    return InkWell(
      onTap: () => _mostrarNotaCompleta(nota, screenWidth, usableHeight),
      borderRadius: BorderRadius.circular(screenWidth * 0.04),
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          border: Border.all(color: grisBorde),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          color: azulFondo,
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: usableHeight * 0.003),
                      Text(
                        fecha,
                        style: TextStyle(
                          color: amarilloOro,
                          fontSize: screenWidth * 0.032,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red.shade300,
                    size: screenWidth * 0.06,
                  ),
                  onPressed: () => _eliminarNota(id),
                ),
              ],
            ),
            SizedBox(height: usableHeight * 0.012),
            Text(
              contenido,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.black87,
                fontSize: screenWidth * 0.038,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
