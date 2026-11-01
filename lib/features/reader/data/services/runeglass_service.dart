import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_client.dart';
import 'local_dictionary_service.dart';

/// Provider for RuneGlassService.
final runeglassServiceProvider = Provider<RuneGlassService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final localDict = ref.watch(localDictionaryServiceProvider);
  return RuneGlassService(apiClient: apiClient, localDictionary: localDict);
});

/// Models representing dictionary lookup results from LoreKeeper `/dictionary/{word}`.
class DictionaryWordEntry {
  final String word;
  final List<DictionaryPhonetic> phonetics;
  final List<DictionaryMeaning> meanings;

  const DictionaryWordEntry({
    required this.word,
    this.phonetics = const [],
    this.meanings = const [],
  });

  factory DictionaryWordEntry.fromJson(Map<String, dynamic> json) {
    final phoneticsRaw = json['phonetics'] as List? ?? [];
    final meaningsRaw = json['meanings'] as List? ?? [];

    return DictionaryWordEntry(
      word: json['word']?.toString() ?? '',
      phonetics: phoneticsRaw
          .whereType<Map<String, dynamic>>()
          .map((p) => DictionaryPhonetic.fromJson(p))
          .toList(),
      meanings: meaningsRaw
          .whereType<Map<String, dynamic>>()
          .map((m) => DictionaryMeaning.fromJson(m))
          .toList(),
    );
  }
}

class DictionaryPhonetic {
  final String? text;
  final String? audio;

  const DictionaryPhonetic({this.text, this.audio});

  factory DictionaryPhonetic.fromJson(Map<String, dynamic> json) {
    return DictionaryPhonetic(
      text: json['text']?.toString(),
      audio: json['audio']?.toString(),
    );
  }
}

class DictionaryMeaning {
  final String partOfSpeech;
  final List<DictionaryDefinition> definitions;

  const DictionaryMeaning({
    required this.partOfSpeech,
    this.definitions = const [],
  });

  factory DictionaryMeaning.fromJson(Map<String, dynamic> json) {
    final defsRaw = json['definitions'] as List? ?? [];
    return DictionaryMeaning(
      partOfSpeech: json['partOfSpeech']?.toString() ?? '',
      definitions: defsRaw
          .whereType<Map<String, dynamic>>()
          .map((d) => DictionaryDefinition.fromJson(d))
          .toList(),
    );
  }
}

class DictionaryDefinition {
  final String definition;
  final String? example;

  const DictionaryDefinition({
    required this.definition,
    this.example,
  });

  factory DictionaryDefinition.fromJson(Map<String, dynamic> json) {
    return DictionaryDefinition(
      definition: json['definition']?.toString() ?? '',
      example: json['example']?.toString(),
    );
  }
}

/// Service handling RuneGlass features:
/// 1. Bionic reading transformation (via LoreKeeper `POST /highlight` or offline fallback).
/// 2. Word definitions (via LoreKeeper `GET /dictionary/{word}`).
class RuneGlassService {
  final ApiClient? apiClient;
  final LocalDictionaryService? localDictionary;
  final Dio _directDio;
  final Map<String, List<DictionaryWordEntry>> _dictionaryCache = {};

