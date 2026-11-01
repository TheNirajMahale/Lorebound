import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lorebound/features/reader/data/services/local_dictionary_service.dart';
import 'package:lorebound/features/reader/data/services/runeglass_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalDictionaryService localDict;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dict_test_');
    localDict = LocalDictionaryService();
    await localDict.initialize(customPath: '${tempDir.path}/test_dict.sqlite');
  });

  tearDown(() async {
    localDict.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('LocalDictionaryService Tests', () {
    test('Pre-seeds core literary words on first initialization', () async {
      final ephemeral = await localDict.getEntry('ephemeral');
      expect(ephemeral, isNotNull);
      expect(ephemeral!.isNotEmpty, isTrue);
      expect(ephemeral.first.word, 'ephemeral');
      expect(ephemeral.first.meanings.first.partOfSpeech, 'adjective');
      expect(ephemeral.first.meanings.first.definitions.first.definition, contains('Lasting for a very short time'));

      final serendipity = await localDict.getEntry('SERENDIPITY'); // case-insensitive
      expect(serendipity, isNotNull);
      expect(serendipity!.first.meanings.first.partOfSpeech, 'noun');
    });

    test('Saves new entries and retrieves them offline', () async {
      final customEntries = [
        const DictionaryWordEntry(
          word: 'halcyon',
          meanings: [
            DictionaryMeaning(
              partOfSpeech: 'adjective',
              definitions: [
                DictionaryDefinition(
                  definition: 'Denoting a period of time in the past that was idyllically happy and peaceful.',
                  example: 'the halcyon days of youth',
                ),
              ],
            ),
          ],
        ),
      ];

      await localDict.saveEntry('halcyon', customEntries);

      final retrieved = await localDict.getEntry('halcyon');
      expect(retrieved, isNotNull);
      expect(retrieved!.first.word, 'halcyon');
      expect(retrieved.first.meanings.first.definitions.first.definition, contains('idyllically happy'));
    });

    test('RuneGlassService uses local dictionary without hitting network', () async {
      final runeglass = RuneGlassService(
        localDictionary: localDict,
      );

      final results = await runeglass.lookupWord('petrichor');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.word, 'petrichor');
      expect(results.first.meanings.first.partOfSpeech, 'noun');
      expect(results.first.meanings.first.definitions.first.definition, contains('pleasant smell'));
    });
  });
}
