import 'package:flutter/material.dart';

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
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          actions: actions,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        ),
      );
}
