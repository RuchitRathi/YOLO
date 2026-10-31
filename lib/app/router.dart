import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/chaos/chaos_screen.dart';
import '../features/decision/decide_screen.dart';
import '../features/home/home_screen.dart';
import '../features/memories/memories_screen.dart';
import '../features/missions/missions_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/squad/squad_screen.dart';

CustomTransitionPage<void> _page(Widget child, GoRouterState state) =>
    CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 240),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        if (reduceMotion) return child;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.025, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
        path: '/splash',
        pageBuilder: (_, state) => _page(const SplashScreen(), state)),
    GoRoute(
        path: '/', pageBuilder: (_, state) => _page(const HomeScreen(), state)),
    GoRoute(
        path: '/onboarding',
        pageBuilder: (_, state) => _page(const OnboardingScreen(), state)),
    GoRoute(
        path: '/chaos',
        pageBuilder: (_, state) => _page(const ChaosScreen(), state)),
    GoRoute(
        path: '/decide',
        pageBuilder: (_, state) => _page(const DecideScreen(), state)),
    GoRoute(
        path: '/missions',
        pageBuilder: (_, state) => _page(const MissionsScreen(), state)),
    GoRoute(
        path: '/memories',
        pageBuilder: (_, state) => _page(const MemoriesScreen(), state)),
    GoRoute(
        path: '/profile',
        pageBuilder: (_, state) => _page(const ProfileScreen(), state)),
    GoRoute(
        path: '/squad',
        pageBuilder: (_, state) => _page(const SquadScreen(), state)),
  ],
);
