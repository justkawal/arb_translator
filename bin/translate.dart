library translate;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

var encoder = JsonEncoder.withIndent('  ');
var decoder = JsonDecoder();

void main(List<String> args) {
  var parser = _initiateParse();
  var result = parser.parse(args);
  var sourceArb = result['source_arb'];
  var apiKeyFilePath = result['api_key'];

  if (sourceArb == null || apiKeyFilePath == null) {
    print(
        '--source_arb are mush to be needed && --api_key are must to be needed');
    print('\nUsage: pub run arb_translator:translate [options]\n');
    print(parser.usage);
    exit(0);
  }

  var sourceArbFile = result['source_arb'];
  var file = File(sourceArbFile);
  var apiKeyFile = File(apiKeyFilePath);

  [file, apiKeyFile].forEach((element) {
    if (!element.existsSync()) {
      print('$element not found on path ${element.path}');
      exit(0);
    }
  });

  var apiKey = apiKeyFile.readAsStringSync();

  var outputDirectory = result['output_directory'];
  List<String> languageCodes = result['language_codes'];

  // read source file contents
  var src = file.readAsStringSync();

  // convert source_arb json file into map
  Map<String, dynamic> data = decoder.convert(src);

  // Removing dublicate codes from list of languageCodes
  var uniqueLanguageCodes = LinkedHashSet<String>.from(languageCodes).toList();
  var keys = data.entries.map((e) => e.key).toList();
  var values = data.entries.map((e) => e.value.toString()).toList();

  var outputFileName = result['output_file_name'];

  for (var code in uniqueLanguageCodes) {
    Future.wait([
      _translateNow(values, <String, dynamic>{'target': code, 'key': apiKey})
    ]).then((value) {
      var translatedMap = <String, String>{};
      for (var i = 0; i < value[0].length; i++) {
        translatedMap[keys[i]] = value[0][i];
      }
      File(path.join(outputDirectory, outputFileName + '_$code.arb'))
          .create(recursive: true)
          .then((File file) {
        file.writeAsStringSync(encoder.convert(translatedMap));
      });
    });
  }
}

Future<List<String>> _translateNow(
    List<String> translateList, var parameters) async {
  var translated = List<String>.from(translateList);
  parameters['q'] = translateList;

  final url =
      Uri.parse('https://translation.googleapis.com/language/translate/v2')
          .resolveUri(Uri(queryParameters: parameters));
  final data = await http.get(url);

  if (data.statusCode != 200) {
    throw http.ClientException('Error ${data.statusCode}: ${data.body}', url);
  } else {
    final jsonData = jsonDecode(data.body);
    var tr = jsonData['data']['translations'];
    if (tr.length > 0) {
      translated = <String>[];
      for (var i in tr) {
        translated.add(i['translatedText']);
      }
    }
  }
  return translated;
}

ArgParser _initiateParse() {
  var parser = ArgParser();
  parser
    ..addOption('source_arb',
        help:
            'source_arb file acts as main file to translate to other [language_codes] provided.')
    ..addOption('output_directory', defaultsTo: './')
    ..addMultiOption('language_codes', defaultsTo: ['en'])
    ..addOption('api_key', help: 'path to api_key must be provided')
    ..addOption('output_file_name',
        defaultsTo: 'arb_translator_translated',
        help:
            'output_file_name is the file name used to concate before language codes');
  return parser;
}
