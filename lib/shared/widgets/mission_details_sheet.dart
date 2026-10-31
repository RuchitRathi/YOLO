import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/repository.dart';
import 'comic_components.dart';
import 'mission_share_card.dart';

Future<void> showMissionDetails(
  BuildContext context,
  WidgetRef ref,
  Mission mission,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mission.title,
                style: Theme.of(sheetContext).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(mission.description),
            const SizedBox(height: 12),
            Text('How: ${mission.instructions}'),
            const SizedBox(height: 12),
            Text(
                '${mission.duration} minutes • ${mission.budget == 0 ? 'FREE' : '${mission.currency}${mission.budget}'} • ${mission.difficulty} • ${mission.xp} XP'),
            const SizedBox(height: 16),
            YoloButton(
              label: 'ACCEPT MISSION',
              onPressed: () async {
                await ref.read(repositoryProvider).record(mission, 'accepted');
                ref.read(progressRevisionProvider.notifier).state++;
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
            ),
            const SizedBox(height: 8),
            YoloButton(
              label: 'COMPLETE MISSION',
              onPressed: () async {
                await ref.read(repositoryProvider).record(mission, 'completed');
                ref.read(progressRevisionProvider.notifier).state++;
                if (sheetContext.mounted) {
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Mission complete! +${mission.xp} XP 🎉')),
                  );
                  await Future<void>.delayed(const Duration(milliseconds: 250));
                  if (context.mounted) {
                    showMissionShareCard(context, ref, mission);
                  }
                }
              },
            ),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Maybe later'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
