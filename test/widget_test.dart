import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yolo_app/app/app.dart';
import 'package:yolo_app/app/providers.dart';
import 'package:yolo_app/app/router.dart';

void main() {
  testWidgets('home screen shows the YOLO actions', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    appRouter.go('/');
    await tester.pumpWidget(ProviderScope(
      overrides: [preferencesProvider.overrideWithValue(preferences)],
      child: const YoloApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('PICK YOUR PLOT TWIST'), findsOneWidget);
    expect(find.text('Chaos Mode'), findsOneWidget);
    expect(find.text('Decide for Me'), findsOneWidget);
    expect(find.text('Explore Missions'), findsOneWidget);
  });

  testWidgets('Crew Huddle collects real votes on one device', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    appRouter.go('/squad');
    await tester.pumpWidget(ProviderScope(
      overrides: [preferencesProvider.overrideWithValue(preferences)],
      child: const YoloApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('SAME-DEVICE GROUP VOTE'), findsOneWidget);
    final firstVoteButton = find.textContaining('LOCK PLAYER 1');
    await tester.ensureVisible(firstVoteButton);
    await tester.tap(firstVoteButton);
    await tester.pumpAndSettle();

    expect(find.text('Player 2 of 2'), findsOneWidget);
    final revealButton = find.text('LOCK VOTE & REVEAL THE MISSION');
    await tester.ensureVisible(revealButton);
    await tester.tap(revealButton);
    await tester.pumpAndSettle();

    expect(find.text('CREW CONSENSUS'), findsOneWidget);
    expect(find.textContaining('Adventurer · Player 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('completing a mission updates XP on the home screen',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    appRouter.go('/');
    await tester.pumpWidget(ProviderScope(
      overrides: [preferencesProvider.overrideWithValue(preferences)],
      child: const YoloApp(),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Explore Missions'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Make a tiny playlist'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Make a tiny playlist'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('I DID IT! +20 XP'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Mission complete! +20 XP'), findsOneWidget);
    await tester.tap(find.byTooltip('Close mission card'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('LEVEL 1  •  20 XP\n1 day streak'), findsOneWidget);
  });

  testWidgets('home layout stays usable at phone and wide breakpoints',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(360, 640), const Size(1280, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      appRouter.go('/');
      await tester.pumpWidget(ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(preferences)],
        child: const YoloApp(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('PICK YOUR PLOT TWIST'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets(
      'personalized panel shows local fallback missions without a Gemini key',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    appRouter.go('/missions');
    await tester.pumpWidget(ProviderScope(
      overrides: [preferencesProvider.overrideWithValue(preferences)],
      child: const YoloApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('A little adventure, made for you'), findsOneWidget);
    await tester.tap(find.text('MAKE 3 PERSONALIZED MISSIONS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Gemini is not configured'), findsOneWidget);
    expect(find.text('YOUR WILD CARD'), findsNothing);
    expect(find.text('A little adventure, made for you'), findsOneWidget);
  });
}
