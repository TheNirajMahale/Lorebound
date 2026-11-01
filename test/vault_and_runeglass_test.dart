import 'package:flutter_test/flutter_test.dart';
import 'package:lorebound/features/reader/data/services/runeglass_service.dart';
import 'package:lorebound/features/reader/domain/models/reader_config.dart';

void main() {
  group('RuneGlass Bionic Reading Tests', () {
    test('Applies bionic highlighting with correct bold boundaries', () {
      const input = 'Hello world! A test.';
      final output = RuneGlassService.applyLocalBionicHighlighting(input);

      // "Hello" length 5 -> ceil(2.5)=3: "<b>Hel</b>lo"
      // "world" length 5 -> ceil(2.5)=3: "<b>wor</b>ld"
      // "A" length 1 -> ceil(0.5)=1: "<b>A</b>"
      // "test" length 4 -> ceil(2.0)=2: "<b>te</b>st"
      expect(output, contains('<b>Hel</b>lo'));
      expect(output, contains('<b>wor</b>ld!'));
      expect(output, contains('<b>A</b>'));
      expect(output, contains('<b>te</b>st.'));
    });

    test('Preserves empty string gracefully', () {
      expect(RuneGlassService.applyLocalBionicHighlighting(''), '');
    });

    test('Preserves non-word punctuation without wrapping', () {
      const input = '... --- ...';
      expect(RuneGlassService.applyLocalBionicHighlighting(input), '... --- ...');
    });
  });

  group('RuneGlass Dictionary Response Mapping Tests', () {
    test('Parses DictionaryResponseDTO JSON accurately', () {
      final json = {
        'word': 'lore',
        'phonetics': [
          {'text': '/lɔː/', 'audio': 'https://api.dictionary.com/lore.mp3'}
        ],
        'meanings': [
          {
            'partOfSpeech': 'noun',
            'definitions': [
              {
                'definition': 'A body of traditions and knowledge on a subject or held by a particular group.',
                'example': 'Ancient Arthurian lore.'
              }
            ]
          }
        ]
      };

      final entry = DictionaryWordEntry.fromJson(json);
      expect(entry.word, 'lore');
      expect(entry.phonetics.length, 1);
      expect(entry.phonetics.first.text, '/lɔː/');
      expect(entry.meanings.length, 1);
      expect(entry.meanings.first.partOfSpeech, 'noun');
      expect(entry.meanings.first.definitions.length, 1);
      expect(entry.meanings.first.definitions.first.definition, contains('body of traditions'));
      expect(entry.meanings.first.definitions.first.example, 'Ancient Arthurian lore.');
    });
  });

  group('ReaderConfig RuneGlass Integration Tests', () {
    test('Defaults bionicReadingEnabled to false and toggles via copyWith', () {
      const config = ReaderConfig();
      expect(config.bionicReadingEnabled, isFalse);
      expect(config.autoLookupOnSelection, isTrue);

      final updated = config.copyWith(
        bionicReadingEnabled: true,
        autoLookupOnSelection: false,
      );
      expect(updated.bionicReadingEnabled, isTrue);
      expect(updated.autoLookupOnSelection, isFalse);
      expect(updated.fontSize, config.fontSize);
      expect(updated.fontFamily, config.fontFamily);
    });
  });
}
