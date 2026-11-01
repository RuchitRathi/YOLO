import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../data/repository.dart';

class MissionGenerationException implements Exception {
  const MissionGenerationException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PersonalizedMissionsService {
  static const _geminiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = 'gemini-3.5-flash-lite';

  Future<String> availability() async =>
      _geminiKey.isEmpty || _geminiKey == 'your-gemini-api-key'
          ? 'missing_key'
          : 'ready';

  List<Mission> localFallback({
    required String preference,
    required List<String> recentHistory,
  }) {
    final recentTitles = recentHistory
        .map((entry) => entry.split(':').last.trim().toLowerCase())
        .where((title) => title.isNotEmpty)
        .toSet();
    final wantedCategory = switch (preference) {
      'Creative' => 'Creative',
      'Adventurous' => 'Adventure',
      'Social' => 'Social',
      'Chill' => 'Entertainment',
      _ => null,
    };
    final fresh = missions
        .where((mission) => !recentTitles.contains(mission.title.toLowerCase()))
        .toList();
    final preferred = wantedCategory == null
        ? fresh
        : fresh.where((mission) => mission.category == wantedCategory).toList();
    final pool = preferred.length >= 3 ? preferred : fresh;
    pool.sort((a, b) {
      final duration = a.duration.compareTo(b.duration);
      return duration != 0 ? duration : a.id.compareTo(b.id);
    });
    pool.shuffle(Random.secure());
    return pool.take(3).map((mission) {
      final vibe = preference == 'Surprise me'
          ? 'your current vibe'
          : '$preference vibe';
      return mission.copyWith(
        fitReason:
            'Picked for $vibe, avoids your recent repeats, and works without live location, weather, or a network connection.',
      );
    }).toList(growable: false);
  }

  Future<List<Mission>> generate({
    required String preference,
    required List<String> recentHistory,
    required String username,
    void Function(String stage)? onProgress,
    void Function(List<Mission> partial)? onPartialMissions,
  }) async {
    if (_geminiKey.isEmpty || _geminiKey == 'your-gemini-api-key') {
      throw const MissionGenerationException(
          'Add a Gemini API key with --dart-define=GEMINI_API_KEY=your_key to generate missions.');
    }

    onProgress?.call('Finding your location…');
    final position = await _tryLocation();
    final location = position == null
        ? null
        : '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';
    var weather = <String, dynamic>{
      'city': 'nearby area',
      'country': '',
      'description': 'weather unavailable',
      'temperatureC': 'unknown',
    };
    if (position == null) {
      onProgress?.call('Location unavailable; continuing without forecast…');
    } else {
      onProgress?.call('Checking the local weather…');
      try {
        weather = await _getWeather(position);
      } on MissionGenerationException catch (error) {
        onProgress?.call('${error.message} Generating without forecast…');
      }
    }
    final now = DateTime.now().toLocal();
    final recent =
        recentHistory.isEmpty ? 'None yet.' : recentHistory.join('; ');
    final prompt =
        '''Create exactly 3 spontaneous, quirky, safe real-world micro-missions. Return ONLY a JSON array, no markdown.
User: $username. Vibe: $preference.
Local date and time: ${now.toString()} (${_weekday(now.weekday)}).
Approximate device location: ${location ?? 'unavailable; keep missions location-neutral'}.
Current weather: ${weather['description']}, ${weather['temperatureC']}°C near ${weather['city']} ${weather['country']}.
Recent missions to avoid repeating: $recent.
Each mission takes 10 minutes and costs at most 5 USD. Make them suitable for a public place or at-home; no trespassing, unsafe traffic, coercion, purchases, or special equipment. Each object must have title, description (one sentence), instructions (one concise sentence), reason (one short truthful sentence explaining how it matches the vibe, available weather/time, and history; never claim unavailable context), category (Adventure, Creative, Social, Fitness, Learning, or Entertainment), costUsd (number 0 to 5).''';

    onProgress?.call('Asking Gemini Flash-Lite…');
    final client = http.Client();
    try {
      final request = http.Request(
        'POST',
        Uri.https(
          'generativelanguage.googleapis.com',
          '/v1beta/models/$_model:streamGenerateContent',
          {'alt': 'sse'},
        ),
      )
        ..headers.addAll({
          'Content-Type': 'application/json',
          'x-goog-api-key': _geminiKey,
        })
        ..body = jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.8,
            'maxOutputTokens': 384,
            'responseMimeType': 'application/json',
            'responseSchema': {
              'type': 'ARRAY',
              'items': {
                'type': 'OBJECT',
                'properties': {
                  'title': {'type': 'STRING'},
                  'description': {'type': 'STRING'},
                  'instructions': {'type': 'STRING'},
                  'reason': {'type': 'STRING'},
                  'category': {
                    'type': 'STRING',
                    'enum': [
                      'Adventure',
                      'Creative',
                      'Social',
                      'Fitness',
                      'Learning',
                      'Entertainment',
                    ],
                  },
                  'costUsd': {'type': 'NUMBER'},
                },
                'required': [
                  'title',
                  'description',
                  'instructions',
                  'reason',
                  'category',
                  'costUsd',
                ],
              },
            },
          },
        });

