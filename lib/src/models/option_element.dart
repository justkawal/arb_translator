import '../utils.dart';
import 'base_element.dart';
import 'option.dart';

abstract class OptionElement extends BaseElement {
  final List<Option> options;

  const OptionElement(ElementType type, String value, this.options)
      : super(type, value);

  @override
  String toString() {
    return '{$value, ${describeEnum(type)}, ${options.join(' ')}}';
  }
}

class GenderElement extends OptionElement {
  const GenderElement(String value, List<Option> options)
      : super(ElementType.gender, value, options);

  // This a select. Not really sure of the rules here
  @override
  String toString() {
    return '{$value, select, ${options.join(' ')}}';
  }

  GenderElement copyWith({String? value, List<Option>? options}) {
    return GenderElement(value ?? this.value, options ?? this.options);
  }
}

class PluralElement extends OptionElement {
  const PluralElement(String value, List<Option> options)
      : super(ElementType.plural, value, options);

  PluralElement copyWith({String? value, List<Option>? options}) {
    return PluralElement(value ?? this.value, options ?? this.options);
  }
}

class SelectElement extends OptionElement {
  const SelectElement(String value, List<Option> options)
      : super(ElementType.select, value, options);

  SelectElement copyWith({String? value, List<Option>? options}) {
    return SelectElement(value ?? this.value, options ?? this.options);
  }
}
