enum ElementType { literal, argument, plural, gender, select }

class BaseElement {
  final ElementType type;

  final String value;

  const BaseElement(this.type, this.value);
}

class Option {
  final String name;

  final List<BaseElement> value;

  const Option(this.name, this.value);
}

class LiteralElement extends BaseElement {
  const LiteralElement(String value) : super(ElementType.literal, value);
}

class ArgumentElement extends BaseElement {
  const ArgumentElement(String value) : super(ElementType.argument, value);
}

class GenderElement extends BaseElement {
  final List<Option> options;

  const GenderElement(String value, this.options)
      : super(ElementType.gender, value);
}

class PluralElement extends BaseElement {
  final List<Option> options;

  const PluralElement(String value, this.options)
      : super(ElementType.plural, value);
}

class SelectElement extends BaseElement {
  final List<Option> options;

  const SelectElement(String value, this.options)
      : super(ElementType.select, value);
}
