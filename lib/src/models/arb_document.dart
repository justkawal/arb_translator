import 'dart:convert';

import 'package:collection/collection.dart';

import 'arb_resource.dart';

class ArbDocument {
  /// “@@locale” – (optional) a global attribute that defined locale for translated strings
  final String? locale;

  /// a minimal key-value pair with translation
  final String? appName;

  final DateTime? lastModified;

  final Map<String, ArbResource> resources;

  const ArbDocument._({
    required this.locale,
    required this.appName,
    required this.lastModified,
    required this.resources,
  });

  factory ArbDocument.empty({
    required String? locale,
    String? appName,
    DateTime? lastModified,
    Map<String, ArbResource>? resources,
  }) {
    return ArbDocument._(
      locale: locale,
      appName: appName,
      lastModified: lastModified,
      resources: resources ?? <String, ArbResource>{},
    );
  }

  Map<String, dynamic> toJson() {
    final _locale = locale;
    final _lastModified = lastModified;
    final _appName = appName;

    final resourceMap = resources.values.fold<Map<String, dynamic>>(
      <String, dynamic>{},
      (previousValue, resource) {
        return <String, dynamic>{...previousValue, ...resource.toJson()};
      },
    );

    return <String, dynamic>{
      if (_locale != null) '@@locale': _locale,
      if (_lastModified != null)
        '@@last_modified': _lastModified.toIso8601String(),
      if (_appName != null) 'appName': _appName,
      ...resourceMap,
    };
  }

  factory ArbDocument.fromJson(
    Map<String, dynamic> json, {
    required bool includeTimestampIfNull,
  }) {
    final _locale = json.remove('@@locale') as String?;
    final _appName = json.remove('appName') as String?;
    final _lastModified = json.remove('@@last_modified') as String?;

    var _dateModified = includeTimestampIfNull ? DateTime.now() : null;

    if (_lastModified != null) {
      _dateModified = DateTime.parse(_lastModified);
    }

    final resourceEntries = json.entries
        .where((entry) => !entry.key.startsWith('@'))
        .map<MapEntry<String, ArbResource>>((entry) {
      final attributesEntry = (json.entries.firstWhereOrNull(
        (_entry) => _entry.key == '@${entry.key}',
      ));

      return MapEntry(
        entry.key,
        ArbResource.fromEntries(
          textEntry: MapEntry(entry.key, entry.value as String),
          attributesEntry: attributesEntry,
        ),
      );
    });

    return ArbDocument.empty(
      locale: _locale,
      appName: _appName,
      lastModified: _dateModified,
      resources: Map<String, ArbResource>.fromEntries(resourceEntries),
    );
  }

  String encode({String indent = '  '}) {
    final encoder = JsonEncoder.withIndent(indent);
    final arbContent = encoder.convert(toJson());

    return arbContent;
  }

  factory ArbDocument.decode(
    String jsonString, {
    String? locale,
    bool includeTimestampIfNull = false,
  }) {
    final arbContent = ArbDocument.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
      includeTimestampIfNull: includeTimestampIfNull,
    );

    return arbContent;
  }

  ArbDocument copyWith({
    String? locale,
    String? appName,
    DateTime? lastModified,
    Map<String, ArbResource>? resources,
  }) {
    return ArbDocument._(
      appName: appName ?? this.appName,
      lastModified: lastModified ?? this.lastModified,
      locale: locale ?? this.locale,
      resources: resources ?? this.resources,
    );
  }
}
