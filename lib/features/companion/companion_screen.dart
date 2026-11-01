import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/repository.dart';
import '../../shared/widgets/yolo_scaffold.dart';
import 'ollama_companion_service.dart';

class CompanionScreen extends ConsumerStatefulWidget {
  const CompanionScreen({super.key});

  @override
  ConsumerState<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends ConsumerState<CompanionScreen> {
  static const _historyKey = 'shinchan_companion_history';
  static const _greeting =
      'Hey! Shinchan here 😎 Tell me what kind of day you’re having, and I’ll cook up a tiny adventure. No boring answers allowed!';

  final _input = TextEditingController();
  final _scroll = ScrollController();
  late final YoloRepository _repository;
  late OllamaCompanionService _service;
  late String _endpoint;
  List<_ChatTurn> _turns = [const _ChatTurn.assistant(_greeting)];
  List<String> _models = const [];
  String? _model;
  String? _connectionError;
  bool _connecting = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(repositoryProvider);
    _endpoint = _repository.prefs.getString('ollama_endpoint') ??
        (kIsWeb ? 'http://127.0.0.1:11434' : 'http://10.0.2.2:11434');
    _service = OllamaCompanionService(_endpoint);
    _restoreHistory();
    _connect();
  }

  Future<void> _restoreHistory() async {
    try {
      final saved = _repository.prefs.getString(_historyKey);
      if (saved == null) return;
      final decoded = jsonDecode(saved) as List<dynamic>;
      final restored = decoded
          .whereType<Map<String, dynamic>>()
          .map(_ChatTurn.fromJson)
          .toList(growable: false);
      if (restored.isNotEmpty && mounted) {
        setState(
            () => _turns = [const _ChatTurn.assistant(_greeting), ...restored]);
      }
    } catch (_) {
      await _repository.prefs.remove(_historyKey);
    }
  }

  Future<void> _connect() async {
    if (mounted) {
      setState(() {
        _connecting = true;
        _connectionError = null;
      });
    }
    try {
      final models = await _service.availableModels();
      if (!mounted) return;
      final savedModel = _repository.prefs.getString('ollama_model');
      final selected = models.contains(savedModel)
          ? savedModel!
          : models.contains('qwen2.5:1.5b-instruct')
              ? 'qwen2.5:1.5b-instruct'
              : models.isEmpty
                  ? ''
                  : models.first;
      setState(() {
        _models = models;
        _model = selected.isEmpty ? null : selected;
        _connecting = false;
        _connectionError = models.isEmpty
            ? 'Ollama is running, but no models are installed.'
            : null;
      });
      if (_model != null) {
        await _repository.prefs.setString('ollama_model', _model!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _connectionError =
            'Can’t reach Ollama at $_endpoint. Open Ollama on this computer, then retry.';
      });
    }
  }

