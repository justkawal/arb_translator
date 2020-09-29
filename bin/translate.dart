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
    print('--source_arb & --api_key are required.');
    _printUsage(parser);
    exit(2);
  }

  var sourceArbFile = result['source_arb'];
  var file = File(sourceArbFile);
  var apiKeyFile = File(apiKeyFilePath);

  [file, apiKeyFile].forEach((element) {
    if (!element.existsSync()) {
      print('$element not found on path ${element.path}');
      exit(2);
    }
  });

  var apiKey = apiKeyFile.readAsStringSync();
  print(file.path);

  var outputDirectory = result['output_directory'] ??
      file.path.substring(0, file.path.lastIndexOf('/') + 1);
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
  print(
      '  ════════════════════════════════════════════\n            arb translator (v1.0.2)\n  ════════════════════════════════════════════\n');

  for (var code in uniqueLanguageCodes) {
    print('• Processing for $code');
    var list = <List<String>>[];
    var k = 128;
    while (k < values.length) {
      list.add(values.sublist(k - 128, k));
      k += 128;
    }
    list.add(values.sublist(k - 128));

    Future.wait(list.map((l) =>
            _translateNow(l, <String, dynamic>{'target': code, 'key': apiKey})))
        .then((value) {
      var translatedMap = <String, String>{};
      var index = 0;
      for (var j = 0; j < value.length; j++) {
        for (var i = 0; i < value[j].length; i++) {
          translatedMap[keys[index]] = value[j][i];
          index++;
        }
      }
      File(path.join(outputDirectory, outputFileName + '$code.arb'))
          .create(recursive: true)
          .then((File file) {
        file.writeAsStringSync(encoder.convert(translatedMap));
      });
    });
  }
  print('✓ Transalations created');
}

void _printUsage(parser) {
  print('\nUsage: pub run arb_translator:translate [options]\n');
  print(parser.usage);
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
    ..addFlag('help', hide: true, abbr: 'h')
    ..addOption('source_arb',
        help:
            'source_arb file acts as main file to translate to other [language_codes] provided.')
    ..addOption('output_directory',
        help: 'directory from where source_arb file was read')
    ..addMultiOption('language_codes', defaultsTo: ['en', 'zh'])
    ..addOption('api_key', help: 'path to api_key must be provided')
    ..addOption('output_file_name',
        defaultsTo: 'arb_translator_',
        help:
            'output_file_name is the file name used to concate before language codes');
  return parser;
}
