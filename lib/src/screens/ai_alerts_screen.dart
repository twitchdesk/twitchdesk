import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_client.dart';

class _PromptExample {
  const _PromptExample({
    required this.title,
    required this.description,
    required this.prompt,
  });

  final String title;
  final String description;
  final String prompt;
}

class _HelpIcon extends StatelessWidget {
  const _HelpIcon({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      child: const Icon(Icons.help_outline, size: 18),
    );
  }
}

class _VariablesHint extends StatelessWidget {
  const _VariablesHint();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Row(
      children: [
        const _HelpIcon(
          message:
              'Du kan bruge variabler i prompten. De bliver udfyldt når alerten trigges. Nogle variabler kræver at dit tool sender de ekstra felter (event_type, tier, months, bits, amount, raid_viewers osv.).',
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Variabler: {{eventId}}, {{username}}, {{message}}, {{eventType}}, {{tier}}, {{months}}, {{bits}}, {{amount}}, {{raidViewers}}, {{timestamp}}, {{channel}}.',
            style: style,
          ),
        ),
      ],
    );
  }
}

class _OverlayVariablesHint extends StatelessWidget {
  const _OverlayVariablesHint();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _HelpIcon(
              message:
                  'GET URL\'en kan sættes ind i tools der kun kan åbne et link. Query params bliver til prompt-variabler.',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'GET query params (typisk i Twitch/HTML tools):',
                style: style,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '- event_id: unik id pr event (ellers duplicate)',
          style: style,
        ),
        Text(
          '- viewer/username: bliver til {{username}}',
          style: style,
        ),
        Text(
          '- message: bliver til {{message}}',
          style: style,
        ),
        Text(
          '- event_type: bliver til {{eventType}} (fx FOLLOW/SUB/RAID)',
          style: style,
        ),
        Text(
          '- tier/months/bits/amount/raid_viewers/channel: ekstra felter',
          style: style,
        ),
        Text(
          '- format=html: giver HTML output til overlay',
          style: style,
        ),
      ],
    );
  }
}

class _PromptHelpCard extends StatelessWidget {
  const _PromptHelpCard({
    required this.onInsert,
    required this.onCopy,
  });

  final void Function(String value) onInsert;
  final Future<void> Function(String text) onCopy;

