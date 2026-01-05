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

// -------------------------------
// AI Alerts
// -------------------------------

class AiTokenStatusResponse {
  AiTokenStatusResponse({required this.connected});

  final bool connected;

  factory AiTokenStatusResponse.fromJson(Map<String, dynamic> json) {
    return AiTokenStatusResponse(
      connected: (json['connected'] as bool?) ?? false,
    );
  }
}

class AiAlertListItem {
  AiAlertListItem({
    required this.id,
    required this.name,
    required this.isEnabled,
    required this.cooldownMs,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final bool isEnabled;
  final int cooldownMs;
  final String updatedAt;

  factory AiAlertListItem.fromJson(Map<String, dynamic> json) {
    return AiAlertListItem(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      isEnabled: (json['is_enabled'] as bool?) ?? false,
      cooldownMs: (json['cooldown_ms'] as num?)?.toInt() ?? 0,
      updatedAt: (json['updated_at'] as String?) ?? '',
    );
  }
}

class AiAlertsListResponse {
  AiAlertsListResponse({required this.alerts});

  final List<AiAlertListItem> alerts;

  factory AiAlertsListResponse.fromJson(Map<String, dynamic> json) {
    final alerts = (json['alerts'] as List<dynamic>?) ?? const [];
    return AiAlertsListResponse(
      alerts: alerts
          .whereType<Map<String, dynamic>>()
          .map(AiAlertListItem.fromJson)
          .toList(growable: false),
    );
  }
}

class AiAlertDetailResponse {
  AiAlertDetailResponse({
    required this.id,
    required this.name,
    required this.prompt,
    required this.isEnabled,
    required this.cooldownMs,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String prompt;
  final bool isEnabled;
  final int cooldownMs;
  final String updatedAt;

  factory AiAlertDetailResponse.fromJson(Map<String, dynamic> json) {
    return AiAlertDetailResponse(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      prompt: (json['prompt'] as String?) ?? '',
      isEnabled: (json['is_enabled'] as bool?) ?? false,
      cooldownMs: (json['cooldown_ms'] as num?)?.toInt() ?? 0,
      updatedAt: (json['updated_at'] as String?) ?? '',
    );
  }
}

class AiAlertPublicStatusResponse {
  AiAlertPublicStatusResponse({required this.enabled, required this.publicUrl});

  final bool enabled;
  final String? publicUrl;

  factory AiAlertPublicStatusResponse.fromJson(Map<String, dynamic> json) {
    final url = (json['public_url'] as String?)?.trim();
    return AiAlertPublicStatusResponse(
      enabled: (json['enabled'] as bool?) ?? false,
      publicUrl: (url == null || url.isEmpty) ? null : url,
    );
  }
}

class AiAlertFireResponse {
  AiAlertFireResponse({required this.status, required this.text});

  final String status;
  final String? text;

  factory AiAlertFireResponse.fromJson(Map<String, dynamic> json) {
    final t = (json['text'] as String?)?.trim();
    return AiAlertFireResponse(
      status: (json['status'] as String?) ?? '',
      text: (t == null || t.isEmpty) ? null : t,
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

  // -------------------------------
  // AI Alerts
  // -------------------------------

  Future<AiTokenStatusResponse> aiTokenStatus({required String accessToken}) async {
    final resp = await _http.get(
      AppConfig.apiUri('/v1/ai/token'),
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return AiTokenStatusResponse.fromJson(json);
  }

  Future<void> aiTokenPut({required String accessToken, required String token}) async {
    final resp = await _http.put(
      AppConfig.apiUri('/v1/ai/token'),
      headers: {
        'authorization': 'Bearer $accessToken',
        'content-type': 'application/json',
      },
      body: jsonEncode({'token': token}),
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
  }

  Future<void> aiTokenDelete({required String accessToken}) async {
    final resp = await _http.delete(
      AppConfig.apiUri('/v1/ai/token'),
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (resp.statusCode != 204) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
  }

  Future<AiAlertsListResponse> aiAlertsList({required String accessToken}) async {
    final resp = await _http.get(
      AppConfig.apiUri('/v1/ai/alerts'),
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return AiAlertsListResponse.fromJson(json);
  }

  Future<AiAlertDetailResponse> aiAlertsCreate({
    required String accessToken,
    required String name,
    required String prompt,
    required bool isEnabled,
    required int cooldownMs,
  }) async {
    final resp = await _http.post(
      AppConfig.apiUri('/v1/ai/alerts'),
      headers: {
        'authorization': 'Bearer $accessToken',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'prompt': prompt,
        'is_enabled': isEnabled,
        'cooldown_ms': cooldownMs,
      }),
    );
    if (resp.statusCode != 201) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return AiAlertDetailResponse.fromJson(json);
  }

  Future<AiAlertDetailResponse> aiAlertsGet({
    required String accessToken,
    required String alertId,
  }) async {
    final resp = await _http.get(
      AppConfig.apiUri('/v1/ai/alerts/$alertId'),
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return AiAlertDetailResponse.fromJson(json);
  }

  Future<AiAlertDetailResponse> aiAlertsUpdate({
    required String accessToken,
    required String alertId,
    required String name,
    required String prompt,
    required bool isEnabled,
    required int cooldownMs,
  }) async {
    final resp = await _http.put(
      AppConfig.apiUri('/v1/ai/alerts/$alertId'),
      headers: {
        'authorization': 'Bearer $accessToken',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'prompt': prompt,
        'is_enabled': isEnabled,
        'cooldown_ms': cooldownMs,
      }),
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return AiAlertDetailResponse.fromJson(json);
  }

  Future<void> aiAlertsDelete({
    required String accessToken,
    required String alertId,
  }) async {
    final resp = await _http.delete(
      AppConfig.apiUri('/v1/ai/alerts/$alertId'),
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (resp.statusCode != 204) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
  }

  Future<AiAlertPublicStatusResponse> aiAlertPublicStatus({
    required String accessToken,
    required String alertId,
  }) async {
    final resp = await _http.get(
      AppConfig.apiUri('/v1/ai/alerts/$alertId/public'),
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return AiAlertPublicStatusResponse.fromJson(json);
  }

  Future<AiAlertPublicStatusResponse> aiAlertPublicEnable({
    required String accessToken,
    required String alertId,
  }) async {
    final resp = await _http.post(
      AppConfig.apiUri('/v1/ai/alerts/$alertId/public'),
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return AiAlertPublicStatusResponse.fromJson(json);
  }

  Future<void> aiAlertPublicDisable({
    required String accessToken,
    required String alertId,
  }) async {
    final resp = await _http.delete(
      AppConfig.apiUri('/v1/ai/alerts/$alertId/public'),
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (resp.statusCode != 204) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
  }

  Future<AiAlertFireResponse> aiAlertFire({
    required String publicUrl,
    required String eventId,
    String? username,
    String? message,
  }) async {
    final resp = await _http.post(
      Uri.parse(publicUrl),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'event_id': eventId,
        if (username != null) 'username': username,
        if (message != null) 'message': message,
      }),
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return AiAlertFireResponse.fromJson(json);
  }

  /// Builds an overlay-friendly GET URL for the public AI alert fire endpoint.
  ///
  /// The returned URL keeps the existing `token` query param and adds:
  /// - `event_id` (required)
  /// - `viewer` (optional)
  /// - `message` (optional)
  /// - `format` = json|text|html
  Uri aiAlertFireGetUrl({
    required String publicUrl,
    required String eventId,
    String? viewer,
    String? message,
    String format = 'json',
  }) {
    final base = Uri.parse(publicUrl);
    final qp = <String, String>{
      ...base.queryParameters,
      'event_id': eventId,
      'format': format,
    };
    final v = viewer?.trim();
    if (v != null && v.isNotEmpty) qp['viewer'] = v;
    final m = message?.trim();
    if (m != null && m.isNotEmpty) qp['message'] = m;

    return base.replace(queryParameters: qp);
  }

  /// Fires the public AI alert endpoint via GET.
  ///
  /// Prefer `format=json` for programmatic testing (it returns AiAlertFireResponse).
  Future<AiAlertFireResponse> aiAlertFireGet({
    required String publicUrl,
    required String eventId,
    String? viewer,
    String? message,
  }) async {
    final url = aiAlertFireGetUrl(
      publicUrl: publicUrl,
      eventId: eventId,
      viewer: viewer,
      message: message,
      format: 'json',
    );
    final resp = await _http.get(url);
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return AiAlertFireResponse.fromJson(json);
  }

  String _bodyOrReason(http.Response resp) {
    final body = resp.body.trim();
    if (body.isNotEmpty) return body;
    return resp.reasonPhrase ?? 'request failed';
  }
}
