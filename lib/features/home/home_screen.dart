import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/repository.dart';
import '../../shared/widgets/animated_entrance.dart';
import '../../shared/widgets/comic_components.dart';
import '../../shared/widgets/mission_details_sheet.dart';
import '../../shared/widgets/yolo_scaffold.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(progressRevisionProvider);
    final repo = ref.watch(repositoryProvider);
    final progress = (repo.xp % 100) / 100;
    return YoloScaffold(
      title: 'YOLO!',
      actions: [
        IconButton(
          tooltip: 'Replay intro',
          onPressed: () => context.go('/splash'),
          icon: const Icon(Icons.replay_rounded),
        ),
      ],
      child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 650;
        final hero = AnimatedEntrance(
          delay: const Duration(milliseconds: 100),
          duration: const Duration(milliseconds: 700),
          child: _AdventureHero(onTap: () => context.push('/chaos')),
        );
        final progressCard = AnimatedEntrance(
          delay: const Duration(milliseconds: 200),
          child: _ProgressCard(
            level: repo.level,
            xp: repo.xp,
            streak: repo.streak,
            progress: progress,
            completed: repo.completed,
          ),
        );
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedEntrance(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _Eyebrow('YOUR DAILY DOSE OF ADVENTURE'),
                            const SizedBox(height: 7),
                            Text(
                              'Hey, ${repo.username}!',
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(fontSize: 35),
                            ),
                            const SizedBox(height: 3),
                            Text('Ready to make today a story?',
                                style: TextStyle(
                                    color:
                                        YoloColors.ink.withValues(alpha: .68),
                                    fontSize: 15)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Open profile · Level ${repo.level}',
                        onPressed: () => context.push('/profile'),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 56, minHeight: 56),
                        icon: _AvatarBadge(level: repo.level),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (wide)
                  Row(children: [
                    Expanded(flex: 6, child: hero),
                    const SizedBox(width: 16),
                    Expanded(flex: 5, child: progressCard),
                  ])
                else ...[
                  hero,
                  const SizedBox(height: 16),
                  progressCard,
                ],
                const SectionTitle('PICK YOUR PLOT TWIST'),
                if (wide)
                  Row(children: [
                    Expanded(
                        child: _QuickActionCard(
                            title: 'Chaos Mode',
                            subtitle: 'Made for your mood',
                            icon: Icons.cyclone_rounded,
                            color: YoloColors.red,
                            onTap: () => context.push('/chaos'),
                            delay: 240)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _QuickActionCard(
                            title: 'Decide for Me',
                            subtitle: 'Spin the wheel',
                            icon: Icons.casino_rounded,
                            color: YoloColors.blue,
                            onTap: () => context.push('/decide'),
                            delay: 320)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _QuickActionCard(
                            title: 'Explore Missions',
                            subtitle: 'Browse adventures',
                            icon: Icons.explore_rounded,
                            color: YoloColors.yellow,
                            onTap: () => context.push('/missions'),
                            delay: 400)),
                  ])
                else ...[
                  AnimatedEntrance(
                    delay: const Duration(milliseconds: 260),
                    child: ActionTile(
                        'Chaos Mode',
                        'A mission that fits your mood',
                        Icons.cyclone_rounded,
                        YoloColors.red,
                        () => context.push('/chaos'),
                        badge: 'MADE FOR YOU'),
                  ),
                  AnimatedEntrance(
                    delay: const Duration(milliseconds: 340),
                    child: ActionTile(
                        'Decide for Me',
                        'Let fate pick from your options',
                        Icons.casino_rounded,
                        YoloColors.blue,
                        () => context.push('/decide'),
                        badge: 'SPIN THE WHEEL'),
                  ),
                  AnimatedEntrance(
                    delay: const Duration(milliseconds: 420),
                    child: ActionTile(
                        'Explore Missions',
                        'Find your next little adventure',
                        Icons.explore_rounded,
                        YoloColors.yellow,
                        () => context.push('/missions'),
                        badge: 'BROWSE ALL'),
                  ),
                ],
                const SectionTitle('YOUR WORLD'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _WorldChip(
                        icon: Icons.groups_rounded,
                        label: 'Squad YOLO',
                        onTap: () => context.push('/squad')),
                    _WorldChip(
                        icon: Icons.smart_toy_rounded,
                        label: 'Ask Shinchan',
                        onTap: () => context.push('/companion')),
                    _WorldChip(
                        icon: Icons.photo_album_outlined,
                        label: 'Memories',
                        onTap: () => context.push('/memories')),
                    _WorldChip(
                        icon: Icons.person_outline_rounded,
                        label: 'Profile',
                        onTap: () => context.push('/profile')),
                    _WorldChip(
                        icon: Icons.tune_rounded,
                        label: 'Preferences',
                        onTap: () => context.push('/onboarding')),
                  ],
                ),
                if (repo.history.isNotEmpty) ...[
                  const SectionTitle('LAST PLOT TWIST'),
                  Builder(builder: (context) {
                    final memory = repo.history.first;
                    return ActionTile(
                      memory.title,
                      '${memory.status.toUpperCase()}  •  ${memory.date}',
                      Icons.auto_awesome_rounded,
                      YoloColors.yellow,
                      () => _showLastMemory(context, ref, memory),
                      badge: 'OPEN MEMORY',
                    );
                  }),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: YoloColors.red),
      );
}

