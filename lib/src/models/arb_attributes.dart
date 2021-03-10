import '../utils.dart';

enum ResourceType { type }

class ArbAttributes {
  final String? description;

  final ResourceType? resourceType;

  final Map<String, Map<String, dynamic>>? placeholders;

  const ArbAttributes({
    required this.description,
    required this.placeholders,
    required this.resourceType,
  });

  bool get isEmpty => description == null && placeholders == null;

  bool get isNotEmpty => !isEmpty;

  factory ArbAttributes.fromJson(Map<String, dynamic> json) {
    final resourceType = json['type'] as String?;

    return ArbAttributes(
      description: json['description'] as String?,
      resourceType: resourceType == null
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
    ResourceType? resourceType,
    Map<String, Map<String, dynamic>>? placeholders,
  }) {
    return ArbAttributes(
      description: description ?? this.description,
      resourceType: resourceType ?? this.resourceType,
      placeholders: placeholders ?? this.placeholders,
    );
  }
}
