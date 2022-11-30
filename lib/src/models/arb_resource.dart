import 'package:arb_translator/src/icu_parser.dart';
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
    return ArbResource._(
      id: textEntry.key,
      text: textEntry.value,
      attributes: attributesEntry?.value != null
          ? ArbAttributes.fromJson(
              attributesEntry!.value as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      id: text,
      if (attributes != null) attributeId: attributes!.toJson()
    };
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