      final response = await client.send(request).timeout(
            const Duration(seconds: 20),
            onTimeout: () => throw TimeoutException('Gemini request timed out'),
          );
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        throw _apiException(response.statusCode, body);
      }

      final output = StringBuffer();
      var emitted = 0;
      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .timeout(const Duration(seconds: 20))) {
        if (!line.startsWith('data:')) continue;
        final data = line.substring(5).trim();
        if (data.isEmpty || data == '[DONE]') continue;
        final event = jsonDecode(data) as Map<String, dynamic>;
        final candidates = event['candidates'] as List<dynamic>? ?? [];
        if (candidates.isEmpty) continue;
        final content = candidates.first['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>? ?? [];
        for (final part in parts.whereType<Map<String, dynamic>>()) {
          output.write(part['text'] as String? ?? '');
        }

        final completedObjects = _completeObjects(output.toString());
        if (completedObjects.length > emitted) {
          emitted = completedObjects.length;
          final partial = completedObjects
              .map((json) => _toMission(jsonDecode(json)))
              .toList(growable: false);
          onPartialMissions?.call(partial);
          onProgress?.call('Gemini made $emitted of 3 missions…');
        }
      }

      final decoded = jsonDecode(output.toString());
      if (decoded is! List || decoded.length != 3) {
        throw const FormatException('Expected three missions');
      }
      return decoded.map(_toMission).toList(growable: false);
    } on MissionGenerationException {
      rethrow;
    } on FormatException {
      throw const MissionGenerationException(
          'Gemini returned an unexpected format. Please try again.');
    } on TimeoutException {
      throw const MissionGenerationException(
          'Gemini is taking too long. Please try again.');
    } catch (_) {
      throw const MissionGenerationException(
          'Could not reach Gemini. Check your connection and API key, then try again.');
    } finally {
      client.close();
    }
  }

  Future<Position?> _tryLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(milliseconds: 700))) {
        return null;
      }
      var permission = await Geolocator.checkPermission()
          .timeout(const Duration(milliseconds: 700));
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 2));
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition()
            .timeout(const Duration(milliseconds: 700));
      } catch (_) {}
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 2),
        ),
      ).timeout(const Duration(seconds: 3));
      return position;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _getWeather(Position position) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '${position.latitude}',
      'longitude': '${position.longitude}',
      'current': 'temperature_2m,weather_code,precipitation,wind_speed_10m',
      'timezone': 'auto',
    });
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        throw MissionGenerationException(
            'Weather lookup failed (${response.statusCode}).');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>;
      final weatherCode = (current['weather_code'] as num?)?.toInt() ?? -1;
      final precipitation = (current['precipitation'] as num?) ?? 0;
      final wind = (current['wind_speed_10m'] as num?) ?? 0;
      final conditions = _weatherDescription(weatherCode);
      return {
        'city': 'nearby area',
        'country': '',
        'description':
            '$conditions, ${precipitation}mm precipitation, ${wind}km/h wind',
        'temperatureC': current['temperature_2m'] ?? 'unknown',
      };
    } on MissionGenerationException {
      rethrow;
    } on TimeoutException {
      throw const MissionGenerationException('Weather lookup timed out.');
    } catch (_) {
      throw const MissionGenerationException('Weather service is unreachable.');
    }
  }

  String _weatherDescription(int code) => switch (code) {
        0 => 'clear sky',
        1 => 'mainly clear',
        2 => 'partly cloudy',
        3 => 'overcast',
        45 || 48 => 'foggy',
        51 || 53 || 55 => 'drizzle',
        56 || 57 => 'freezing drizzle',
        61 || 63 || 65 => 'rainy',
        66 || 67 => 'freezing rain',
        71 || 73 || 75 || 77 => 'snowy',
        80 || 81 || 82 => 'rain showers',
        85 || 86 => 'snow showers',
        95 || 96 || 99 => 'thunderstorms',
        _ => 'weather unknown',
      };

  List<String> _completeObjects(String text) {
    final objects = <String>[];
    var start = -1;
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var index = 0; index < text.length; index++) {
      final char = text[index];
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (char == r'\') {
          escaped = true;
        } else if (char == '"') {
          inString = false;
        }
        continue;
      }
      if (char == '"') {
        inString = true;
      } else if (char == '{') {
        if (depth == 0) start = index;
        depth++;
      } else if (char == '}' && depth > 0) {
        depth--;
        if (depth == 0 && start >= 0) {
          objects.add(text.substring(start, index + 1));
          start = -1;
        }
      }
    }
    return objects;
  }

  MissionGenerationException _apiException(int statusCode, String body) {
    if (statusCode == 429) {
      return const MissionGenerationException(
          'Gemini rate limit reached. Wait a moment and try again.');
    }
    try {
      final error = (jsonDecode(body) as Map<String, dynamic>)['error'];
      if (error is Map<String, dynamic> && error['message'] is String) {
        return MissionGenerationException(error['message'] as String);
      }
    } catch (_) {}
    return MissionGenerationException('Gemini request failed ($statusCode).');
  }

  Mission _toMission(dynamic value) {
    if (value is! Map<String, dynamic>) throw const FormatException();
    final title = value['title'];
    final description = value['description'];
    final instructions = value['instructions'];
    final reason = value['reason'];
    final category = value['category'];
    final rawCost = value['costUsd'];
    const categories = {
      'Adventure',
      'Creative',
      'Social',
      'Fitness',
      'Learning',
      'Entertainment'
    };
    if (title is! String ||
        description is! String ||
        instructions is! String ||
        category is! String ||
        !categories.contains(category) ||
        rawCost is! num) {
      throw const FormatException();
    }
    final cost = rawCost.clamp(0, 5).toDouble();
    return Mission(
      id: 'gemini-${DateTime.now().microsecondsSinceEpoch}-${title.hashCode}',
      title: title,
      description: description,
      instructions: instructions,
      category: category,
      moods: const ['adventurous', 'creative'],
      duration: 10,
      budget: cost.ceil(),
      currency: '\$',
      difficulty: 'Easy',
      xp: 15,
      environment: 'Anywhere',
      fitReason: reason is String && reason.trim().isNotEmpty
          ? reason.trim()
          : 'Matches your selected vibe and avoids repeating recent missions.',
    );
  }

  String _weekday(int day) => const [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ][day - 1];
}
