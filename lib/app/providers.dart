import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repository.dart';

final preferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences must be overridden.'),
);
final repositoryProvider = Provider<YoloRepository>(
  (ref) => YoloRepository(ref.watch(preferencesProvider)),
);
final progressRevisionProvider = StateProvider<int>((ref) => 0);
