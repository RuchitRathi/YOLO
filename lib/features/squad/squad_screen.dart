import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/repository.dart';
import '../../shared/widgets/mission_details_sheet.dart';
import '../../shared/widgets/yolo_scaffold.dart';

class SquadScreen extends ConsumerStatefulWidget {
  const SquadScreen({super.key});

  @override
  ConsumerState<SquadScreen> createState() => _SquadScreenState();
}

class _SquadScreenState extends ConsumerState<SquadScreen> {
  static const _categories = [
    'Adventure',
    'Creative',
    'Social',
    'Fitness',
    'Learning',
    'Entertainment',
  ];
  static const _times = [5, 10, 15, 30, 60];
  static const _budgets = [0, 100, 250, 500, 1000];

  final _nameController = TextEditingController();
  final List<_CrewVote> _votes = [];
  int _playerCount = 2;
  int _minutes = 15;
  int _budget = 0;
  String _category = 'Adventure';
  String _environment = 'Both';
  String? _error;
  Mission? _consensus;
  bool _revealed = false;
  bool _wheelFinished = true;

  @override
  void initState() {
    super.initState();
    final name = ref.read(repositoryProvider).username.trim();
    _nameController.text = name.isEmpty ? 'Player 1' : name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int get _playerNumber => _votes.length + 1;

  void _lockVote() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Add a name or nickname to continue.');
      return;
    }

