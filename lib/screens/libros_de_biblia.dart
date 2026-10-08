import 'package:atrio/screens/detalle_libro_biblia_screen.dart';
import 'package:flutter/material.dart';

class LibrosDeBibliaScreen extends StatefulWidget {
  static const routeName = 'libros_de_biblia';

  const LibrosDeBibliaScreen({super.key});

  @override
  State<LibrosDeBibliaScreen> createState() => _LibrosDeBibliaScreenState();
}

class _LibrosDeBibliaScreenState extends State<LibrosDeBibliaScreen> {
  bool _isAntiguoTestamento = false;
  String _filtroBusqueda = '';
  final TextEditingController _searchController = TextEditingController();
  bool _mostrandoBuscador = false;

  final List<Map<String, dynamic>> _antiguoTestamento = [
    {
      'id': 1,
      'nombre': 'Génesis',
      'capitulos': 50,
      'color': const Color(0xFF4CAF50),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 2,
      'nombre': 'Éxodo',
      'capitulos': 40,
      'color': const Color(0xFFFF9800),
      'icon': Icons.auto_stories_rounded,
    },
    {
      'id': 3,
      'nombre': 'Levítico',
      'capitulos': 27,
      'color': const Color(0xFF29B6F6),
      'icon': Icons.import_contacts_rounded,
    },
    {
      'id': 4,
      'nombre': 'Números',
      'capitulos': 36,
      'color': const Color(0xFF5C6BC0),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 5,
      'nombre': 'Deuteronomio',
      'capitulos': 34,
      'color': const Color(0xFFAB47BC),
      'icon': Icons.book_rounded,
    },
    {
      'id': 6,
      'nombre': 'Josué',
      'capitulos': 24,
      'color': const Color(0xFF26A69A),
      'icon': Icons.auto_stories_rounded,
    },
    {
      'id': 7,
      'nombre': 'Jueces',
      'capitulos': 21,
      'color': const Color(0xFFFFB74D),
      'icon': Icons.import_contacts_rounded,
    },
    {
      'id': 8,
      'nombre': 'Rut',
      'capitulos': 4,
      'color': const Color(0xFF7E57C2),
      'icon': Icons.book_rounded,
    },
    {
      'id': 9,
      'nombre': '1 Samuel',
      'capitulos': 31,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 10,
      'nombre': '2 Samuel',
      'capitulos': 24,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 11,
      'nombre': '1 Reyes',
      'capitulos': 22,
      'color': const Color(0xFFFFA726),
      'icon': Icons.auto_stories_rounded,
    },
    {
      'id': 12,
      'nombre': '2 Reyes',
      'capitulos': 25,
      'color': const Color(0xFFFFA726),
      'icon': Icons.auto_stories_rounded,
    },
    {
      'id': 13,
      'nombre': '1 Crónicas',
      'capitulos': 29,
      'color': const Color(0xFF42A5F5),
      'icon': Icons.import_contacts_rounded,
    },
    {
      'id': 14,
      'nombre': '2 Crónicas',
      'capitulos': 36,
      'color': const Color(0xFF42A5F5),
      'icon': Icons.import_contacts_rounded,
    },
    {
      'id': 15,
      'nombre': 'Esdras',
      'capitulos': 10,
      'color': const Color(0xFF8D6E63),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 16,
      'nombre': 'Nehemías',
      'capitulos': 13,
      'color': const Color(0xFF8D6E63),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 17,
      'nombre': 'Ester',
      'capitulos': 10,
      'color': const Color(0xFFEC407A),
      'icon': Icons.book_rounded,
    },
    {
      'id': 18,
      'nombre': 'Job',
      'capitulos': 42,
      'color': const Color(0xFF78909C),
      'icon': Icons.auto_stories_rounded,
    },
    {
      'id': 19,
      'nombre': 'Salmos',
      'capitulos': 150,
      'color': const Color(0xFF26C6DA),
      'icon': Icons.music_note_rounded,
    },
    {
      'id': 20,
      'nombre': 'Proverbios',
      'capitulos': 31,
      'color': const Color(0xFFFFA726),
      'icon': Icons.lightbulb_rounded,
    },
    {
      'id': 21,
      'nombre': 'Eclesiastés',
      'capitulos': 12,
      'color': const Color(0xFF78909C),
      'icon': Icons.import_contacts_rounded,
    },
    {
      'id': 22,
      'nombre': 'Cantares',
      'capitulos': 8,
      'color': const Color(0xFFF06292),
      'icon': Icons.favorite_rounded,
    },
    {
      'id': 23,
      'nombre': 'Isaías',
      'capitulos': 66,
      'color': const Color(0xFFAB47BC),
      'icon': Icons.auto_stories_rounded,
    },
    {
      'id': 24,
      'nombre': 'Jeremías',
      'capitulos': 52,
      'color': const Color(0xFF5C6BC0),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 25,
      'nombre': 'Lamentaciones',
      'capitulos': 5,
      'color': const Color(0xFF5C6BC0),
      'icon': Icons.import_contacts_rounded,
    },
    {
      'id': 26,
      'nombre': 'Ezequiel',
      'capitulos': 48,
      'color': const Color(0xFF26A69A),
      'icon': Icons.auto_stories_rounded,
    },
    {
      'id': 27,
      'nombre': 'Daniel',
      'capitulos': 12,
      'color': const Color(0xFFFFA726),
      'icon': Icons.lightbulb_rounded,
    },
    {
      'id': 28,
      'nombre': 'Oseas',
      'capitulos': 14,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 29,
      'nombre': 'Joel',
      'capitulos': 3,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 30,
      'nombre': 'Amós',
      'capitulos': 9,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 31,
      'nombre': 'Abdías',
      'capitulos': 1,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 32,
      'nombre': 'Jonás',
      'capitulos': 4,
      'color': const Color(0xFF29B6F6),
      'icon': Icons.auto_stories_rounded,
    },
    {
      'id': 33,
      'nombre': 'Miqueas',
      'capitulos': 7,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 34,
      'nombre': 'Nahúm',
      'capitulos': 3,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 35,
      'nombre': 'Habacuc',
      'capitulos': 3,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 36,
      'nombre': 'Sofonías',
      'capitulos': 3,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 37,
      'nombre': 'Hageo',
      'capitulos': 2,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 38,
      'nombre': 'Zacarías',
      'capitulos': 14,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 39,
      'nombre': 'Malaquías',
      'capitulos': 4,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.menu_book_rounded,
    },
  ];

