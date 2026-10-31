import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/repository.dart';
import '../../shared/widgets/mission_share_card.dart';
import '../../shared/widgets/yolo_scaffold.dart';

class MemoriesScreen extends ConsumerWidget {
  const MemoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(progressRevisionProvider);
    final history = ref.watch(repositoryProvider).history;
    return YoloScaffold(
      title: 'YOLO Memories',
      child: history.isEmpty
          ? const Center(
              child: Text('Your story starts with one small adventure.'))
          : ListView(
              children: [
                for (final item in history)
                  ListTile(
                    leading: const Icon(Icons.auto_awesome),
                    title: Text(item.title),
                    subtitle: Text(
                        '${item.status} • ${item.date}${item.xpEarned > 0 ? ' • +${item.xpEarned} XP' : ''}'),
                    trailing: IconButton(
                        tooltip: 'Share memory card',
                        icon: const Icon(Icons.ios_share_rounded),
                        onPressed: () {
                          Mission? mission;
                          for (final candidate in missions) {
                            if (candidate.title == item.title) {
                              mission = candidate;
                              break;
                            }
                          }
                          final memoryXp = item.xpEarned > 0
                              ? item.xpEarned
                              : (mission?.xp ?? 0);
                          final shareMission = mission ??
                              Mission(
                                  id: 'memory',
                                  title: item.title,
                                  description: 'A moment from your YOLO story.',
                                  category: 'Adventure',
                                  moods: [],
                                  duration: 10,
                                  budget: 0,
                                  difficulty: 'Easy',
                                  xp: 0,
                                  environment: 'Both',
                                  instructions: '');
                          showMissionShareCard(context, ref, shareMission,
                              subtitle: item.status == 'completed'
                                  ? 'MISSION COMPLETE!'
                                  : 'A MOMENT FROM MY STORY',
                              xpEarned: memoryXp);
                        }),
                  ),
              ],
            ),
    );
  }
}
