import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/ui_providers.dart';

/// A palette of pleasant preset colours for categories (aligned with the design).
final _presetColors = <String>[
  '#5B6CFF', '#22C55E', '#F472B6', '#FBBF24', '#60A5FA',
  '#A78BFA', '#14B8A6', '#F97316', '#EF4444', '#84CC16',
];

/// Manage categories (Work, Study, Health, …) with colour coding.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.categories,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.newCategory),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
        data: (categories) => categories.isEmpty
            ? EmptyState(
                icon: Icons.label_outline_rounded,
                title: l10n.noCategoriesYet,
                message: l10n.noCategoriesMessage,
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                children: [
                  for (final cat in categories)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CategoryRow(
                        category: cat,
                        onEdit: () => _showEditor(context, ref, existing: cat),
                        onDelete: () => ref.read(categoryRepositoryProvider).delete(cat),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _showEditor(BuildContext context, WidgetRef ref, {Category? existing}) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: existing?.name ?? '');
    var color = existing?.colorHex ?? _presetColors.first;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) {
          final c = context.colors;
          return AlertDialog(
            title: Text(existing == null ? l10n.newCategory : l10n.editCategory),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
                  decoration: InputDecoration(
                    labelText: l10n.nameLabel,
                    fillColor: c.surfaceAlt,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final hex in _presetColors)
                      GestureDetector(
                        onTap: () => setDialog(() => color = hex),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Category(id: '', name: '', colorHex: hex).color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color == hex ? c.ink : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: color == hex
                              ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                              : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
                onPressed: () async {
                  final name = controller.text.trim();
                  if (name.isEmpty) return;
                  final repo = ref.read(categoryRepositoryProvider);
                  if (existing == null) {
                    await repo.create(name: name, colorHex: color);
                  } else {
                    await repo.update(Category(id: existing.id, name: name, colorHex: color));
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category, required this.onEdit, required this.onDelete});
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 16,
      onTap: onEdit,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: category.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: category.color)),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(category.name,
                style: TextStyle(fontFamily: AppFonts.sans, fontSize: 14.5, fontWeight: FontWeight.w600, color: c.ink)),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: c.textMuted),
            onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 19, color: c.textSecondary),
                  const SizedBox(width: 12),
                  Text(l10n.edit, style: TextStyle(fontFamily: AppFonts.sans, fontWeight: FontWeight.w600, color: c.ink)),
                ]),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline_rounded, size: 19, color: c.danger),
                  const SizedBox(width: 12),
                  Text(l10n.delete, style: TextStyle(fontFamily: AppFonts.sans, fontWeight: FontWeight.w600, color: c.danger)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
