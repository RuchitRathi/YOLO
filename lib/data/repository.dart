import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Mission {
  final String id, title, description, category, difficulty, environment;
  final List<String> moods;
  final int duration, budget, xp;
  final String instructions;
  final String currency;
  final String? fitReason;
  const Mission(
      {required this.id,
      required this.title,
      required this.description,
      required this.category,
      required this.moods,
      required this.duration,
      required this.budget,
      required this.difficulty,
      required this.xp,
      required this.environment,
      required this.instructions,
      this.currency = '₹',
      this.fitReason});
  Mission copyWith({String? fitReason}) => Mission(
        id: id,
        title: title,
        description: description,
        category: category,
        moods: moods,
        duration: duration,
        budget: budget,
        difficulty: difficulty,
        xp: xp,
        environment: environment,
        instructions: instructions,
        currency: currency,
        fitReason: fitReason ?? this.fitReason,
      );
  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'status': '', 'date': ''};
}

class Memory {
  final String title, status, date;
  final String? id;
  final int xpEarned;
  const Memory(this.title, this.status, this.date,
      {this.id, this.xpEarned = 0});
  Map<String, dynamic> toJson() => {
        'title': title,
        'status': status,
        'date': date,
        'id': id,
        'xpEarned': xpEarned
      };
  factory Memory.fromJson(Map<String, dynamic> j) =>
      Memory(j['title'] as String, j['status'] as String, j['date'] as String,
          id: j['id'] as String?,
          xpEarned: (j['xpEarned'] as num?)?.toInt() ?? 0);
}

class YoloRepository {
  final SharedPreferences prefs;
  final SupabaseClient? supabase;
  YoloRepository(this.prefs, {this.supabase});
  String get username => prefs.getString('username') ?? 'Adventurer';
  int get xp => prefs.getInt('xp') ?? 0;
  int get level => xp ~/ 100 + 1;
  int get streak => prefs.getInt('streak') ?? 1;
  int get completed => prefs.getInt('completed') ?? 0;
  List<Memory> get history => (prefs.getStringList('history') ?? [])
      .map((s) => Memory.fromJson(jsonDecode(s) as Map<String, dynamic>))
      .toList()
      .reversed
      .toList();
  Future<void> setUsername(String name) async {
    await prefs.setString('username', name);
    await _pushCloud();
  }

  Future<void> record(Mission mission, String status) async {
    final nextXp = xp + (status == 'completed' ? mission.xp : 0);
    await prefs.setInt('xp', nextXp);
    if (status == 'completed') await prefs.setInt('completed', completed + 1);
    final items = prefs.getStringList('history') ?? [];
    final now = DateTime.now().toLocal();
    final memoryId = 'local-${now.microsecondsSinceEpoch}';
    items.add(jsonEncode(Memory(
            mission.title, status, now.toString().split('.').first,
            id: memoryId, xpEarned: status == 'completed' ? mission.xp : 0)
        .toJson()));
    await prefs.setStringList('history', items);
    await _pushCloud();
  }

