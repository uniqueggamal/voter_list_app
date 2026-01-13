import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/voter_provider.dart';
import '../models/voter.dart';
import 'voter_details_dialog.dart';

class VoterListWidget extends ConsumerWidget {
  const VoterListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voterState = ref.watch(voterProvider);

    if (voterState.isLoading && voterState.voters.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (voterState.voters.isEmpty) {
      return const Center(child: Text('No voters found'));
    }

    return Scrollbar(
      child: ListView.builder(
        itemCount: voterState.voters.length,
        //  + (voterState.hasMoreData ? 1 : 0)
        itemBuilder: (context, index) {
          if (index == voterState.voters.length) {
            // Load more indicator
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final voter = voterState.voters[index];
          return VoterListItem(voter: voter, index: index);
        },
      ),
    );
  }
}

class VoterListItem extends ConsumerWidget {
  final Voter voter;
  final int index;

  const VoterListItem({super.key, required this.voter, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voterState = ref.watch(voterProvider);

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => VoterDetailsDialog(voterId: voter.id),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      voterState.pageSize == -1
                          ? '${index + 1}'
                          : '${(voterState.currentPage - 1) * voterState.pageSize + index + 1}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voter.nameNepali,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Voter ID: ${voter.voterNo}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: [
                  _buildInfoChip('Age', voter.age?.toString() ?? 'N/A'),
                  _buildInfoChip('Gender', voter.gender ?? 'N/A'),
                  _buildInfoChip('Booth', voter.boothName ?? voter.boothCode),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${voter.municipality}, Ward ${voter.wardNo} - ${voter.district}, ${voter.province}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: Colors.blue[700],
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        softWrap: true,
        overflow: TextOverflow.visible,
      ),
    );
  }
}
