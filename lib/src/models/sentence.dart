import 'base_element.dart';

abstract class SentenceElement extends BaseElement {
  const SentenceElement(ElementType type, String value) : super(type, value);
}

class LiteralElement extends SentenceElement {
  const LiteralElement(String value) : super(ElementType.literal, value);

  @override
  String toString() {
    return '$value';
  }

  LiteralElement copyWith({String? value}) {
    return LiteralElement(value ?? this.value);
  }
}

class ArgumentElement extends SentenceElement {
  const ArgumentElement(String value) : super(ElementType.argument, value);

  ArgumentElement copyWith({String? value}) {
    return ArgumentElement(value ?? this.value);
  }

  @override
  String toString() {
    return '{$value}';
  }
}

class Sentence extends BaseElement {
  final List<SentenceElement> elements;

  Sentence(this.elements) : super(ElementType.sentence, elements.join(''));

  @override
  String toString() {
    return elements.join('');
  }

  String toHtml() {
    return elements.join('');
  }

  Sentence copyWith({List<SentenceElement>? elements}) {
    return Sentence(elements ?? this.elements);
  }
}
