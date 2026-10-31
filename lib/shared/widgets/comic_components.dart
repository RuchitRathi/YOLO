import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/repository.dart';

class ComicCard extends StatelessWidget {
  final Widget child;
  final Color color;

  const ComicCard({super.key, required this.child, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: YoloColors.ink, width: 2),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x33202020), offset: Offset(4, 5)),
          ],
        ),
        child: child,
      );
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 10),
        child: Text(
          text,
          style:
              const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1),
        ),
      );
}

class ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  const ActionTile(
    this.title,
    this.subtitle,
    this.icon,
    this.color,
    this.onTap, {
    super.key,
    this.badge,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _AnimatedActionTile(
          title: title,
          subtitle: subtitle,
          icon: icon,
          color: color,
          onTap: onTap,
          badge: badge,
        ),
      );
}

class _AnimatedActionTile extends StatefulWidget {
  const _AnimatedActionTile(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.color,
      required this.onTap,
      this.badge});
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  @override
  State<_AnimatedActionTile> createState() => _AnimatedActionTileState();
}

class _AnimatedActionTileState extends State<_AnimatedActionTile> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          scale: _pressed ? .975 : (_hovered ? 1.015 : 1),
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutBack,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapCancel: () => setState(() => _pressed = false),
              onTapUp: (_) => setState(() => _pressed = false),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0x29202020),
                        offset: Offset(0, _hovered ? 7 : 4),
                        blurRadius: _hovered ? 8 : 0)
                  ],
                ),
                child: ComicCard(
                  color: widget.color,
                  child: Row(
                    children: [
                      AnimatedRotation(
                          duration: const Duration(milliseconds: 280),
                          turns: _hovered ? .06 : 0,
                          child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .86),
                                  borderRadius: BorderRadius.circular(14)),
                              child: Icon(widget.icon, size: 26))),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 17)),
                            const SizedBox(height: 2),
                            Text(widget.subtitle,
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      if (widget.badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                                color: YoloColors.ink.withValues(alpha: .08),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(widget.badge!,
                                style: const TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .4))),
                      ],
                      const SizedBox(width: 5),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class YoloButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const YoloButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: YoloColors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 17),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: YoloColors.ink, width: 2),
            ),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      );
}

class MissionCard extends StatelessWidget {
  final Mission mission;
  final VoidCallback onTap;
  const MissionCard({super.key, required this.mission, required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: ComicCard(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: _missionColor(mission.category)
                            .withValues(alpha: .24),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(_missionIcon(mission.category), size: 20),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                      child: Text(mission.category.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1))),
                  _MissionTag(
                      label: mission.difficulty.toUpperCase(),
                      color: YoloColors.background),
                  const SizedBox(width: 5),
                  const Icon(Icons.arrow_outward_rounded, size: 17),
                ]),
                const SizedBox(height: 11),
                Text(mission.title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.25)),
                const SizedBox(height: 4),
                Text(mission.description,
                    style: TextStyle(
                        color: YoloColors.ink.withValues(alpha: .72),
                        height: 1.3)),
                const SizedBox(height: 11),
                Wrap(spacing: 7, runSpacing: 6, children: [
                  _MissionTag(
                      label: '${mission.duration} MIN',
                      icon: Icons.schedule_rounded,
                      color: const Color(0xFFF0F0ED)),
                  _MissionTag(
                      label: mission.budget == 0
                          ? 'FREE'
                          : '${mission.currency}${mission.budget}',
                      icon: Icons.account_balance_wallet_outlined,
                      color: const Color(0xFFF0F0ED)),
                  _MissionTag(
                      label: '+${mission.xp} XP',
                      icon: Icons.bolt_rounded,
                      color: YoloColors.yellow),
                ]),
              ],
            ),
          ),
        ),
      );
}

class _MissionTag extends StatelessWidget {
  const _MissionTag({required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 12), const SizedBox(width: 4)],
          Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .35)),
        ]),
      );
}

IconData _missionIcon(String category) => switch (category) {
      'Adventure' => Icons.explore_rounded,
      'Creative' => Icons.palette_rounded,
      'Social' => Icons.forum_rounded,
      'Fitness' => Icons.bolt_rounded,
      'Learning' => Icons.lightbulb_rounded,
      _ => Icons.auto_awesome_rounded,
    };

Color _missionColor(String category) => switch (category) {
      'Adventure' => YoloColors.blue,
      'Creative' => YoloColors.red,
      'Social' => const Color(0xFF8DD6B5),
      'Fitness' => YoloColors.yellow,
      'Learning' => const Color(0xFFD5B4F2),
      _ => const Color(0xFFFFA94D),
    };
