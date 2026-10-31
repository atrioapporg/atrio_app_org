import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../modelos/moderation_models.dart';
import '../providers/moderation_provider.dart';
import '../widgets/permission_guard.dart';

/// Pantalla para administrar el catálogo de palabras restringidas (Odoo 19 `/platform/moderation/words`).
/// Permite agregar, editar, pausar/activar y eliminar palabras con modos 'flag' y 'block'.
class ModerationWordsScreen extends StatefulWidget {
  static const routeName = 'moderation_words_screen';

  const ModerationWordsScreen({super.key});

  @override
  State<ModerationWordsScreen> createState() => _ModerationWordsScreenState();
}

class _ModerationWordsScreenState extends State<ModerationWordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.isPlatformAdmin) {
        context.read<ModerationProvider>().loadWords();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddOrEditDialog({ModerationWordModel? wordToEdit}) {
    final l10n = AppLocalizations.of(context);
    final isEditing = wordToEdit != null;

    final wordController = TextEditingController(text: wordToEdit?.word ?? '');
    final noteController = TextEditingController(text: wordToEdit?.note ?? '');
    String selectedMode = wordToEdit?.mode ?? 'flag';
    bool wholeWord = wordToEdit?.wholeWord ?? true;
    bool active = wordToEdit?.active ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          const Color azulFondo = Color(0xFF072B4F);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              isEditing
                  ? (l10n?.palabrasRestringidas ?? 'Editar Palabra')
                  : (l10n?.nuevaPalabra ?? 'Nueva Palabra'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: wordController,
                    decoration: InputDecoration(
                      labelText: l10n?.palabraOFrase ?? 'Palabra o Frase',
                      hintText: l10n?.palabraOFraseHint ?? 'Ej. término indebido',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.modoPalabra ?? 'Modo de Acción',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: [
                        ButtonSegment<String>(
                          value: 'flag',
                          label: Text(l10n?.modoFlag ?? 'Marcar (Flag)'),
                          icon: const Icon(Icons.flag_outlined, size: 16),
                        ),
                        ButtonSegment<String>(
                          value: 'block',
                          label: Text(l10n?.modoBlock ?? 'Bloquear (Block)'),
                          icon: const Icon(Icons.block_outlined, size: 16),
                        ),
                      ],
                      selected: {selectedMode},
                      onSelectionChanged: (newSelection) {
                        setDialogState(() => selectedMode = newSelection.first);
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    selectedMode == 'flag'
                        ? 'Guarda el contenido y lo marca para revisión'
                        : 'No deja guardar al autor (retorna 400 content_blocked)',
                    style: TextStyle(
                      fontSize: 11,
                      color: selectedMode == 'block'
                          ? Colors.red.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n?.palabraCompleta ?? 'Palabra completa',
                      style: const TextStyle(fontSize: 13),
                    ),
                    value: wholeWord,
                    activeTrackColor: azulFondo,
                    onChanged: (val) => setDialogState(() => wholeWord = val),
                  ),
                  if (isEditing)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l10n?.palabraActiva ?? 'Regla activa',
                        style: const TextStyle(fontSize: 13),
                      ),
                      value: active,
                      activeTrackColor: Colors.green,
                      onChanged: (val) => setDialogState(() => active = val),
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l10n?.notaInterna ?? 'Nota Interna (opcional)',
                      hintText: l10n?.notaInternaHint ?? 'Contexto de la regla',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n?.cancelar ?? 'Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: azulFondo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final text = wordController.text.trim();
                  if (text.isEmpty) return;

                  Navigator.pop(ctx);
                  bool ok;
                  if (isEditing) {
                    ok = await context.read<ModerationProvider>().editWord(
                          wordToEdit.id,
                          word: text,
                          mode: selectedMode,
                          wholeWord: wholeWord,
                          active: active,
                          note: noteController.text.trim().isNotEmpty
                              ? noteController.text.trim()
                              : null,
                        );
                  } else {
                    ok = await context.read<ModerationProvider>().addWord(
                          word: text,
                          mode: selectedMode,
                          wholeWord: wholeWord,
                          note: noteController.text.trim().isNotEmpty
                              ? noteController.text.trim()
                              : null,
                        );
                  }

                  if (mounted && ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n?.palabraGuardadaExito ?? 'Palabra guardada con éxito',
                        ),
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                    );
                  }
                },
                child: Text(l10n?.guardar ?? 'Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDialog(ModerationWordModel word) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.eliminarPalabra ?? 'Eliminar Palabra'),
        content: Text(
          l10n?.confirmarEliminarPalabra ??
              '¿Deseas eliminar esta palabra de la lista de restricciones?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.cancelar ?? 'Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await context
                  .read<ModerationProvider>()
                  .removeWord(word.id);
              if (mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n?.palabraEliminadaExito ?? 'Palabra eliminada',
                    ),
                  ),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSuperAdmin = context.isPlatformAdmin;

    const Color azulFondo = Color(0xFF072B4F);
    const Color amarilloOro = Color(0xFFE5A023);
    const Color blancoFondo = Color(0xFFFAF7F0);

    if (!isSuperAdmin) {
      return Scaffold(
        backgroundColor: blancoFondo,
        appBar: AppBar(
          title: Text(l10n?.palabrasRestringidas ?? 'Palabras Restringidas'),
          backgroundColor: azulFondo,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n?.permisoRequeridoSuperAdmin ??
                  'Acceso exclusivo para Super Administradores',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    final provider = context.watch<ModerationProvider>();
    final allWords = provider.words;
    final isLoading = provider.isWordsLoading;

    final filteredWords = _filterQuery.isEmpty
        ? allWords
        : allWords
            .where((w) =>
                w.word.toLowerCase().contains(_filterQuery.toLowerCase()) ||
                (w.note?.toLowerCase().contains(_filterQuery.toLowerCase()) ?? false))
            .toList();

    return Scaffold(
      backgroundColor: blancoFondo,
      appBar: AppBar(
        title: Text(
          l10n?.palabrasRestringidas ?? 'Palabras Restringidas',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: azulFondo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<ModerationProvider>().loadWords(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: amarilloOro,
        foregroundColor: azulFondo,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          l10n?.nuevaPalabra ?? 'Nueva Palabra',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () => _showAddOrEditDialog(),
      ),
      body: Column(
        children: [
          // 1. Buscador
          Container(
            color: Colors.white,
            padding: const EdgeInsetsDirectional.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n?.buscarPalabra ?? 'Buscar palabra...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _filterQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _filterQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) => setState(() => _filterQuery = val.trim()),
            ),
          ),

          // 2. Listado de palabras
          Expanded(
            child: isLoading && allWords.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(azulFondo),
                    ),
                  )
                : filteredWords.isEmpty
                    ? Center(
                        child: Text(
                          l10n?.sinPalabrasRestringidas ??
                              'No hay palabras restringidas registradas',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsetsDirectional.only(
                          start: 16,
                          end: 16,
                          top: 12,
                          bottom: 80,
                        ),
                        itemCount: filteredWords.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final word = filteredWords[index];
                          return _WordCard(
                            word: word,
                            onToggleActive: (val) {
                              context
                                  .read<ModerationProvider>()
                                  .toggleWordActive(word.id, val);
                            },
                            onEdit: () => _showAddOrEditDialog(wordToEdit: word),
                            onDelete: () => _showDeleteDialog(word),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final ModerationWordModel word;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WordCard({
    required this.word,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const Color azulFondo = Color(0xFF072B4F);

    return Container(
      padding: const EdgeInsetsDirectional.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: word.active ? const Color(0xFFCBD5E1) : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Indicador de modo (Flag vs Block)
          Container(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: word.isBlock
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              word.mode.toUpperCase(),
              style: TextStyle(
                color: word.isBlock
                    ? const Color(0xFFB91C1C)
                    : const Color(0xFFB45309),
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word.word,
                  style: TextStyle(
                    color: word.active ? azulFondo : Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    decoration: word.active ? null : TextDecoration.lineThrough,
                  ),
                ),
                if (word.note != null && word.note!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    word.note!,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  word.wholeWord ? 'Palabra completa' : 'Coincidencia parcial',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                ),
              ],
            ),
          ),
          Switch(
            value: word.active,
            activeTrackColor: const Color(0xFF16A34A),
            onChanged: onToggleActive,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 20),
            onSelected: (val) {
              if (val == 'edit') onEdit();
              if (val == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
