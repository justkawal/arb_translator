import 'base_element.dart';

class Option {
  final String name;

  final List<BaseElement> elements;

  /// FIXME:
  /// This disregards the fact there might be another option in elements
  final String text;

  Option(this.name, this.elements) : text = elements.join('');

  @override
  String toString() {
    return '$name{$text}';
  }

  Option copyWith({
    String? name,
    List<BaseElement>? elements,
  }) {
    return Option(
      name ?? this.name,
      elements ?? this.elements,
    );
  }
}
