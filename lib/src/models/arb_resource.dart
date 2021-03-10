import 'package:arb_translator/src/icu_parser.dart';

import 'arb_attributes.dart';
import 'base_element.dart';

enum ArbResourceType { text }

class ArbResource {
  final String id;

  final String attributeId;

  final BaseElement element;

  final ArbAttributes? attributes;

  const ArbResource._({
    required this.id,
    required this.element,
    required this.attributes,
  }) : attributeId = '@$id';

  factory ArbResource.fromEntries({
    required MapEntry<String, String> textEntry,
    required MapEntry<String, dynamic>? attributesEntry,
  }) {
    final _arbAttributes = attributesEntry?.value as Map<String, dynamic>?;

    final parseResult = IcuParser().parse(textEntry.value);

    if (parseResult.isFailure) {
      throw parseResult.message;
    }

    return ArbResource._(
      id: textEntry.key,
      element: parseResult.value,
      attributes: _arbAttributes == null
          ? null
          : ArbAttributes.fromJson(_arbAttributes),
    );
  }

  Map<String, dynamic> toJson() {
    final _attributes = attributes;

    return <String, dynamic>{
      // id: element.text,
      if (_attributes != null) attributeId: _attributes.toJson()
    };
  }

  ArbResource copyWith({
    String? id,
    BaseElement? element,
    ArbAttributes? attributes,
  }) {
    return ArbResource._(
      id: id ?? this.id,
      element: element ?? this.element,
      attributes: attributes ?? this.attributes,
    );
  }
}