class _QuickActionCard extends StatefulWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.delay,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  @override
  State<_QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<_QuickActionCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => AnimatedEntrance(
        delay: Duration(milliseconds: widget.delay),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedScale(
            scale: _pressed ? .96 : (_hovered ? 1.025 : 1),
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutBack,
            child: Material(
              color: widget.color,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: widget.onTap,
                onTapDown: (_) => setState(() => _pressed = true),
                onTapUp: (_) => setState(() => _pressed = false),
                onTapCancel: () => setState(() => _pressed = false),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 132),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: YoloColors.ink, width: 2),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Color(0x33202020), offset: Offset(3, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedRotation(
                        turns: _hovered ? .08 : 0,
                        duration: const Duration(milliseconds: 240),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .85),
                              borderRadius: BorderRadius.circular(14)),
                          child: Icon(widget.icon, size: 25),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w900)),
                      Text(widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 54,
        height: 54,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
            left: 2,
            top: 1,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: YoloColors.yellow,
                shape: BoxShape.circle,
                border: Border.all(color: YoloColors.ink, width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0x29202020), offset: Offset(2, 3))
                ],
              ),
              child:
                  const Icon(Icons.sentiment_very_satisfied_rounded, size: 27),
            ),
          ),
          Positioned(
            right: -1,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: YoloColors.red,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text('L$level',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900)),
            ),
          ),
        ]),
      );
}

Future<void> _showLastMemory(
  BuildContext context,
  WidgetRef ref,
  Memory memory,
) async {
  Mission? mission;
  for (final item in missions) {
    if (item.title == memory.title) {
      mission = item;
      break;
    }
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Eyebrow('A MOMENT FROM YOUR STORY'),
            const SizedBox(height: 8),
            Text(memory.title,
                style: Theme.of(sheetContext).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('${memory.status.toUpperCase()}  •  ${memory.date}',
                style: const TextStyle(
                    color: YoloColors.red, fontWeight: FontWeight.w900)),
            if (mission != null) ...[
              const SizedBox(height: 14),
              Text(mission.description),
              const SizedBox(height: 8),
              Text('Your next step: ${mission.instructions}'),
              const SizedBox(height: 18),
              YoloButton(
                label: 'REVISIT THIS ADVENTURE',
                onPressed: () {
                  Navigator.pop(sheetContext);
                  showMissionDetails(context, ref, mission!);
                },
              ),
            ],
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AdventureHero extends StatelessWidget {
  const _AdventureHero({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: YoloColors.ink,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            constraints: const BoxConstraints(minHeight: 190),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: YoloColors.ink, width: 2),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x33202020),
                    offset: Offset(0, 7),
                    blurRadius: 0)
              ],
            ),
            child: LayoutBuilder(builder: (context, constraints) {
              final narrow = constraints.maxWidth < 450;
              final mascotWidth = narrow
                  ? (constraints.maxWidth * .28).clamp(78.0, 96.0)
                  : 116.0;
              final mascot = _ShinchanMascot(
                width: mascotWidth,
                height: mascotWidth * 1.46,
              );
              final intro = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: YoloColors.yellow,
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('TODAY IS YOURS',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2)),
                  ),
                  const SizedBox(height: 13),
                  Text('Make a little\nchaos.',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: narrow ? 27 : 34,
                          height: 1.02,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.4)),
                  const SizedBox(height: 9),
                  const Text('One small adventure can change the whole vibe.',
                      style: TextStyle(color: Color(0xFFD9D7D0), fontSize: 12)),
                ],
              );
              final action = Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: YoloColors.red,
                    borderRadius: BorderRadius.circular(14)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('FIND MY ADVENTURE',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: .7)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 16),
                ]),
              );

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: intro),
                      const SizedBox(width: 8),
                      mascot,
                    ]),
                    const SizedBox(height: 16),
                    action,
                  ],
                );
              }
              return Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [intro, const SizedBox(height: 16), action],
                  ),
                ),
                const SizedBox(width: 8),
                mascot,
              ]);
            }),
          ),
        ),
      );
}

