import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'api_client.dart';

class TemplateVersionSummary {
  TemplateVersionSummary({
    required this.version,
    required this.isPublished,
    required this.updatedAt,
  });

  final String version;
  final bool isPublished;
  final String updatedAt;

  factory TemplateVersionSummary.fromJson(Map<String, dynamic> json) {
    return TemplateVersionSummary(
      version: (json['version'] as String?) ?? '',
      isPublished: (json['is_published'] as bool?) ?? false,
      updatedAt: (json['updated_at'] as String?) ?? '',
    );
  }
}

class TemplateListItem {
  TemplateListItem({
    required this.id,
    required this.name,
    required this.updatedAt,
    required this.versions,
  });

  final String id;
  final String name;
  final String updatedAt;
  final List<TemplateVersionSummary> versions;

  factory TemplateListItem.fromJson(Map<String, dynamic> json) {
    final versions = (json['versions'] as List<dynamic>?) ?? const [];
    return TemplateListItem(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      updatedAt: (json['updated_at'] as String?) ?? '',
      versions: versions
          .whereType<Map<String, dynamic>>()
          .map(TemplateVersionSummary.fromJson)
          .toList(growable: false),
    );
  }
}

class TemplatesListResponse {
  TemplatesListResponse({required this.templates});

  final List<TemplateListItem> templates;

  factory TemplatesListResponse.fromJson(Map<String, dynamic> json) {
    final templates = (json['templates'] as List<dynamic>?) ?? const [];
    return TemplatesListResponse(
      templates: templates
          .whereType<Map<String, dynamic>>()
          .map(TemplateListItem.fromJson)
          .toList(growable: false),
    );
  }
}

class TemplateVersionResponse {
  TemplateVersionResponse({
    required this.templateId,
    required this.version,
    required this.isPublished,
    required this.updatedAt,
    required this.indexHtml,
    required this.styleCss,
    required this.overlayJs,
  });

  final String templateId;
  final String version;
  final bool isPublished;
  final String updatedAt;
  final String indexHtml;
  final String styleCss;
  final String overlayJs;

  factory TemplateVersionResponse.fromJson(Map<String, dynamic> json) {
    return TemplateVersionResponse(
      templateId: (json['template_id'] as String?) ?? '',
      version: (json['version'] as String?) ?? '',
      isPublished: (json['is_published'] as bool?) ?? false,
      updatedAt: (json['updated_at'] as String?) ?? '',
      indexHtml: (json['index_html'] as String?) ?? '',
      styleCss: (json['style_css'] as String?) ?? '',
      overlayJs: (json['overlay_js'] as String?) ?? '',
    );
  }
}

class TemplatesApi {
  TemplatesApi({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<TemplatesListResponse> listTemplates({required String accessToken}) async {
    final resp = await _http.get(
      AppConfig.apiUri('/api/templates'),
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return TemplatesListResponse.fromJson(json);
  }

  Future<void> createTemplate({required String accessToken, required String name}) async {
    final resp = await _http.post(
      AppConfig.apiUri('/api/templates'),
      headers: {
        'authorization': 'Bearer $accessToken',
        'content-type': 'application/json',
      },
      body: jsonEncode({'name': name}),
    );
    if (resp.statusCode != 201) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
  }

  Future<TemplateVersionResponse> getVersion({
    required String accessToken,
    required String templateId,
    required String version,
  }) async {
    final resp = await _http.get(
      AppConfig.apiUri('/api/templates/$templateId/versions/$version'),
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return TemplateVersionResponse.fromJson(json);
  }

  Future<TemplateVersionResponse> updateVersion({
    required String accessToken,
    required String templateId,
    required String version,
    required String indexHtml,
    required String styleCss,
    required String overlayJs,
  }) async {
    final resp = await _http.put(
      AppConfig.apiUri('/api/templates/$templateId/versions/$version'),
      headers: {
        'authorization': 'Bearer $accessToken',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'index_html': indexHtml,
        'style_css': styleCss,
        'overlay_js': overlayJs,
      }),
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return TemplateVersionResponse.fromJson(json);
  }

  Future<TemplateVersionResponse> publishVersion({
    required String accessToken,
    required String templateId,
    required String version,
  }) async {
    final resp = await _http.post(
      AppConfig.apiUri('/api/templates/$templateId/versions/$version/publish'),
      headers: {'authorization': 'Bearer $accessToken'},
    );
    if (resp.statusCode != 200) {
      throw ApiException(resp.statusCode, _bodyOrReason(resp));
    }
    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    return TemplateVersionResponse.fromJson(json);
  }

  String _bodyOrReason(http.Response resp) {
    final body = resp.body.trim();
    if (body.isNotEmpty) return body;
    return resp.reasonPhrase ?? 'request failed';
  }
}
