import 'package:arb_translator_abcx3/src/icu_parser.dart';
import 'package:petitparser/petitparser.dart';

import 'arb_attributes.dart';

enum ArbResourceType { text }

class ArbResource {
  final String id;

  final String attributeId;

  final String text;

  final ArbAttributes? attributes;

  List<Token> get tokens => IcuParser().parse(text).value;

  const ArbResource._({
    required this.id,
    required this.text,
    required this.attributes,
  }) : attributeId = '@$id';

  factory ArbResource.fromEntries({
    required MapEntry<String, String> textEntry,
    required MapEntry<String, dynamic>? attributesEntry,
  }) {
    final _arbAttributes = attributesEntry?.value as Map<String, dynamic>?;
    final text = textEntry.value;

    return ArbResource._(
      id: textEntry.key,
      text: text,
      attributes: _arbAttributes == null ? null : ArbAttributes.fromJson(_arbAttributes),
    );
  }

  Map<String, dynamic> toJson() {
    final _attributes = attributes;

    return <String, dynamic>{id: text, if (_attributes != null) attributeId: _attributes.toJson()};
  }

  ArbResource copyWith({
    String? id,
    String? text,
    ArbAttributes? attributes,
  }) {
    return ArbResource._(
      id: id ?? this.id,
      text: text ?? this.text,
      attributes: attributes ?? this.attributes,
    );
  }
}
