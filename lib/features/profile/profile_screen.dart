import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../shared/widgets/yolo_scaffold.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(progressRevisionProvider);
    final profile = ref.watch(repositoryProvider);
    return YoloScaffold(
      title: 'Your Profile',
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(profile.username, style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 38)),
            const SizedBox(height: 16),
            Text('Level ${profile.level}  •  ${profile.xp} XP  •  ${profile.streak} day streak', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text('Missions completed: ${profile.completed}'),
            const SizedBox(height: 10),
            const Text('Badges: First Step • Curious Mind • On a Roll'),
          ],
        ),
      ),
    );
  }
}