  final List<Map<String, dynamic>> _nuevoTestamento = [
    {
      'id': 40,
      'nombre': 'Mateo',
      'capitulos': 28,
      'color': const Color(0xFF4CAF50),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 41,
      'nombre': 'Marcos',
      'capitulos': 16,
      'color': const Color(0xFFFF9800),
      'icon': Icons.auto_stories_rounded,
    },
    {
      'id': 42,
      'nombre': 'Lucas',
      'capitulos': 24,
      'color': const Color(0xFF29B6F6),
      'icon': Icons.import_contacts_rounded,
    },
    {
      'id': 43,
      'nombre': 'Juan',
      'capitulos': 21,
      'color': const Color(0xFFAB47BC),
      'icon': Icons.book_rounded,
    },
    {
      'id': 44,
      'nombre': 'Hechos',
      'capitulos': 28,
      'color': const Color(0xFFE53935),
      'icon': Icons.explore_rounded,
    },
    {
      'id': 45,
      'nombre': 'Romanos',
      'capitulos': 16,
      'color': const Color(0xFF5C6BC0),
      'icon': Icons.menu_book_rounded,
    },
    {
      'id': 46,
      'nombre': '1 Corintios',
      'capitulos': 16,
      'color': const Color(0xFF26A69A),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 47,
      'nombre': '2 Corintios',
      'capitulos': 13,
      'color': const Color(0xFF26A69A),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 48,
      'nombre': 'Gálatas',
      'capitulos': 6,
      'color': const Color(0xFFFFA726),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 49,
      'nombre': 'Efesios',
      'capitulos': 6,
      'color': const Color(0xFF7E57C2),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 50,
      'nombre': 'Filipenses',
      'capitulos': 4,
      'color': const Color(0xFFEC407A),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 51,
      'nombre': 'Colosenses',
      'capitulos': 4,
      'color': const Color(0xFF42A5F5),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 52,
      'nombre': '1 Tesalonicenses',
      'capitulos': 5,
      'color': const Color(0xFF8D6E63),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 53,
      'nombre': '2 Tesalonicenses',
      'capitulos': 3,
      'color': const Color(0xFF8D6E63),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 54,
      'nombre': '1 Timoteo',
      'capitulos': 6,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 55,
      'nombre': '2 Timoteo',
      'capitulos': 4,
      'color': const Color(0xFF66BB6A),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 56,
      'nombre': 'Tito',
      'capitulos': 3,
      'color': const Color(0xFF26C6DA),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 57,
      'nombre': 'Filemón',
      'capitulos': 1,
      'color': const Color(0xFF78909C),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 58,
      'nombre': 'Hebreos',
      'capitulos': 13,
      'color': const Color(0xFF5C6BC0),
      'icon': Icons.auto_stories_rounded,
    },
    {
      'id': 59,
      'nombre': 'Santiago',
      'capitulos': 5,
      'color': const Color(0xFFFFA726),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 60,
      'nombre': '1 Pedro',
      'capitulos': 5,
      'color': const Color(0xFF4CAF50),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 61,
      'nombre': '2 Pedro',
      'capitulos': 3,
      'color': const Color(0xFF4CAF50),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 62,
      'nombre': '1 Juan',
      'capitulos': 5,
      'color': const Color(0xFFAB47BC),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 63,
      'nombre': '2 Juan',
      'capitulos': 1,
      'color': const Color(0xFFAB47BC),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 64,
      'nombre': '3 Juan',
      'capitulos': 1,
      'color': const Color(0xFFAB47BC),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 65,
      'nombre': 'Judas',
      'capitulos': 1,
      'color': const Color(0xFFE53935),
      'icon': Icons.mark_email_read_rounded,
    },
    {
      'id': 66,
      'nombre': 'Apocalipsis',
      'capitulos': 22,
      'color': const Color(0xFFD32F2F),
      'icon': Icons.wb_sunny_rounded,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width; //
    final screenHeight = MediaQuery.sizeOf(context).height; //
    final safeAreaTop = MediaQuery.of(context).padding.top; //
    final safeAreaBottom = MediaQuery.of(context).padding.bottom; //
    final usableHeight = screenHeight - safeAreaTop - safeAreaBottom; //

    const Color azulFondo = Color(0xFF072B4F); //
    const Color amarilloOro = Color(0xFFE5A023); //
    const Color blancoFondo = Color(0xFFFAF7F0); //
    const Color grisBorde = Color(0xFFE5E5E5); //

    final listaBase = _isAntiguoTestamento
        ? _antiguoTestamento
        : _nuevoTestamento;
    final librosFiltrados = listaBase.where((libro) {
      final nombre = (libro['nombre'] as String).toLowerCase();
      return nombre.contains(_filtroBusqueda.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: azulFondo, //
      body: SafeArea(
        bottom: true, //
        child: SizedBox(
          width: screenWidth, //
          height: usableHeight, //
          child: Column(
            children: [
              // Encabezado Superior (App Bar + Buscador colapsable)
              Container(
                width: screenWidth, //
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: usableHeight * 0.015,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        Text(
                          'Libros de la Biblia',
                          style: TextStyle(
                            color: Colors.white, //
                            fontSize: screenWidth * 0.055,
                            fontWeight: FontWeight.bold, //
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _mostrandoBuscador = !_mostrandoBuscador;
                              if (!_mostrandoBuscador) {
                                _searchController.clear();
                                _filtroBusqueda = '';
                              }
                            });
                          },
                          icon: Icon(
                            _mostrandoBuscador
                                ? Icons.close
                                : Icons.search_rounded,
                            color: Colors.white, //
                            size: screenWidth * 0.07, //
                          ),
                        ),
                      ],
                    ),
                    if (_mostrandoBuscador) ...[
                      SizedBox(height: usableHeight * 0.012),
                      Container(
                        height: usableHeight * 0.05,
                        decoration: BoxDecoration(
                          color: Colors.white, //
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.03,
                          ), //
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: (val) {
                            setState(() {
                              _filtroBusqueda = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Filtrar por nombre de libro...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade500, //
                              fontSize: screenWidth * 0.035, //
                            ),
                            prefixIcon: Icon(
                              Icons.search, //
                              color: Colors.grey.shade600, //
                              size: screenWidth * 0.05, //
                            ),
                            border: InputBorder.none, //
                            contentPadding: EdgeInsets.symmetric(
                              vertical: usableHeight * 0.012, //
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Contenedor Blanco Inferior
              Expanded(
                child: Container(
                  width: screenWidth, //
                  decoration: BoxDecoration(
                    color: blancoFondo, //
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.08), //
                      topRight: Radius.circular(screenWidth * 0.08), //
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.08), //
                      topRight: Radius.circular(screenWidth * 0.08), //
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: usableHeight * 0.02),

                        // Switch de Pestañas: Antiguo / Nuevo Testamento
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                          ),
                          child: Container(
                            height: usableHeight * 0.055,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8ECEF),
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.03,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isAntiguoTestamento = true;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _isAntiguoTestamento
                                            ? azulFondo
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(
                                          screenWidth * 0.025,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Antiguo Testamento',
                                          style: TextStyle(
                                            color: _isAntiguoTestamento
                                                ? Colors.white
                                                : Colors.grey.shade700,
                                            fontWeight: FontWeight.bold, //
                                            fontSize: screenWidth * 0.034,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isAntiguoTestamento = false;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: !_isAntiguoTestamento
                                            ? azulFondo
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(
                                          screenWidth * 0.025,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Nuevo Testamento',
                                          style: TextStyle(
                                            color: !_isAntiguoTestamento
                                                ? Colors.white
                                                : Colors.grey.shade700,
                                            fontWeight: FontWeight.bold, //
                                            fontSize: screenWidth * 0.034,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(height: usableHeight * 0.015),

                        // Lista de Libros
                        Expanded(
                          child: librosFiltrados.isEmpty
                              ? Center(
                                  child: Text(
                                    'No se encontraron libros',
                                    style: TextStyle(
                                      color: Colors.grey.shade600, //
                                      fontSize: screenWidth * 0.038,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  physics: const BouncingScrollPhysics(), //
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.05,
                                    vertical: usableHeight * 0.01,
                                  ),
                                  itemCount: librosFiltrados.length,
                                  separatorBuilder: (context, index) =>
                                      SizedBox(height: usableHeight * 0.012),
                                  itemBuilder: (context, index) {
                                    final libro = librosFiltrados[index];
                                    return _buildBookTile(
                                      id: libro['id'] as int,
                                      nombre: libro['nombre'] as String,
                                      capitulos: libro['capitulos'] as int,
                                      colorIcono: libro['color'] as Color,
                                      icono: libro['icon'] as IconData,
                                      screenWidth: screenWidth,
                                      usableHeight: usableHeight,
                                      azulFondo: azulFondo,
                                      amarilloOro: amarilloOro,
                                      grisBorde: grisBorde,
                                    );
                                  },
                                ),
                        ),
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
  //
  //

  Widget _buildBookTile({
    required int id,
    required String nombre,
    required int capitulos,
    required Color colorIcono,
    required IconData icono,
    required double screenWidth,
    required double usableHeight,
    required Color azulFondo,
    required Color amarilloOro,
    required Color grisBorde,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, //
        borderRadius: BorderRadius.circular(screenWidth * 0.035), //
        border: Border.all(color: grisBorde), //
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(screenWidth * 0.035), //
          onTap: () {
            // Navegación hacia la lectura del libro
            Navigator.pushNamed(
              context,
              DetalleLibroBibliaScreen.routeName,
              arguments: {
                'id': id,
                'nombre': nombre,
                'capitulos': capitulos,
                'color': colorIcono,
                'icon': icono,
              },
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: usableHeight * 0.014,
            ),
            child: Row(
              children: [
                // Ícono del Libro con fondo suave
                Container(
                  width: screenWidth * 0.12,
                  height: screenWidth * 0.12,
                  decoration: BoxDecoration(
                    color: colorIcono.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                  ),
                  child: Icon(
                    icono,
                    color: colorIcono,
                    size: screenWidth * 0.065,
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),

                // Textos: Nombre y Capítulos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: TextStyle(
                          color: azulFondo, //
                          fontSize: screenWidth * 0.042,
                          fontWeight: FontWeight.bold, //
                        ),
                      ),
                      SizedBox(height: usableHeight * 0.003),
                      Text(
                        '$capitulos capítulos',
                        style: TextStyle(
                          color: Colors.grey.shade600, //
                          fontSize: screenWidth * 0.032, //
                          fontWeight: FontWeight.w500, //
                        ),
                      ),
                    ],
                  ),
                ),

                // Chevron derecho
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: screenWidth * 0.06,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
