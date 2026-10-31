import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.58, curve: Curves.elasticOut),
    );
    _rotation = Tween<double>(begin: -0.08, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.58, curve: Curves.easeOutBack),
      ),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          mounted &&
          GoRouter.of(context).state.uri.path == '/splash') {
        context.go('/');
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Transform.rotate(
                angle: _rotation.value,
                child: Transform.scale(scale: _scale.value, child: child),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 132,
                    height: 132,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: YoloColors.yellow,
                      border: Border.all(color: YoloColors.ink, width: 4),
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: const [
                        BoxShadow(color: YoloColors.ink, offset: Offset(7, 8)),
                      ],
                    ),
                    child: const Text(
                      'YOLO!',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'STOP THINKING.\nSTART LIVING.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
