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

class ChannelStatus {
  ChannelStatus({required this.login, required this.isLive});

  final String login;
  final bool isLive;

  factory ChannelStatus.fromJson(Map<String, dynamic> json) {
    return ChannelStatus(
      login: (json['login'] as String?) ?? '',
      isLive: (json['is_live'] as bool?) ?? false,
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

    // Style
    required this.durationMs,
    required this.textColor,
    required this.fontFamily,
    required this.fontSizePx,

    // Safety / quality
    required this.maxOutputChars,
    required this.fallbackText,
    required this.tone,
    required this.language,
    required this.noSwearing,

    // Session/context
    required this.sessionEnabled,
    required this.sessionMaxEntries,
  });

  final String id;
  final String name;
  final String prompt;
  final bool isEnabled;
  final int cooldownMs;
  final String updatedAt;

  // Style
  final int durationMs;
  final String textColor;
  final String fontFamily;
  final int fontSizePx;

  // Safety / quality
  final int maxOutputChars;
  final String fallbackText;
  final String tone;
  final String language;
  final bool noSwearing;

  // Session/context
  final bool sessionEnabled;
  final int sessionMaxEntries;

  factory AiAlertDetailResponse.fromJson(Map<String, dynamic> json) {
    return AiAlertDetailResponse(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      prompt: (json['prompt'] as String?) ?? '',
      isEnabled: (json['is_enabled'] as bool?) ?? false,
      cooldownMs: (json['cooldown_ms'] as num?)?.toInt() ?? 0,
      updatedAt: (json['updated_at'] as String?) ?? '',

      durationMs: (json['duration_ms'] as num?)?.toInt() ?? 4500,
      textColor: (json['text_color'] as String?)?.trim() ?? 'white',
      fontFamily:
          (json['font_family'] as String?)?.trim() ?? 'system-ui, Segoe UI, Arial, sans-serif',
      fontSizePx: (json['font_size_px'] as num?)?.toInt() ?? 32,

      maxOutputChars: (json['max_output_chars'] as num?)?.toInt() ?? 200,
      fallbackText: (json['fallback_text'] as String?)?.trim() ?? '',
      tone: (json['tone'] as String?)?.trim() ?? '',
      language: (json['language'] as String?)?.trim() ?? '',
      noSwearing: (json['no_swearing'] as bool?) ?? false,

      sessionEnabled: (json['session_enabled'] as bool?) ?? false,
      sessionMaxEntries: (json['session_max_entries'] as num?)?.toInt() ?? 10,
    );
  }
}

class AiAlertPublicStatusResponse {
  AiAlertPublicStatusResponse({
    required this.enabled,
    required this.publicUrl,
    required this.overlayUrl,
    required this.streamUrl,
  });

  final bool enabled;
  final String? publicUrl;
  final String? overlayUrl;
  final String? streamUrl;

  factory AiAlertPublicStatusResponse.fromJson(Map<String, dynamic> json) {
    final url = (json['public_url'] as String?)?.trim();
    final overlay = (json['overlay_url'] as String?)?.trim();
    final stream = (json['stream_url'] as String?)?.trim();
    return AiAlertPublicStatusResponse(
      enabled: (json['enabled'] as bool?) ?? false,
      publicUrl: (url == null || url.isEmpty) ? null : url,
      overlayUrl: (overlay == null || overlay.isEmpty) ? null : overlay,
      streamUrl: (stream == null || stream.isEmpty) ? null : stream,
    );
  }
}

class AiAlertPreviewResponse {
  AiAlertPreviewResponse({required this.renderedPrompt, required this.effectivePrompt});

  final String renderedPrompt;
  final String effectivePrompt;

  factory AiAlertPreviewResponse.fromJson(Map<String, dynamic> json) {
    return AiAlertPreviewResponse(
      renderedPrompt: (json['rendered_prompt'] as String?) ?? '',
      effectivePrompt: (json['effective_prompt'] as String?) ?? '',
    );
  }
}

class AiAlertSessionResponse {
  AiAlertSessionResponse({
    required this.sessionEnabled,
    required this.isActive,
    required this.sessionId,
    required this.contextEntries,
  });

