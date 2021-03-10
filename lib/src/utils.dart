/// Returns a string version of an enum
///
/// e.g. enum House { small, large }
/// describeEnum(House.small) -> 'small'
///
String describeEnum(Object enumEntry) {
  final description = enumEntry.toString();
  final indexOfDot = description.indexOf('.');
  assert(
    indexOfDot != -1 && indexOfDot < description.length - 1,
    'The provided object "$enumEntry" is not an enum.',
  );
  return description.substring(indexOfDot + 1);
}

/// Given enum values, returns an enum Type
T enumFromString<T>(List<T> values, String value) {
  return values.firstWhere((v) => v.toString().split('.')[1] == value);
}

const _noTranslateOpen = '<span class="notranslate">';
const _noTranslateClose = '</span>';

String removeHtml(String value) {
  return value
      // This might help in removing weird non-unicode chars
      .replaceAll(RegExp('~\p{Cf}+~u'), ' ')
      .replaceAll('  ', ' ')
      .substring('<span>'.length, value.length - '</span>'.length)
      .replaceAll(_noTranslateOpen, '{')
      .replaceAll(_noTranslateClose, '}');
}

String toHtml(String value) {
  final innerText = value
      .replaceAll('{', _noTranslateOpen)
      .replaceAll('}', _noTranslateClose);

  return '<span>$innerText</span>';
}
