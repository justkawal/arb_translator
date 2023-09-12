import 'dart:convert';

import 'package:http/http.dart' as http;

class DeeplTranslator {
  final List<String> translateList;
  String targetLanguageCode;
  String apiKey;

  DeeplTranslator({
    required this.translateList,
    required this.targetLanguageCode,
    required this.apiKey,
  });

  /// translate string list and return translations
  Future<List<String>> translate() async {
    final translated = <String>[];

    final url = Uri.parse('https://api.deepl.com/v2/translate');

    String requestBody = jsonEncode({
      'text': translateList,
      'target_lang': targetLanguageCode.toUpperCase(),
      'tag_handling': 'html',
    });

    final data = await http.post(
      url,
      headers: {
        'content-type': 'application/json',
        'authorization': 'DeepL-Auth-Key $apiKey',
      },
      body: requestBody,
    );

    if (data.statusCode != 200) {
      throw http.ClientException('Error ${data.statusCode}: ${data.body}', url);
    } else {
      final jsonData =
          json.decode(utf8.decode(data.bodyBytes)) as Map<String, dynamic>;


      final translations = List<Map<String, dynamic>>.from(
        jsonData['translations'] as Iterable,
      );

      if (translations.isNotEmpty) {
        for (final singleTranslation in translations) {
          translated.add(singleTranslation['text'] as String);
        }
      }
    }

    return translated;
  }
}
