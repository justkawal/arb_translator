enum ResourceType {
  type,
}

T enumFromString<T>(List<T> values, String value) {
  return values.firstWhere((v) => v.toString().split('.')[1] == value);
}

class ArbAttributes {
  final String? description;

  final ResourceType? type;

  // TODO: Have a better data structure for these values
  final Map<String, Map<String, dynamic>>? placeholders;

  const ArbAttributes({
    required this.description,
    required this.placeholders,
    required this.type,
  });

  bool get isEmpty => description == null && placeholders == null;

  bool get isNotEmpty => !isEmpty;

  factory ArbAttributes.fromJson(Map<String, dynamic> json) {
    final resourceType = json['type'] as String?;

    return ArbAttributes(
      description: json['description'] as String?,
      type: resourceType == null
          ? null
          : enumFromString(ResourceType.values, resourceType),
      placeholders: json['placeholders'] == null
          ? null
          : Map<String, Map<String, dynamic>>.from(
              json['placeholders'] as Map<String, dynamic>,
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (description != null) 'description': description,
      if (placeholders != null) 'placeholders': placeholders,
    };
  }

  ArbAttributes copyWith({
    String? description,
    ResourceType? type,
    Map<String, Map<String, dynamic>>? placeholders,
  }) {
    return ArbAttributes(
      description: description ?? this.description,
      type: type ?? this.type,
      placeholders: placeholders ?? this.placeholders,
    );
  }
}