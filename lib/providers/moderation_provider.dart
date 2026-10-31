import 'dart:async';
import 'package:flutter/material.dart';
import '../atrio_api.dart';
import '../modelos/moderation_models.dart';
import '../servicios/moderation_service.dart';

/// Provider para la gestión reactiva de Moderación de Plataforma de ATRIO (Odoo 19).
/// Exclusivo para el rol Super Admin (`role: platform_admin`).
class ModerationProvider extends ChangeNotifier {
  final ModerationService _service;

  ModerationProvider({required AtrioApi api})
      : _service = ModerationService(api: api);

  // ===========================================================================
  // 1. ESTADO DEL RESUMEN Y CONTENIDO MODERADO
  // ===========================================================================
  ModerationSummaryModel? _summary;
  List<ModeratedItemModel> _items = [];
  int _totalItems = 0;

  String _selectedType = 'post'; // 'post', 'event', 'notification'
  String _selectedStatus = 'flagged'; // 'flagged', 'banned', 'all'
  String _searchQuery = '';

  bool _isLoading = false;
  String? _errorMessage;

  ModerationSummaryModel? get summary => _summary;
  List<ModeratedItemModel> get items => _items;
  int get totalItems => _totalItems;
  String get selectedType => _selectedType;
  String get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setTypeFilter(String type) {
    if (_selectedType == type) return;
    _selectedType = type;
    notifyListeners();
    loadContent(refresh: true);
  }

  void setStatusFilter(String status) {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
    notifyListeners();
    loadContent(refresh: true);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
    loadContent(refresh: true);
  }

  /// Carga los totales de contenido por tipo (/summary).
  Future<void> loadSummary() async {
    try {
      final summary = await _service.getSummary();
      _summary = summary;
      notifyListeners();
    } on AtrioApiException catch (e) {
      debugPrint('[ModerationProvider] Error al cargar resumen: $e');
    } catch (e) {
      debugPrint('[ModerationProvider] Error inesperado en loadSummary: $e');
    }
  }

