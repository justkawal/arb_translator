import 'package:arb_translator/src/icu_parser.dart';
import 'package:arb_translator/src/message_format.dart';

class ArbResourceValue {
  // TODO: This should be a getter based off elements
  String get text => elements.map((element) => element.value).join();

  final List<BaseElement> elements;

  const ArbResourceValue({required this.elements});

  factory ArbResourceValue.fromText(String text) {
    final parseResult = IcuParser().parse(text);

    if (parseResult.isFailure) {
      throw parseResult.message;
    }

    return ArbResourceValue(elements: parseResult.value);
  }

  ArbResourceValue copyWith({List<BaseElement>? elements}) {
    return ArbResourceValue(elements: elements ?? this.elements);
  }
}
