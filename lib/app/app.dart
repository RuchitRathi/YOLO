import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class YoloApp extends StatelessWidget {
  const YoloApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'YOLO! — Stop Thinking. Start Living.',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        routerConfig: appRouter,
      );
}
