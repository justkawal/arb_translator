enum ElementType { literal, argument, plural, gender, select, sentence }

abstract class BaseElement {
  final ElementType type;

  final String value;

  const BaseElement(this.type, this.value);
}
