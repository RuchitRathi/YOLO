import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'data/repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supabase = await _initializeSupabaseIfConfigured();
  final preferences = await SharedPreferences.getInstance();
  final repository = YoloRepository(preferences, supabase: supabase);
  final container = ProviderContainer(
    overrides: [
      preferencesProvider.overrideWithValue(preferences),
      repositoryProvider.overrideWithValue(repository),
    ],
  );
  runApp(UncontrolledProviderScope(
    container: container,
    child: const YoloApp(),
  ));
  unawaited(repository.syncCloud().then((_) {
    container.read(progressRevisionProvider.notifier).state++;
  }));
}

Future<SupabaseClient?> _initializeSupabaseIfConfigured() async {
  const url = String.fromEnvironment('SUPABASE_URL');
  const publishableKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isEmpty || publishableKey.isEmpty) return null;
  try {
    await Supabase.initialize(url: url, publishableKey: publishableKey);
    final client = Supabase.instance.client;
    if (client.auth.currentSession == null) {
      try {
        await client.auth
            .signInAnonymously()
            .timeout(const Duration(seconds: 4));
      } catch (_) {
        // Local progress remains usable if anonymous sign-in is unavailable.
      }
    }
    return client;
  } catch (_) {
    // Local demo mode remains available if Supabase setup or network is unavailable.
    return null;
  }
}
