class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'TWITCHDESK_API_BASE_URL',
    defaultValue: 'https://api.twitchdesk.com',
  );

  static Uri apiUri(String path) {
    final base = apiBaseUrl.trim().replaceAll(RegExp(r'/*$'), '');
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p');
  }
}
