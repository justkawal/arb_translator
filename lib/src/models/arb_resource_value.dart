import 'package:arb_translator/src/icu_parser.dart';
import 'package:arb_translator/src/message_format.dart';

class ArbResourceValue {
  final String text;

  final List<BaseElement> elements;

  const ArbResourceValue({
    required this.text,
    required this.elements,
  });

  // bool get hasPlaceholders => placeholders.isNotEmpty;

  factory ArbResourceValue.fromText(String text) {
    final parseResult = IcuParser().parse(text);

    if (parseResult.isFailure) {
      throw parseResult.message;
    }

    return ArbResourceValue(text: text, elements: parseResult.value);
  }

  ArbResourceValue copyWith({
    String? text,
    List<BaseElement>? elements,
  }) {
    return ArbResourceValue(
      text: text ?? this.text,
      elements: elements ?? this.elements,
    );
  }
}
