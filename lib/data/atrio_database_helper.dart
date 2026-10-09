import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AtrioDatabaseHelper {
  static const _databaseName = "atrio.db";
  // Subimos a versión 2 para migrar las nuevas tablas de notas y favoritos
  static const _databaseVersion = 2;

  // Nombres de las tablas
  static const tableUsuario = 'usuario';
  static const tableConfig = 'config_atrio';
  static const tableNotas = 'notas_biblia';
  static const tableFavoritos = 'favoritos_biblia';

  // Singleton
  AtrioDatabaseHelper._init();
  static final AtrioDatabaseHelper instance = AtrioDatabaseHelper._init();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_databaseName);
    return _database!;
  }

  // Inicializar la base de datos nativa
  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    debugPrint('[ATRIO_DB] Abriendo/Creando base de datos en: $path');
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgradeDB,
    );
  }

  // ============================================================
  // CREACIÓN DE TABLAS (Instalación limpia desde cero)
  // ============================================================
  Future _createDB(Database db, int version) async {
    debugPrint('[ATRIO_DB] Creando tablas nuevas en versión $version...');

    // 1. Tabla: usuario
    await db.execute('''
      CREATE TABLE $tableUsuario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        apellido TEXT,
        celular TEXT,
        email TEXT UNIQUE,
        fe_religiosa TEXT,
        iglesia_nombre TEXT,
        idioma TEXT DEFAULT 'es_DO',
        creado_en TEXT
      )
    ''');

    // 2. Tabla: config_atrio
    await db.execute('''
      CREATE TABLE $tableConfig (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tema_oscuro INTEGER DEFAULT 0,
        version_app TEXT,
        url_app TEXT,
        url_privacidad TEXT,
        actualizado_en TEXT
      )
    ''');

    // 3. Tabla: notas_biblia
    await db.execute('''
      CREATE TABLE $tableNotas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        libro TEXT NOT NULL,
        capitulo INTEGER NOT NULL,
        versiculo INTEGER DEFAULT 1,
        titulo TEXT,
        contenido TEXT NOT NULL,
        fecha_creacion TEXT NOT NULL
      )
    ''');

    // 4. Tabla: favoritos_biblia (con restricción única por capítulo/pasaje)
    await db.execute('''
      CREATE TABLE $tableFavoritos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        libro TEXT NOT NULL,
        capitulo INTEGER NOT NULL,
        versiculo INTEGER DEFAULT 1,
        texto_resumen TEXT,
        fecha_guardado TEXT NOT NULL,
        UNIQUE(libro, capitulo, versiculo)
      )
    ''');

    // 5 Tabla en SQLite para guardar emisoras favoritas
    await db.execute('''
      CREATE TABLE favoritos_emisoras (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        dial TEXT NOT NULL,
        stream_url TEXT NOT NULL,
        logo_url TEXT,
        guardado_en TEXT NOT NULL
      )
    ''');

    // Configuración inicial por defecto
    await db.insert(tableConfig, {
      'tema_oscuro': 0,
      'version_app': '1.0.0',
      'url_app': 'https://atrioapp.com',
      'url_privacidad': 'https://atrioapp.com/privacidad',
      'actualizado_en': DateTime.now().toIso8601String(),
    });

    debugPrint('[ATRIO_DB] Todas las tablas creadas con éxito.');
  }

  // ============================================================
  // MIGRACIÓN (Si el usuario ya tenía la versión 1 instalada)
  // ============================================================
  Future _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    debugPrint(
      '[ATRIO_DB] Migrando base de datos de v$oldVersion a v$newVersion...',
    );

    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableNotas (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          libro TEXT NOT NULL,
          capitulo INTEGER NOT NULL,
          versiculo INTEGER DEFAULT 1,
          titulo TEXT,
          contenido TEXT NOT NULL,
          fecha_creacion TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableFavoritos (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          libro TEXT NOT NULL,
          capitulo INTEGER NOT NULL,
          versiculo INTEGER DEFAULT 1,
          texto_resumen TEXT,
          fecha_guardado TEXT NOT NULL,
          UNIQUE(libro, capitulo, versiculo)
        )
      ''');
      debugPrint(
        '[ATRIO_DB] Migración a v2 completada (tablas notas y favoritos creadas).',
      );
    }
  }

  // ============================================================
  // MÉTODOS CRUD: USUARIO
  // ============================================================
  Future<int> guardarUsuario(Map<String, dynamic> usuarioMap) async {
    final db = await instance.database;
    usuarioMap['creado_en'] = DateTime.now().toIso8601String();
    return await db.insert(
      tableUsuario,
      usuarioMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUsuario() async {
    final db = await instance.database;
    final result = await db.query(tableUsuario, limit: 1);
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<int> guardarFeReligiosa(String feReligiosa) async {
    final db = await instance.database;
    final usuario = await getUsuario();
    if (usuario != null) {
      return await db.update(
        tableUsuario,
        {'fe_religiosa': feReligiosa},
        where: 'id = ?',
        whereArgs: [usuario['id']],
      );
    } else {
      return await db.insert(tableUsuario, {
        'nombre': 'Usuario',
        'fe_religiosa': feReligiosa,
        'creado_en': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Guarda o actualiza el nombre de la iglesia del usuario en la tabla 'usuario'
  Future<int> guardarIglesiaNombre(String iglesiaNombre) async {
    final db = await instance.database;
    final usuario = await getUsuario();
    if (usuario != null) {
      return await db.update(
        tableUsuario,
        {'iglesia_nombre': iglesiaNombre},
        where: 'id = ?',
        whereArgs: [usuario['id']],
      );
    } else {
      return await db.insert(tableUsuario, {
        'nombre': 'Usuario',
        'iglesia_nombre': iglesiaNombre,
        'creado_en': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Elimina los registros del usuario y sus datos personales asociados de SQLite
  /// (Cumplimiento de directrices de eliminación de cuenta de Apple y Google).
  Future<void> eliminarUsuarioYDatos() async {
    final db = await instance.database;
    debugPrint('[ATRIO_DB] Eliminando todos los datos del usuario localmente...');
    await db.delete(tableUsuario);
    await db.delete(tableNotas);
    await db.delete(tableFavoritos);
    debugPrint('[ATRIO_DB] Datos personales y tablas de usuario purgadas.');
  }

  // ============================================================
  // MÉTODOS CRUD: CONFIG_ATRIO
  // ============================================================
  Future<int> actualizarConfiguracion(Map<String, dynamic> configMap) async {
    final db = await instance.database;
    configMap['actualizado_en'] = DateTime.now().toIso8601String();
    return await db.update(
      tableConfig,
      configMap,
      where: 'id = ?',
      whereArgs: [1],
    );
  }

  Future<Map<String, dynamic>?> getConfiguracion() async {
    final db = await instance.database;
    final result = await db.query(tableConfig, limit: 1);
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  // ============================================================
  // MÉTODOS CRUD: NOTAS DE LA BIBLIA
  // ============================================================
  /// Inserta una nueva nota personal
  Future<int> insertarNota({
    required String libro,
    required int capitulo,
    int versiculo = 1,
    String? titulo,
    required String contenido,
  }) async {
    final db = await instance.database;
    return await db.insert(tableNotas, {
      'libro': libro,
      'capitulo': capitulo,
      'versiculo': versiculo,
      'titulo': titulo ?? '$libro $capitulo',
      'contenido': contenido,
      'fecha_creacion': DateTime.now().toIso8601String(),
    });
  }

  /// Obtiene todas las notas ordenadas de la más reciente a la más antigua
  Future<List<Map<String, dynamic>>> obtenerNotas() async {
    final db = await instance.database;
    return await db.query(tableNotas, orderBy: 'id DESC');
  }

  /// Cuenta la cantidad total de notas guardadas (para el badge de BibliaScreen)
  Future<int> contarNotas() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM $tableNotas',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Elimina una nota por su ID
  Future<int> eliminarNota(int id) async {
    final db = await instance.database;
    return await db.delete(tableNotas, where: 'id = ?', whereArgs: [id]);
  }

  // ============================================================
  // MÉTODOS CRUD: FAVORITOS / MARCADORES
  // ============================================================
  /// Alterna entre guardar o quitar de favoritos (Retorna true si quedó guardado, false si se quitó)
  Future<bool> toggleFavorito({
    required String libro,
    required int capitulo,
    int versiculo = 1,
    String? textoResumen,
  }) async {
    final db = await instance.database;
    final existe = await esFavorito(
      libro: libro,
      capitulo: capitulo,
      versiculo: versiculo,
    );

    if (existe) {
      await db.delete(
        tableFavoritos,
        where: 'libro = ? AND capitulo = ? AND versiculo = ?',
        whereArgs: [libro, capitulo, versiculo],
      );
      return false;
    } else {
      await db.insert(tableFavoritos, {
        'libro': libro,
        'capitulo': capitulo,
        'versiculo': versiculo,
        'texto_resumen': textoResumen ?? '$libro $capitulo',
        'fecha_guardado': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return true;
    }
  }

  /// Verifica si un pasaje/capítulo específico está marcado como favorito
  Future<bool> esFavorito({
    required String libro,
    required int capitulo,
    int versiculo = 1,
  }) async {
    final db = await instance.database;
    final result = await db.query(
      tableFavoritos,
      where: 'libro = ? AND capitulo = ? AND versiculo = ?',
      whereArgs: [libro, capitulo, versiculo],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Obtiene todos los favoritos guardados
  Future<List<Map<String, dynamic>>> obtenerFavoritos() async {
    final db = await instance.database;
    return await db.query(tableFavoritos, orderBy: 'id DESC');
  }

  /// Cuenta la cantidad total de favoritos guardados
  Future<int> contarFavoritos() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM $tableFavoritos',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
  //
  // En lib/data/atrio_database_helper.dart

  /// Guarda la última posición de lectura en config_atrio o SharedPreferences
  Future<int> guardarUltimaLectura({
    required String libro,
    required int capitulo,
    required int totalCapitulos,
  }) async {
    final db = await instance.database;
    return await db.rawInsert(
      '''
    INSERT OR REPLACE INTO $tableConfig (id, version_app, url_app, actualizado_en)
    VALUES (
      1, 
      ?, 
      ?, 
      ?
    )
  ''',
      [
        '$libro|$capitulo|$totalCapitulos', // Guardado compacto
        'ultima_lectura',
        DateTime.now().toIso8601String(),
      ],
    );
  }

  /// Obtiene la última posición de lectura guardada
  Future<Map<String, dynamic>> obtenerUltimaLectura() async {
    final db = await instance.database;
    final res = await db.query(tableConfig, where: 'id = 1', limit: 1);

    if (res.isNotEmpty && res.first['url_app'] == 'ultima_lectura') {
      final partes = (res.first['version_app'] as String).split('|');
      if (partes.length == 3) {
        return {
          'libro': partes[0],
          'capitulo': int.tryParse(partes[1]) ?? 1,
          'totalCapitulos': int.tryParse(partes[2]) ?? 50,
        };
      }
    }
    // Valor inicial por defecto si nunca ha leído nada
    return {'libro': 'Génesis', 'capitulo': 1, 'totalCapitulos': 50};
  }
  //
}