  /// Carga la lista de contenido auditado según los filtros activos (/content).
  Future<void> loadContent({bool refresh = false}) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.getContent(
        type: _selectedType,
        status: _selectedStatus,
        search: _searchQuery.trim().isNotEmpty ? _searchQuery.trim() : null,
      );
      _items = result.items;
      _totalItems = result.total;
    } on AtrioApiException catch (e) {
      _errorMessage = e.message;
      debugPrint('[ModerationProvider] Error al cargar contenido moderado: $e');
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('[ModerationProvider] Error inesperado en loadContent: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Bloquea un contenido reportado exigiendo un motivo que la iglesia verá.
  Future<bool> banContent({
    required String type,
    required int id,
    required String reason,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _service.banContent(
        type: type,
        id: id,
        reason: reason,
      );
      if (updated != null) {
        final index = _items.indexWhere((it) => it.id == id && it.type == type);
        if (index != -1) {
          _items[index] = updated;
        }
      }
      // Actualizamos resumen en segundo plano
      await loadSummary();
      await loadContent(refresh: true);
      return true;
    } on AtrioApiException catch (e) {
      _errorMessage = e.message;
      debugPrint('[ModerationProvider] Error al bloquear contenido: $e');
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Desbloquea un contenido censurado y avisa a la iglesia.
  Future<bool> unbanContent({
    required String type,
    required int id,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _service.unbanContent(type: type, id: id);
      if (updated != null) {
        final index = _items.indexWhere((it) => it.id == id && it.type == type);
        if (index != -1) {
          _items[index] = updated;
        }
      }
      await loadSummary();
      await loadContent(refresh: true);
      return true;
    } on AtrioApiException catch (e) {
      _errorMessage = e.message;
      debugPrint('[ModerationProvider] Error al desbloquear contenido: $e');
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // 2. GESTIÓN DE PALABRAS RESTRINGIDAS (/words)
  // ===========================================================================
  List<ModerationWordModel> _words = [];
  bool _isWordsLoading = false;
  String? _wordsError;

  List<ModerationWordModel> get words => _words;
  bool get isWordsLoading => _isWordsLoading;
  String? get wordsError => _wordsError;

  /// Consulta todas las palabras restringidas.
  Future<void> loadWords() async {
    _isWordsLoading = true;
    _wordsError = null;
    notifyListeners();

    try {
      final list = await _service.getWords();
      _words = list;
    } on AtrioApiException catch (e) {
      _wordsError = e.message;
      debugPrint('[ModerationProvider] Error al cargar palabras: $e');
    } catch (e) {
      _wordsError = e.toString();
      debugPrint('[ModerationProvider] Error inesperado en loadWords: $e');
    } finally {
      _isWordsLoading = false;
      notifyListeners();
    }
  }

  /// Registra una nueva palabra restringida.
  Future<bool> addWord({
    required String word,
    String mode = 'flag',
    bool wholeWord = true,
    String? note,
  }) async {
    _isWordsLoading = true;
    _wordsError = null;
    notifyListeners();

    try {
      final created = await _service.createWord(
        word: word,
        mode: mode,
        wholeWord: wholeWord,
        note: note,
      );
      _words.insert(0, created);
      return true;
    } on AtrioApiException catch (e) {
      _wordsError = e.message;
      debugPrint('[ModerationProvider] Error al crear palabra: $e');
      return false;
    } catch (e) {
      _wordsError = e.toString();
      return false;
    } finally {
      _isWordsLoading = false;
      notifyListeners();
    }
  }

  /// Edita los parámetros de una palabra restringida.
  Future<bool> editWord(
    int id, {
    String? word,
    String? mode,
    bool? wholeWord,
    bool? active,
    String? note,
  }) async {
    _isWordsLoading = true;
    _wordsError = null;
    notifyListeners();

    try {
      final updated = await _service.updateWord(
        id,
        word: word,
        mode: mode,
        wholeWord: wholeWord,
        active: active,
        note: note,
      );
      final index = _words.indexWhere((w) => w.id == id);
      if (index != -1) {
        _words[index] = updated;
      }
      return true;
    } on AtrioApiException catch (e) {
      _wordsError = e.message;
      debugPrint('[ModerationProvider] Error al editar palabra: $e');
      return false;
    } catch (e) {
      _wordsError = e.toString();
      return false;
    } finally {
      _isWordsLoading = false;
      notifyListeners();
    }
  }

  /// Pausa o reactiva una palabra restringida mandando `active`.
  Future<bool> toggleWordActive(int id, bool active) async {
    return await editWord(id, active: active);
  }

  /// Elimina una palabra restringida.
  Future<bool> removeWord(int id) async {
    _isWordsLoading = true;
    _wordsError = null;
    notifyListeners();

    try {
      final ok = await _service.deleteWord(id);
      if (ok) {
        _words.removeWhere((w) => w.id == id);
      }
      return ok;
    } on AtrioApiException catch (e) {
      _wordsError = e.message;
      debugPrint('[ModerationProvider] Error al eliminar palabra: $e');
      return false;
    } catch (e) {
      _wordsError = e.toString();
      return false;
    } finally {
      _isWordsLoading = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // 3. REESCANEO GLOBAL (/rescan)
  // ===========================================================================
  bool _isRescanning = false;
  bool get isRescanning => _isRescanning;

  /// Ejecuta el reescaneo asíncrono de todo el contenido de la plataforma.
  /// Retorna la cantidad de elementos marcados.
  Future<int?> rescanAllContent() async {
    _isRescanning = true;
    notifyListeners();

    try {
      final count = await _service.rescanAll();
      await loadSummary();
      await loadContent(refresh: true);
      return count;
    } on AtrioApiException catch (e) {
      _errorMessage = e.message;
      debugPrint('[ModerationProvider] Error en rescan: $e');
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isRescanning = false;
      notifyListeners();
    }
  }

  /// Restablece todo el estado a su valor inicial.
  void reset() {
    _summary = null;
    _items = [];
    _totalItems = 0;
    _selectedType = 'post';
    _selectedStatus = 'flagged';
    _searchQuery = '';
    _isLoading = false;
    _errorMessage = null;

    _words = [];
    _isWordsLoading = false;
    _wordsError = null;

    _isRescanning = false;
    notifyListeners();
  }
}
