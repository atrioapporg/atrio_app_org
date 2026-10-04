// lib/data/database_helper.dart
// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const _databaseName = "biblia_audio.db";
  static const _databaseVersion = 1;
  static const table = 'tiempos_capitulos';
  static const bool debugDatabase = true;

  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  static void _log(String mensaje) {
    if (debugDatabase) debugPrint('[DATABASE] $mensaje');
  }

  static void _separator() {
    if (debugDatabase) {
      debugPrint(
        '============================================================',
      );
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_databaseName);
    return _database!;
  }

  // ============================================================
  // NORMALIZACIÓN DE NOMBRES (Elimina tildes y diacríticos)
  // ============================================================
  static String normalizarNombreLibro(String texto) {
    return texto
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .trim();
  }

  // ============================================================
  // INICIALIZAR Y COPIAR SQLITE PRECONSTRUIDA
  // ============================================================
  Future<Database> _initDB(String fileName) async {
    final stopwatch = Stopwatch()..start();
    _separator();
    _log('🚀 INICIANDO SQLITE PRECONSTRUIDA');

    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, fileName);
      _log('📍 Ruta destino: $path');

      // 1. ¿Existe la base de datos local?
      final existe = await databaseExists(path);

      if (!existe) {
        _log('⚠️ La BD no existe localmente. Iniciando copia desde assets...');

        try {
          await Directory(dbPath).create(recursive: true);
        } catch (_) {}

        // 2. Cargar desde assets (soporta assets/ o assets/database/)
        ByteData data;
        try {
          _log('📥 Cargando archivo desde assets/database/$fileName');
          data = await rootBundle.load('assets/database/$fileName');
        } catch (_) {
          _log('📥 Intento alternativo desde assets/$fileName');
          data = await rootBundle.load('assets/$fileName');
        }

        List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );

        _log('💾 Escribiendo archivo en el dispositivo...');
        await File(path).writeAsBytes(bytes, flush: true);
        _log('✅ Copia completada exitosamente.');
      } else {
        _log('✅ La BD ya existe en el dispositivo. Omitiendo copia.');
      }

      // 3. Abrir la base de datos
      _log('🔓 Abriendo base de datos...');
      final db = await openDatabase(
        path,
        version: _databaseVersion,
        onOpen: (db) async {
          _log('🔓 Evento onOpen() ejecutado.');
        },
      );

      stopwatch.stop();
      _log('✅ SQLITE LISTA PARA USAR');
      _log('⏱️ Tiempo total: ${stopwatch.elapsedMilliseconds} ms');
      _separator();

      return db;
    } catch (e, stackTrace) {
      stopwatch.stop();
      _separator();
      _log('💥 ERROR AL COPIAR/ABRIR SQLITE');
      _log('❌ Error: $e');
      _log('📚 StackTrace:\n$stackTrace');
      _separator();
      rethrow;
    }
  }

  // ============================================================
  // MÉTODOS DE CONSULTA (READ)
  // ============================================================

  /// Obtiene los tiempos exactos y el video de un capítulo específico
  Future<Map<String, dynamic>?> getCapitulo(
    String nombreLibro,
    int numeroCapitulo,
  ) async {
    try {
      final db = await instance.database;
      final libroNormalizado = normalizarNombreLibro(nombreLibro);

      final result = await db.query(
        table, // 'tiempos_capitulos'
        where: 'LOWER(libro) = LOWER(?) AND capitulo = ?',
        whereArgs: [libroNormalizado, numeroCapitulo],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return result.first;
      }
      return null;
    } catch (e) {
      _log(
        'Error al consultar el capítulo $numeroCapitulo de $nombreLibro: $e',
      );
      return null;
    }
  }

  /// Obtiene todos los capítulos de un libro ordenados
  Future<List<Map<String, dynamic>>> getCapitulosPorLibro(
    String nombreLibro,
  ) async {
    try {
      final db = await instance.database;
      final libroNormalizado = normalizarNombreLibro(nombreLibro);

      return await db.query(
        table,
        where: 'LOWER(libro) = LOWER(?)',
        whereArgs: [libroNormalizado],
        orderBy: 'capitulo ASC',
      );
    } catch (e) {
      _log('Error al consultar la lista de capítulos de $nombreLibro: $e');
      return [];
    }
  }
}
