import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../data/repository.dart';

Future<void> showNearbyMissionPlaces(BuildContext context, Mission mission) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: YoloColors.background,
      builder: (_) => NearbyPlacesSheet(mission: mission),
    );

class NearbyPlacesSheet extends StatefulWidget {
  const NearbyPlacesSheet({super.key, required this.mission});
  final Mission mission;

  @override
  State<NearbyPlacesSheet> createState() => _NearbyPlacesSheetState();
}

class _NearbyPlacesSheetState extends State<NearbyPlacesSheet> {
  String? _error;

  String get _searchTerm {
    final mission = widget.mission;
    return switch (mission.category) {
      'Adventure' => 'parks, gardens, and attractions',
      'Creative' => 'libraries, galleries, and creative spaces',
      'Social' => 'cafes, restaurants, and community spaces',
      'Fitness' => 'parks, sports, and fitness spaces',
      'Learning' => 'libraries, museums, and learning spaces',
      _ => 'attractions and interesting places',
    };
  }

  Future<void> _openNearbyMaps() async {
    setState(() {
      _error = null;
    });
    try {
      final uri = Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': '$_searchTerm near me',
      });
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) throw Exception('Maps could not be opened.');
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not open Maps. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .72,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: YoloColors.ink.withValues(alpha: .24),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                const Icon(Icons.place_rounded, color: YoloColors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MISSION NEAR YOU',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1)),
                      Text(widget.mission.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close nearby places',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ]),
              const SizedBox(height: 14),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          color: YoloColors.yellow,
                          shape: BoxShape.circle,
                          border: Border.all(color: YoloColors.ink, width: 2),
                        ),
                        child: const Icon(Icons.map_rounded, size: 48),
                      ),
                      const SizedBox(height: 16),
                      Text('Find your kind of place',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Open Maps to see nearby $_searchTerm for “${widget.mission.title}”. The search starts from your current location.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(height: 1.45),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: YoloColors.red)),
                      ],
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _openNearbyMaps,
                        icon: const Icon(Icons.near_me_rounded),
                        label: const Text('OPEN NEARBY PLACES IN MAPS'),
                        style: FilledButton.styleFrom(
                          backgroundColor: YoloColors.ink,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Maps uses your device location for “near me”. No location permission or API key is needed in YOLO.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11, color: Color(0xFF6B665E)),
                      ),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
