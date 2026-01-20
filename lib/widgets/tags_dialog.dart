import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tag_provider.dart';
import '../models/tag.dart';

class TagsDialog extends ConsumerStatefulWidget {
  const TagsDialog({super.key});

  @override
  ConsumerState<TagsDialog> createState() => _TagsDialogState();
}

class _TagsDialogState extends ConsumerState<TagsDialog> {
  final TextEditingController _tagController = TextEditingController();

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tagName = _tagController.text.trim();
    if (tagName.isNotEmpty) {
      final newTag = Tag(
        id: DateTime.now().millisecondsSinceEpoch, // Simple ID generation
        name: tagName,
        color: '#FF6B6B', // Default color
      );
      ref.read(tagProvider.notifier).addTag(newTag);
      _tagController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(tagProvider);

    return AlertDialog(
      title: const Text('Tags'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add new tag input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(
                      hintText: 'Enter tag name',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _addTag, child: const Text('Add')),
              ],
            ),
            const SizedBox(height: 16),
            // Existing tags list
            if (tags.isEmpty)
              const Text('No tags yet. Add your first tag above!')
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: tags.length,
                  itemBuilder: (context, index) {
                    final tag = tags[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(
                          int.parse(tag.color.replaceFirst('#', '0xFF')),
                        ),
                        radius: 12,
                      ),
                      title: Text(tag.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () {
                          ref.read(tagProvider.notifier).removeTag(tag.id);
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
