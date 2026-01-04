import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class TwitchOAuthStartResponse {
  TwitchOAuthStartResponse({required this.url, required this.redirectUri});

  final String url;
  final String redirectUri;

  factory TwitchOAuthStartResponse.fromJson(Map<String, dynamic> json) {
    return TwitchOAuthStartResponse(
      url: (json['url'] as String?) ?? '',
      redirectUri: (json['redirect_uri'] as String?) ?? '',
    );
  }
}

class TwitchUser {
  TwitchUser({
    required this.id,
    required this.login,
    required this.displayName,
    required this.profileImageUrl,
  });

  final String id;
  final String login;
  final String displayName;
  final String profileImageUrl;

  factory TwitchUser.fromJson(Map<String, dynamic> json) {
    return TwitchUser(
      id: (json['id'] as String?) ?? '',
      login: (json['login'] as String?) ?? '',
      displayName: (json['display_name'] as String?) ?? '',
      profileImageUrl: (json['profile_image_url'] as String?) ?? '',
    );
  }
}

class MeResponse {
  MeResponse({
    required this.username,
    required this.twitchClientId,
    required this.hasClientSecret,
    required this.publicTwitchAvatarEnabled,
    required this.twitchChannels,
    required this.twitchChannel,
    required this.twitchBotUsername,
  });

  final String username;
  final String twitchClientId;
  final bool hasClientSecret;
  final bool publicTwitchAvatarEnabled;
  final List<String> twitchChannels;
  final String? twitchChannel;
  final String? twitchBotUsername;

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    return MeResponse(
      username: (json['username'] as String?) ?? '',
      twitchClientId: (json['twitch_client_id'] as String?) ?? '',
      hasClientSecret: (json['has_client_secret'] as bool?) ?? false,
      publicTwitchAvatarEnabled:
          (json['public_twitch_avatar_enabled'] as bool?) ?? false,
      twitchChannels: (json['twitch_channels'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      twitchChannel: json['twitch_channel'] as String?,
      twitchBotUsername: json['twitch_bot_username'] as String?,
    );
  }
}

class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<void> health() async {
    final resp = await _http.get(AppConfig.apiUri('/health'));
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
  }

  Future<String> login({required String username, required String password}) async {
    final resp = await _http.post(
      AppConfig.apiUri('/v1/auth/login'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final token = (json['access_token'] as String?)?.trim() ?? '';
    if (token.isEmpty) {
      throw ApiException(500, 'missing access_token in response');
    }
    return token;
  }

  Future<MeResponse> me({required String accessToken}) async {
    final resp = await _http.get(
      AppConfig.apiUri('/v1/users/me'),
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return MeResponse.fromJson(json);
  }

  Future<TwitchOAuthStartResponse> twitchOauthStart({required String accessToken}) async {
    final resp = await _http.get(
      AppConfig.apiUri('/v1/twitch/oauth/start'),
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return TwitchOAuthStartResponse.fromJson(json);
  }

  Future<List<TwitchUser>> twitchUsers({
    required String accessToken,
    required String login,
  }) async {
    final q = login.trim();
    if (q.isEmpty) return const [];

    final uri = AppConfig.apiUri('/v1/twitch/users').replace(queryParameters: {'login': q});
    final resp = await _http.get(
      uri,
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final data = (json['data'] as List<dynamic>?) ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(TwitchUser.fromJson)
        .toList(growable: false);
  }

  Future<void> patchMe({
    required String accessToken,
    String? twitchClientId,
    String? twitchClientSecret,
    bool? publicTwitchAvatarEnabled,
  }) async {
    final body = <String, dynamic>{};
    if (twitchClientId != null) body['twitch_client_id'] = twitchClientId;
    if (twitchClientSecret != null) body['twitch_client_secret'] = twitchClientSecret;
    if (publicTwitchAvatarEnabled != null) {
      body['public_twitch_avatar_enabled'] = publicTwitchAvatarEnabled;
    }

    final resp = await _http.patch(
      AppConfig.apiUri('/v1/users/me'),
      headers: {
        'authorization': 'Bearer $accessToken',
        'content-type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
  }

  String _bodyOrReason(http.Response resp) {
    final body = resp.body.trim();
    if (body.isNotEmpty) return body;
    return resp.reasonPhrase ?? 'request failed';
  }
}
