import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/category.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/ui_providers.dart';

/// A palette of pleasant preset colours for categories.
const _presetColors = <String>[
  '#6C63FF', '#22C55E', '#EF4444', '#F59E0B', '#3B82F6',
  '#EC4899', '#14B8A6', '#8B5CF6', '#64748B', '#84CC16',
];

/// Manage categories (Work, Study, Health, …) with colour coding.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.categories)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditor(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.newCategory),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
        data: (categories) => categories.isEmpty
            ? EmptyState(
                icon: Icons.label_outline,
                title: l10n.noCategoriesYet,
                message: l10n.noCategoriesMessage,
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: categories.length,
                itemBuilder: (_, i) {
                  final c = categories[i];
                  return ListTile(
                    leading: CircleAvatar(backgroundColor: c.color, radius: 12),
                    title: Text(c.name),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') {
                          _showEditor(context, ref, existing: c);
                        } else if (v == 'delete') {
                          await ref.read(categoryRepositoryProvider).delete(c);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                        PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                      ],
                    ),
                    onTap: () => _showEditor(context, ref, existing: c),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _showEditor(BuildContext context, WidgetRef ref,
      {Category? existing}) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: existing?.name ?? '');
    var color = existing?.colorHex ?? _presetColors.first;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(existing == null ? l10n.newCategory : l10n.editCategory),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l10n.nameLabel),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final hex in _presetColors)
                    GestureDetector(
                      onTap: () => setDialog(() => color = hex),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Category(id: '', name: '', colorHex: hex).color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: color == hex
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                final repo = ref.read(categoryRepositoryProvider);
                if (existing == null) {
                  await repo.create(name: name, colorHex: color);
                } else {
                  await repo.update(Category(
                      id: existing.id, name: name, colorHex: color));
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
