import 'arb_attributes.dart';
import 'arb_resource_value.dart';

enum ArbResourceType { text }

class ArbResource {
  final String id;

  final String attributeId;

  // TODO: I think I can remove this value thing
  final ArbResourceValue value;

  final ArbAttributes? attributes;

  const ArbResource._({
    required this.id,
    required this.value,
    required this.attributes,
  }) : attributeId = '@$id';

  factory ArbResource.fromEntries({
    required MapEntry<String, String> textEntry,
    required MapEntry<String, dynamic>? attributesEntry,
  }) {
    final _arbAttributes = attributesEntry?.value as Map<String, dynamic>?;

    return ArbResource._(
      id: textEntry.key,
      value: ArbResourceValue.fromText(textEntry.value),
      attributes: _arbAttributes == null
          ? null
          : ArbAttributes.fromJson(_arbAttributes),
    );
  }

  Map<String, dynamic> toJson() {
    final _attributes = attributes;

    return <String, dynamic>{
      id: value.text,
      if (_attributes != null) attributeId: _attributes.toJson()
    };
  }

  ArbResource copyWith({
    String? id,
    ArbResourceValue? value,
    ArbAttributes? attributes,
  }) {
    return ArbResource._(
      id: id ?? this.id,
      value: value ?? this.value,
      attributes: attributes ?? this.attributes,
    );
  }
}
