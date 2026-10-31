import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../data/repository.dart';
import '../../shared/widgets/yolo_scaffold.dart';

class SquadScreen extends ConsumerStatefulWidget {
  const SquadScreen({super.key});
  @override
  ConsumerState<SquadScreen> createState() => _SquadScreenState();
}

class _SquadScreenState extends ConsumerState<SquadScreen> {
  final _code = TextEditingController();
  final _area = TextEditingController();
  final _budget = TextEditingController(text: '0');
  String _category = 'Adventure';
  int _minutes = 15;
  String _environment = 'Both';
  String? _roomId;
  String? _roomCode;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _votes = [];
  Mission? _consensus;
  bool _busy = false;
  String? _error;

  String get _name => ref.read(repositoryProvider).username;

  @override
  void dispose() {
    _code.dispose();
    _area.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final roomCode = _newRoomCode();
    _activateDemoRoom(roomCode);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _join() async {
    final roomCode = _code.text.trim().toUpperCase();
    if (roomCode.length != 8) {
      return _showError('Enter an 8-character demo room code.');
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    _activateDemoRoom(roomCode);
    if (mounted) setState(() => _busy = false);
  }

  int get _parsedBudget =>
      (int.tryParse(_budget.text) ?? 0).clamp(0, 100000).toInt();

  String get _displayName => _name.trim().isEmpty
      ? 'Adventurer'
      : _name.trim().substring(0, min(_name.trim().length, 32));

  String _newRoomCode() {
    final random = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  void _activateDemoRoom(String code) {
    final area = _area.text.trim().isEmpty ? 'Nearby' : _area.text.trim();
    setState(() {
      _roomId = code;
      _roomCode = code;
      _consensus = null;
      _members = [
        {
          'user_id': 'you',
          'display_name': _displayName,
          'area': area,
          'budget': _parsedBudget,
        },
        {
          'user_id': 'demo-a',
          'display_name': 'Mira · demo',
          'area': 'Nearby',
          'budget': _parsedBudget,
        },
        {
          'user_id': 'demo-b',
          'display_name': 'Avi · demo',
          'area': 'Nearby',
          'budget': _parsedBudget,
        },
      ];
      _votes = [
        {
          'user_id': 'demo-a',
          'category': 'Adventure',
          'minutes': 15,
          'budget': _parsedBudget,
          'environment': 'Both',
        },
        {
          'user_id': 'demo-b',
          'category': 'Creative',
          'minutes': 30,
          'budget': _parsedBudget,
          'environment': 'Both',
        },
      ];
    });
    _vote();
  }

  Future<void> _vote() async {
    if (_roomId == null || !mounted) return;
    setState(() {
      _votes = [
        ..._votes.where((vote) => vote['user_id'] != 'you'),
        {
          'user_id': 'you',
          'category': _category,
          'minutes': _minutes,
          'budget': _parsedBudget,
          'environment': _environment,
        },
      ];
    });
    _chooseConsensus();
  }

  void _chooseConsensus() {
    if (_votes.isEmpty || !mounted) return;
    final categories = <String, int>{};
    for (final vote in _votes) {
      final c = vote['category'] as String? ?? 'Adventure';
      categories[c] = (categories[c] ?? 0) + 1;
    }
    final category = categories.keys
        .reduce((a, b) => categories[a]! >= categories[b]! ? a : b);
    final minutes =
        _votes.map((v) => (v['minutes'] as num).toInt()).reduce(min);
    final budget = _members.isEmpty
        ? 0
        : _members.map((m) => (m['budget'] as num).toInt()).reduce(min);
    final indoorVotes =
        _votes.where((v) => v['environment'] == 'Indoor').length;
    final outdoorVotes =
        _votes.where((v) => v['environment'] == 'Outdoor').length;
    final environment = indoorVotes > outdoorVotes
        ? 'Indoor'
        : outdoorVotes > indoorVotes
            ? 'Outdoor'
            : 'Both';
    final candidates = missions
        .where((m) =>
            m.category == category &&
            m.duration <= minutes &&
            m.budget <= budget &&
            (environment == 'Both' ||
                m.environment == 'Both' ||
                m.environment == environment))
        .toList();
    candidates.sort((a, b) => a.id.compareTo(b.id));
    final seed = '$_roomId|$category|$minutes|$budget|$environment'.hashCode;
    setState(() => _consensus =
        candidates.isEmpty ? null : candidates[seed.abs() % candidates.length]);
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _roomCode ?? ''));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Demo code copied (this session only).')));
    }
  }