  Future<void> syncCloud() async {
    final client = supabase;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    try {
      final remoteProfile = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      if (remoteProfile != null) {
        if (username == 'Adventurer' &&
            (remoteProfile['username'] as String? ?? 'Adventurer') !=
                'Adventurer') {
          await prefs.setString(
              'username', remoteProfile['username'] as String);
        }
        final remoteXp = (remoteProfile['xp'] as num?)?.toInt() ?? 0;
        final remoteStreak = (remoteProfile['streak'] as num?)?.toInt() ?? 0;
        final remoteCompleted =
            (remoteProfile['completed'] as num?)?.toInt() ?? 0;
        if (remoteXp > xp) await prefs.setInt('xp', remoteXp);
        if (remoteStreak > streak) await prefs.setInt('streak', remoteStreak);
        if (remoteCompleted > completed) {
          await prefs.setInt('completed', remoteCompleted);
        }
      }

      final rows = await client
          .from('activity_history')
          .select('id,client_id,selected_option,status,created_at')
          .eq('user_id', userId)
          .eq('activity_type', 'mission')
          .order('created_at')
          .limit(500)
          .timeout(const Duration(seconds: 5));
      final stored = prefs.getStringList('history') ?? <String>[];
      final local = stored
          .map((value) =>
              Memory.fromJson(jsonDecode(value) as Map<String, dynamic>))
          .toList();
      var changed = false;
      for (var index = 0; index < local.length; index++) {
        final memory = local[index];
        if (memory.id == null) {
          local[index] = Memory(
            memory.title,
            memory.status,
            memory.date,
            id: 'legacy-${DateTime.now().microsecondsSinceEpoch}-$index',
          );
          changed = true;
        }
      }
      final knownIds =
          local.map((memory) => memory.id).whereType<String>().toSet();
      for (final row in rows) {
        final title = row['selected_option'] as String?;
        final status = row['status'] as String?;
        if (title == null || status == null) continue;
        final id = row['client_id'] as String? ?? 'cloud-${row['id']}';
        if (knownIds.add(id)) {
          final created =
              DateTime.tryParse(row['created_at'] as String? ?? '')?.toLocal();
          local.add(Memory(
              title, status, created?.toString().split('.').first ?? '',
              id: id));
          changed = true;
        }
      }
      if (changed) {
        await prefs.setStringList('history',
            local.map((memory) => jsonEncode(memory.toJson())).toList());
      }
      await _pushCloud();
    } catch (_) {
      // Keep local-first progress usable when the service or schema is unavailable.
    }
  }

  Future<void> _pushCloud() async {
    final client = supabase;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;
    try {
      await client.from('profiles').upsert({
        'id': userId,
        'username': username,
        'xp': xp,
        'level': level,
        'streak': streak,
        'completed': completed,
      }).timeout(const Duration(seconds: 4));
      final rows = history.where((memory) => memory.id != null).map((memory) {
        final created =
            DateTime.tryParse(memory.date)?.toUtc().toIso8601String();
        return <String, dynamic>{
          'user_id': userId,
          'client_id': memory.id,
          'activity_type': 'mission',
          'selected_option': memory.title,
          'status': memory.status,
          if (created != null) 'created_at': created,
          if (memory.status == 'completed' && created != null)
            'completed_at': created,
        };
      }).toList();
      if (rows.isNotEmpty) {
        await client
            .from('activity_history')
            .upsert(rows,
                onConflict: 'user_id,client_id', ignoreDuplicates: true)
            .timeout(const Duration(seconds: 4));
      }
    } catch (_) {
      // Local writes always succeed even when cloud sync is offline or misconfigured.
    }
  }
}

