import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tag.dart';
import '../helpers/tags_database_helper.dart';

class TagNotifier extends StateNotifier<List<Tag>> {
  final TagsDatabaseHelper _dbHelper = TagsDatabaseHelper();

  TagNotifier() : super([]) {
    _loadTags();
  }

  Future<void> _loadTags() async {
    final tags = await _dbHelper.getTags();
    state = tags;
  }

  Future<void> addTag(Tag tag) async {
    await _dbHelper.insertTag(tag);
    state = [...state, tag];
  }

  Future<void> removeTag(int id) async {
    await _dbHelper.deleteTag(id);
    state = state.where((tag) => tag.id != id).toList();
  }

  Future<void> updateTag(Tag updatedTag) async {
    await _dbHelper.updateTag(updatedTag);
    state = state
        .map((tag) => tag.id == updatedTag.id ? updatedTag : tag)
        .toList();
  }

  Tag? getTagById(int id) {
    try {
      return state.firstWhere((tag) => tag.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Tag> getTagsByIds(List<int> ids) {
    return state.where((tag) => ids.contains(tag.id)).toList();
  }
}

final tagProvider = StateNotifierProvider<TagNotifier, List<Tag>>((ref) {
  return TagNotifier();
});