  final bool sessionEnabled;
  final bool isActive;
  final String? sessionId;
  final int contextEntries;

  factory AiAlertSessionResponse.fromJson(Map<String, dynamic> json) {
    final sid = (json['session_id'] as String?)?.trim();
    return AiAlertSessionResponse(
      sessionEnabled: (json['session_enabled'] as bool?) ?? false,
      isActive: (json['is_active'] as bool?) ?? false,
      sessionId: (sid == null || sid.isEmpty) ? null : sid,
      contextEntries: (json['context_entries'] as num?)?.toInt() ?? 0,
    );
  }
}

class AiAlertStatsDay {
  AiAlertStatsDay({
    required this.day,
    required this.processedCount,
    required this.duplicateCount,
    required this.cooldownCount,
    required this.errorCount,
    required this.openaiErrorCount,
  });

  final String day;
  final int processedCount;
  final int duplicateCount;
  final int cooldownCount;
  final int errorCount;
  final int openaiErrorCount;

  factory AiAlertStatsDay.fromJson(Map<String, dynamic> json) {
    return AiAlertStatsDay(
      day: (json['day'] as String?) ?? '',
      processedCount: (json['processed_count'] as num?)?.toInt() ?? 0,
      duplicateCount: (json['duplicate_count'] as num?)?.toInt() ?? 0,
      cooldownCount: (json['cooldown_count'] as num?)?.toInt() ?? 0,
      errorCount: (json['error_count'] as num?)?.toInt() ?? 0,
      openaiErrorCount: (json['openai_error_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class AiAlertStatsResponse {
  AiAlertStatsResponse({required this.days});

  final List<AiAlertStatsDay> days;

  factory AiAlertStatsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['days'] as List<dynamic>?) ?? const [];
    return AiAlertStatsResponse(
      days: list
          .whereType<Map<String, dynamic>>()
          .map(AiAlertStatsDay.fromJson)
          .toList(growable: false),
    );
  }
}

class AiAlertRecentVarsEvent {
  AiAlertRecentVarsEvent({
    required this.eventId,
    required this.createdAtEpoch,
    required this.vars,
  });

  final String eventId;
  final double createdAtEpoch;
  final Map<String, String> vars;

  factory AiAlertRecentVarsEvent.fromJson(Map<String, dynamic> json) {
    final rawVars = (json['vars'] as Map<String, dynamic>?) ?? const {};
    return AiAlertRecentVarsEvent(
      eventId: (json['event_id'] as String?) ?? '',
      createdAtEpoch: (json['created_at_epoch'] as num?)?.toDouble() ?? 0.0,
      vars: rawVars.map((k, v) => MapEntry(k, v.toString())),
    );
  }
}

class AiAlertRecentVarsResponse {
  AiAlertRecentVarsResponse({required this.events});

  final List<AiAlertRecentVarsEvent> events;

  factory AiAlertRecentVarsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['events'] as List<dynamic>?) ?? const [];
    return AiAlertRecentVarsResponse(
      events: list
          .whereType<Map<String, dynamic>>()
          .map(AiAlertRecentVarsEvent.fromJson)
          .toList(growable: false),
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

  Future<String> register({required String username, required String password}) async {
    final resp = await _http.post(
      AppConfig.apiUri('/v1/auth/register'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        // Backend requires a config object; defaults are applied server-side.
        'config': <String, dynamic>{},
      }),
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
    String? twitchChannel,
    bool? publicTwitchAvatarEnabled,
  }) async {
    final body = <String, dynamic>{};
    if (twitchClientId != null) body['twitch_client_id'] = twitchClientId;
    if (twitchClientSecret != null) body['twitch_client_secret'] = twitchClientSecret;
    if (twitchChannel != null) body['twitch_channel'] = twitchChannel;
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

  Future<List<ChannelStatus>> channelStatus({required String accessToken}) async {
    final resp = await _http.get(
      AppConfig.apiUri('/v1/channels/status'),
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }

    final json = jsonDecode(resp.body);
    final data = (json as List<dynamic>?) ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ChannelStatus.fromJson)
        .toList(growable: false);
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

    int durationMs = 4500,
    String textColor = 'white',
    String fontFamily = 'system-ui, Segoe UI, Arial, sans-serif',
    int fontSizePx = 32,
    int maxOutputChars = 200,
    String fallbackText = '',
    String tone = '',
    String language = '',
    bool noSwearing = false,
    bool sessionEnabled = false,
    int sessionMaxEntries = 10,
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

        'duration_ms': durationMs,
        'text_color': textColor,
        'font_family': fontFamily,
        'font_size_px': fontSizePx,
        'max_output_chars': maxOutputChars,
        'fallback_text': fallbackText,
        'tone': tone,
        'language': language,
        'no_swearing': noSwearing,
        'session_enabled': sessionEnabled,
        'session_max_entries': sessionMaxEntries,
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

    int durationMs = 4500,
    String textColor = 'white',
    String fontFamily = 'system-ui, Segoe UI, Arial, sans-serif',
    int fontSizePx = 32,
    int maxOutputChars = 200,
    String fallbackText = '',
    String tone = '',
    String language = '',
    bool noSwearing = false,
    bool sessionEnabled = false,
    int sessionMaxEntries = 10,
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

        'duration_ms': durationMs,
        'text_color': textColor,
        'font_family': fontFamily,
        'font_size_px': fontSizePx,
        'max_output_chars': maxOutputChars,
        'fallback_text': fallbackText,
        'tone': tone,
        'language': language,
        'no_swearing': noSwearing,
        'session_enabled': sessionEnabled,
        'session_max_entries': sessionMaxEntries,
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

    String? eventType,
    String? tier,
    int? months,
    int? bits,
    double? amount,
    int? raidViewers,
    String? timestamp,
    String? channel,
  }) async {
    final resp = await _http.post(
      Uri.parse(publicUrl),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'event_id': eventId,
        if (username != null) 'username': username,
        if (message != null) 'message': message,

        if (eventType != null) 'event_type': eventType,
        if (tier != null) 'tier': tier,
        if (months != null) 'months': months,
        if (bits != null) 'bits': bits,
        if (amount != null) 'amount': amount,
        if (raidViewers != null) 'raid_viewers': raidViewers,
        if (timestamp != null) 'timestamp': timestamp,
        if (channel != null) 'channel': channel,
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
  /// - `event_id` (optional)
  /// - `viewer` (optional)
  /// - `message` (optional)
  ///
  /// Note: the backend endpoint always returns plain text.
  Uri aiAlertFireGetUrl({
    required String publicUrl,
    String? eventId,
    String? viewer,
    String? message,
    String? eventType,
    String? tier,
    int? months,
    int? bits,
    double? amount,
    int? raidViewers,
    String? timestamp,
    String? channel,
  }) {
    final base = Uri.parse(publicUrl);
    final qp = <String, String>{
      ...base.queryParameters,
    };
    final eid = eventId?.trim();
    if (eid != null && eid.isNotEmpty) qp['event_id'] = eid;
    final v = viewer?.trim();
    if (v != null && v.isNotEmpty) qp['viewer'] = v;
    final m = message?.trim();
    if (m != null && m.isNotEmpty) qp['message'] = m;

    final et = eventType?.trim();
    if (et != null && et.isNotEmpty) qp['event_type'] = et;
    final ti = tier?.trim();
    if (ti != null && ti.isNotEmpty) qp['tier'] = ti;
    if (months != null) qp['months'] = months.toString();
    if (bits != null) qp['bits'] = bits.toString();
    if (amount != null) qp['amount'] = amount.toString();
    if (raidViewers != null) qp['raid_viewers'] = raidViewers.toString();
    final ts = timestamp?.trim();
    if (ts != null && ts.isNotEmpty) qp['timestamp'] = ts;
    final ch = channel?.trim();
    if (ch != null && ch.isNotEmpty) qp['channel'] = ch;

    return base.replace(queryParameters: qp);
  }

  /// Fires the public AI alert endpoint via GET.
  Future<AiAlertFireResponse> aiAlertFireGet({
    required String publicUrl,
    String? eventId,
    String? viewer,
    String? message,
    String? eventType,
    String? tier,
    int? months,
    int? bits,
    double? amount,
    int? raidViewers,
    String? timestamp,
    String? channel,
  }) async {
    final url = aiAlertFireGetUrl(
      publicUrl: publicUrl,
      eventId: eventId,
      viewer: viewer,
      message: message,
      eventType: eventType,
      tier: tier,
      months: months,
      bits: bits,
      amount: amount,
      raidViewers: raidViewers,
      timestamp: timestamp,
      channel: channel,
    );
    final resp = await _http.get(url);
    // Backend always returns text/plain.
    if (resp.statusCode == 200) {
      final text = resp.body.trim();
      if (text.isEmpty) {
        return AiAlertFireResponse(status: 'empty', text: null);
      }
      return AiAlertFireResponse(status: 'ok', text: text);
    }
    if (resp.statusCode == 429) {
      return AiAlertFireResponse(status: 'cooldown', text: null);
    }
    throw ApiException(resp.statusCode, _bodyOrReason(resp));
  }

  Future<AiAlertPreviewResponse> aiAlertPreview({
    required String accessToken,
    required String alertId,
    String? username,
    String? message,
    String? eventId,
    String? eventType,
    String? tier,
    int? months,
    int? bits,
    double? amount,
    int? raidViewers,
    String? timestamp,
    String? channel,
  }) async {
    final resp = await _http.post(
      AppConfig.apiUri('/v1/ai/alerts/$alertId/preview'),
      headers: {
        'authorization': 'Bearer $accessToken',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        if (eventId != null) 'event_id': eventId,
        if (username != null) 'username': username,
        if (message != null) 'message': message,
        if (eventType != null) 'event_type': eventType,
        if (tier != null) 'tier': tier,
        if (months != null) 'months': months,
        if (bits != null) 'bits': bits,
        if (amount != null) 'amount': amount,
        if (raidViewers != null) 'raid_viewers': raidViewers,
        if (timestamp != null) 'timestamp': timestamp,
        if (channel != null) 'channel': channel,
      }),
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return AiAlertPreviewResponse.fromJson(json);
  }

  Future<AiAlertSessionResponse> aiAlertSessionGet({
    required String accessToken,
    required String alertId,
  }) async {
    final resp = await _http.get(
      AppConfig.apiUri('/v1/ai/alerts/$alertId/session'),
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return AiAlertSessionResponse.fromJson(json);
  }

  Future<AiAlertSessionResponse> aiAlertSessionStart({
    required String accessToken,
    required String alertId,
  }) async {
    final resp = await _http.post(
      AppConfig.apiUri('/v1/ai/alerts/$alertId/session/start'),
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return AiAlertSessionResponse.fromJson(json);
  }

  Future<AiAlertSessionResponse> aiAlertSessionStop({
    required String accessToken,
    required String alertId,
  }) async {
    final resp = await _http.post(
      AppConfig.apiUri('/v1/ai/alerts/$alertId/session/stop'),
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return AiAlertSessionResponse.fromJson(json);
  }

  Future<AiAlertSessionResponse> aiAlertSessionReset({
    required String accessToken,
    required String alertId,
  }) async {
    final resp = await _http.post(
      AppConfig.apiUri('/v1/ai/alerts/$alertId/session/reset'),
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return AiAlertSessionResponse.fromJson(json);
  }

  Future<AiAlertStatsResponse> aiAlertStats({
    required String accessToken,
    required String alertId,
    int days = 7,
  }) async {
    final uri = AppConfig.apiUri('/v1/ai/alerts/$alertId/stats')
        .replace(queryParameters: {'days': days.toString()});
    final resp = await _http.get(
      uri,
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return AiAlertStatsResponse.fromJson(json);
  }

  Future<AiAlertRecentVarsResponse> aiAlertRecentVars({
    required String accessToken,
    required String alertId,
    int limit = 10,
  }) async {
    final uri = AppConfig.apiUri('/v1/ai/alerts/$alertId/recent-vars')
        .replace(queryParameters: {'limit': limit.toString()});
    final resp = await _http.get(
      uri,
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return AiAlertRecentVarsResponse.fromJson(json);
  }

  String _bodyOrReason(http.Response resp) {
    final body = resp.body.trim();
    if (body.isNotEmpty) return body;
    return resp.reasonPhrase ?? 'request failed';
  }
}
