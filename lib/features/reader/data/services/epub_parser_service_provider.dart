import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'epub_parser_service.dart';
import 'epub_cache_service.dart';

final epubParserServiceProvider = Provider<EpubParserService>((ref) {
  return EpubParserService(ref.watch(epubCacheServiceProvider));
});
