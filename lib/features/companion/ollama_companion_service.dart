import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class OllamaCompanionService {
  OllamaCompanionService(String endpoint)
      : _endpoint = endpoint.replaceAll(RegExp(r'/+$'), '');

  final String _endpoint;
  final http.Client _client = http.Client();

  Future<List<String>> availableModels() async {
    final response = await _client
        .get(Uri.parse('$_endpoint/api/tags'))
        .timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) {
      throw OllamaCompanionException(
          'Ollama returned ${response.statusCode} while listing models.');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final models = body['models'] as List<dynamic>? ?? const [];
    return models
        .whereType<Map<String, dynamic>>()
        .map((model) => model['name'] as String?)
        .whereType<String>()
        .toList(growable: false);
  }

  Future<void> reply({
    required String model,
    required List<Map<String, String>> messages,
    required void Function(String token) onToken,
    double temperature = 0.82,
    int maxTokens = 160,
  }) async {
    final request = http.Request('POST', Uri.parse('$_endpoint/api/chat'))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'model': model,
        'messages': messages,
        'stream': true,
        'keep_alive': '15m',
        'options': {
          'temperature': temperature,
          'num_predict': maxTokens,
          'num_ctx': 4096,
        },
      });
    final response =
        await _client.send(request).timeout(const Duration(seconds: 35));
    if (response.statusCode != 200) {
      final details = await response.stream.bytesToString();
      throw OllamaCompanionException(_messageFrom(details));
    }
    await for (final line in response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .timeout(const Duration(seconds: 90))) {
      if (line.trim().isEmpty) continue;
      final event = jsonDecode(line) as Map<String, dynamic>;
      final message = event['message'] as Map<String, dynamic>?;
      final token = message?['content'] as String?;
      if (token != null && token.isNotEmpty) onToken(token);
      if (event['done'] == true) break;
    }
  }

  String _messageFrom(String body) {
    try {
      final message = (jsonDecode(body) as Map<String, dynamic>)['error'];
      if (message is String && message.trim().isNotEmpty) return message;
    } catch (_) {}
    return 'Ollama could not answer. Check that the selected model is installed.';
  }

  void close() => _client.close();
}

class OllamaCompanionException implements Exception {
  const OllamaCompanionException(this.message);
  final String message;
  @override
  String toString() => message;
}
