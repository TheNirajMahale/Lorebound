import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'runeglass_service.dart';

/// Provider for LocalDictionaryService.
final localDictionaryServiceProvider = Provider<LocalDictionaryService>((ref) {
  final service = LocalDictionaryService();
  return service;
});

/// High-speed local offline SQLite dictionary database.
///
/// Features:
/// 1. Instant 0–2ms lookups with zero network requests.
/// 2. Pre-seeded with core English literary words.
/// 3. Automatically persists any newly looked up words from online sources for permanent offline access.
class LocalDictionaryService {
  Database? _db;
  bool _isInitialized = false;

  /// Initializes the SQLite dictionary database.
  Future<void> initialize({String? customPath}) async {
    if (_isInitialized && _db != null) return;
    try {
      final String dbPath;
      if (customPath != null) {
        dbPath = customPath;
      } else {
        final dir = await getApplicationDocumentsDirectory();
        dbPath = p.join(dir.path, 'local_dictionary.sqlite');
      }

      _db = sqlite3.open(dbPath);
      _db!.execute('''
        CREATE TABLE IF NOT EXISTS dictionary_entries (
          word TEXT PRIMARY KEY,
          entry_json TEXT NOT NULL,
          created_at INTEGER NOT NULL
        );
        CREATE INDEX IF NOT EXISTS idx_dict_word ON dictionary_entries(word);
      ''');

      _isInitialized = true;
      _seedCommonWords();
    } catch (e) {
      debugPrint('LocalDictionaryService init error: $e');
    }
  }

  /// Seeds core literary words so offline reading works out of the box without any network requests.
  void _seedCommonWords() {
    final db = _db;
    if (db == null) return;

    final countResult = db.select('SELECT COUNT(*) as count FROM dictionary_entries');
    final count = countResult.first['count'] as int? ?? 0;
    if (count > 0) return; // Already seeded

    final seeds = <String, Map<String, dynamic>>{
      'ephemeral': {
        'word': 'ephemeral',
        'meanings': [
          {
            'partOfSpeech': 'adjective',
            'definitions': [
              {
                'definition': 'Lasting for a very short time; transitory; fleeting.',
                'example': 'Fashions are ephemeral, changing with each passing season.',
              },
              {
                'definition': 'Having a very short life cycle, like certain flowers or insects.',
                'example': 'The ephemeral spring blooms vanished in a week.',
              }
            ]
          }
        ]
      },
      'serendipity': {
        'word': 'serendipity',
        'meanings': [
          {
            'partOfSpeech': 'noun',
            'definitions': [
              {
                'definition': 'The occurrence and development of events by chance in a happy or beneficial way.',
                'example': 'Finding the antique book was pure serendipity.',
              }
            ]
          }
        ]
      },
      'petrichor': {
        'word': 'petrichor',
        'meanings': [
          {
            'partOfSpeech': 'noun',
            'definitions': [
              {
                'definition': 'A pleasant smell that frequently accompanies the first rain after a long period of warm, dry weather.',
                'example': 'The rich petrichor rose from the sun-baked garden.',
              }
            ]
          }
        ]
      },
      'wanderlust': {
        'word': 'wanderlust',
        'meanings': [
          {
            'partOfSpeech': 'noun',
            'definitions': [
              {
                'definition': 'A strong desire to travel and explore the world.',
                'example': 'His wanderlust compelled him to journey across continents.',
              }
            ]
          }
        ]
      },
      'solitude': {
        'word': 'solitude',
        'meanings': [
          {
            'partOfSpeech': 'noun',
            'definitions': [
              {
                'definition': 'The state or situation of being alone, often experienced as peaceful or meditative.',
                'example': 'She savored the peace and quiet of morning solitude.',
              }
            ]
          }
        ]
      },
      'melancholy': {
        'word': 'melancholy',
        'meanings': [
          {
            'partOfSpeech': 'noun',
            'definitions': [
              {
                'definition': 'A feeling of pensive sadness, typically with no obvious cause.',
                'example': 'An air of melancholy settled over the autumn woods.',
              }
            ]
          },
          {
            'partOfSpeech': 'adjective',
            'definitions': [
              {
                'definition': 'Having a feeling of melancholy; sad and pensive.',
                'example': 'The cellist played a melancholy tune.',
              }
            ]
          }
        ]
      },
      'eloquent': {
        'word': 'eloquent',
        'meanings': [
          {
            'partOfSpeech': 'adjective',
            'definitions': [
              {
                'definition': 'Fluent or persuasive in speaking or writing; vividly expressive.',
                'example': 'The scholar gave an eloquent speech on freedom.',
              }
            ]
          }
        ]
      },
      'resilience': {
        'word': 'resilience',
        'meanings': [
          {
            'partOfSpeech': 'noun',
            'definitions': [
              {
                'definition': 'The capacity to recover quickly from difficulties; toughness.',
                'example': 'The city demonstrated remarkable resilience after the storm.',
              }
            ]
          }
        ]
      },
      'luminescence': {
        'word': 'luminescence',
        'meanings': [
          {
            'partOfSpeech': 'noun',
            'definitions': [
              {
                'definition': 'The emission of light by a substance not resulting from heat.',
                'example': 'The gentle luminescence of deep-sea creatures illuminated the dark.',
              }
            ]
          }
        ]
      },
      'ubiquitous': {
        'word': 'ubiquitous',
        'meanings': [
          {
            'partOfSpeech': 'adjective',
            'definitions': [
              {
                'definition': 'Present, appearing, or found everywhere simultaneously.',
                'example': 'Smartphones have become ubiquitous across modern life.',
              }
            ]
          }
        ]
      },
      'ineffable': {
        'word': 'ineffable',
        'meanings': [
          {
            'partOfSpeech': 'adjective',
            'definitions': [
              {
                'definition': 'Too great or extreme to be expressed or described in words.',
                'example': 'An ineffable sense of wonder gripped the explorers.',
              }
            ]
          }
        ]
      },
      'nostalgia': {
        'word': 'nostalgia',
        'meanings': [
          {
            'partOfSpeech': 'noun',
            'definitions': [
              {
                'definition': 'A sentimental longing or wistful affection for the past.',
                'example': 'Photographs from childhood filled her with warm nostalgia.',
              }
            ]
          }
        ]
      },
    };

    final stmt = db.prepare('''
      INSERT OR REPLACE INTO dictionary_entries (word, entry_json, created_at)
      VALUES (?, ?, ?)
    ''');

    for (final entry in seeds.entries) {
      final jsonStr = jsonEncode([entry.value]);
      stmt.execute([entry.key, jsonStr, DateTime.now().millisecondsSinceEpoch]);
    }

    stmt.close();
  }

