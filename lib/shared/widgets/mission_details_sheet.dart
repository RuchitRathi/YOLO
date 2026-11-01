import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repository.dart';
import '../../features/missions/nearby_places_sheet.dart';
import 'comic_components.dart';
import 'mission_run_sheet.dart';

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
            if (mission.fitReason case final reason?) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0B8),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_rounded, size: 19),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            const Text('WHY IT FITS',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .8)),
                            const SizedBox(height: 4),
                            Text(reason, style: const TextStyle(height: 1.3)),
                          ])),
                    ]),
              ),
            ],
            const SizedBox(height: 12),
            Text(
                '${mission.duration} minutes • ${mission.budget == 0 ? 'FREE' : '${mission.currency}${mission.budget}'} • ${mission.difficulty} • ${mission.xp} XP'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                  if (context.mounted) {
                    await showNearbyMissionPlaces(context, mission);
                  }
                },
                icon: const Icon(Icons.travel_explore_rounded),
                label: const Text('FIND A PLACE IN MAPS'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  side: const BorderSide(color: Colors.black, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
            const SizedBox(height: 8),
            YoloButton(
              label: 'START MISSION RUN',
              onPressed: () async {
                if (sheetContext.mounted) Navigator.pop(sheetContext);
                if (context.mounted) {
                  await showMissionRun(context, ref, mission);
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
