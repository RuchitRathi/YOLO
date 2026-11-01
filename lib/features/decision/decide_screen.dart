import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/repository.dart';
import '../../shared/widgets/animated_entrance.dart';
import '../../shared/widgets/comic_components.dart';
import '../../shared/widgets/yolo_scaffold.dart';

class DecideScreen extends StatefulWidget {
  const DecideScreen({super.key});

  @override
  State<DecideScreen> createState() => _DecideScreenState();
}

class _DecideScreenState extends State<DecideScreen>
    with SingleTickerProviderStateMixin {
  final _options = <String>['Walk', 'Make a snack', 'Text a friend'];
  final _input = TextEditingController();
  late final AnimationController _spinController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  String? _winner;
  String? _pendingWinner;
  double _currentAngle = 0;
  double _targetAngle = 0;

  bool get _spinning => _spinController.isAnimating;

  @override
  void initState() {
    super.initState();
    _spinController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _currentAngle = _targetAngle % (2 * math.pi);
          _winner = _pendingWinner;
          _pendingWinner = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _spinController.dispose();
    super.dispose();
  }

  void _addOption() {
    final option = _input.text.trim();
    if (_spinning || option.isEmpty || _options.length >= 12) return;
    setState(() {
      _options.add(option);
      _winner = null;
    });
    _input.clear();
  }

  void _removeOption(int index) {
    if (_spinning || _options.length <= 2) return;
    setState(() {
      _options.removeAt(index);
      _winner = null;
    });
  }

  void _spin() {
    if (_spinning || _options.length < 2) return;
    final winner = chooseOption(_options);
    final index = _options.indexOf(winner);
    final sector = 2 * math.pi / _options.length;
    final aligned = (-(index + .5) * sector) % (2 * math.pi);
    final offset = (aligned - _currentAngle) % (2 * math.pi);
    _pendingWinner = winner;
    _targetAngle = _currentAngle + 2 * math.pi * 5 + offset;
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() {
        _currentAngle = _targetAngle % (2 * math.pi);
        _winner = winner;
      });
      _pendingWinner = null;
      return;
    }
    setState(() => _winner = null);
    _spinController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) => YoloScaffold(
        title: 'Decide for Me',
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: Column(
            children: [
              AnimatedEntrance(
                child: Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Give fate a spin.',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 3),
                        const Text('Pick 2–12 options. The wheel picks one.'),
                      ])),
                  const Icon(Icons.casino_rounded,
                      size: 29, color: YoloColors.red),
                ]),
              ),
              const SizedBox(height: 5),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    maxLength: 80,
                    enabled: !_spinning && _options.length < 12,
                    onSubmitted: (_) => _addOption(),
                    decoration: InputDecoration(
                      labelText: _options.length >= 12
                          ? '12 options max'
                          : 'Add an option',
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed:
                      _spinning || _options.length >= 12 ? null : _addOption,
                  tooltip: 'Add option',
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                      backgroundColor: YoloColors.yellow,
                      foregroundColor: YoloColors.ink,
                      side: const BorderSide(color: YoloColors.ink, width: 2)),
                ),
              ]),
              SizedBox(
                height: 212,
                child: Center(
                  child: _SpinWheel(
                    options: _options,
                    controller: _spinController,
                    currentAngle: _currentAngle,
                    targetAngle: _targetAngle,
                    spinning: _spinning,
                    onTap: _spin,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: _options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) => ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    tileColor: _winner == _options[index]
                        ? YoloColors.yellow.withValues(alpha: .5)
                        : Colors.white,
                    leading: Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                            color: YoloColors.background,
                            shape: BoxShape.circle),
                        child: Text('${index + 1}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 12))),
                    title: Text(_options[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    trailing: IconButton(
                      tooltip: 'Remove ${_options[index]}',
                      icon: const Icon(Icons.close_rounded, size: 19),
                      onPressed: _options.length > 2 && !_spinning
                          ? () => _removeOption(index)
                          : null,
                    ),
                  ),
                ),
              ),
              if (_winner != null)
                AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 360),
                  transitionBuilder: (child, animation) => ScaleTransition(
                      scale: CurvedAnimation(
                          parent: animation, curve: Curves.elasticOut),
                      child: FadeTransition(opacity: animation, child: child)),
                  child: Container(
                    key: ValueKey(_winner),
                    margin: const EdgeInsets.only(bottom: 9),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                        color: YoloColors.yellow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: YoloColors.ink, width: 2)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.celebration_rounded, size: 19),
                      const SizedBox(width: 7),
                      Text('$_winner!',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 16)),
                    ]),
                  ),
                ),
              YoloButton(
                  label: _spinning
                      ? 'THE WHEEL IS SPINNING…'
                      : _winner == null
                          ? 'SPIN THE WHEEL!'
                          : 'SPIN AGAIN!',
                  onPressed: _spinning ? null : _spin),
            ],
          ),
        ),
      );
}

class _SpinWheel extends StatelessWidget {
  const _SpinWheel(
      {required this.options,
      required this.controller,
      required this.currentAngle,
      required this.targetAngle,
      required this.spinning,
      required this.onTap});
  final List<String> options;
  final AnimationController controller;
  final double currentAngle;
  final double targetAngle;
  final bool spinning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: spinning ? null : onTap,
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final eased = Curves.easeOutQuart.transform(controller.value);
            final angle = currentAngle + (targetAngle - currentAngle) * eased;
            return SizedBox(
              width: 212,
              height: 212,
              child: Stack(alignment: Alignment.center, children: [
                Transform.rotate(
                  angle: angle,
                  child: CustomPaint(
                      size: const Size(196, 196),
                      painter: _WheelPainter(options)),
                ),
                const Positioned(
                    top: 0,
                    child: Icon(Icons.arrow_drop_down_rounded,
                        size: 42, color: YoloColors.red)),
                Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: YoloColors.ink, width: 2),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x55202020), offset: Offset(1, 2))
                        ])),
                if (spinning)
                  Positioned(
                      bottom: 1,
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: YoloColors.ink,
                              borderRadius: BorderRadius.circular(20)),
                          child: const Text('GOOD LUCK!',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: .8)))),
              ]),
            );
          },
        ),
      );
}

class _WheelPainter extends CustomPainter {
  const _WheelPainter(this.options);
  final List<String> options;
  static const _colors = [
    YoloColors.yellow,
    YoloColors.red,
    YoloColors.blue,
    YoloColors.sage,
    YoloColors.yellow,
    YoloColors.mauve
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 3;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final step = 2 * math.pi / options.length;
    final fill = Paint()..style = PaintingStyle.fill;
    final line = Paint()
      ..color = YoloColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < options.length; i++) {
      final start = -math.pi / 2 + i * step;
      fill.color = _colors[i % _colors.length];
      canvas.drawArc(rect, start, step, true, fill);
      canvas.drawArc(rect, start, step, true, line);
      final mid = start + step / 2;
      final label = options[i].length > 12
          ? '${options[i].substring(0, 11)}…'
          : options[i];
      final painter = TextPainter(
        text: TextSpan(
            text: label,
            style: const TextStyle(
                color: YoloColors.ink,
                fontSize: 10,
                fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: radius * .72);
      canvas.save();
      canvas.translate(center.dx + math.cos(mid) * radius * .56,
          center.dy + math.sin(mid) * radius * .56);
      var labelAngle = mid + math.pi / 2;
      if (labelAngle > math.pi / 2 && labelAngle < 3 * math.pi / 2) {
        labelAngle += math.pi;
      }
      canvas.rotate(labelAngle);
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
      canvas.restore();
    }
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = YoloColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      oldDelegate.options != options;
}