    final finalVote = _votes.length + 1 == _playerCount;
    setState(() {
      _votes.add(_CrewVote(
        name: name,
        category: _category,
        minutes: _minutes,
        budget: _budget,
        environment: _environment,
      ));
      _error = null;
      if (_votes.length == _playerCount) {
        _revealed = true;
        _consensus = _pickConsensus(_votes);
        _wheelFinished = _consensus == null;
      } else {
        _nameController.text = 'Player ${_votes.length + 1}';
        _category = 'Adventure';
        _minutes = 15;
        _budget = 0;
        _environment = 'Both';
      }
    });
    if (finalVote && _consensus != null) {
      final duration = MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 1750);
      Future<void>.delayed(duration, () {
        if (mounted) setState(() => _wheelFinished = true);
      });
    }
  }

  Mission? _pickConsensus(List<_CrewVote> votes) {
    if (votes.isEmpty) return null;
    final maxMinutes = votes.map((vote) => vote.minutes).reduce(min);
    final maxBudget = votes.map((vote) => vote.budget).reduce(min);
    final categoryCounts = <String, int>{};
    for (final vote in votes) {
      categoryCounts.update(vote.category, (count) => count + 1,
          ifAbsent: () => 1);
    }
    final indoor = votes.where((vote) => vote.environment == 'Indoor').length;
    final outdoor = votes.where((vote) => vote.environment == 'Outdoor').length;
    final environment = indoor == outdoor
        ? 'Both'
        : indoor > outdoor
            ? 'Indoor'
            : 'Outdoor';

    final eligible = missions
        .where((mission) =>
            mission.duration <= maxMinutes &&
            mission.budget <= maxBudget &&
            (environment == 'Both' ||
                mission.environment == 'Both' ||
                mission.environment == environment))
        .toList();
    eligible.sort((a, b) {
      final categoryScore = (categoryCounts[b.category] ?? 0)
          .compareTo(categoryCounts[a.category] ?? 0);
      if (categoryScore != 0) return categoryScore;
      final durationScore = a.duration.compareTo(b.duration);
      if (durationScore != 0) return durationScore;
      return a.budget.compareTo(b.budget);
    });
    if (eligible.isEmpty) return null;

    final topScore = categoryCounts[eligible.first.category] ?? 0;
    final topChoices = eligible
        .where((mission) => (categoryCounts[mission.category] ?? 0) == topScore)
        .take(3)
        .toList();
    return topChoices[Random.secure().nextInt(topChoices.length)];
  }

  void _startAgain() {
    setState(() {
      _votes.clear();
      _revealed = false;
      _consensus = null;
      _wheelFinished = true;
      _error = null;
      _category = 'Adventure';
      _minutes = 15;
      _budget = 0;
      _environment = 'Both';
      _nameController.text = ref.read(repositoryProvider).username;
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = 'Player 1';
      }
    });
  }

  @override
  Widget build(BuildContext context) => YoloScaffold(
        title: 'Crew Huddle',
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          children: [
            Text('Make the plot twist together.',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(
                'Pass one phone around. Everyone sets their limits and casts a private vote, then reveal a mission the whole crew can do.'),
            const SizedBox(height: 16),
            _privacyBanner(),
            const SizedBox(height: 18),
            if (!_revealed) ...[
              _playerCountPicker(),
              const SizedBox(height: 16),
              _voteForm(),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _lockVote,
                icon: const Icon(Icons.lock_rounded),
                label: Text(_playerNumber == _playerCount
                    ? 'LOCK VOTE & REVEAL THE MISSION'
                    : 'LOCK PLAYER $_playerNumber’S VOTE'),
                style: FilledButton.styleFrom(
                    backgroundColor: YoloColors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 9),
                Text(_error!,
                    style: const TextStyle(
                        color: YoloColors.red, fontWeight: FontWeight.w800)),
              ],
              const SizedBox(height: 10),
              Text(
                  _votes.isEmpty
                      ? 'Votes stay hidden until everyone has picked.'
                      : '${_votes.length} vote${_votes.length == 1 ? '' : 's'} locked. Pass the phone to Player $_playerNumber.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      color: YoloColors.ink.withValues(alpha: .7))),
            ] else
              _results(),
          ],
        ),
      );

  Widget _privacyBanner() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: YoloColors.mint.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: YoloColors.ink, width: 1.5),
        ),
        child:
            const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.phone_android_rounded, size: 21),
          SizedBox(width: 9),
          Expanded(
            child: Text(
                'SAME-DEVICE GROUP VOTE · No fake players, accounts, API keys, or network. Votes stay on this screen and reset when you leave.',
                style: TextStyle(fontSize: 11, height: 1.35)),
          ),
        ]),
      );

  Widget _playerCountPicker() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section('HOW MANY ADVENTURERS?'),
          Wrap(spacing: 7, children: [
            for (final count in [2, 3, 4, 5, 6])
              ChoiceChip(
                label: Text('$count'),
                selected: _playerCount == count,
                onSelected: _votes.isNotEmpty
                    ? null
                    : (_) => setState(() => _playerCount = count),
                selectedColor: YoloColors.yellow,
                backgroundColor: Colors.white,
                side: BorderSide(
                    color: YoloColors.ink,
                    width: _playerCount == count ? 1.5 : 1),
              ),
          ]),
          const SizedBox(height: 4),
          Text('Player $_playerNumber of $_playerCount',
              style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      );

  Widget _voteForm() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: YoloColors.ink, width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x22202020), offset: Offset(3, 4))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            key: ValueKey('crew-player-$_playerNumber'),
            controller: _nameController,
            maxLength: 24,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Your name or nickname',
              prefixIcon: Icon(Icons.person_outline_rounded),
              counterText: '',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'What sounds fun?'),
            items: _categories
                .map((value) =>
                    DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _minutes,
                decoration: const InputDecoration(labelText: 'Time'),
                items: _times
                    .map((value) => DropdownMenuItem(
                        value: value, child: Text('$value min')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _minutes = value);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _budget,
                decoration: const InputDecoration(labelText: 'Budget'),
                items: _budgets
                    .map((value) => DropdownMenuItem(
                        value: value,
                        child: Text(value == 0 ? '₹0' : '₹$value')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _budget = value);
                },
              ),
            ),
          ]),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _environment,
            decoration:
                const InputDecoration(labelText: 'Where works for you?'),
            items: const ['Both', 'Indoor', 'Outdoor']
                .map((value) => DropdownMenuItem(
                    value: value,
                    child: Text(value == 'Both' ? 'Anywhere' : value)))
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _environment = value);
            },
          ),
        ]),
      );

  Widget _results() {
    final maxMinutes = _votes.map((vote) => vote.minutes).reduce(min);
    final maxBudget = _votes.map((vote) => vote.budget).reduce(min);
    final names = _votes.map((vote) => vote.name).join(' · ');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TweenAnimationBuilder<double>(
        key: ValueKey('crew-reveal-${_votes.length}-${_consensus?.id}'),
        tween: Tween(begin: .82, end: 1),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 650),
        curve: Curves.elasticOut,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: child,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: YoloColors.yellow,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: YoloColors.ink, width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x33202020), offset: Offset(4, 5))
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.bolt_rounded, color: YoloColors.red),
              SizedBox(width: 7),
              Text('CREW CONSENSUS',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
            ]),
            const SizedBox(height: 9),
            if (_consensus == null) ...[
              Text('No mission fits everyone yet.',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              const Text(
                  'Try another huddle with a little more time or budget, or choose Anywhere.'),
            ] else if (!_wheelFinished) ...[
              _CrewWheelReveal(category: _consensus!.category),
            ] else ...[
              Text(_consensus!.title,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 5),
              Text(_consensus!.description),
              const SizedBox(height: 10),
              Wrap(spacing: 7, runSpacing: 6, children: [
                _constraintTag('${_consensus!.duration} min'),
                _constraintTag(_consensus!.budget == 0
                    ? 'Free'
                    : 'Up to ₹${_consensus!.budget}'),
                _constraintTag(_consensus!.environment),
              ]),
              const SizedBox(height: 8),
              Text('Fits everyone’s limits: ≤$maxMinutes min · ≤₹$maxBudget',
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800)),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: YoloColors.ink, width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('THE CREW',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .9)),
          const SizedBox(height: 4),
          Text(names, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text('$_playerCount votes · this device only',
              style: const TextStyle(fontSize: 10, color: Color(0xFF6B665E))),
        ]),
      ),
      const SizedBox(height: 14),
      if (_consensus != null && _wheelFinished)
        FilledButton.icon(
          onPressed: () => showMissionDetails(context, ref, _consensus!),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('START THE CREW MISSION'),
          style: FilledButton.styleFrom(
              backgroundColor: YoloColors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52)),
        ),
      OutlinedButton.icon(
        onPressed: _startAgain,
        icon: const Icon(Icons.replay_rounded),
        label: const Text('START A NEW HUDDLE'),
        style: OutlinedButton.styleFrom(
          foregroundColor: YoloColors.ink,
          side: const BorderSide(color: YoloColors.ink, width: 1.5),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    ]);
  }

  Widget _constraintTag(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
      );

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
      );
}

