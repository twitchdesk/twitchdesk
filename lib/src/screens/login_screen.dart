import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../config.dart';
import '../widgets/cyber/cyber_background.dart';

class LoginResult {
  LoginResult(this.accessToken);
  final String accessToken;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await widget.api.health();
      final token = await widget.api.login(
        username: _usernameCtrl.text,
        password: _passwordCtrl.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop(LoginResult(token));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openRegisterDialog() async {
    final usernameCtrl = TextEditingController(text: _usernameCtrl.text.trim());
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    try {
      final token = await showDialog<String>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setInner) {
            var busy = false;
            String? localError;

            Future<void> doRegister() async {
              final username = usernameCtrl.text.trim();
              final password = passwordCtrl.text;
              final confirm = confirmCtrl.text;

              if (username.isEmpty) {
                setInner(() => localError = 'Username er påkrævet');
                return;
              }
              if (password.isEmpty) {
                setInner(() => localError = 'Password er påkrævet');
                return;
              }
              if (password != confirm) {
                setInner(() => localError = 'Passwords matcher ikke');
                return;
              }

              setInner(() {
                busy = true;
                localError = null;
              });

              try {
                await widget.api.health();
                final token = await widget.api.register(username: username, password: password);
                if (!context.mounted) return;
                Navigator.of(context).pop(token);
              } on ApiException catch (e) {
                setInner(() {
                  localError = e.message;
                  busy = false;
                });
              } catch (e) {
                setInner(() {
                  localError = e.toString();
                  busy = false;
                });
              }
            }

            final username = usernameCtrl.text.trim();
            final password = passwordCtrl.text;
            final confirm = confirmCtrl.text;
            final canSubmit =
                !busy && username.isNotEmpty && password.isNotEmpty && confirm.isNotEmpty;

            return AlertDialog(
              title: const Text('Register account'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (localError != null) ...[
                      Text(
                        localError!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: usernameCtrl,
                      enabled: !busy,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person),
                      ),
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setInner(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordCtrl,
                      enabled: !busy,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setInner(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmCtrl,
                      enabled: !busy,
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      onSubmitted: (_) => canSubmit ? doRegister() : null,
                      onChanged: (_) => setInner(() {}),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: busy ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: canSubmit ? doRegister : null,
                  icon: busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add),
                  label: const Text('Register'),
                ),
              ],
            );
          },
        ),
      );

      if (!mounted) return;
      if (token == null || token.trim().isEmpty) return;
      Navigator.of(context).pop(LoginResult(token));
    } finally {
      usernameCtrl.dispose();
      passwordCtrl.dispose();
      confirmCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: CyberBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Hero(
                      tag: 'td_logo',
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        child: const Icon(Icons.videogame_asset_rounded, size: 28),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'TwitchDesk',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'API: ${AppConfig.apiBaseUrl}',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _usernameCtrl,
                      enabled: !_busy,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordCtrl,
                      enabled: !_busy,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      onSubmitted: (_) => _busy ? null : _doLogin(),
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _error == null
                          ? const SizedBox.shrink()
                          : Text(
                              _error!,
                              key: const ValueKey('err'),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _busy ? null : _doLogin,
                      icon: _busy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: const Text('Log in'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _openRegisterDialog,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Register'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
