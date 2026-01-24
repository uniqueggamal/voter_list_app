import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tag_provider.dart';
import '../providers/voter_tags_provider.dart';

class VoterTagsDialog extends ConsumerWidget {
  final int voterId;

  const VoterTagsDialog({super.key, required this.voterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTags = ref.watch(tagProvider);
    final voterTags = ref.watch(voterTagsProvider(voterId));

    return AlertDialog(
      title: const Text('Select Tags'),
      content: SizedBox(
        width: double.maxFinite,
        child: allTags.isEmpty
            ? const Center(child: Text('No tags available. Create tags first.'))
            : ListView.builder(
                itemCount: allTags.length,
                itemBuilder: (context, index) {
                  final tag = allTags[index];
                  final isSelected = voterTags.any((t) => t.id == tag.id);

                  return CheckboxListTile(
                    title: Text(tag.name),
                    secondary: CircleAvatar(
                      backgroundColor: Color(
                        int.parse(tag.color.replaceFirst('#', '0xFF')),
                      ),
                      radius: 12,
                    ),
                    value: isSelected,
                    onChanged: (bool? value) async {
                      if (value == true) {
                        await ref
                            .read(voterTagsProvider(voterId).notifier)
                            .addTag(tag.id);
                      } else {
                        await ref
                            .read(voterTagsProvider(voterId).notifier)
                            .removeTag(tag.id);
                      }
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
