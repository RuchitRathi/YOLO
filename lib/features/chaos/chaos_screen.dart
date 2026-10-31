import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/repository.dart';
import '../../shared/widgets/animated_entrance.dart';
import '../../shared/widgets/comic_components.dart';
import '../../shared/widgets/mission_details_sheet.dart';
import '../../shared/widgets/yolo_scaffold.dart';

class ChaosScreen extends ConsumerStatefulWidget {
  const ChaosScreen({super.key});

  @override
  ConsumerState<ChaosScreen> createState() => _ChaosScreenState();
}

class _ChaosScreenState extends ConsumerState<ChaosScreen>
    with SingleTickerProviderStateMixin {
  String mood = 'Bored';
  String time = '15 minutes';
  String budget = 'Free';
  String environment = 'Both';
  String category = 'Entertainment';
  Mission? result;
  Mission? _pendingResult;
  late final AnimationController _rollController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1450),
  );

  bool get _rolling => _rollController.isAnimating;

  @override
  void initState() {
    super.initState();
    _rollController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          result = _pendingResult;
          _pendingResult = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _rollController.dispose();
    super.dispose();
  }

  void _rollChaos() {
    final minutes = int.parse(time.split(' ').first);
    final maxBudget = switch (budget) {
      'Free' => 0,
      '₹100' => 100,
      '₹300' => 300,
      _ => 999999,
    };
    _pendingResult = recommendMission(
      missions,
      mood: mood,
      minutes: minutes,
      budget: maxBudget,
      environment: environment,
      category: category,
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => result = _pendingResult);
      _pendingResult = null;
      return;
    }
    setState(() => result = null);
    _rollController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) => YoloScaffold(
        title: 'Chaos Mode',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            AnimatedEntrance(
              child: Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Let’s make today less same-y.',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 5),
                        const Text('Set a vibe, then let the dice decide.'),
                      ]),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.auto_awesome_rounded,
                    color: YoloColors.red, size: 30),
              ]),
            ),
            const SizedBox(height: 14),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 80),
              child: _DiceStage(controller: _rollController),
            ),
            const SizedBox(height: 14),
            _choice(
                'Mood',
                mood,
                [
                  'Happy',
                  'Bored',
                  'Stressed',
                  'Adventurous',
                  'Creative',
                  'Lazy'
                ],
                (value) => setState(() {
                      mood = value;
                      result = null;
                    })),
            _choice(
                'Time',
                time,
                ['5 minutes', '15 minutes', '30 minutes', '60 minutes'],
                (value) => setState(() {
                      time = value;
                      result = null;
                    })),
            _choice(
                'Budget',
                budget,
                ['Free', '₹100', '₹300', '₹500+'],
                (value) => setState(() {
                      budget = value;
                      result = null;
                    })),
            _choice(
                'Where?',
                environment,
                ['Indoor', 'Outdoor', 'Both'],
                (value) => setState(() {
                      environment = value;
                      result = null;
                    })),
            _choice(
                'Vibe',
                category,
                [
                  'Social',
                  'Creative',
                  'Learning',
                  'Entertainment',
                  'Adventure',
                  'Fitness'
                ],
                (value) => setState(() {
                      category = value;
                      result = null;
                    })),
            YoloButton(
                label: _rolling
                    ? 'ROLLING…'
                    : result == null
                        ? 'ROLL THE CHAOS'
                        : 'ROLL AGAIN',
                onPressed: _rolling ? null : _rollChaos),
            AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 450),
              switchInCurve: Curves.elasticOut,
              transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: FadeTransition(opacity: animation, child: child)),
              child: result == null
                  ? const SizedBox(key: ValueKey('no-result'), height: 12)
                  : Padding(
                      key: ValueKey(result!.id),
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _ResultConfettiLabel(),
                            const SizedBox(height: 8),
                            MissionCard(
                                mission: result!,
                                onTap: () =>
                                    showMissionDetails(context, ref, result!)),
                          ]),
                    ),
            ),
          ],
        ),
      );

  Widget _choice(String label, String value, List<String> options,
          ValueChanged<String> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0x33202020))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0x33202020))),
          ),
          items: options
              .map((option) =>
                  DropdownMenuItem(value: option, child: Text(option)))
              .toList(),
          onChanged: _rolling
              ? null
              : (next) {
                  if (next != null) onChanged(next);
                },
        ),
      );
}

class _DiceStage extends StatelessWidget {
  const _DiceStage({required this.controller});
  final AnimationController controller;
  static const _faces = [
    Icons.looks_one_rounded,
    Icons.looks_two_rounded,
    Icons.looks_3_rounded,
    Icons.looks_4_rounded,
    Icons.looks_5_rounded,
    Icons.looks_6_rounded
  ];

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final roll = controller.value;
          final faceIndex = (roll * 36).floor() % 6;
          final tumbling = controller.isAnimating &&
              !MediaQuery.disableAnimationsOf(context);
          final angle = tumbling ? math.sin(roll * math.pi * 20) * .16 : 0.0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
                color: YoloColors.ink,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x33202020), offset: Offset(3, 4))
                ]),
            child: Row(children: [
              Expanded(
                  child: Text(
                      tumbling ? 'Shake up your day…' : 'YOUR CHAOS ROLL',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .8,
                          fontSize: 11))),
              _Die(
                  face: _faces[faceIndex],
                  angle: angle,
                  color: YoloColors.yellow),
              const SizedBox(width: 9),
              _Die(
                  face: _faces[(faceIndex * 3 + 2) % 6],
                  angle: -angle,
                  color: YoloColors.red),
            ]),
          );
        },
      );
}

class _Die extends StatelessWidget {
  const _Die({required this.face, required this.angle, required this.color});
  final IconData face;
  final double angle;
  final Color color;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: angle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
              color: color,
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(13),
              boxShadow: const [
                BoxShadow(color: Color(0x55000000), offset: Offset(2, 3))
              ]),
          child: Icon(face, size: 31, color: YoloColors.ink),
        ),
      );
}

class _ResultConfettiLabel extends StatelessWidget {
  const _ResultConfettiLabel();

  @override
  Widget build(BuildContext context) => const Row(children: [
        Icon(Icons.celebration_rounded, color: YoloColors.red),
        SizedBox(width: 7),
        Text('THE DICE HAVE SPOKEN!',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: .8)),
      ]);
}
