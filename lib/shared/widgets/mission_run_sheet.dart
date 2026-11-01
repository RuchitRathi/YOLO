import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/repository.dart';
import 'mission_share_card.dart';

Future<void> showMissionRun(
  BuildContext context,
  WidgetRef ref,
  Mission mission, {
  Duration? demoDuration,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: YoloColors.background,
    builder: (sheetContext) => MissionRunSheet(
      mission: mission,
      demoDuration: demoDuration,
      onComplete: () async {
        final repo = ref.read(repositoryProvider);
        await repo.record(mission, 'completed');
        if (!sheetContext.mounted) return;
        ref.read(progressRevisionProvider.notifier).state++;
        Navigator.pop(sheetContext);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mission complete! +${mission.xp} XP 🎉')),
        );
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (context.mounted) showMissionShareCard(context, ref, mission);
      },
    ),
  );
}

class MissionRunSheet extends ConsumerStatefulWidget {
  const MissionRunSheet({
    super.key,
    required this.mission,
    required this.onComplete,
    this.demoDuration,
  });

  final Mission mission;
  final Future<void> Function() onComplete;
  final Duration? demoDuration;

  @override
  ConsumerState<MissionRunSheet> createState() => _MissionRunSheetState();
}

class _MissionRunSheetState extends ConsumerState<MissionRunSheet> {
  Timer? _timer;
  late final Future<void> _accepted;
  late final int _totalSeconds =
      widget.demoDuration?.inSeconds ?? widget.mission.duration * 60;
  late int _secondsLeft = _totalSeconds;
  bool _paused = false;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _accepted = ref.read(repositoryProvider).record(widget.mission, 'accepted');
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _paused || _secondsLeft <= 0) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft == 0) _timer?.cancel();
    });
  }

  String get _timeLabel {
    final minutes = _secondsLeft ~/ 60;
    final seconds = _secondsLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    _timer?.cancel();
    await _accepted;
    await widget.onComplete();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final progress = _totalSeconds == 0
        ? 1.0
        : 1 - (_secondsLeft / _totalSeconds).clamp(0.0, 1.0);
    final demo = widget.demoDuration != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            22, 18, 22, 22 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                  color: YoloColors.ink.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(
                child: Text(demo ? 'SAMPLE MISSION RUN' : 'MISSION RUN',
                    style: const TextStyle(
                        color: YoloColors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1))),
            if (demo)
              const Chip(
                  label: Text('30 SEC DEMO'),
                  visualDensity: VisualDensity.compact),
          ]),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(widget.mission.title,
                style: Theme.of(context).textTheme.headlineSmall),
          ),
          const SizedBox(height: 6),
          Align(
              alignment: Alignment.centerLeft,
              child: Text(widget.mission.description,
                  style: const TextStyle(height: 1.35))),
          const SizedBox(height: 22),
          SizedBox(
            width: 176,
            height: 176,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 11,
                  strokeCap: StrokeCap.round,
                  backgroundColor: YoloColors.yellow.withValues(alpha: .35),
                  color: YoloColors.red,
                ),
              ),
              AnimatedScale(
                scale: reduceMotion ? 1 : (_paused ? .94 : 1),
                duration: const Duration(milliseconds: 250),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_timeLabel,
                      style: const TextStyle(
                          fontSize: 39,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.5)),
                  Text(_secondsLeft == 0 ? 'TIME’S UP!' : 'TIME LEFT',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: YoloColors.ink, width: 1.5),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.checklist_rounded, color: YoloColors.red),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('YOUR MOVE',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8)),
                    const SizedBox(height: 5),
                    Text(widget.mission.instructions,
                        style: const TextStyle(height: 1.35)),
                  ])),
            ]),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _secondsLeft == 0
                    ? null
                    : () => setState(() => _paused = !_paused),
                icon: Icon(
                    _paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                label: Text(_paused ? 'RESUME' : 'PAUSE'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: _finishing ? null : _finish,
                icon: _finishing
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.celebration_rounded),
                label: Text(_finishing
                    ? 'SAVING…'
                    : 'I DID IT! +${widget.mission.xp} XP'),
                style: FilledButton.styleFrom(
                    backgroundColor: YoloColors.red,
                    foregroundColor: Colors.white),
              ),
            ),
          ]),
          const SizedBox(height: 7),
          const Text('Done early? Finish whenever you’ve completed the steps.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF66615A))),
        ]),
      ),
    );
  }
}