  void _showError(String message) {
    if (mounted) setState(() => _error = message);
  }

  @override
  Widget build(BuildContext context) => YoloScaffold(
        title: 'Squad YOLO',
        child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Make the plot twist together.',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text(
                  'Try the group vote and see what mission your crew agrees on.'),
              const SizedBox(height: 18),
              if (_roomId == null) ...[
                const Card(
                    child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Text(
                            'Local demo: the crew is simulated on this device. No Firebase, API key, or server is needed; room codes do not connect other devices.'))),
                _section('YOUR SHAREABLE DETAILS'),
                TextField(
                    controller: _area,
                    maxLength: 80,
                    decoration: const InputDecoration(
                        labelText: 'Area or neighborhood (optional)',
                        prefixIcon: Icon(Icons.place_outlined),
                        helperText:
                            'Only this label is shared with squad members. No GPS location is collected.')),
                TextField(
                    controller: _budget,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Your max budget (₹)',
                        prefixIcon: Icon(Icons.currency_rupee))),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                      child: FilledButton.icon(
                          onPressed: _busy ? null : _create,
                          icon: const Icon(Icons.add),
                          label: Text(
                              _busy ? 'Setting up…' : 'Start local demo'))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: OutlinedButton.icon(
                          onPressed: _busy ? null : _join,
                          icon: const Icon(Icons.login),
                          label: const Text('Use a code')))
                ]),
                TextField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 8,
                    decoration:
                        const InputDecoration(labelText: 'Room code to join')),
              ] else ...[
                Card(
                    color: YoloColors.yellow,
                    child: ListTile(
                        leading: const Icon(Icons.groups_rounded),
                        title: Text('DEMO ${_roomCode ?? ''}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                        subtitle:
                            Text('${_members.length} players • local votes'),
                        trailing: IconButton(
                            tooltip: 'Copy demo code',
                            onPressed: _copyCode,
                            icon: const Icon(Icons.copy_rounded)))),
                _section('YOUR VOTE'),
                DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration:
                        const InputDecoration(labelText: 'Mission vibe'),
                    items: const [
                      'Adventure',
                      'Creative',
                      'Social',
                      'Learning',
                      'Fitness',
                      'Entertainment'
                    ]
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _category = v);
                      _vote();
                    }),
                DropdownButtonFormField<int>(
                    initialValue: _minutes,
                    decoration:
                        const InputDecoration(labelText: 'Time available'),
                    items: const [5, 15, 30, 60, 90]
                        .map((v) => DropdownMenuItem(
                            value: v, child: Text('$v minutes')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _minutes = v);
                      _vote();
                    }),
                DropdownButtonFormField<String>(
                    initialValue: _environment,
                    decoration: const InputDecoration(labelText: 'Where?'),
                    items: const ['Both', 'Indoor', 'Outdoor']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _environment = v);
                      _vote();
                    }),
                const SizedBox(height: 14),
                _section('THE CREW'),
                for (final member in _members)
                  ListTile(
                      dense: true,
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(member['display_name'] as String),
                      subtitle: Text(
                          '${(member['area'] as String).isEmpty ? 'Area not shared' : member['area']} · ₹${member['budget']} max')),
                _section('SQUAD CONSENSUS'),
                if (_consensus == null)
                  const Card(
                      child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                              'No mission matches everyone’s current time, budget and vibe. Try adjusting a vote.')))
                else
                  Card(
                      color: const Color(0xFFFFF3E9),
                      child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'SQUAD CONSENSUS • ${_consensus!.category.toUpperCase()}',
                                    style: const TextStyle(
                                        color: YoloColors.red,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: .8)),
                                const SizedBox(height: 8),
                                Text(_consensus!.title,
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 6),
                                Text(_consensus!.description),
                                const SizedBox(height: 8),
                                Text(
                                    '${_consensus!.duration} min · up to ₹${_consensus!.budget} · ${_members.map((m) => (m['area'] as String)).where((a) => a.isNotEmpty).toSet().join(' + ')}'),
                                TextButton.icon(
                                    onPressed: () => context.push('/missions'),
                                    icon: const Icon(Icons.explore),
                                    label: const Text('Open missions'))
                              ]))),
                TextButton.icon(
                    onPressed: () async {
                      if (mounted) {
                        setState(() {
                          _roomId = null;
                          _roomCode = null;
                          _members = [];
                          _votes = [];
                        });
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Leave this view')),
              ],
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!,
                        style: const TextStyle(
                            color: YoloColors.red,
                            fontWeight: FontWeight.w700))),
            ])),
      );

  Widget _section(String title) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1)));
}
