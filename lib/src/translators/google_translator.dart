import 'dart:convert';

import 'package:http/http.dart' as http;

class GoogleTranslator {
  final List<String> translateList;
  String apiKey;
  String targetLanguageCode;

  GoogleTranslator({
    required this.translateList,
    required this.targetLanguageCode,
    required this.apiKey,
  });

  /// translate string list and return translations
  Future<List<String>> translate() async {
    final translated = <String>[];

    var parameters = <String, dynamic>{
      'target': targetLanguageCode.toUpperCase(),
      'key': apiKey,
      'q': translateList,
    };

    final url =
        Uri.parse('https://translation.googleapis.com/language/translate/v2')
            .resolveUri(Uri(queryParameters: parameters));

    final data = await http.get(url);

    if (data.statusCode != 200) {
      throw http.ClientException('Error ${data.statusCode}: ${data.body}', url);
    } else {
      final jsonData = jsonDecode(data.body) as Map<String, dynamic>;

      final translations = List<Map<String, dynamic>>.from(
        jsonData['data']['translations'] as Iterable,
      );

      if (translations.isNotEmpty) {
        for (final singleTranslation in translations) {
          translated.add(singleTranslation['translatedText'] as String);
        }
      }
    }

    return translated;
  }
}
