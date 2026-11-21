import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../blocks/strategy_registry.dart';
import '../core/models.dart';
import '../core/modes_repository.dart';
import '../core/nfc_payload.dart';
import '../services/focus_controller.dart';

/// Demo shell around the real logic. A designer can replace this file without
/// touching the protocol, repository or controller.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.strategies,
    required this.controller,
  });

  final ModesRepository repository;
  final StrategyRegistry strategies;
  final FocusController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _tokenIdInput = TextEditingController();
  final TextEditingController _labelInput = TextEditingController();

  List<FocusMode> _modes = const <FocusMode>[];
  List<TokenBinding> _bindings = const <TokenBinding>[];
  String? _selectedModeId;
  String? _selectedTokenId;
  String? _selectedStrategyId;
  String _status = 'Ready. Bind a token, then simulate a tap.';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tokenIdInput.dispose();
    _labelInput.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final modes = await widget.repository.listModes();
    final bindings = await widget.repository.listBindings();
    if (!mounted) return;
    setState(() {
      _modes = modes;
      _bindings = bindings;
      _selectedModeId ??= modes.isEmpty ? null : modes.first.id;
      _selectedTokenId ??= bindings.isEmpty ? null : bindings.first.tokenId;
      _selectedStrategyId ??= widget.strategies.get(
                widget.controller.preferredStrategyId,
              ) !=
              null
          ? widget.controller.preferredStrategyId
          : (widget.strategies.all.isEmpty
              ? null
              : widget.strategies.all.first.id);
    });
  }

  Future<void> _run(Future<CommandOutcome> Function() action) async {
    setState(() => _busy = true);
    final outcome = await action();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _status = '${outcome.ok ? 'OK' : 'Error'}: ${outcome.message}';
    });
    await _load();
  }

  Future<void> _bindToken() async {
    final modeId = _selectedModeId;
    if (modeId == null) {
      setState(() => _status = 'Error: create a mode first.');
      return;
    }
    try {
      await widget.repository.saveBinding(
        TokenBinding(
          tokenId: _tokenIdInput.text.trim(),
          modeId: modeId,
          label: _labelInput.text.trim().isEmpty
              ? 'Unnamed token'
              : _labelInput.text.trim(),
        ),
      );
      _tokenIdInput.clear();
      _labelInput.clear();
      if (!mounted) return;
      setState(() => _status = 'OK: token bound.');
      await _load();
    } on ArgumentError catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _simulateTap() async {
    final tokenId = _selectedTokenId;
    if (tokenId == null) {
      setState(() => _status = 'Error: no token bound yet.');
      return;
    }
    final url = buildTagUrl(tokenId: tokenId, action: NfcAction.toggle);
    await _run(() => widget.controller.handleTagUrl(url));
  }

  Future<void> _export() async {
    final json = await widget.repository.exportJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Snapshot copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.controller.activeSession;
    final activeModeName = session == null
        ? null
        : _modes
            .where((m) => m.id == session.modeId)
            .map((m) => m.name)
            .firstWhere((_) => true, orElse: () => session.modeId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taplock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'Copy backup JSON',
            onPressed: _export,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: session == null
                ? null
                : Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session == null ? 'Not blocked' : '$activeModeName active',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session == null
                        ? 'Tap a bound token to start a focus session.'
                        : '${session.strategyId} · ${session.elapsed.inMinutes} min',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _section(
            'Status',
            <Widget>[
              Text(_status),
              if (_busy) const LinearProgressIndicator(),
            ],
          ),
          _section('Blocking strategy', <Widget>[
            DropdownButtonFormField<String>(
              value: _selectedStrategyId,
              decoration: const InputDecoration(
                labelText: 'Preferred strategy',
                border: OutlineInputBorder(),
              ),
              items: widget.strategies.all
                  .map(
                    (s) => DropdownMenuItem<String>(
                      value: s.id,
                      child: Text(s.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedStrategyId = value;
                  widget.controller.preferredStrategyId = value;
                });
              },
            ),
            if (_selectedStrategyId != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  widget.strategies.get(_selectedStrategyId!)?.description ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ]),
          _section('Tokens', <Widget>[
            if (_bindings.isEmpty) const Text('No tokens bound yet.'),
            ..._bindings.map(
              (b) => ListTile(
                leading: const Icon(Icons.nfc),
                title: Text(b.label),
                subtitle: Text('${b.tokenId} -> ${b.modeId}'),
              ),
            ),
            DropdownButtonFormField<String>(
              value: _selectedTokenId,
              decoration: const InputDecoration(labelText: 'Bound token'),
              items: _bindings
                  .map(
                    (b) => DropdownMenuItem<String>(
                      value: b.tokenId,
                      child: Text(b.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _selectedTokenId = value),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _simulateTap,
              icon: const Icon(Icons.touch_app),
              label: const Text('Simulate tag tap (toggle)'),
            ),
          ]),
          _section('Bind a new token', <Widget>[
            TextField(
              controller: _tokenIdInput,
              decoration: const InputDecoration(
                labelText: 'Token ID (6-64 letters, digits, _ or -)',
              ),
            ),
            TextField(
              controller: _labelInput,
              decoration: const InputDecoration(labelText: 'Label (optional)'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedModeId,
              decoration: const InputDecoration(labelText: 'Mode'),
              items: _modes
                  .map(
                    (m) => DropdownMenuItem<String>(
                      value: m.id,
                      child: Text(m.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedModeId = value),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _bindToken,
              icon: const Icon(Icons.link),
              label: const Text('Bind token'),
            ),
          ]),
          _section(
            'Modes',
            _modes
                .map(
                  (m) => ListTile(
                    title: Text(m.name),
                    subtitle: Text(
                      '${m.blockedBundleIds.length} apps'
                      '${m.description == null ? '' : ' · ${m.description}'}',
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