class _ShinchanMascot extends StatefulWidget {
  const _ShinchanMascot({required this.width, required this.height});

  final double width;
  final double height;

  @override
  State<_ShinchanMascot> createState() => _ShinchanMascotState();
}

class _ShinchanMascotState extends State<_ShinchanMascot>
    with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final AnimationController _dance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  );

  @override
  void initState() {
    super.initState();
    _idle.addStatusListener((status) {
      if (status == AnimationStatus.completed) _idle.reverse();
    });
    _idle.forward();
  }

  @override
  void dispose() {
    _idle.dispose();
    _dance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Shinchan. Tap to make him dance.',
        child: GestureDetector(
          onTap: () => _dance.forward(from: 0),
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: AnimatedBuilder(
              animation: Listenable.merge([_idle, _dance]),
              builder: (context, _) {
                final idle = _idle.value;
                final dance = _dance.value;
                final danceFade = 1 - dance;
                final wiggle = math.sin(dance * math.pi * 10) * danceFade;
                final disabled = MediaQuery.disableAnimationsOf(context);
                final offset = disabled
                    ? Offset.zero
                    : Offset(
                        wiggle * 7,
                        -math.sin(dance * math.pi) * 10 +
                            math.sin(idle * math.pi) * 4);
                final angle = disabled
                    ? 0.0
                    : wiggle * .18 + math.sin(idle * math.pi * 2) * .025;
                return Transform.translate(
                  offset: offset,
                  child: Transform.rotate(
                    angle: angle,
                    child: Image.asset(
                      'assets/images/shinchan.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      excludeFromSemantics: true,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard(
      {required this.level,
      required this.xp,
      required this.streak,
      required this.progress,
      required this.completed});
  final int level;
  final int xp;
  final int streak;
  final double progress;
  final int completed;

  @override
  Widget build(BuildContext context) => ComicCard(
        color: YoloColors.yellow,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.bolt_rounded, size: 27)),
            const SizedBox(width: 12),
            Expanded(
                child: Text('LEVEL $level  •  $xp XP\n$streak day streak',
                    style: const TextStyle(
                        fontSize: 16,
                        height: 1.35,
                        fontWeight: FontWeight.w900))),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('$completed',
                  style: const TextStyle(
                      fontSize: 21, fontWeight: FontWeight.w900)),
              const Text('ADVENTURES',
                  style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .7))
            ]),
          ]),
          const SizedBox(height: 14),
          ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: .8),
                      color: YoloColors.red))),
          const SizedBox(height: 6),
          Text('${(progress * 100).round()}% to the next level',
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
        ]),
      );
}

class _WorldChip extends StatelessWidget {
  const _WorldChip(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
        avatar: Icon(icon, size: 17, color: YoloColors.ink),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        onPressed: onTap,
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0x22202020)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      );
}
