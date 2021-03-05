library translate;

import 'dart:convert';
import 'dart:io';

import 'package:arb_translator/src/message_format.dart';
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

class Action {
  final ArbResource Function(String text) updateFunction;

  final String text;

  final String resourceId;

  final int? index;

  const Action({
    required this.updateFunction,
    required this.resourceId,
    required this.text,
    required this.index,
  });
}

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

    const maxWords = 128;
    var newArbDocument = arbDocument.copyWith(locale: code);
    final actionLists = <List<Action>>[];
    final actionList = <Action>[];

    for (final resource in arbDocument.resources.values) {
      final elements = resource.value.elements;

      for (var i = 0; i < elements.length; i++) {
        final element = elements[i];

        if (element is LiteralElement) {
          if (actionList.length > maxWords) {
            actionLists.add(actionList);
            actionList.clear();
          }

          actionList.add(
            Action(
              text: resource.value.text,
              resourceId: resource.id,
              index: i,
              updateFunction: (String value) {
                return resource.copyWith(value: ArbResourceValue.empty(value));
              },
            ),
          );
        }
      }

      final _description = resource.attributes?.description;

      if (_description != null) {
        if (actionList.length > maxWords) {
          actionLists.add(actionList);
          actionList.clear();
        }

        actionList.add(
          Action(
            text: _description,
            resourceId: resource.id,
            index: null,
            updateFunction: (String value) {
              return resource.copyWith(
                attributes: resource.attributes!.copyWith(
                  description: value,
                ),
              );
            },
          ),
        );
      }
    }

    // FIXME: This is wrong as it might add it twice
    actionLists.add(actionList);

    final futuresList = actionLists.map((actionList) {
      return _translateNow(
        translateList: actionList.map((action) => action.text).toList(),
        parameters: <String, dynamic>{'target': code, 'key': apiKey},
      );
    }).toList();

    final translateResults = await Future.wait(futuresList);

    for (var i = 0; i < translateResults.length; i++) {
      final translateList = translateResults[i];
      final actionList = actionLists[i];

      for (var j = 0; j < translateList.length; j++) {
        final translatedWord = translateList[j];
        final action = actionList[j];

        newArbDocument = newArbDocument.copyWith(
          resources: newArbDocument.resources
            ..update(
              action.resourceId,
              (_) {
                if (action.index != null) {
                  // FIXME: This is not right
                  final arbResource = action.updateFunction(translatedWord);

                  return arbResource;
                } else {
                  final arbResource = action.updateFunction(translatedWord);

                  return arbResource;
                }
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
