library translate;

import 'dart:convert';
import 'dart:io';

import 'package:arb_translator/src/models/arb_document.dart';
import 'package:arb_translator/src/models/arb_resource.dart';
import 'package:arb_translator/src/utils.dart';
import 'package:args/args.dart';
import 'package:console/console.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

final encoder = JsonEncoder.withIndent('  ');
final decoder = JsonDecoder();

const _sourceArb = 'source_arb';
const _apiKey = 'api_key';
const _help = 'help';
const _outputDirectory = 'output_directory';
const _languageCodes = 'language_codes';
const _outputFileName = 'output_file_name';

class Action {
  final ArbResource Function(String translation, String currentText)
      updateFunction;

  final String text;

  final String resourceId;

  const Action({
    required this.updateFunction,
    required this.resourceId,
    required this.text,
  });
}

void main(List<String> args) async {
  final yaml = loadYaml(await File('./pubspec.yaml').readAsString()) as YamlMap;
  final unescape = HtmlUnescape();
  final name = yaml['name'] as String;
  final version = yaml['version'] as String;
  Console.init();

  final parser = _initiateParse();
  final result = parser.parse(args);

  if (result[_help] as bool? ?? false) {
    print(parser.usage);
    exit(0);
  }

  if (!result.wasParsed(_sourceArb)) {
    _setBrightRed();
    stderr.write('--source_arb is required.');
    exit(2);
  }

  if (!result.wasParsed(_apiKey)) {
    _setBrightRed();
    stderr.write('---api_key is required');
    exit(2);
  }

  final sourceArb = result[_sourceArb] as String;
  final apiKeyFilePath = result[_apiKey] as String;
  final outputFileName = result[_outputFileName] as String;
  final languageCodes =
      (result[_languageCodes] as List<String>).map((e) => e.trim()).toList();
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
      _setBrightRed();
      stderr.write('$element not found on path ${element.path}');
      exit(2);
    }
  });

  if (languageCodes.toSet().length != languageCodes.length) {
    _setBrightRed();
    stderr.write('Please remove language code duplicates');
    exit(2);
  }

  print('${'-' * 15}  $name $version  ${'-' * 15}');

  const maxWords = 128;
  final actionLists = <List<Action>>[];
  final actionList = <Action>[];

  for (final resource in arbDocument.resources.values) {
    final tokens = resource.tokens;

    for (final token in tokens) {
      final text = token.value as String;
      final htmlSafe = text.contains('{') ? toHtml(text) : text;

      actionList.add(
        Action(
          text: htmlSafe,
          resourceId: resource.id,
          updateFunction: (String translation, String currentText) {
            return resource.copyWith(
              text: currentText.replaceRange(
                token.start,
                token.stop,
                translation,
              ),
            );
          },
        ),
      );

      if (actionList.length >= maxWords) {
        actionLists.add([...actionList]);
        actionList.clear();
      }
    }
  }

  if (actionList.isNotEmpty) {
    actionLists.add([...actionList]);
    actionList.clear();
  }

  for (final languageCode in languageCodes) {
    print('• Processing for $languageCode');

    var newArbDocument = arbDocument.copyWith(locale: languageCode);

    final futuresList = actionLists.map((list) {
      return _translateNow(
        translateList: list.map((action) => action.text).toList(),
        parameters: <String, dynamic>{'target': languageCode, 'key': apiKey},
      );
    }).toList();

    final translateResults = await Future.wait(futuresList);

    // This is reversed so that end operations replace contents in string
    // before the beginning ones.
    for (var i = translateResults.length - 1; i >= 0; i--) {
      final translateList = translateResults[i];
      final actionList = actionLists[i];

      for (var j = translateList.length - 1; j >= 0; j--) {
        final action = actionList[j];
        final translation = translateList[j];
        final sanitizedTranslation = unescape.convert(
          translation.contains('<') ? removeHtml(translation) : translation,
        );

        newArbDocument = newArbDocument.copyWith(
          resources: newArbDocument.resources
            ..update(
              action.resourceId,
              (resource) {
                final arbResource = action.updateFunction(
                  sanitizedTranslation,
                  resource.text,
                );

                return arbResource;
              },
            ),
        );
      }
    }

    final file = await File(
      path.join(outputDirectory, outputFileName + '$languageCode.arb'),
    ).create(recursive: true);

    file.writeAsStringSync(newArbDocument.encode());
  }

  _setBrightGreen();
  print('✓ Transalations created');
  Console.resetTextColor();
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
    //  Also, we might use translate v3
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

void _setBrightGreen() {
  Console.setTextColor(2, bright: true);
}

void _setBrightRed() {
  Console.setTextColor(1, bright: true);
}

ArgParser _initiateParse() {
  final parser = ArgParser();

  parser
    ..addFlag('help', hide: true, abbr: 'h')
    ..addOption(
      _sourceArb,
      help: 'source_arb file acts as main file to be translated to other '
          '[language_codes] provided.',
    )
    ..addOption(
      _outputDirectory,
      help: 'directory from where source_arb file was read',
    )
    ..addMultiOption(_languageCodes, defaultsTo: ['es'])
    ..addOption(_apiKey, help: 'path to api_key must be provided')
    ..addOption(
      _outputFileName,
      defaultsTo: 'arb_translator_',
      help: 'output_file_name is the file name used to concate before language '
          'codes',
    );

  return parser;
}
