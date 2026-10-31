import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/repository.dart';
import '../../shared/widgets/animated_entrance.dart';
import '../../shared/widgets/comic_components.dart';
import '../../shared/widgets/mission_details_sheet.dart';
import '../../shared/widgets/yolo_scaffold.dart';
import 'personalized_missions_service.dart';

class MissionsScreen extends ConsumerStatefulWidget {
  const MissionsScreen({super.key});

  @override
  ConsumerState<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends ConsumerState<MissionsScreen> {
  static const _categories = [
    'All',
    'Adventure',
    'Creative',
    'Social',
    'Fitness',
    'Learning',
    'Entertainment'
  ];
  final _searchController = TextEditingController();
  String _category = 'All';
  Mission? _surprisePick;
  int _surpriseCount = 0;
  final _personalizer = PersonalizedMissionsService();
  static const _preferences = [
    'Surprise me',
    'Creative',
    'Adventurous',
    'Chill',
    'Social'
  ];
  String _preference = 'Surprise me';
  bool _generating = false;
  String? _aiMessage;
  List<Mission> _aiMissions = [];

  @override
  void initState() {
    super.initState();
    _preference =
        ref.read(repositoryProvider).prefs.getString('ai_mission_preference') ??
            _preference;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Mission> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return missions.where((mission) {
      final categoryMatch = _category == 'All' || mission.category == _category;
      final searchMatch = query.isEmpty ||
          '${mission.title} ${mission.description} ${mission.category}'
              .toLowerCase()
              .contains(query);
      return categoryMatch && searchMatch;
    }).toList();
  }

  void _surprise(List<Mission> options) {
    if (options.isEmpty) return;
    setState(() {
      _surprisePick = options[Random.secure().nextInt(options.length)];
      _surpriseCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return YoloScaffold(
      title: 'Explore Missions',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
        children: [
          _personalizedPanel(),
          if (_aiMissions.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(2, 16, 2, 9),
              child: Text('MADE FOR THIS MOMENT',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: .8)),
            ),
            for (final mission in _aiMissions)
              MissionCard(
                  mission: mission,
                  onTap: () => showMissionDetails(context, ref, mission)),
          ],
          AnimatedEntrance(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: YoloColors.ink,
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33202020), offset: Offset(4, 5))
                  ]),
              child: Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('40 tiny adventures.',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.4)),
                      const SizedBox(height: 4),
                      const Text('Zero pressure. Pick what feels good.',
                          style: TextStyle(
                              color: Color(0xFFD9D7D0), fontSize: 12)),
                      const SizedBox(height: 12),
                      Material(
                        color: YoloColors.red,
                        borderRadius: BorderRadius.circular(13),
                        child: InkWell(
                          onTap: filtered.isEmpty
                              ? null
                              : () => _surprise(filtered),
                          borderRadius: BorderRadius.circular(13),
                          child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 9),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    MediaQuery.disableAnimationsOf(context)
                                        ? const Icon(Icons.shuffle_rounded,
                                            color: Colors.white, size: 16)
                                        : AnimatedRotation(
                                            turns: _surpriseCount.toDouble(),
                                            duration: const Duration(
                                                milliseconds: 600),
                                            curve: Curves.easeOutBack,
                                            child: const Icon(
                                                Icons.shuffle_rounded,
                                                color: Colors.white,
                                                size: 16)),
                                    const SizedBox(width: 7),
                                    const Text('SURPRISE ME',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: .6)),
                                  ])),
                        ),
                      ),
                    ])),
                const SizedBox(width: 8),
                const _MissionSparkle(),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() => _surprisePick = null),
            decoration: InputDecoration(
              hintText: 'Search by name or vibe',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _surprisePick = null);
                      }),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0x33202020))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0x33202020))),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final selected = category == _category;
                return ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _category = category;
                    _surprisePick = null;
                  }),
                  backgroundColor: Colors.white,
                  selectedColor: YoloColors.yellow,
                  side: BorderSide(
                      color:
                          YoloColors.ink.withValues(alpha: selected ? .85 : .2),
                      width: selected ? 1.5 : 1),
                  labelStyle: TextStyle(
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                      fontSize: 11),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                );
              },
            ),
          ),
          if (_surprisePick case final pick?) ...[
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 420),
              transitionBuilder: (child, animation) => ScaleTransition(
                  scale: CurvedAnimation(
                      parent: animation, curve: Curves.elasticOut),
                  child: FadeTransition(opacity: animation, child: child)),
              child: Container(
                key: ValueKey('pick-${pick.id}-$_surpriseCount'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: YoloColors.yellow.withValues(alpha: .45),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: YoloColors.ink, width: 2)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 18, color: YoloColors.red),
                        SizedBox(width: 6),
                        Text('YOUR WILD CARD',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .9))
                      ]),
                      const SizedBox(height: 7),
                      MissionCard(
                          mission: pick,
                          onTap: () => showMissionDetails(context, ref, pick)),
                    ]),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 17, 2, 9),
            child: Row(children: [
              Text(
                  '${filtered.length} ${filtered.length == 1 ? 'adventure' : 'adventures'}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 15)),
              const Spacer(),
              if (_category != 'All' || _searchController.text.isNotEmpty)
                TextButton(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _category = 'All';
                        _surprisePick = null;
                      });
                    },
                    child: const Text('Clear filters')),
            ]),
          ),
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: YoloColors.ink, width: 2)),
              child: const Column(children: [
                Icon(Icons.search_off_rounded, size: 35),
                SizedBox(height: 8),
                Text('No adventures found. Try another vibe.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w800))
              ]),
            )
          else
            for (final (index, mission) in filtered.indexed)
              AnimatedEntrance(
                key: ValueKey(
                    '${mission.id}-$_category-${_searchController.text}'),
                delay: Duration(milliseconds: index < 8 ? index * 45 : 0),
                child: MissionCard(
                    mission: mission,
                    onTap: () => showMissionDetails(context, ref, mission)),
              ),
        ],
      ),
    );
  }

  Widget _personalizedPanel() {
    final prefs = ref.read(repositoryProvider).prefs;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFFE879), Color(0xFFFFC8A7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: YoloColors.ink, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x33202020), offset: Offset(3, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.auto_awesome_rounded, color: YoloColors.red),
          SizedBox(width: 8),
          Expanded(
              child: Text('A little adventure, made for you',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)))
        ]),
        const SizedBox(height: 5),
        const Text(
            'Fast Gemini Flash-Lite dreams up 3 ten-minute missions from your vibe, nearby weather and recent adventures.',
            style: TextStyle(fontSize: 12, height: 1.35)),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 4, children: [
          for (final option in _preferences)
            ChoiceChip(
                label: Text(option),
                selected: _preference == option,
                onSelected: _generating
                    ? null
                    : (_) async {
                        setState(() => _preference = option);
                        await prefs.setString('ai_mission_preference', option);
                      },
                visualDensity: VisualDensity.compact),
        ]),
        const SizedBox(height: 8),
        SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _generating ? null : _makePersonalizedMissions,
              icon: _generating
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.casino_rounded),
              label: Text(
                  _generating
                      ? 'DREAMING UP MISSIONS…'
                      : 'MAKE 3 WITH GEMINI FLASH-LITE',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              style: FilledButton.styleFrom(
                  backgroundColor: YoloColors.ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13)),
            )),
        if (_aiMessage != null) ...[
          const SizedBox(height: 8),
          Text(_aiMessage!,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 7),
        Text(
            'On tap, your location is used for a local Open-Meteo forecast and rounded before it is shared with Google Gemini alongside your vibe and recent missions. Weather needs no API key; if unavailable, Gemini still creates missions. Weather data by Open-Meteo (CC BY 4.0).',
            style: TextStyle(
                fontSize: 10,
                height: 1.3,
                color: YoloColors.ink.withValues(alpha: .72))),
      ]),
    );
  }

  Future<void> _makePersonalizedMissions() async {
    setState(() {
      _generating = true;
      _aiMessage = null;
      _aiMissions = [];
    });
    try {
      final repo = ref.read(repositoryProvider);
      final availability = await _personalizer.availability();
      if (availability == 'missing_key') {
        throw const MissionGenerationException(
            'Add a Gemini API key with --dart-define=GEMINI_API_KEY=your_key to enable Gemini Flash.');
      }
      final recent = repo.history
          .take(8)
          .map((entry) => '${entry.status}: ${entry.title}')
          .toList();
      final generated = await _personalizer.generate(
          preference: _preference,
          recentHistory: recent,
          username: repo.username,
          onProgress: (stage) {
            if (mounted) setState(() => _aiMessage = stage);
          },
          onPartialMissions: (partial) {
            if (mounted) {
              setState(() {
                _aiMissions = partial;
                _aiMessage = 'A mission is ready… ${partial.length}/3';
              });
            }
          });
      if (!mounted) return;
      setState(() {
        _aiMissions = generated;
        _aiMessage = 'Fresh ideas, made for you ✨';
      });
    } on MissionGenerationException catch (error) {
      if (mounted) setState(() => _aiMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _aiMessage =
            'Could not make missions right now. Check the setup and try again.');
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }
}

class _MissionSparkle extends StatefulWidget {
  const _MissionSparkle();

  @override
  State<_MissionSparkle> createState() => _MissionSparkleState();
}

class _MissionSparkleState extends State<_MissionSparkle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const artwork = _MissionSparkleArtwork();
    if (MediaQuery.disableAnimationsOf(context)) return artwork;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final value = Curves.easeOutBack.transform(_controller.value);
        return Transform.rotate(
          angle: (1 - value) * .4,
          child: Transform.scale(scale: value, child: artwork),
        );
      },
    );
  }
}

class _MissionSparkleArtwork extends StatelessWidget {
  const _MissionSparkleArtwork();

  @override
  Widget build(BuildContext context) => Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: YoloColors.yellow,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: const Icon(Icons.explore_rounded, size: 38),
      );
}