  RuneGlassService({
    this.apiClient,
    this.localDictionary,
    Dio? directDio,
  }) : _directDio = directDio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 5),
                receiveTimeout: const Duration(seconds: 5),
              ),
            );

  static final RegExp _wordPattern = RegExp(r"\p{L}[\p{L}'-]*|[^\p{L}]+", unicode: true);

  /// Transforms text using LoreKeeper's Bionic Reading algorithm.
  /// If online, sends raw text to `POST /highlight`.
  /// If offline or server is unreachable, falls back to the exact local regex algorithm.
  Future<String> highlight(String text) async {
    if (text.isEmpty) return '';

    if (apiClient != null) {
      try {
        final response = await apiClient!.post<String>(
          '/highlight',
          data: text,
          options: Options(
            headers: {'Content-Type': 'text/plain'},
            responseType: ResponseType.plain,
          ),
        );
        if (response.data != null && response.data!.isNotEmpty) {
          return response.data!;
        }
      } catch (_) {
        // Fallback to local bionic transformation
      }
    }

    return applyLocalBionicHighlighting(text);
  }

  /// Local bionic highlighting algorithm identical to Spring Boot `HighlightService.java`.
  static String applyLocalBionicHighlighting(String text) {
    if (text.isEmpty) return '';

    final buffer = StringBuffer();
    final matches = _wordPattern.allMatches(text);

    for (final match in matches) {
      final token = match.group(0) ?? '';
      if (token.isEmpty) continue;

      // Check if token starts with a letter
      final isLetter = RegExp(r'^\p{L}', unicode: true).hasMatch(token);

      if (!isLetter) {
        buffer.write(token);
        continue;
      }

      final boldBoundary = (token.length / 2.0).ceil();
      buffer.write('<b>');
      buffer.write(token.substring(0, boldBoundary));
      buffer.write('</b>');
      buffer.write(token.substring(boldBoundary));
    }

    return buffer.toString();
  }

  /// Looks up definitions and phonetics for a word:
  /// 1. Sanitizes punctuation, quotes, and whitespace.
  /// 2. Checks in-memory cache for instant 0ms response.
  /// 3. Queries Free Dictionary API directly with fallback to LoreKeeper proxy.
  /// 4. Handles inflected forms (plurals, past tense) via lemma heuristics.
  Future<List<DictionaryWordEntry>> lookupWord(String word) async {
    // Strip leading/trailing punctuation, quotes, brackets
    String cleanWord = word.trim().replaceAll(RegExp(r'^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$', unicode: true), '').toLowerCase();

    // If selection contains spaces, take the first word for dictionary lookup
    if (cleanWord.contains(' ')) {
      final words = cleanWord.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      if (words.isNotEmpty) {
        cleanWord = words.first;
      }
    }

    if (cleanWord.isEmpty) return [];

    // 1. Check memory cache (0ms)
    if (_dictionaryCache.containsKey(cleanWord)) {
      return _dictionaryCache[cleanWord]!;
    }

    // 2. Query Local SQLite Dictionary (Tier 0: 0-2ms, 100% offline)
    if (localDictionary != null) {
      final localResults = await localDictionary!.getEntry(cleanWord);
      if (localResults != null && localResults.isNotEmpty) {
        _dictionaryCache[cleanWord] = localResults;
        return localResults;
      }
    }

    // 3. Online Fetch (Tier 1: Free Dictionary API -> Tier 2: LoreKeeper proxy)
    List<DictionaryWordEntry> results = await _fetchDictionaryEntries(cleanWord);

    // If no direct result found, attempt root word / lemma heuristics
    if (results.isEmpty) {
      String? fallbackWord;
      if (cleanWord.endsWith("'s")) {
        fallbackWord = cleanWord.substring(0, cleanWord.length - 2);
      } else if (cleanWord.endsWith("s") && cleanWord.length > 3 && !cleanWord.endsWith("ss")) {
        fallbackWord = cleanWord.substring(0, cleanWord.length - 1);
      } else if (cleanWord.endsWith("ed") && cleanWord.length > 4) {
        fallbackWord = cleanWord.substring(0, cleanWord.length - 2);
      } else if (cleanWord.endsWith("ing") && cleanWord.length > 5) {
        fallbackWord = cleanWord.substring(0, cleanWord.length - 3);
      }

      if (fallbackWord != null && fallbackWord.isNotEmpty) {
        // Check local SQLite for fallback lemma
        if (localDictionary != null) {
          final localFallback = await localDictionary!.getEntry(fallbackWord);
          if (localFallback != null && localFallback.isNotEmpty) {
            _dictionaryCache[cleanWord] = localFallback;
            return localFallback;
          }
        }
        results = await _fetchDictionaryEntries(fallbackWord);
      }
    }

    if (results.isNotEmpty) {
      _dictionaryCache[cleanWord] = results;
      // Persist to local SQLite so subsequent lookups are 100% offline
      localDictionary?.saveEntry(cleanWord, results);
    }

    return results;
  }

  Future<List<DictionaryWordEntry>> _fetchDictionaryEntries(String word) async {
    // Tier 1: Direct query to Free Dictionary API
    try {
      final response = await _directDio.get<dynamic>(
        'https://api.dictionaryapi.dev/api/v2/entries/en/${Uri.encodeComponent(word)}',
      );
      final data = response.data;
      if (data is List) {
        final parsed = data
            .whereType<Map<String, dynamic>>()
            .map((item) => DictionaryWordEntry.fromJson(item))
            .toList();
        if (parsed.isNotEmpty) return parsed;
      }
    } catch (_) {}

    // Tier 2: Fallback query to LoreKeeper proxy /dictionary/{word}
    if (apiClient != null) {
      try {
        final response = await apiClient!.get<dynamic>(
          '/dictionary/${Uri.encodeComponent(word)}',
        );
        final data = response.data;
        if (data is List) {
          final parsed = data
              .whereType<Map<String, dynamic>>()
              .map((item) => DictionaryWordEntry.fromJson(item))
              .toList();
          if (parsed.isNotEmpty) return parsed;
        }
      } catch (_) {}
    }

    return [];
  }
}