  Future<void> _editEndpoint() async {
    final controller = TextEditingController(text: _endpoint);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Connect to local Ollama'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Ollama address',
            hintText: 'http://127.0.0.1:11434',
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const Text('SAVE & CONNECT')),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty || !mounted) return;
    _service.close();
    setState(() {
      _endpoint = result.replaceAll(RegExp(r'/+$'), '');
      _service = OllamaCompanionService(_endpoint);
    });
    await _repository.prefs.setString('ollama_endpoint', _endpoint);
    await _connect();
  }

  Future<void> _selectModel(String? model) async {
    if (model == null) return;
    setState(() => _model = model);
    await _repository.prefs.setString('ollama_model', model);
  }

  Future<void> _send([String? suggestedText]) async {
    if (_sending || _model == null) return;
    final text = (suggestedText ?? _input.text).trim();
    if (text.isEmpty) return;
    _input.clear();
    setState(() {
      _turns = [..._turns, _ChatTurn.user(text), const _ChatTurn.assistant('')];
      _sending = true;
    });
    await _saveHistory();

    final recentMissions = _repository.history
        .take(6)
        .map((memory) => '${memory.status}: ${memory.title}')
        .join('\n');
    final system =
        '''You are Shinchan, YOLO's playful, cheeky mission buddy. Be energetic, funny, a little mischievous, warm, and concise. Speak like a cartoon companion in short natural chat messages, with occasional playful emojis. Help ${_repository.username} escape boredom and turn vague ideas into spontaneous, safe, low-cost mini-missions. Use their recent mission history to avoid repeats and celebrate their progress. Never suggest trespassing, dangerous stunts, harassment, humiliation, or spending money without consent. If they ask for a mission, give one concrete action with a simple first step. If they seem overwhelmed, make it smaller and easier. Do not claim to access their camera, location, or other apps. Recent YOLO history:\n${recentMissions.isEmpty ? 'No completed adventures yet.' : recentMissions}''';
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': system},
      for (final turn in _turns.skip(1).takeLast(12))
        if (turn.content.isNotEmpty)
          {'role': turn.role, 'content': turn.content},
    ];
    final output = StringBuffer();
    try {
      await _service.reply(
        model: _model!,
        messages: messages,
        onToken: (token) {
          output.write(token);
          if (!mounted) return;
          setState(() {
            _turns = [
              ..._turns.take(_turns.length - 1),
              _ChatTurn.assistant(output.toString()),
            ];
          });
          _scrollToBottom();
        },
      );
      if (output.isEmpty) {
        throw const OllamaCompanionException(
            'The local model returned an empty reply. Try once more.');
      }
      await _saveHistory();
    } catch (error) {
      if (mounted) {
        setState(() {
          _turns = [
            ..._turns.take(_turns.length - 1),
            _ChatTurn.assistant(error.toString()),
          ];
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
      await _saveHistory();
      _scrollToBottom();
    }
  }

  Future<void> _saveHistory() async {
    final history = _turns
        .skip(1)
        .where((turn) => turn.content.isNotEmpty)
        .toList(growable: false);
    final bounded =
        history.length <= 30 ? history : history.sublist(history.length - 30);
    await _repository.prefs.setString(
        _historyKey, jsonEncode(bounded.map((turn) => turn.toJson()).toList()));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _clearChat() async {
    setState(() => _turns = [const _ChatTurn.assistant(_greeting)]);
    await _repository.prefs.remove(_historyKey);
  }

  @override
  void dispose() {
    _service.close();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => YoloScaffold(
        title: 'ASK SHINCHAN',
        actions: [
          IconButton(
              tooltip: 'Ollama settings',
              onPressed: _editEndpoint,
              icon: const Icon(Icons.tune_rounded)),
          IconButton(
              tooltip: 'Clear conversation',
              onPressed: _sending ? null : _clearChat,
              icon: const Icon(Icons.delete_outline_rounded)),
        ],
        child: Column(children: [
          _connectionPanel(),
          if (_models.length > 1 && _model != null) _modelPicker(),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
              itemCount: _turns.length,
              itemBuilder: (context, index) => _messageTile(_turns[index]),
            ),
          ),
          if (_turns.length == 1) _suggestions(),
          _composer(),
        ]),
      );

  Widget _connectionPanel() => Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _connectionError == null
                ? YoloColors.mint
                : YoloColors.yellow.withValues(alpha: .58),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: YoloColors.ink, width: 1.2),
          ),
          child: Row(children: [
            Icon(
                _connecting
                    ? Icons.sync_rounded
                    : _connectionError == null
                        ? Icons.memory_rounded
                        : Icons.cloud_off_rounded,
                size: 19,
                color: _connectionError == null
                    ? Colors.green[800]
                    : YoloColors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _connecting
                    ? 'Checking your local Ollama…'
                    : _connectionError ?? 'LOCAL AI · ${_model ?? 'READY'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ),
            if (!_connecting && _connectionError != null)
              TextButton(onPressed: _connect, child: const Text('RETRY')),
          ]),
        ),
      );

  Widget _modelPicker() => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
        child: Row(children: [
          const Text('MODEL',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
          const SizedBox(width: 9),
          DropdownButton<String>(
            value: _model,
            isDense: true,
            underline: const SizedBox.shrink(),
            items: _models
                .map((model) => DropdownMenuItem(
                    value: model,
                    child: Text(model,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700))))
                .toList(),
            onChanged: _sending ? null : _selectModel,
          ),
        ]),
      );

  Widget _messageTile(_ChatTurn turn) {
    final fromBuddy = turn.role == 'assistant';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            fromBuddy ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (fromBuddy) ...[
            const _BuddyAvatar(size: 34),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 510),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: fromBuddy ? Colors.white : YoloColors.yellow,
                border: Border.all(color: YoloColors.ink, width: 1.3),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(17),
                  topRight: const Radius.circular(17),
                  bottomLeft: Radius.circular(fromBuddy ? 4 : 17),
                  bottomRight: Radius.circular(fromBuddy ? 17 : 4),
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0x1E202020), offset: Offset(2, 3)),
                ],
              ),
              child: turn.content.isEmpty && _sending
                  ? const SizedBox(
                      width: 38,
                      height: 18,
                      child: _TypingDots(),
                    )
                  : Text(turn.content,
                      style: const TextStyle(height: 1.35, fontSize: 14)),
            ),
          ),
          if (!fromBuddy) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _suggestions() => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 5),
        child: Wrap(spacing: 7, runSpacing: 5, children: [
          _suggestion('Give me a tiny dare 🎲'),
          _suggestion('I’m bored. Rescue me!'),
          _suggestion('Make my mission sillier'),
        ]),
      );

  Widget _suggestion(String text) => ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 10)),
        onPressed: _sending ? null : () => _send(text),
        visualDensity: VisualDensity.compact,
      );

  Widget _composer() => Padding(
        padding: EdgeInsets.fromLTRB(
            14, 8, 14, 12 + MediaQuery.viewInsetsOf(context).bottom),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: _model == null
                    ? 'Start Ollama to chat…'
                    : 'Tell Shinchan what’s up…',
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: YoloColors.ink)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide:
                        const BorderSide(color: YoloColors.ink, width: 1.4)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Send message',
            onPressed: _sending || _model == null ? null : _send,
            style: IconButton.styleFrom(
                backgroundColor: YoloColors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(49, 49)),
            icon: _sending
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded),
          ),
        ]),
      );
}

