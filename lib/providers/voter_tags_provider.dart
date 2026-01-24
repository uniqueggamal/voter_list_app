import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../helpers/tags_database_helper.dart';
import '../models/tag.dart';

class VoterTagsNotifier extends StateNotifier<List<Tag>> {
  final int voterId;
  final TagsDatabaseHelper _dbHelper = TagsDatabaseHelper();

  VoterTagsNotifier(this.voterId) : super([]) {
    _loadVoterTags();
  }

  Future<void> _loadVoterTags() async {
    final tags = await _dbHelper.getTagsForVoter(voterId);
    state = tags;
  }

  Future<void> addTag(int tagId) async {
    await _dbHelper.addTagToVoter(voterId, tagId);
    final tags = await _dbHelper.getTagsForVoter(voterId);
    state = tags;
  }

  Future<void> removeTag(int tagId) async {
    await _dbHelper.removeTagFromVoter(voterId, tagId);
    final tags = await _dbHelper.getTagsForVoter(voterId);
    state = tags;
  }

  bool hasTag(int tagId) {
    return state.any((tag) => tag.id == tagId);
  }
}

final voterTagsProvider =
    StateNotifierProvider.family<VoterTagsNotifier, List<Tag>, int>((
      ref,
      voterId,
    ) {
      return VoterTagsNotifier(voterId);
    });
