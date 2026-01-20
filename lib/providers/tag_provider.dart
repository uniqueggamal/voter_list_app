import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tag.dart';

class TagNotifier extends StateNotifier<List<Tag>> {
  TagNotifier() : super([]);

  void addTag(Tag tag) {
    state = [...state, tag];
  }

  void removeTag(int id) {
    state = state.where((tag) => tag.id != id).toList();
  }

  void updateTag(Tag updatedTag) {
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