class _CrewVote {
  const _CrewVote({
    required this.name,
    required this.category,
    required this.minutes,
    required this.budget,
    required this.environment,
  });

  final String name;
  final String category;
  final int minutes;
  final int budget;
  final String environment;
}

class _CrewWheelReveal extends StatelessWidget {
  const _CrewWheelReveal({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    const categories = _SquadScreenState._categories;
    final index =
        categories.indexOf(category).clamp(0, categories.length - 1).toInt();
    final sweep = 2 * pi / categories.length;
    final turns = (6 * 2 * pi - (index + .5) * sweep).toDouble();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(children: [
        SizedBox(
          width: 220,
          height: 232,
          child: Stack(alignment: Alignment.topCenter, children: [
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: TweenAnimationBuilder<double>(
                key: ValueKey('crew-wheel-$category'),
                tween: Tween(begin: 0, end: turns),
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 1650),
                curve: Curves.decelerate,
                builder: (context, angle, child) => Transform.rotate(
                  angle: angle,
                  child: child,
                ),
                child: CustomPaint(
                  size: const Size.square(205),
                  painter: _CrewWheelPainter(category),
                ),
              ),
            ),
            const Positioned(
              top: -4,
              child: Icon(Icons.arrow_drop_down_rounded,
                  size: 48, color: YoloColors.red),
            ),
          ]),
        ),
        const Text('THE CREW’S VIBE IS SPINNING…',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .8)),
      ]),
    );
  }
}

class _CrewWheelPainter extends CustomPainter {
  const _CrewWheelPainter(this.winner);
  final String winner;

  static const categories = _SquadScreenState._categories;
  static const colors = [
    YoloColors.red,
    YoloColors.yellow,
    YoloColors.blue,
    YoloColors.sage,
    YoloColors.mauve,
    YoloColors.yellow,
  ];
  static const labels = [
    'ADVENTURE',
    'CREATIVE',
    'SOCIAL',
    'FITNESS',
    'LEARNING',
    'FUN',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 3;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    final sweep = 2 * pi / categories.length;

    for (var index = 0; index < categories.length; index++) {
      final selected = categories[index] == winner;
      final paint = Paint()
        ..color = colors[index]
        ..style = PaintingStyle.fill;
      canvas.drawArc(bounds, -pi / 2 + index * sweep, sweep, true, paint);
      canvas.drawArc(
        bounds,
        -pi / 2 + index * sweep,
        sweep,
        true,
        Paint()
          ..color = YoloColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      final text = TextPainter(
        text: TextSpan(
          text: labels[index],
          style: TextStyle(
            color: selected ? Colors.white : YoloColors.ink,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: .2,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: 54);
      final angle = -pi / 2 + (index + .5) * sweep;
      final labelCenter =
          center + Offset(cos(angle) * radius * .62, sin(angle) * radius * .62);
      text.paint(canvas, labelCenter - Offset(text.width / 2, text.height / 2));
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = YoloColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(center, 20, Paint()..color = YoloColors.ink);
    final centerText = TextPainter(
      text: const TextSpan(
          text: 'GO!',
          style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: .5)),
      textDirection: TextDirection.ltr,
    )..layout();
    centerText.paint(
        canvas, center - Offset(centerText.width / 2, centerText.height / 2));
  }

  @override
  bool shouldRepaint(covariant _CrewWheelPainter oldDelegate) =>
      oldDelegate.winner != winner;
}
