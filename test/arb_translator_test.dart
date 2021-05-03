import 'dart:io';

import 'package:arb_translator/src/models/arb_document.dart';
import 'package:path/path.dart' show join;
import 'package:test/test.dart';

void main() {
  final testDirectory = join(
    Directory.current.path,
    Directory.current.path.endsWith('test') ? '' : 'test',
  );

  final testFileOne = File(join(testDirectory, 'resources/example_one.arb'));
  final contents = testFileOne.readAsStringSync();

  group(
    'Correctly parses arb documents',
    () {
      final document = ArbDocument.decode(
        contents,
        includeTimestampIfNull: false,
      );

      group('Top Level Fields', () {
        test(
          'Parses document appName',
          () {
            expect(document.appName, equals('Demo app'));
          },
        );

        test(
          'Parses document locale',
          () {
            expect(document.locale, equals('en'));
          },
        );

        test(
          'Last modified is null',
          () {
            expect(document.lastModified, equals(null));
          },
        );

        test(
          'Document contains resources',
          () {
            expect(document.resources.isNotEmpty, equals(true));
          },
        );
      });

      group('Resources', () {
        final pageLoginResource = document.resources.entries.first;
        final pageHomeResource = document.resources.entries.firstWhere(
          (entry) => entry.key == 'pageHomeInboxCount',
        );

        test('resource contains correct id', () {
          expect(pageLoginResource.key, equals('pageLoginUsername'));
        });

        test('resource has same id as internal id', () {
          expect(pageLoginResource.key, equals(pageLoginResource.value.id));
        });

        test('resource has null attributes', () {
          expect(pageLoginResource.value.attributes?.isEmpty, isTrue);
        });

        test('has same id as internal', () {
          expect(pageHomeResource.key, equals(pageHomeResource.value.id));
        });

        test('has non null and correct description', () {
          expect(
            pageHomeResource.value.attributes?.description,
            equals('New messages count on the Home screen'),
          );
        });

        test('has non empty text', () {
          final text = pageHomeResource.value.text;

          expect(
            text,
            isNotEmpty,
          );
        });

        test('has non empty tokens', () {
          final tokens = pageHomeResource.value.tokens;

          expect(
            tokens.length,
            equals(3),
          );
        });

        test('has non empty attributes placeholders', () {
          expect(
            pageHomeResource.value.attributes?.placeholders?.isNotEmpty ??
                false,
            isTrue,
          );
        });

        test('There exists a key \'count\' inside placholders', () {
          expect(
            pageHomeResource.value.attributes?.placeholders
                    ?.containsKey('count') ??
                false,
            isTrue,
          );
        });
      });

      test('deserialize', () {
        final deserialized = document.encode();

        expect(deserialized, equals(contents));
      });
    },
  );

  group('translates test_file', () {
    test('General help', () async {
      final task = await Process.run(
        'flutter',
        ['pub', 'run', 'arb_translator:translate', '--help'],
      );

      expect(task.stdout, isNotEmpty);
      expect(task.stderr, isEmpty);
    });

    test('Throw error without arguments', () async {
      final task = await Process.run(
        'flutter',
        ['pub', 'run', 'arb_translator:translate'],
      );

      expect(task.stderr, isNotEmpty);
      expect(task.exitCode, greaterThan(1));
    });

    test('Throw error without api key', () async {
      final task = await Process.run(
        'flutter',
        [
          'pub',
          'run',
          'arb_translator:translate',
          '--source_arb',
          '/test_file.arb',
        ],
      );

      expect(task.stderr, isNotEmpty);
      expect(task.exitCode, greaterThan(1));
    });

    test('Translates text', () async {
      // Todo This will need a mock api t
      // final task = await Process.run(
      //   'flutter',
      //   [
      //     'pub',
      //     'run',
      //     'arb_translator:translate',
      //     '--source_arb',
      //     '/test_file.arb',
      //   ],
      // );
    });
  });
}
