library translate;

import 'dart:convert';
import 'dart:io';

import 'package:arb_translator/src/models/arb_document.dart';
import 'package:arb_translator/src/models/arb_resource.dart';
import 'package:arb_translator/src/models/arb_resource_value.dart';
import 'package:args/args.dart';
import 'package:dart_console/dart_console.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

final encoder = JsonEncoder.withIndent('  ');
final decoder = JsonDecoder();

const _sourceArb = 'source_arb';
const _apiKey = 'api_key';
const _outputDirectory = 'output_directory';
const _languageCodes = 'language_codes';
const _outputFileName = 'output_file_name';

typedef UpdateDocument<T, R> = T Function(R text);

void main(List<String> args) async {
  final yaml = loadYaml(await File('./pubspec.yaml').readAsString()) as YamlMap;
  final name = yaml['name'] as String;
  final version = yaml['version'] as String;
  final console = Console();

  final parser = _initiateParse();
  final result = parser.parse(args);

  if (result['help'] as bool) {
    print(parser.usage);
    exit(0);
  }

  if (!result.wasParsed(_sourceArb)) {
    console.writeErrorLine('--source_arb is required.');
    exit(2);
  }

  if (!result.wasParsed(_apiKey)) {
    console.writeErrorLine('---api_key is required');
    exit(2);
  }

  final sourceArb = result[_sourceArb] as String;
  final apiKeyFilePath = result[_apiKey] as String;
  final outputFileName = result[_outputFileName] as String;
  final languageCodes = result[_languageCodes] as List<String>;
  var outputDirectory = result[_outputDirectory] as String?;

  final arbFile = File(sourceArb);
  final apiKeyFile = File(apiKeyFilePath);

  final apiKey = apiKeyFile.readAsStringSync();
  final src = arbFile.readAsStringSync();
  final arbDocument = ArbDocument.decode(src);

  outputDirectory ??=
      arbFile.path.substring(0, arbFile.path.lastIndexOf('/') + 1);

  [arbFile, apiKeyFile].forEach((element) {
    if (!element.existsSync()) {
      console.writeErrorLine('$element not found on path ${element.path}');
      exit(2);
    }
  });

  if (languageCodes.toSet().length != languageCodes.length) {
    console.writeErrorLine('Please remove language code duplicates');
    exit(2);
  }

  final width = console.windowWidth;
  // TODO: padRight this and have it the center or whatever
  final halfLength = ((width - name.length - version.length - 5) / 2).floor();

  console.writeLine('${'-' * halfLength}  $name $version  ${'-' * halfLength}');

  for (final code in languageCodes) {
    console.writeLine('• Processing for $code');

    // This logic needs to be simplified.
    // We create a
    const maxWords = 128;
    var newArbDocument = arbDocument.copyWith(locale: code);
    final wordLists = <List<String>>[];
    final callbackLists = <List<UpdateDocument<ArbResource, String>>>[];
    final resourceIdsLists = <List<String>>[];

    final wordList = <String>[];
    final callbackList = <UpdateDocument<ArbResource, String>>[];
    final resourceIdList = <String>[];

    for (final resource in arbDocument.resources.values) {
      if (wordList.length > maxWords) {
        resourceIdsLists.add(resourceIdList);
        wordLists.add(wordList);
        callbackLists.add(callbackList);
        resourceIdList.clear();
        wordList.clear();
        callbackList.clear();
      }

      resourceIdList.add(resource.id);
      wordList.add(resource.value.text);
      callbackList.add(
        (String value) {
          return resource.copyWith(value: ArbResourceValue.empty(value));
        },
      );

      final _description = resource.attributes?.description;

      if (_description != null) {
        // TODO: Duplicated code
        if (wordList.length > maxWords) {
          resourceIdsLists.add(resourceIdList);
          wordLists.add(wordList);
          callbackLists.add(callbackList);
          resourceIdList.clear();
          wordList.clear();
          callbackList.clear();
        }

        resourceIdList.add(resource.id);
        wordList.add(_description);
        callbackList.add(
          (String value) {
            return resource.copyWith(
              attributes: resource.attributes!.copyWith(
                description: value,
              ),
            );
          },
        );
      }
    }

    // FIXME: This is wrong as it might add it twice
    resourceIdsLists.add(resourceIdList);
    wordLists.add(wordList);
    callbackLists.add(callbackList);

    final futuresList = wordLists.map((_wordList) {
      return _translateNow(
        translateList: _wordList,
        parameters: <String, dynamic>{'target': code, 'key': apiKey},
      );
    }).toList();

    final translateResults = await Future.wait(futuresList);

    for (var i = 0; i < translateResults.length; i++) {
      final translateList = translateResults[i];
      final callbackList = callbackLists[i];
      final resourceIdsList = resourceIdsLists[i];

      for (var j = 0; j < translateList.length; j++) {
        final translatedWord = translateList[j];
        final callback = callbackList[j];
        final resourceId = resourceIdsList[j];

        newArbDocument = newArbDocument.copyWith(
          resources: newArbDocument.resources
            ..update(
              resourceId,
              (_) {
                final arbResource = callback(translatedWord);

                return arbResource;
              },
            ),
        );
      }
    }

    final file = await File(
      path.join(outputDirectory, outputFileName + '$code.arb'),
    ).create(recursive: true);

    file.writeAsStringSync(newArbDocument.encode());
  }

  console.setForegroundColor(ConsoleColor.brightGreen);
  console.writeLine('✓ Transalations created');
  console.resetColorAttributes();
}

Future<List<String>> _translateNow({
  required List<String> translateList,
  required Map<String, dynamic> parameters,
}) async {
  final translated = <String>[];

  parameters['q'] = translateList;

  final url =
      Uri.parse('https://translation.googleapis.com/language/translate/v2')
          .resolveUri(Uri(queryParameters: parameters));

  final data = await http.get(url);

  if (data.statusCode != 200) {
    throw http.ClientException('Error ${data.statusCode}: ${data.body}', url);
  } else {
    // TODO: We should use `googleapis` to deserialize this
    final jsonData = jsonDecode(data.body) as Map<String, dynamic>;

    final tr = List<Map<String, dynamic>>.from(
      jsonData['data']['translations'] as Iterable,
    );

    if (tr.isNotEmpty) {
      for (final i in tr) {
        translated.add(i['translatedText'] as String);
      }
    }
  }

  return translated;
}

ArgParser _initiateParse() {
  final parser = ArgParser();

  parser
    ..addFlag('help', hide: true, abbr: 'h')
    ..addOption(_sourceArb,
        help:
            'source_arb file acts as main file to translate to other [language_codes] provided.')
    ..addOption(_outputDirectory,
        help: 'directory from where source_arb file was read')
    ..addMultiOption(_languageCodes, defaultsTo: ['zh'])
    ..addOption(_apiKey, help: 'path to api_key must be provided')
    ..addOption(_outputFileName,
        defaultsTo: 'arb_translator_',
        help:
            'output_file_name is the file name used to concate before language codes');

  return parser;
}

// Translate LiteralElement
