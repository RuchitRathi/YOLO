import 'package:flutter/material.dart';

import '../../app/theme.dart';

class YoloScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget> actions;

  const YoloScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          actions: actions,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [YoloColors.background, Color(0xFFEAF6F0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            const _PlayfulBackdrop(),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: SizedBox(width: double.infinity, child: child),
                ),
              ),
            ),
          ],
        ),
      );
}

class _PlayfulBackdrop extends StatefulWidget {
  const _PlayfulBackdrop();

  @override
  State<_PlayfulBackdrop> createState() => _PlayfulBackdropState();
}

class _PlayfulBackdropState extends State<_PlayfulBackdrop>
    with SingleTickerProviderStateMixin {
  bool? _reducedMotion;
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4600),
  )..repeat(reverse: true);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion == reduceMotion) return;
    _reducedMotion = reduceMotion;
    if (reduceMotion) {
      _float.stop();
    } else {
      _float.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _float,
        builder: (context, _) {
          final drift = reduceMotion ? 0.0 : _float.value * 13;
          return Stack(children: [
            Positioned(
              top: 42 + drift,
              right: -16,
              child: Transform.rotate(
                angle: reduceMotion ? .15 : .15 + _float.value * .14,
                child: Icon(Icons.auto_awesome_rounded,
                    size: 76, color: YoloColors.yellow.withValues(alpha: .23)),
              ),
            ),
            Positioned(
              left: -25,
              bottom: 74 - drift,
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: YoloColors.red.withValues(alpha: .07), width: 18),
                ),
              ),
            ),
            Positioned(
              top: 220 - drift * .55,
              left: 27,
              child: Icon(Icons.star_rounded,
                  size: 20, color: YoloColors.red.withValues(alpha: .14)),
            ),
          ]);
        },
      ),
    );
  }
}