class _ChatTurn {
  const _ChatTurn(this.role, this.content);
  const _ChatTurn.user(String content) : this('user', content);
  const _ChatTurn.assistant(String content) : this('assistant', content);

  final String role;
  final String content;

  factory _ChatTurn.fromJson(Map<String, dynamic> json) => _ChatTurn(
        json['role'] as String,
        json['content'] as String,
      );

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class _BuddyAvatar extends StatelessWidget {
  const _BuddyAvatar({this.size = 38});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: YoloColors.yellow,
          shape: BoxShape.circle,
          border: Border.all(color: YoloColors.ink, width: 1.5),
        ),
        child: ClipOval(
          child: Image.asset('assets/images/shinchan.png', fit: BoxFit.cover),
        ),
      );
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(3, (index) {
            final phase = (_controller.value * 3 - index).abs();
            final opacity = (1 - phase.clamp(0, 1)).toDouble();
            return Opacity(
              opacity: .35 + opacity * .65,
              child: const CircleAvatar(
                  radius: 3, backgroundColor: YoloColors.red),
            );
          }),
        ),
      );
}

extension _TakeLast<T> on Iterable<T> {
  Iterable<T> takeLast(int count) {
    final list = toList(growable: false);
    return list.skip(list.length > count ? list.length - count : 0);
  }
}