final missions = <Mission>[
  const Mission(
      id: 'm01',
      title: 'Make a tiny playlist',
      description: 'Build a five-song soundtrack for your current mood.',
      category: 'Creative',
      moods: ['Happy', 'Bored', 'Creative'],
      duration: 15,
      budget: 0,
      difficulty: 'Easy',
      xp: 20,
      environment: 'Indoor',
      instructions: 'Name the playlist and add five songs.'),
  const Mission(
      id: 'm02',
      title: 'Take the scenic route',
      description: 'Walk a familiar route and notice three new things.',
      category: 'Adventure',
      moods: ['Bored', 'Adventurous', 'Stressed'],
      duration: 30,
      budget: 0,
      difficulty: 'Easy',
      xp: 30,
      environment: 'Outdoor',
      instructions: 'Choose a safe public route and take your time.'),
  const Mission(
      id: 'm03',
      title: 'Sketch the nearest object',
      description: 'Draw something near you without lifting your pen.',
      category: 'Creative',
      moods: ['Creative', 'Bored'],
      duration: 15,
      budget: 0,
      difficulty: 'Easy',
      xp: 20,
      environment: 'Indoor',
      instructions: 'Use any paper. Keep it playful.'),
  const Mission(
      id: 'm04',
      title: 'Send a kind message',
      description: 'Let someone know one thing you appreciate about them.',
      category: 'Social',
      moods: ['Happy', 'Stressed', 'Lazy'],
      duration: 5,
      budget: 0,
      difficulty: 'Easy',
      xp: 15,
      environment: 'Indoor',
      instructions: 'Send a genuine, specific message.'),
  const Mission(
      id: 'm05',
      title: 'Learn a new word',
      description: 'Find a word you have never used and try it in a sentence.',
      category: 'Learning',
      moods: ['Curious', 'Bored', 'Creative'],
      duration: 5,
      budget: 0,
      difficulty: 'Easy',
      xp: 15,
      environment: 'Both',
      instructions: 'Look it up in a dictionary and write a sentence.'),
  const Mission(
      id: 'm06',
      title: 'Stretch break',
      description: 'Follow a gentle five-minute full-body stretch.',
      category: 'Fitness',
      moods: ['Stressed', 'Lazy', 'Happy'],
      duration: 5,
      budget: 0,
      difficulty: 'Easy',
      xp: 15,
      environment: 'Indoor',
      instructions: 'Move gently and stop if anything hurts.'),
  const Mission(
      id: 'm07',
      title: 'Cloud shapes',
      description: 'Find three shapes in the clouds or treetops.',
      category: 'Adventure',
      moods: ['Lazy', 'Bored', 'Happy'],
      duration: 15,
      budget: 0,
      difficulty: 'Easy',
      xp: 20,
      environment: 'Outdoor',
      instructions: 'Stay in a safe spot and let your imagination wander.'),
  const Mission(
      id: 'm08',
      title: 'Cook a new snack',
      description: 'Make a simple snack using ingredients already at home.',
      category: 'Creative',
      moods: ['Happy', 'Creative'],
      duration: 30,
      budget: 100,
      difficulty: 'Easy',
      xp: 30,
      environment: 'Indoor',
      instructions: 'Use safe kitchen habits and clean up afterward.'),
  const Mission(
      id: 'm09',
      title: 'Mini photo safari',
      description: 'Photograph five interesting patterns nearby.',
      category: 'Creative',
      moods: ['Adventurous', 'Creative', 'Bored'],
      duration: 30,
      budget: 0,
      difficulty: 'Easy',
      xp: 30,
      environment: 'Both',
      instructions: 'Photograph objects, not strangers.'),
  const Mission(
      id: 'm10',
      title: 'Dance to one song',
      description:
          'Put on a favorite song and dance like nobody is grading you.',
      category: 'Fitness',
      moods: ['Happy', 'Bored', 'Stressed'],
      duration: 5,
      budget: 0,
      difficulty: 'Easy',
      xp: 15,
      environment: 'Indoor',
      instructions: 'Make space and move at your own pace.'),
  const Mission(
      id: 'm11',
      title: 'Curiosity rabbit hole',
      description: 'Spend 15 minutes learning how something everyday works.',
      category: 'Learning',
      moods: ['Curious', 'Bored', 'Creative'],
      duration: 15,
      budget: 0,
      difficulty: 'Easy',
      xp: 20,
      environment: 'Indoor',
      instructions: 'Pick a safe topic and share one surprising fact.'),
  const Mission(
      id: 'm12',
      title: 'Plan a dream day',
      description: 'Design a no-pressure day out with a friend.',
      category: 'Social',
      moods: ['Happy', 'Adventurous'],
      duration: 30,
      budget: 100,
      difficulty: 'Easy',
      xp: 30,
      environment: 'Both',
      instructions: 'Make a plan that suits both people and budgets.'),
  const Mission(
      id: 'm13',
      title: 'Desk reset',
      description: 'Make your study space a little more inviting.',
      category: 'Entertainment',
      moods: ['Stressed', 'Lazy', 'Bored'],
      duration: 15,
      budget: 0,
      difficulty: 'Easy',
      xp: 20,
      environment: 'Indoor',
      instructions: 'Clear one surface and add one thing you enjoy.'),
  const Mission(
      id: 'm14',
      title: 'Invent a silly quiz',
      description: 'Write five funny questions for a friend or family member.',
      category: 'Social',
      moods: ['Happy', 'Creative'],
      duration: 15,
      budget: 0,
      difficulty: 'Easy',
      xp: 20,
      environment: 'Both',
      instructions: 'Keep questions kind and answerable.'),
  const Mission(
      id: 'm15',
      title: 'Neighborhood colors',
      description: 'Find something red, yellow, blue, green, and purple.',
      category: 'Adventure',
      moods: ['Bored', 'Adventurous'],
      duration: 30,
      budget: 0,
      difficulty: 'Easy',
      xp: 30,
      environment: 'Outdoor',
      instructions: 'Stay on familiar public paths.'),
  const Mission(
      id: 'm16',
      title: 'Draw a comic panel',
      description: 'Turn a tiny everyday moment into a one-panel comic.',
      category: 'Creative',
      moods: ['Creative', 'Happy'],
      duration: 30,
      budget: 0,
      difficulty: 'Easy',
      xp: 30,
      environment: 'Indoor',
      instructions: 'Stick figures absolutely count.'),
  const Mission(
      id: 'm17',
      title: 'Learn a card trick',
      description: 'Practice one simple card trick and show someone.',
      category: 'Entertainment',
      moods: ['Adventurous', 'Creative'],
      duration: 30,
      budget: 0,
      difficulty: 'Medium',
      xp: 35,
      environment: 'Indoor',
      instructions: 'Use any standard deck and practice patiently.'),
  const Mission(
      id: 'm18',
      title: 'Five-minute tidy race',
      description: 'Set a timer and tidy one small area before it rings.',
      category: 'Fitness',
      moods: ['Bored', 'Stressed'],
      duration: 5,
      budget: 0,
      difficulty: 'Easy',
      xp: 15,
      environment: 'Indoor',
      instructions: 'Stop when the timer ends.'),
  const Mission(
      id: 'm19',
      title: 'Ask a grand question',
      description: 'Ask someone older what they loved doing at your age.',
      category: 'Social',
      moods: ['Curious', 'Happy'],
      duration: 15,
      budget: 0,
      difficulty: 'Easy',
      xp: 20,
      environment: 'Both',
      instructions: 'Listen to their story without rushing.'),
  const Mission(
      id: 'm20',
      title: 'Make a paper plane',
      description: 'Fold a paper plane and test three gentle designs.',
      category: 'Creative',
      moods: ['Bored', 'Creative'],
      duration: 15,
      budget: 0,
      difficulty: 'Easy',
      xp: 20,
      environment: 'Both',
      instructions: 'Fly it in a clear, safe space.'),
  const Mission(
      id: 'm21',
      title: 'Try box breathing',
      description: 'Practice a calm breathing pattern for a few minutes.',
      category: 'Fitness',
      moods: ['Stressed', 'Lazy'],
      duration: 5,
      budget: 0,
      difficulty: 'Easy',
      xp: 15,
      environment: 'Indoor',
      instructions: 'Breathe comfortably; stop if you feel dizzy.'),
  const Mission(
      id: 'm22',
      title: 'Local history hunt',
      description: 'Find one interesting fact about your town or campus.',
      category: 'Learning',
      moods: ['Curious', 'Adventurous'],
      duration: 30,
      budget: 0,
      difficulty: 'Easy',
      xp: 30,
      environment: 'Both',
      instructions: 'Use a library or trusted local source.'),
  const Mission(
      id: 'm23',
      title: 'Compliment chain',
      description: 'Give three sincere, specific compliments today.',
      category: 'Social',
      moods: ['Happy', 'Adventurous'],
      duration: 15,
      budget: 0,
      difficulty: 'Easy',
      xp: 20,
      environment: 'Both',
      instructions: 'Keep each compliment respectful and genuine.'),
  const Mission(
      id: 'm24',
      title: 'Make a mood board',
      description:
          'Collect colors, words, and images that match your dream weekend.',
      category: 'Creative',
      moods: ['Creative', 'Happy'],
      duration: 30,
      budget: 0,
      difficulty: 'Easy',
      xp: 30,
      environment: 'Indoor',
      instructions: 'Use paper or a digital canvas.'),
  const Mission(
      id: 'm25',
      title: 'Try a new playlist genre',
      description: 'Listen to a music style you rarely choose.',
      category: 'Entertainment',
      moods: ['Bored', 'Curious'],
      duration: 15,
      budget: 0,
      difficulty: 'Easy',
      xp: 20,
      environment: 'Both',
      instructions: 'Pick one favorite sound from it.'),
  const Mission(
      id: 'm26',
      title: 'Take the stairs',
      description: 'Choose a safe extra flight of stairs on your next trip.',
      category: 'Fitness',
      moods: ['Adventurous', 'Happy'],
      duration: 5,
      budget: 0,
      difficulty: 'Easy',
      xp: 15,
      environment: 'Both',
      instructions: 'Skip this if stairs are unsuitable for you.'),
  const Mission(
      id: 'm27',
      title: 'Origami minute',
      description: 'Fold a paper boat or fortune teller.',
      category: 'Creative',
      moods: ['Lazy', 'Creative'],
      duration: 15,
      budget: 0,
      difficulty: 'Easy',
      xp: 20,
      environment: 'Indoor',
      instructions: 'Find a simple diagram and give it a go.'),
  const Mission(
      id: 'm28',
      title: 'Design a secret handshake',
      description: 'Invent a harmless handshake with someone you know.',
      category: 'Social',
      moods: ['Happy', 'Bored'],
      duration: 15,
      budget: 0,
      difficulty: 'Easy',
      xp: 20,
      environment: 'Both',
      instructions: 'Ask first and keep it comfortable.'),
  const Mission(
      id: 'm29',
      title: 'A-to-Z scavenger hunt',
      description:
          'Spot five things nearby whose names start with different letters.',
      category: 'Adventure',
      moods: ['Bored', 'Adventurous'],
      duration: 15,
      budget: 0,
      difficulty: 'Easy',
      xp: 20,
      environment: 'Both',
      instructions: 'Explore only places where you are allowed.'),
  const Mission(
      id: 'm30',
      title: 'Teach-back',
      description: 'Explain something you learned recently in two minutes.',
      category: 'Learning',
      moods: ['Creative', 'Happy'],
      duration: 15,
      budget: 0,
      difficulty: 'Easy',
      xp: 20,
      environment: 'Both',
      instructions: 'Teach a friend or record a private voice note.'),
  const Mission(
      id: 'm31',
      title: 'Make a paper bookmark',
      description: 'Create a bookmark that makes you smile.',
      category: 'Creative',
      moods: ['Lazy', 'Creative'],
      duration: 15,
      budget: 0,
      difficulty: 'Easy',
      xp: 20,
      environment: 'Indoor',
      instructions: 'Use spare paper and decorate it.'),
  const Mission(
      id: 'm32',
      title: 'Friendly trivia round',
      description: 'Ask a friend five light-hearted trivia questions.',
      category: 'Entertainment',
      moods: ['Happy', 'Social'],
      duration: 15,
      budget: 0,
      difficulty: 'Easy',
      xp: 20,
      environment: 'Both',
      instructions: 'Pick fun general knowledge questions.'),
  const Mission(
      id: 'm33',
      title: 'Water and window',
      description:
          'Drink a glass of water and take a two-minute outside break.',
      category: 'Fitness',
      moods: ['Stressed', 'Lazy'],
      duration: 5,
      budget: 0,
      difficulty: 'Easy',
      xp: 15,
      environment: 'Both',
      instructions: 'Use a safe outdoor spot or open a window.'),
  const Mission(
      id: 'm34',
      title: 'Make a mini zine',
      description: 'Fold a sheet of paper into a tiny illustrated zine.',
      category: 'Creative',
      moods: ['Creative', 'Adventurous'],
      duration: 60,
      budget: 0,
      difficulty: 'Medium',
      xp: 45,
      environment: 'Indoor',
      instructions: 'Fill each panel with a thought, drawing, or joke.'),
  const Mission(
      id: 'm35',
      title: 'Visit a free public spot',
      description: 'Explore a nearby park, library, or public garden.',
      category: 'Adventure',
      moods: ['Adventurous', 'Stressed'],
      duration: 60,
      budget: 0,
      difficulty: 'Easy',
      xp: 45,
      environment: 'Outdoor',
      instructions: 'Check opening hours and arrange safe travel.'),
  const Mission(
      id: 'm36',
      title: 'No-phone snack break',
      description: 'Enjoy a snack slowly without looking at a screen.',
      category: 'Entertainment',
      moods: ['Stressed', 'Lazy'],
      duration: 15,
      budget: 100,
      difficulty: 'Easy',
      xp: 20,
      environment: 'Both',
      instructions: 'Notice the taste, smell, and texture.'),
  const Mission(
      id: 'm37',
      title: 'Language swap',
      description: 'Learn to say hello and thank you in a new language.',
      category: 'Learning',
      moods: ['Curious', 'Creative'],
      duration: 15,
      budget: 0,
      difficulty: 'Easy',
      xp: 20,
      environment: 'Indoor',
      instructions: 'Practice pronunciation with a trusted learning source.'),
  const Mission(
      id: 'm38',
      title: 'Build a blanket fort',
      description: 'Create a cozy reading or relaxing nook.',
      category: 'Entertainment',
      moods: ['Lazy', 'Creative'],
      duration: 30,
      budget: 0,
      difficulty: 'Easy',
      xp: 30,
      environment: 'Indoor',
      instructions: 'Keep exits clear and avoid unstable furniture.'),
  const Mission(
      id: 'm39',
      title: 'Family story time',
      description: 'Ask someone at home to share a favorite childhood memory.',
      category: 'Social',
      moods: ['Curious', 'Lazy'],
      duration: 30,
      budget: 0,
      difficulty: 'Easy',
      xp: 30,
      environment: 'Indoor',
      instructions: 'Give them your full attention.'),
  const Mission(
      id: 'm40',
      title: 'Sunset or sky check',
      description: 'Pause and watch the changing sky for a few minutes.',
      category: 'Adventure',
      moods: ['Stressed', 'Happy', 'Lazy'],
      duration: 15,
      budget: 0,
      difficulty: 'Easy',
      xp: 20,
      environment: 'Outdoor',
      instructions: 'Choose a comfortable, safe viewing spot.'),
];

