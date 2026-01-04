import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';

class TwitchLookupScreen extends StatefulWidget {
  const TwitchLookupScreen({
    super.key,
    required this.api,
    required this.accessToken,
  });

  final ApiClient api;
  final String accessToken;

  @override
  State<TwitchLookupScreen> createState() => _TwitchLookupScreenState();
}

class _TwitchLookupScreenState extends State<TwitchLookupScreen> {
  final _queryCtrl = TextEditingController();

  Timer? _debounce;
  bool _busy = false;
  String? _error;
  List<TwitchUser> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _search();
    });
  }

  Future<void> _search() async {
    final q = _queryCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _error = null;
        _results = const [];
        _busy = false;
      });
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final res = await widget.api.twitchUsers(accessToken: widget.accessToken, login: q);
      if (!mounted) return;
      setState(() {
        _results = res;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _results = const [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _results = const [];
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Twitch Lookup'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _queryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Twitch login',
                    hintText: 'e.g. shroud',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _onQueryChanged(),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: 12),
                if (_busy) const LinearProgressIndicator(),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 12),
                Expanded(
                  child: _results.isEmpty
                      ? Center(
                          child: Text(
                            _queryCtrl.text.trim().isEmpty
                                ? 'Type a Twitch login to look it up.'
                                : 'No users found.',
                          ),
                        )
                      : ListView.separated(
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final u = _results[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(u.profileImageUrl),
                              ),
                              title: Text(u.displayName),
                              subtitle: Text(u.login),
                              trailing: Text(u.id),
                            );
                          },
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