  /// Looks up a word from the local SQLite database.
  Future<List<DictionaryWordEntry>?> getEntry(String word) async {
    final clean = word.trim().toLowerCase();
    if (clean.isEmpty) return null;

    try {
      if (!_isInitialized || _db == null) {
        await initialize();
      }
      final db = _db;
      if (db == null) return null;

      final stmt = db.prepare('SELECT entry_json FROM dictionary_entries WHERE word = ? LIMIT 1');
      final result = stmt.select([clean]);
      stmt.close();

      if (result.isNotEmpty) {
        final jsonStr = result.first['entry_json'] as String?;
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final decoded = jsonDecode(jsonStr);
          if (decoded is List) {
            final parsed = decoded
                .whereType<Map<String, dynamic>>()
                .map((m) => DictionaryWordEntry.fromJson(m))
                .toList();
            if (parsed.isNotEmpty) return parsed;
          }
        }
      }
    } catch (e) {
      debugPrint('LocalDictionaryService getEntry error: $e');
    }
    return null;
  }

  /// Saves a dictionary word entry into the local SQLite database for future offline access.
  Future<void> saveEntry(String word, List<DictionaryWordEntry> entries) async {
    final clean = word.trim().toLowerCase();
    if (clean.isEmpty || entries.isEmpty) return;

    try {
      if (!_isInitialized || _db == null) {
        await initialize();
      }
      final db = _db;
      if (db == null) return;

      final jsonStr = jsonEncode(entries.map((e) => {
        'word': e.word,
        'meanings': e.meanings.map((m) => {
          'partOfSpeech': m.partOfSpeech,
          'definitions': m.definitions.map((d) => {
            'definition': d.definition,
            'example': d.example,
          }).toList(),
        }).toList(),
      }).toList());

      final stmt = db.prepare('''
        INSERT OR REPLACE INTO dictionary_entries (word, entry_json, created_at)
        VALUES (?, ?, ?)
      ''');
      stmt.execute([clean, jsonStr, DateTime.now().millisecondsSinceEpoch]);
      stmt.close();
    } catch (e) {
      debugPrint('LocalDictionaryService saveEntry error: $e');
    }
  }

  void dispose() {
    _db?.close();
    _db = null;
    _isInitialized = false;
  }
}