String chooseOption(List<String> options, {Random? random}) {
  if (options.length < 2 || options.length > 12) {
    throw ArgumentError('Choose between 2 and 12 options.');
  }
  return options[(random ?? Random.secure()).nextInt(options.length)];
}

Mission recommendMission(List<Mission> pool,
    {required String mood,
    required int minutes,
    required int budget,
    required String environment,
    required String category,
    Random? random}) {
  final eligible = pool
      .where((m) =>
          m.duration <= minutes &&
          m.budget <= budget &&
          (environment == 'Both' ||
              m.environment == 'Both' ||
              m.environment == environment))
      .toList();
  if (eligible.isEmpty) {
    throw StateError(
        'No missions match. Try more time, budget, or environments.');
  }
  double score(Mission m) {
    final moodScore = m.moods.contains(mood) ? 1.0 : .35;
    final timeScore = (minutes / m.duration).clamp(.35, 1.0);
    final budgetScore = m.budget == 0
        ? 1.0
        : (budget == 0 ? 0.0 : (budget / m.budget).clamp(.35, 1.0));
    final prefScore = (m.category == category ? 1.0 : .35);
    return .35 * moodScore +
        .25 * timeScore +
        .20 * budgetScore +
        .20 * prefScore;
  }

  eligible.sort((a, b) => score(b).compareTo(score(a)));
  final top = eligible.take(min(3, eligible.length)).toList();
  return top[(random ?? Random.secure()).nextInt(top.length)];
}