  static const _examples = <_PromptExample>[
    _PromptExample(
      title: 'Kort follow alert (DA)',
      description: 'Kort og tydelig, egnet til overlay.',
      prompt:
          'Skriv en kort dansk Twitch alert på 1 linje. Event: FOLLOW. Person: {{username}}. Ekstra: {{message}}. Ingen emojis.',
    ),
    _PromptExample(
      title: 'Hype / celebration',
      description: 'Mere energi, men stadig kort.',
      prompt:
          'Lav en kort dansk celebration alert (maks 12 ord). Event: {{message}}. Navn: {{username}}.',
    ),
    _PromptExample(
      title: 'Raid velkomst',
      description: 'Velkomst til raiders med call-to-action.',
      prompt:
          'Skriv en dansk velkomst til en raid fra {{username}}. Hold det under 2 linjer. Slut med en kort CTA.',
    ),
    _PromptExample(
      title: 'TTS-venlig',
      description: 'Undgår svære tegn og er let at læse op.',
      prompt:
          'Skriv en dansk TTS-venlig alert uden emojis og uden specialtegn. Navn: {{username}}. Event: {{message}}. Maks 15 ord.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Prompt examples',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(width: 8),
                const _HelpIcon(
                  message:
                      'Klik “Insert” for at udfylde prompt-feltet. Du kan derefter tilrette teksten.',
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._examples.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.title,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () => onInsert(e.prompt),
                          child: const Text('Insert'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => onCopy(e.prompt),
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Copy'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AiAlertsScreen extends StatefulWidget {
  const AiAlertsScreen({
    super.key,
    required this.api,
    required this.accessToken,
  });

  final ApiClient api;
  final String accessToken;

  @override
  State<AiAlertsScreen> createState() => _AiAlertsScreenState();
}

class _AiAlertsScreenState extends State<AiAlertsScreen> {
  final _tokenCtrl = TextEditingController();

  // Remembers per-alert test inputs during the current app session.
  final Map<String, Map<String, String>> _testFieldCache = {};

  bool _busy = true;
  String? _error;

  String? _username;
  AiTokenStatusResponse? _tokenStatus;
  AiAlertsListResponse? _alerts;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        widget.api.me(accessToken: widget.accessToken),
        widget.api.aiTokenStatus(accessToken: widget.accessToken),
        widget.api.aiAlertsList(accessToken: widget.accessToken),
      ]);

      final me = results[0] as MeResponse;
      final token = results[1] as AiTokenStatusResponse;
      final alerts = results[2] as AiAlertsListResponse;

      if (!mounted) return;
      setState(() {
        _username = me.username.trim().isEmpty ? null : me.username.trim();
        _tokenStatus = token;
        _alerts = alerts;
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied.')),
    );
  }

  Future<void> _saveToken() async {
    final tok = _tokenCtrl.text.trim();
    if (tok.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await widget.api.aiTokenPut(accessToken: widget.accessToken, token: tok);
      _tokenCtrl.clear();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token saved.')),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnectToken() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await widget.api.aiTokenDelete(accessToken: widget.accessToken);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disconnected.')),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createAlert() async {
    final nameCtrl = TextEditingController();
    final promptCtrl = TextEditingController();
    var enabled = true;
    final cooldownCtrl = TextEditingController(text: '0');

    // Style
    final durationCtrl = TextEditingController(text: '4500');
    final textColorCtrl = TextEditingController(text: 'white');
    final fontFamilyCtrl = TextEditingController(text: 'system-ui, Segoe UI, Arial, sans-serif');
    final fontSizeCtrl = TextEditingController(text: '32');

    // Safety
    final maxOutputCtrl = TextEditingController(text: '200');
    final toneCtrl = TextEditingController(text: '');
    final languageCtrl = TextEditingController(text: 'da');
    var noSwearing = false;

    // Session
    var sessionEnabled = false;
    final sessionMaxEntriesCtrl = TextEditingController(text: '10');

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setInner) {
          String? nonNegativeIntError(TextEditingController c) {
            final t = c.text.trim();
            if (t.isEmpty) return 'Påkrævet';
            final v = int.tryParse(t);
            if (v == null) return 'Skal være et tal';
            if (v < 0) return 'Skal være ≥ 0';
            return null;
          }

          String? positiveIntError(TextEditingController c) {
            final t = c.text.trim();
            if (t.isEmpty) return 'Påkrævet';
            final v = int.tryParse(t);
            if (v == null) return 'Skal være et tal';
            if (v <= 0) return 'Skal være > 0';
            return null;
          }

          final name = nameCtrl.text.trim();
          final prompt = promptCtrl.text.trim();

          final cooldownErr = nonNegativeIntError(cooldownCtrl);
          final durationErr = positiveIntError(durationCtrl);
          final fontSizeErr = positiveIntError(fontSizeCtrl);
          final maxOutputErr = positiveIntError(maxOutputCtrl);
          final sessionMaxErr = sessionEnabled ? positiveIntError(sessionMaxEntriesCtrl) : null;

          final canCreate =
              name.isNotEmpty &&
              prompt.isNotEmpty &&
              [cooldownErr, durationErr, fontSizeErr, maxOutputErr, sessionMaxErr].every((e) => e == null);

          return AlertDialog(
            title: const Text('New AI alert'),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PromptHelpCard(
                      onInsert: (value) => setInner(() => promptCtrl.text = value),
                      onCopy: _copy,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      onChanged: (_) => setInner(() {}),
                      decoration: InputDecoration(
                        labelText: 'Name',
                        errorText: name.isEmpty ? 'Påkrævet' : null,
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: promptCtrl,
                      onChanged: (_) => setInner(() {}),
                      decoration: InputDecoration(
                        labelText: 'Prompt',
                        hintText: 'Use {{username}} and {{message}}',
                        errorText: prompt.isEmpty ? 'Påkrævet' : null,
                      ),
                      minLines: 3,
                      maxLines: 10,
                    ),
                    const SizedBox(height: 8),
                    const _VariablesHint(),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: enabled,
                      onChanged: (v) => setInner(() => enabled = v),
                      title: const Text('Enabled'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cooldownCtrl,
                      onChanged: (_) => setInner(() {}),
                      decoration: InputDecoration(
                        labelText: 'Cooldown (ms)',
                        errorText: cooldownErr,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Style (overlay)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bruges af overlay-siden (overlay_url).',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: durationCtrl,
                      onChanged: (_) => setInner(() {}),
                      decoration: InputDecoration(
                        labelText: 'Duration (ms)',
                        errorText: durationErr,
                        suffixIcon: const _HelpIcon(
                          message: 'Hvor længe teksten bliver vist på overlay efter et event.',
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: textColorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Text color (CSS)',
                        hintText: 'white / #ffffff / rgb(255,255,255)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fontFamilyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Font family (CSS)',
                        hintText: 'system-ui, Segoe UI, Arial, sans-serif',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fontSizeCtrl,
                      onChanged: (_) => setInner(() {}),
                      decoration: InputDecoration(
                        labelText: 'Font size (px)',
                        errorText: fontSizeErr,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Safety / quality',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: maxOutputCtrl,
                      onChanged: (_) => setInner(() {}),
                      decoration: InputDecoration(
                        labelText: 'Max output chars',
                        errorText: maxOutputErr,
                        suffixIcon: const _HelpIcon(
                          message: 'Sikkerhedsgrænse for længden af AI output (truncates).',
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: toneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tone (optional)',
                        hintText: 'fx “hype”, “rolig”, “tør humor”',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: languageCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Language (optional)',
                        hintText: 'fx da / en',
                      ),
                    ),
                    SwitchListTile(
                      value: noSwearing,
                      onChanged: (v) => setInner(() => noSwearing = v),
                      title: const Text('No swearing'),
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Session / context',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    SwitchListTile(
                      value: sessionEnabled,
                      onChanged: (v) => setInner(() => sessionEnabled = v),
                      title: const Text('Enable session memory'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: sessionMaxEntriesCtrl,
                      onChanged: (_) => setInner(() {}),
                      decoration: InputDecoration(
                        labelText: 'Max context entries',
                        errorText: sessionMaxErr,
                        suffixIcon: const _HelpIcon(
                          message: 'Hvor mange tidligere entries der bruges som kontekst i prompten.',
                        ),
                      ),
                      enabled: sessionEnabled,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    if (sessionEnabled)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Tip: session virker først når alerten er gemt (serveren bruger gemte settings).',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: canCreate ? () => Navigator.of(context).pop(true) : null,
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true) return;

    final name = nameCtrl.text.trim();
    final prompt = promptCtrl.text.trim();
    final cooldownMs = int.tryParse(cooldownCtrl.text.trim()) ?? 0;
    if (name.isEmpty || prompt.isEmpty) return;

    int parseIntOr(TextEditingController c, int fallback) {
      final v = int.tryParse(c.text.trim());
      return v ?? fallback;
    }

    final durationMs = parseIntOr(durationCtrl, 4500);
    final fontSizePx = parseIntOr(fontSizeCtrl, 32);
    final maxOutputChars = parseIntOr(maxOutputCtrl, 200);
    final sessionMaxEntries = parseIntOr(sessionMaxEntriesCtrl, 10);

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await widget.api.aiAlertsCreate(
        accessToken: widget.accessToken,
        name: name,
        prompt: prompt,
        isEnabled: enabled,
        cooldownMs: cooldownMs,

        durationMs: durationMs,
        textColor: textColorCtrl.text.trim().isEmpty ? 'white' : textColorCtrl.text.trim(),
        fontFamily: fontFamilyCtrl.text.trim().isEmpty
            ? 'system-ui, Segoe UI, Arial, sans-serif'
            : fontFamilyCtrl.text.trim(),
        fontSizePx: fontSizePx,
        maxOutputChars: maxOutputChars,
        tone: toneCtrl.text.trim(),
        language: languageCtrl.text.trim(),
        noSwearing: noSwearing,
        sessionEnabled: sessionEnabled,
        sessionMaxEntries: sessionMaxEntries,
      );
      await _load();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _withUsername(String? url) {
    final u = _username;
    if (url == null || url.trim().isEmpty) return null;
    if (u == null || u.isEmpty) return url;
    return url.replaceAll('{username}', Uri.encodeComponent(u));
  }

  String _buildUrlWithRawPlaceholders(
    String baseUrl, {
    required Map<String, String> params,
    bool encodeValues = true,
  }) {
    final uri = Uri.parse(baseUrl);
    final merged = <String, String>{...uri.queryParameters, ...params};

    String encodeValue(String v) {
      if (!encodeValues) return v;
      return Uri.encodeQueryComponent(v);
    }

    final query = merged.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${encodeValue(e.value)}')
        .join('&');

    final base = uri.replace(query: '').toString();
    return '$base?$query';
  }

  String _twitchTemplateUrl(
    String rawPublicUrl, {
    required bool includeAdvanced,
  }) {
    // Twitch tools typically support {var} placeholders. We must not URL-encode them.
    final base = rawPublicUrl;
    final qp = <String, String>{
      'event_id': '{event_id}',
      'viewer': '{username}',
      'message': '{message}',
      'format': 'html',
    };
    if (includeAdvanced) {
      qp.addAll({
        'event_type': '{event_type}',
        'tier': '{tier}',
        'months': '{months}',
        'bits': '{bits}',
        'amount': '{amount}',
        'raid_viewers': '{raid_viewers}',
        'channel': '{channel}',
      });
    }
    return _buildUrlWithRawPlaceholders(base, params: qp, encodeValues: false);
  }

  String _testUrl(
    String rawPublicUrl, {
    required String eventId,
    String? viewer,
    String? message,
    String? eventType,
    String? tier,
    String? months,
    String? bits,
    String? amount,
    String? raidViewers,
    String? channel,
    required bool includeAdvanced,
  }) {
    final qp = <String, String>{
      'event_id': eventId,
      if (viewer != null && viewer.trim().isNotEmpty) 'viewer': viewer.trim(),
      if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
      'format': 'html',
    };
    if (includeAdvanced) {
      if (eventType != null && eventType.trim().isNotEmpty) qp['event_type'] = eventType.trim();
      if (tier != null && tier.trim().isNotEmpty) qp['tier'] = tier.trim();
      if (months != null && months.trim().isNotEmpty) qp['months'] = months.trim();
      if (bits != null && bits.trim().isNotEmpty) qp['bits'] = bits.trim();
      if (amount != null && amount.trim().isNotEmpty) qp['amount'] = amount.trim();
      if (raidViewers != null && raidViewers.trim().isNotEmpty) qp['raid_viewers'] = raidViewers.trim();
      if (channel != null && channel.trim().isNotEmpty) qp['channel'] = channel.trim();
    }
    return _buildUrlWithRawPlaceholders(rawPublicUrl, params: qp, encodeValues: true);
  }

  Future<void> _openAlertEditor(AiAlertListItem item) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    AiAlertDetailResponse? detail;
    AiAlertPublicStatusResponse? pub;

    try {
      final results = await Future.wait([
        widget.api.aiAlertsGet(accessToken: widget.accessToken, alertId: item.id),
        widget.api.aiAlertPublicStatus(accessToken: widget.accessToken, alertId: item.id),
      ]);
      detail = results[0] as AiAlertDetailResponse;
      pub = results[1] as AiAlertPublicStatusResponse;
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    if (!mounted || detail == null || pub == null) return;

    AiAlertDetailResponse currentDetail = detail;

    final nameCtrl = TextEditingController(text: detail.name);
    final promptCtrl = TextEditingController(text: detail.prompt);
    final cooldownCtrl = TextEditingController(text: detail.cooldownMs.toString());
    var enabled = detail.isEnabled;

    // Style
    final durationCtrl = TextEditingController(text: detail.durationMs.toString());
    final textColorCtrl = TextEditingController(text: detail.textColor);
    final fontFamilyCtrl = TextEditingController(text: detail.fontFamily);
    final fontSizeCtrl = TextEditingController(text: detail.fontSizePx.toString());

    // Safety
    final maxOutputCtrl = TextEditingController(text: detail.maxOutputChars.toString());
    final toneCtrl = TextEditingController(text: detail.tone);
    final languageCtrl = TextEditingController(text: detail.language);
    var noSwearing = detail.noSwearing;

    // Session
    var sessionEnabled = detail.sessionEnabled;
    final sessionMaxEntriesCtrl = TextEditingController(text: detail.sessionMaxEntries.toString());

    final testEventIdCtrl = TextEditingController(text: 'test-${DateTime.now().millisecondsSinceEpoch}');
    final testUsernameCtrl = TextEditingController(text: _username ?? '');
    final testMessageCtrl = TextEditingController(text: 'Hello from TwitchDesk');

    final testEventTypeCtrl = TextEditingController(text: 'FOLLOW');
    final testTierCtrl = TextEditingController(text: '');
    final testMonthsCtrl = TextEditingController(text: '');
    final testBitsCtrl = TextEditingController(text: '');
    final testAmountCtrl = TextEditingController(text: '');
    final testRaidViewersCtrl = TextEditingController(text: '');
    final testChannelCtrl = TextEditingController(text: '');

    // Restore cached test fields for this alert (in-app only).
    final cached = _testFieldCache[item.id];
    if (cached != null) {
      final vEventId = cached['event_id'];
      if (vEventId != null) testEventIdCtrl.text = vEventId;
      final vViewer = cached['viewer'];
      if (vViewer != null) testUsernameCtrl.text = vViewer;
      final vMsg = cached['message'];
      if (vMsg != null) testMessageCtrl.text = vMsg;
      final vEventType = cached['event_type'];
      if (vEventType != null) testEventTypeCtrl.text = vEventType;
      final vTier = cached['tier'];
      if (vTier != null) testTierCtrl.text = vTier;
      final vMonths = cached['months'];
      if (vMonths != null) testMonthsCtrl.text = vMonths;
      final vBits = cached['bits'];
      if (vBits != null) testBitsCtrl.text = vBits;
      final vAmount = cached['amount'];
      if (vAmount != null) testAmountCtrl.text = vAmount;
      final vRaid = cached['raid_viewers'];
      if (vRaid != null) testRaidViewersCtrl.text = vRaid;
      final vChannel = cached['channel'];
      if (vChannel != null) testChannelCtrl.text = vChannel;
    }

    void cacheTestFields() {
      _testFieldCache[item.id] = {
        'event_id': testEventIdCtrl.text,
        'viewer': testUsernameCtrl.text,
        'message': testMessageCtrl.text,
        'event_type': testEventTypeCtrl.text,
        'tier': testTierCtrl.text,
        'months': testMonthsCtrl.text,
        'bits': testBitsCtrl.text,
        'amount': testAmountCtrl.text,
        'raid_viewers': testRaidViewersCtrl.text,
        'channel': testChannelCtrl.text,
      };
    }

    void attachCacheListeners() {
      testEventIdCtrl.addListener(cacheTestFields);
      testUsernameCtrl.addListener(cacheTestFields);
      testMessageCtrl.addListener(cacheTestFields);
      testEventTypeCtrl.addListener(cacheTestFields);
      testTierCtrl.addListener(cacheTestFields);
      testMonthsCtrl.addListener(cacheTestFields);
      testBitsCtrl.addListener(cacheTestFields);
      testAmountCtrl.addListener(cacheTestFields);
      testRaidViewersCtrl.addListener(cacheTestFields);
      testChannelCtrl.addListener(cacheTestFields);
    }

    attachCacheListeners();

    AiAlertPublicStatusResponse currentPub = pub;
    AiAlertFireResponse? lastFire;
    AiAlertPreviewResponse? preview;
    AiAlertSessionResponse? session;
    AiAlertStatsResponse? stats;
    String? localError;

    var includeAdvancedUrlFields = false;
    var saving = false;

    int parseIntOr(TextEditingController c, int fallback) {
      final v = int.tryParse(c.text.trim());
      return v ?? fallback;
    }

    int? parseOptInt(TextEditingController c) {
      final t = c.text.trim();
      if (t.isEmpty) return null;
      return int.tryParse(t);
    }

    double? parseOptDouble(TextEditingController c) {
      final t = c.text.trim();
      if (t.isEmpty) return null;
      return double.tryParse(t);
    }

    Future<void> refreshPublic(StateSetter setInner) async {
      try {
        final s = await widget.api.aiAlertPublicStatus(
          accessToken: widget.accessToken,
          alertId: item.id,
        );
        setInner(() => currentPub = s);
      } on ApiException catch (e) {
        setInner(() => localError = e.message);
      } catch (e) {
        setInner(() => localError = e.toString());
      }
    }

    Future<void> enablePublic(StateSetter setInner) async {
      try {
        final s = await widget.api.aiAlertPublicEnable(
          accessToken: widget.accessToken,
          alertId: item.id,
        );
        setInner(() {
          currentPub = s;
          localError = null;
        });
      } on ApiException catch (e) {
        setInner(() => localError = e.message);
      } catch (e) {
        setInner(() => localError = e.toString());
      }
    }

    Future<void> disablePublic(StateSetter setInner) async {
      try {
        await widget.api.aiAlertPublicDisable(
          accessToken: widget.accessToken,
          alertId: item.id,
        );
        await refreshPublic(setInner);
      } on ApiException catch (e) {
        setInner(() => localError = e.message);
      } catch (e) {
        setInner(() => localError = e.toString());
      }
    }

    Future<void> testFire(StateSetter setInner) async {
      final raw = currentPub.publicUrl;
      final url = _withUsername(raw);
      final eventId = testEventIdCtrl.text.trim();
      if (url == null || url.isEmpty) {
        setInner(() => localError = 'Public URL not available (check PUBLIC_BASE_URL + enable).');
        return;
      }
      if (eventId.isEmpty) {
        setInner(() => localError = 'Missing event_id');
        return;
      }

      try {
        final res = await widget.api.aiAlertFire(
          publicUrl: url,
          eventId: eventId,
          username: testUsernameCtrl.text.trim().isEmpty ? null : testUsernameCtrl.text.trim(),
          message: testMessageCtrl.text.trim().isEmpty ? null : testMessageCtrl.text.trim(),

          eventType: testEventTypeCtrl.text.trim().isEmpty ? null : testEventTypeCtrl.text.trim(),
          tier: testTierCtrl.text.trim().isEmpty ? null : testTierCtrl.text.trim(),
          months: parseOptInt(testMonthsCtrl),
          bits: parseOptInt(testBitsCtrl),
          amount: parseOptDouble(testAmountCtrl),
          raidViewers: parseOptInt(testRaidViewersCtrl),
          timestamp: DateTime.now().toUtc().toIso8601String(),
          channel: testChannelCtrl.text.trim().isEmpty ? null : testChannelCtrl.text.trim(),
        );
        setInner(() {
          lastFire = res;
          localError = null;
        });
      } on ApiException catch (e) {
        setInner(() => localError = e.message);
      } catch (e) {
        setInner(() => localError = e.toString());
      }
    }

    Future<void> testFireGet(StateSetter setInner) async {
      final raw = currentPub.publicUrl;
      final url = _withUsername(raw);
      final eventId = testEventIdCtrl.text.trim();
      if (url == null || url.isEmpty) {
        setInner(() => localError = 'Public URL not available (check PUBLIC_BASE_URL + enable).');
        return;
      }
      if (eventId.isEmpty) {
        setInner(() => localError = 'Missing event_id');
        return;
      }

      try {
        final res = await widget.api.aiAlertFireGet(
          publicUrl: url,
          eventId: eventId,
          viewer: testUsernameCtrl.text.trim().isEmpty ? null : testUsernameCtrl.text.trim(),
          message: testMessageCtrl.text.trim().isEmpty ? null : testMessageCtrl.text.trim(),

          eventType: testEventTypeCtrl.text.trim().isEmpty ? null : testEventTypeCtrl.text.trim(),
          tier: testTierCtrl.text.trim().isEmpty ? null : testTierCtrl.text.trim(),
          months: parseOptInt(testMonthsCtrl),
          bits: parseOptInt(testBitsCtrl),
          amount: parseOptDouble(testAmountCtrl),
          raidViewers: parseOptInt(testRaidViewersCtrl),
          timestamp: DateTime.now().toUtc().toIso8601String(),
          channel: testChannelCtrl.text.trim().isEmpty ? null : testChannelCtrl.text.trim(),
        );
        setInner(() {
          lastFire = res;
          localError = null;
        });
      } on ApiException catch (e) {
        setInner(() => localError = e.message);
      } catch (e) {
        setInner(() => localError = e.toString());
      }
    }

    Future<void> runPreview(StateSetter setInner) async {
      try {
        final res = await widget.api.aiAlertPreview(
          accessToken: widget.accessToken,
          alertId: item.id,
          eventId: testEventIdCtrl.text.trim().isEmpty ? null : testEventIdCtrl.text.trim(),
          username: testUsernameCtrl.text.trim().isEmpty ? null : testUsernameCtrl.text.trim(),
          message: testMessageCtrl.text.trim().isEmpty ? null : testMessageCtrl.text.trim(),
          eventType: testEventTypeCtrl.text.trim().isEmpty ? null : testEventTypeCtrl.text.trim(),
          tier: testTierCtrl.text.trim().isEmpty ? null : testTierCtrl.text.trim(),
          months: parseOptInt(testMonthsCtrl),
          bits: parseOptInt(testBitsCtrl),
          amount: parseOptDouble(testAmountCtrl),
          raidViewers: parseOptInt(testRaidViewersCtrl),
          timestamp: DateTime.now().toUtc().toIso8601String(),
          channel: testChannelCtrl.text.trim().isEmpty ? null : testChannelCtrl.text.trim(),
        );
        setInner(() {
          preview = res;
          localError = null;
        });
      } on ApiException catch (e) {
        setInner(() => localError = e.message);
      } catch (e) {
        setInner(() => localError = e.toString());
      }
    }

    Future<void> refreshSession(StateSetter setInner) async {
      try {
        final res = await widget.api.aiAlertSessionGet(
          accessToken: widget.accessToken,
          alertId: item.id,
        );
        setInner(() {
          session = res;
          localError = null;
        });
      } on ApiException catch (e) {
        setInner(() => localError = e.message);
      } catch (e) {
        setInner(() => localError = e.toString());
      }
    }

    Future<void> sessionStart(StateSetter setInner) async {
      try {
        final res = await widget.api.aiAlertSessionStart(
          accessToken: widget.accessToken,
          alertId: item.id,
        );
        setInner(() {
          session = res;
          localError = null;
        });
      } on ApiException catch (e) {
        setInner(() => localError = e.message);
      } catch (e) {
        setInner(() => localError = e.toString());
      }
    }

    Future<void> sessionStop(StateSetter setInner) async {
      try {
        final res = await widget.api.aiAlertSessionStop(
          accessToken: widget.accessToken,
          alertId: item.id,
        );
        setInner(() {
          session = res;
          localError = null;
        });
      } on ApiException catch (e) {
        setInner(() => localError = e.message);
      } catch (e) {
        setInner(() => localError = e.toString());
      }
    }

    Future<void> sessionReset(StateSetter setInner) async {
      try {
        final res = await widget.api.aiAlertSessionReset(
          accessToken: widget.accessToken,
          alertId: item.id,
        );
        setInner(() {
          session = res;
          localError = null;
        });
      } on ApiException catch (e) {
        setInner(() => localError = e.message);
      } catch (e) {
        setInner(() => localError = e.toString());
      }
    }

    Future<void> refreshStats(StateSetter setInner) async {
      try {
        final res = await widget.api.aiAlertStats(
          accessToken: widget.accessToken,
          alertId: item.id,
          days: 7,
        );
        setInner(() {
          stats = res;
          localError = null;
        });
      } on ApiException catch (e) {
        setInner(() => localError = e.message);
      } catch (e) {
        setInner(() => localError = e.toString());
      }
    }

    Future<bool> saveInDialog(StateSetter setInner) async {
      if (saving) return false;

      setInner(() {
        saving = true;
        localError = null;
      });

      final name = nameCtrl.text.trim();
      final prompt = promptCtrl.text.trim();
      final cooldownMs = int.tryParse(cooldownCtrl.text.trim()) ?? 0;
      final durationMs = parseIntOr(durationCtrl, 4500);
      final fontSizePx = parseIntOr(fontSizeCtrl, 32);
      final maxOutputChars = parseIntOr(maxOutputCtrl, 200);
      final sessionMaxEntries = parseIntOr(sessionMaxEntriesCtrl, 10);

      try {
        await widget.api.aiAlertsUpdate(
          accessToken: widget.accessToken,
          alertId: item.id,
          name: name,
          prompt: prompt,
          isEnabled: enabled,
          cooldownMs: cooldownMs,
          durationMs: durationMs,
          textColor: textColorCtrl.text.trim().isEmpty ? 'white' : textColorCtrl.text.trim(),
          fontFamily: fontFamilyCtrl.text.trim().isEmpty
              ? 'system-ui, Segoe UI, Arial, sans-serif'
              : fontFamilyCtrl.text.trim(),
          fontSizePx: fontSizePx,
          maxOutputChars: maxOutputChars,
          tone: toneCtrl.text.trim(),
          language: languageCtrl.text.trim(),
          noSwearing: noSwearing,
          sessionEnabled: sessionEnabled,
          sessionMaxEntries: sessionMaxEntries,
        );

        final updated = await widget.api.aiAlertsGet(
          accessToken: widget.accessToken,
          alertId: item.id,
        );

        // Update currentDetail and show if server adjusted values.
        currentDetail = updated;
        final adjustments = <String>[];
        void checkNum(String label, int wanted, int got) {
          if (wanted != got) adjustments.add('$label $wanted → $got');
        }

        void checkBool(String label, bool wanted, bool got) {
          if (wanted != got) adjustments.add('$label $wanted → $got');
        }

        checkNum('cooldown_ms', cooldownMs, updated.cooldownMs);
        checkNum('duration_ms', durationMs, updated.durationMs);
        checkNum('font_size_px', fontSizePx, updated.fontSizePx);
        checkNum('max_output_chars', maxOutputChars, updated.maxOutputChars);
        checkBool('session_enabled', sessionEnabled, updated.sessionEnabled);
        if (sessionEnabled) {
          checkNum('session_max_entries', sessionMaxEntries, updated.sessionMaxEntries);
        }
        checkBool('no_swearing', noSwearing, updated.noSwearing);
        checkBool('is_enabled', enabled, updated.isEnabled);

        if (adjustments.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Server adjusted: ${adjustments.join(', ')}')),
          );
        }

        setInner(() {
          // Sync any clamped values back to the UI.
          cooldownCtrl.text = updated.cooldownMs.toString();
          durationCtrl.text = updated.durationMs.toString();
          fontSizeCtrl.text = updated.fontSizePx.toString();
          maxOutputCtrl.text = updated.maxOutputChars.toString();
          sessionMaxEntriesCtrl.text = updated.sessionMaxEntries.toString();
          enabled = updated.isEnabled;
          noSwearing = updated.noSwearing;
          sessionEnabled = updated.sessionEnabled;
          saving = false;
        });

        return true;
      } on ApiException catch (e) {
        setInner(() {
          localError = e.message;
          saving = false;
        });
        return false;
      } catch (e) {
        setInner(() {
          localError = e.toString();
          saving = false;
        });
        return false;
      }
    }

    final res = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setInner) {
          final canCopy = _withUsername(currentPub.publicUrl);
          final overlayUrl = _withUsername(currentPub.overlayUrl);
          final streamUrl = _withUsername(currentPub.streamUrl);

          final rawForCopy = _withUsername(currentPub.publicUrl);

          final twitchTemplateUrl = (rawForCopy == null || rawForCopy.isEmpty)
              ? null
              : _twitchTemplateUrl(rawForCopy, includeAdvanced: includeAdvancedUrlFields);

          final testUrl = (rawForCopy == null || rawForCopy.isEmpty)
              ? null
              : _testUrl(
                  rawForCopy,
                  eventId: testEventIdCtrl.text.trim().isEmpty
                      ? 'test-${DateTime.now().millisecondsSinceEpoch}'
                      : testEventIdCtrl.text.trim(),
                  viewer: testUsernameCtrl.text,
                  message: testMessageCtrl.text,
                  eventType: testEventTypeCtrl.text,
                  tier: testTierCtrl.text,
                  months: testMonthsCtrl.text,
                  bits: testBitsCtrl.text,
                  amount: testAmountCtrl.text,
                  raidViewers: testRaidViewersCtrl.text,
                  channel: testChannelCtrl.text,
                  includeAdvanced: includeAdvancedUrlFields,
                );

          // Lazy-load session/stats once the dialog is visible.
          // This avoids extra latency before the editor opens.
          if (session == null && stats == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              refreshSession(setInner);
              refreshStats(setInner);
            });
          }

          String? nonNegativeIntError(TextEditingController c) {
            final t = c.text.trim();
            if (t.isEmpty) return 'Påkrævet';
            final v = int.tryParse(t);
            if (v == null) return 'Skal være et tal';
            if (v < 0) return 'Skal være ≥ 0';
            return null;
          }

          String? positiveIntError(TextEditingController c) {
            final t = c.text.trim();
            if (t.isEmpty) return 'Påkrævet';
            final v = int.tryParse(t);
            if (v == null) return 'Skal være et tal';
            if (v <= 0) return 'Skal være > 0';
            return null;
          }

          final name = nameCtrl.text.trim();
          final prompt = promptCtrl.text.trim();

          final cooldownErr = nonNegativeIntError(cooldownCtrl);
          final durationErr = positiveIntError(durationCtrl);
          final fontSizeErr = positiveIntError(fontSizeCtrl);
          final maxOutputErr = positiveIntError(maxOutputCtrl);
          final sessionMaxErr = sessionEnabled ? positiveIntError(sessionMaxEntriesCtrl) : null;

          final canSave =
              name.isNotEmpty &&
              prompt.isNotEmpty &&
              [cooldownErr, durationErr, fontSizeErr, maxOutputErr, sessionMaxErr].every((e) => e == null);

          final dirty =
              nameCtrl.text.trim() != currentDetail.name ||
              promptCtrl.text.trim() != currentDetail.prompt ||
              enabled != currentDetail.isEnabled ||
              (int.tryParse(cooldownCtrl.text.trim()) ?? currentDetail.cooldownMs) != currentDetail.cooldownMs ||
              (int.tryParse(durationCtrl.text.trim()) ?? currentDetail.durationMs) != currentDetail.durationMs ||
              textColorCtrl.text.trim() != currentDetail.textColor ||
              fontFamilyCtrl.text.trim() != currentDetail.fontFamily ||
              (int.tryParse(fontSizeCtrl.text.trim()) ?? currentDetail.fontSizePx) != currentDetail.fontSizePx ||
              (int.tryParse(maxOutputCtrl.text.trim()) ?? currentDetail.maxOutputChars) != currentDetail.maxOutputChars ||
              toneCtrl.text.trim() != currentDetail.tone ||
              languageCtrl.text.trim() != currentDetail.language ||
              noSwearing != currentDetail.noSwearing ||
              sessionEnabled != currentDetail.sessionEnabled ||
              (int.tryParse(sessionMaxEntriesCtrl.text.trim()) ?? currentDetail.sessionMaxEntries) !=
                  currentDetail.sessionMaxEntries;

          Future<bool> ensureSavedForTesting() async {
            if (!dirty) return true;
            if (!canSave) {
              setInner(() => localError = 'Du har ændringer, men nogle felter er ugyldige. Ret dem eller tryk Close.');
              return false;
            }
            return await saveInDialog(setInner);
          }

          return AlertDialog(
            title: Text('Edit: ${detail!.name}'),
            content: SizedBox(
              width: 720,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (localError != null) ...[
                      Text(
                        localError!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: nameCtrl,
                      onChanged: (_) => setInner(() {}),
                      decoration: InputDecoration(
                        labelText: 'Name',
                        errorText: name.isEmpty ? 'Påkrævet' : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PromptHelpCard(
                      onInsert: (value) => setInner(() => promptCtrl.text = value),
                      onCopy: _copy,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: promptCtrl,
                      onChanged: (_) => setInner(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Prompt',
                        hintText: 'Use {{username}} and {{message}}',
                      ),
                      minLines: 3,
                      maxLines: 10,
                    ),
                    const SizedBox(height: 8),
                    const _VariablesHint(),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: enabled,
                      onChanged: (v) => setInner(() => enabled = v),
                      title: const Text('Enabled'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cooldownCtrl,
                      onChanged: (_) => setInner(() {}),
                      decoration: InputDecoration(
                        labelText: 'Cooldown (ms)',
                        errorText: cooldownErr,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Text(
                      'Style (overlay)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: durationCtrl,
                      onChanged: (_) => setInner(() {}),
                      decoration: InputDecoration(
                        labelText: 'Duration (ms)',
                        errorText: durationErr,
                        suffixIcon: const _HelpIcon(message: 'Hvor længe teksten bliver vist på overlay.'),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: textColorCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Text color (CSS)',
                        hintText: 'white / #ffffff / rgb(...)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fontFamilyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Font family (CSS)',
                        hintText: 'system-ui, Segoe UI, Arial, sans-serif',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: fontSizeCtrl,
                      onChanged: (_) => setInner(() {}),
                      decoration: InputDecoration(
                        labelText: 'Font size (px)',
                        errorText: fontSizeErr,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Text(
                      'Safety / quality',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: maxOutputCtrl,
                      onChanged: (_) => setInner(() {}),
                      decoration: InputDecoration(
                        labelText: 'Max output chars',
                        errorText: maxOutputErr,
                        suffixIcon:
                            const _HelpIcon(message: 'Sikkerhedsgrænse for output længde (truncates).'),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: toneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tone (optional)',
                        hintText: 'fx hype/rolig/tør humor',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: languageCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Language (optional)',
                        hintText: 'fx da / en',
                      ),
                    ),
                    SwitchListTile(
                      value: noSwearing,
                      onChanged: (v) => setInner(() => noSwearing = v),
                      title: const Text('No swearing'),
                      contentPadding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Session / context',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refresh session',
                          onPressed: () => refreshSession(setInner),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      value: sessionEnabled,
                      onChanged: (v) => setInner(() => sessionEnabled = v),
                      title: const Text('Enable session memory'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    TextField(
                      controller: sessionMaxEntriesCtrl,
                      onChanged: (_) => setInner(() {}),
                      enabled: sessionEnabled,
                      decoration: InputDecoration(
                        labelText: 'Max context entries',
                        errorText: sessionMaxErr,
                        suffixIcon:
                            const _HelpIcon(message: 'Hvor mange tidligere entries der bruges som kontekst.'),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    if (sessionEnabled)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Tip: Session controls bruger serverens gemte settings — tryk Save efter ændringer.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (session != null)
                      Text(
                        session!.isActive
                            ? 'Active session: ${session!.sessionId ?? '-'} (entries: ${session!.contextEntries})'
                            : 'No active session (entries: ${session!.contextEntries})',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonal(
                            onPressed: sessionEnabled ? () => sessionStart(setInner) : null,
                            child: const Text('Start session'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: sessionEnabled ? () => sessionStop(setInner) : null,
                            child: const Text('Stop'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: sessionEnabled ? () => sessionReset(setInner) : null,
                            child: const Text('Reset context'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Public overlay URL',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (dirty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              'Unsaved changes',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        if (currentPub.enabled)
                          OutlinedButton(
                            onPressed: () => disablePublic(setInner),
                            child: const Text('Disable'),
                          )
                        else
                          FilledButton.tonal(
                            onPressed: () => enablePublic(setInner),
                            child: const Text('Enable'),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Refresh',
                          onPressed: () => refreshPublic(setInner),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (currentPub.publicUrl == null) ...[
                      Text(
                        currentPub.enabled
                            ? 'Enabled, but no URL was returned. Check server env: PUBLIC_BASE_URL.'
                            : 'Disabled.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ] else ...[
                      SelectableText(canCopy ?? currentPub.publicUrl!),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: canCopy == null ? null : () => _copy(canCopy),
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy'),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),
                    Text(
                      'Overlay page URL (HTML)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    if (overlayUrl == null || overlayUrl.isEmpty)
                      Text(
                        'Not available yet. Enable public and ensure PUBLIC_BASE_URL is set.',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else ...[
                      SelectableText(overlayUrl),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _copy(overlayUrl),
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy overlay URL'),
                      ),
                    ],

                    const SizedBox(height: 12),
                    Text(
                      'Stream URL (SSE)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    if (streamUrl == null || streamUrl.isEmpty)
                      Text(
                        'Not available yet. Enable public and ensure PUBLIC_BASE_URL is set.',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else ...[
                      SelectableText(streamUrl),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _copy(streamUrl),
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy stream URL'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Twitch/HTML setup (GET URL)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Twitch bruger typisk {variable}. Brug URL\'en herunder som copy/paste (den er ikke URL-encoded). Sæt de variabler dit tool understøtter. event_id skal være unik pr event.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    const _OverlayVariablesHint(),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: includeAdvancedUrlFields,
                      onChanged: (v) => setInner(() => includeAdvancedUrlFields = v),
                      title: const Text('Include advanced fields (tier/bits/months/...)'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (twitchTemplateUrl != null) ...[
                      SelectableText(twitchTemplateUrl),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _copy(twitchTemplateUrl),
                              icon: const Icon(Icons.copy),
                              label: const Text('Copy Twitch template URL'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Test URL (konkrete værdier)',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      if (testUrl != null) ...[
                        SelectableText(testUrl),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _copy(testUrl),
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy test URL'),
                        ),
                      ],
                    ] else ...[
                      Text(
                        'Enable public URL first to get the base token URL.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Stats (last 7 days)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refresh stats',
                          onPressed: () => refreshStats(setInner),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (stats == null)
                      Text(
                        'Loading…',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else if (stats!.days.isEmpty)
                      Text(
                        'No data yet.',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: stats!.days
                            .map(
                              (d) => Text(
                                '${d.day}: ok=${d.processedCount}, dup=${d.duplicateCount}, cooldown=${d.cooldownCount}, err=${d.errorCount}, openai=${d.openaiErrorCount}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            )
                            .toList(growable: false),
                      ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Text(
                      'Test fire',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: testEventIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'event_id',
                        suffixIcon: _HelpIcon(
                          message:
                              'Skal være unik for hvert event (ellers bliver det "duplicate"). Brug et timestamp/uuid fra dit tool.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: testUsernameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'viewer/username (optional)',
                        suffixIcon: _HelpIcon(
                          message:
                              'Vises i prompten som {{username}}. Det kan være follower/sub/raider navn afhængigt af event.',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: testMessageCtrl,
                      decoration: const InputDecoration(
                        labelText: 'message (optional)',
                        suffixIcon: _HelpIcon(
                          message:
                              'Vises i prompten som {{message}}. Brug fx event-type (follow/sub/raid) eller ekstra info.',
                        ),
                      ),
                      minLines: 2,
                      maxLines: 6,
                    ),

                    const SizedBox(height: 12),
                    Text(
                      'Extra fields (optional)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: testEventTypeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'event_type',
                        suffixIcon: _HelpIcon(message: 'Bliver til {{eventType}}.'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: testTierCtrl,
                      decoration: const InputDecoration(labelText: 'tier'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: testMonthsCtrl,
                      decoration: const InputDecoration(labelText: 'months'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: testBitsCtrl,
                      decoration: const InputDecoration(labelText: 'bits'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: testAmountCtrl,
                      decoration: const InputDecoration(labelText: 'amount'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: testRaidViewersCtrl,
                      decoration: const InputDecoration(labelText: 'raid_viewers'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: testChannelCtrl,
                      decoration: const InputDecoration(labelText: 'channel'),
                    ),

                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: saving
                          ? null
                          : () async {
                              final ok = await ensureSavedForTesting();
                              if (!ok) return;
                              await runPreview(setInner);
                            },
                      child: const Text('Preview prompt (no OpenAI call)'),
                    ),
                    if (preview != null) ...[
                      const SizedBox(height: 12),
                      Text('Rendered prompt:', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 6),
                      SelectableText(preview!.renderedPrompt),
                      const SizedBox(height: 10),
                      Text('Effective prompt (incl. context):',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 6),
                      SelectableText(preview!.effectivePrompt),
                    ],

                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final ok = await ensureSavedForTesting();
                              if (!ok) return;
                              await testFire(setInner);
                            },
                      child: const Text('Send test (POST)'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final ok = await ensureSavedForTesting();
                              if (!ok) return;
                              await testFireGet(setInner);
                            },
                      child: const Text('Send test (GET)'),
                    ),
                    if (lastFire != null) ...[
                      const SizedBox(height: 12),
                      Text('Status: ${lastFire!.status}'),
                      if ((lastFire!.text ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        SelectableText(lastFire!.text!),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Close'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('delete'),
                child: const Text('Delete'),
              ),
              FilledButton(
                onPressed: (!canSave || saving)
                    ? null
                    : () async {
                        final nav = Navigator.of(context);
                        final ok = await saveInDialog(setInner);
                        if (ok) {
                          nav.pop('saved');
                        }
                      },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (res == null) return;

    if (res == 'saved') {
      // Saved inside the dialog (so Preview/Test can use latest settings).
      await _load();
      return;
    }

    if (res == 'delete') {
      setState(() {
        _busy = true;
        _error = null;
      });
      try {
        await widget.api.aiAlertsDelete(accessToken: widget.accessToken, alertId: item.id);
        await _load();
      } on ApiException catch (e) {
        setState(() => _error = e.message);
      } catch (e) {
        setState(() => _error = e.toString());
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }

    if (res == 'save') {
      final name = nameCtrl.text.trim();
      final prompt = promptCtrl.text.trim();
      final cooldownMs = int.tryParse(cooldownCtrl.text.trim()) ?? 0;
      if (name.isEmpty || prompt.isEmpty) return;

      final durationMs = parseIntOr(durationCtrl, 4500);
      final fontSizePx = parseIntOr(fontSizeCtrl, 32);
      final maxOutputChars = parseIntOr(maxOutputCtrl, 200);
      final sessionMaxEntries = parseIntOr(sessionMaxEntriesCtrl, 10);

      setState(() {
        _busy = true;
        _error = null;
      });

      try {
        await widget.api.aiAlertsUpdate(
          accessToken: widget.accessToken,
          alertId: item.id,
          name: name,
          prompt: prompt,
          isEnabled: enabled,
          cooldownMs: cooldownMs,

          durationMs: durationMs,
          textColor: textColorCtrl.text.trim().isEmpty ? 'white' : textColorCtrl.text.trim(),
          fontFamily: fontFamilyCtrl.text.trim().isEmpty
              ? 'system-ui, Segoe UI, Arial, sans-serif'
              : fontFamilyCtrl.text.trim(),
          fontSizePx: fontSizePx,
          maxOutputChars: maxOutputChars,
          tone: toneCtrl.text.trim(),
          language: languageCtrl.text.trim(),
          noSwearing: noSwearing,
          sessionEnabled: sessionEnabled,
          sessionMaxEntries: sessionMaxEntries,
        );

        // Re-fetch and inform if server clamped/adjusted values.
        try {
          final updated = await widget.api.aiAlertsGet(
            accessToken: widget.accessToken,
            alertId: item.id,
          );

          final adjustments = <String>[];
          void checkNum(String label, int wanted, int got) {
            if (wanted != got) adjustments.add('$label $wanted → $got');
          }

          void checkBool(String label, bool wanted, bool got) {
            if (wanted != got) adjustments.add('$label $wanted → $got');
          }

          checkNum('cooldown_ms', cooldownMs, updated.cooldownMs);
          checkNum('duration_ms', durationMs, updated.durationMs);
          checkNum('font_size_px', fontSizePx, updated.fontSizePx);
          checkNum('max_output_chars', maxOutputChars, updated.maxOutputChars);
          checkBool('session_enabled', sessionEnabled, updated.sessionEnabled);
          if (sessionEnabled) {
            checkNum('session_max_entries', sessionMaxEntries, updated.sessionMaxEntries);
          }
          checkBool('no_swearing', noSwearing, updated.noSwearing);
          checkBool('is_enabled', enabled, updated.isEnabled);

          if (adjustments.isNotEmpty && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Server adjusted: ${adjustments.join(', ')}'),
              ),
            );
          }
        } catch (_) {
          // If this fails, we still saved successfully; ignore.
        }

        await _load();
      } on ApiException catch (e) {
        setState(() => _error = e.message);
      } catch (e) {
        setState(() => _error = e.toString());
      } finally {
        if (mounted) setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = _tokenStatus?.connected;
    final alerts = _alerts?.alerts ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Alerts'),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
          ),
          IconButton(
            onPressed: _busy ? null : _createAlert,
            icon: const Icon(Icons.add),
            tooltip: 'New alert',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                if (_busy) const LinearProgressIndicator(),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'OpenAI token',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          connected == null
                              ? 'Loading…'
                              : (connected ? 'Connected' : 'Not connected'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _tokenCtrl,
                          enabled: !_busy,
                          decoration: const InputDecoration(
                            labelText: 'Paste token to connect',
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: _busy ? null : _saveToken,
                                child: const Text('Save token'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: (_busy || connected != true) ? null : _disconnectToken,
                                child: const Text('Disconnect'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Alerts',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (alerts.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              children: [
                                const Text('No AI alerts yet.'),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: _busy ? null : _createAlert,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create your first alert'),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: alerts.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final a = alerts[index];
                              return ListTile(
                                title: Text(a.name),
                                subtitle: Text(
                                  'Updated: ${a.updatedAt} • Cooldown: ${a.cooldownMs}ms',
                                ),
                                trailing: a.isEnabled
                                    ? const Icon(Icons.check_circle_outline)
                                    : const Icon(Icons.pause_circle_outline),
                                onTap: _busy ? null : () => _openAlertEditor(a),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
