import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lorebound/features/reader/data/services/epub_cache_service.dart';
import 'package:lorebound/features/reader/data/services/epub_parser_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File dummyEpubFile;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('lorebound_test_');

    // Mock path_provider
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return tempDir.path;
      }
      return null;
    });

    // Generate a large dummy EPUB
    final archive = Archive();
    
    // container.xml
    const containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
    archive.addFile(ArchiveFile('META-INF/container.xml', containerXml.length, utf8.encode(containerXml)));

    // content.opf
    final StringBuffer opfXml = StringBuffer('''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.opf.org/2007/opf" version="2.0">
  <metadata>
    <dc:title>Test Mock Novel Large</dc:title>
    <dc:creator>Test Author</dc:creator>
  </metadata>
  <manifest>
''');
    
    for (int i = 1; i <= 100; i++) {
      opfXml.writeln('    <item id="ch$i" href="chapter$i.xhtml" media-type="application/xhtml+xml"/>');
    }
    opfXml.writeln('  </manifest>');
    opfXml.writeln('  <spine>');
    for (int i = 1; i <= 100; i++) {
      opfXml.writeln('    <itemref idref="ch$i"/>');
    }
    opfXml.writeln('  </spine>');
    opfXml.writeln('</package>');
    
    final opfBytes = utf8.encode(opfXml.toString());
    archive.addFile(ArchiveFile('OEBPS/content.opf', opfBytes.length, opfBytes));

    // Generate 100 chapters
    for (int i = 1; i <= 100; i++) {
      final chapterHtml = '''<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Chapter $i</title></head>
<body><p>This is test text for resilience. Repeated text to increase size. ''' * 50 + '''</p></body>
</html>''';
      final chBytes = utf8.encode(chapterHtml);
      archive.addFile(ArchiveFile('OEBPS/chapter$i.xhtml', chBytes.length, chBytes));
    }

    final zipBytes = ZipEncoder().encode(archive);
    
    dummyEpubFile = File('${tempDir.path}/test_large.epub');
    await dummyEpubFile.writeAsBytes(zipBytes!);
  });

  tearDownAll(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Performance Audit: Direct Zip vs Cache', () async {
    final cacheService = EpubCacheService();
    final parserService = EpubParserService(cacheService);

    // 1. Direct Zip Parsing (No Cache)
    final stopwatchZip = Stopwatch()..start();
    final bookDirect = await parserService.loadBookFromFile(dummyEpubFile.path);
    stopwatchZip.stop();
    debugPrint('Direct Zip Parsing (100 chapters): ${stopwatchZip.elapsedMilliseconds} ms');

    // Clear RAM cache so it doesn't skew results
    // We can't access private _bookCache, so we just instantiate a new parser
    final parserService2 = EpubParserService(cacheService);

    // 2. Save to Cache
    final stopwatchSave = Stopwatch()..start();
    await cacheService.saveToCache(999, bookDirect);
    stopwatchSave.stop();
    debugPrint('Saving to Cache: ${stopwatchSave.elapsedMilliseconds} ms');

    // 3. Load from Cache
    final stopwatchLoad = Stopwatch()..start();
    final bookCache = await parserService2.loadBookFromFile(dummyEpubFile.path, bookId: 999);
    stopwatchLoad.stop();
    debugPrint('Loading from Cache: ${stopwatchLoad.elapsedMilliseconds} ms');

    // Verify cache loaded correctly
    expect(bookCache.Chapters!.length, 100);
    
    final cacheSize = await cacheService.getCacheSize(999);
    debugPrint('Cache size on disk: ${cacheSize / 1024} KB');

    // Analysis assertion
    expect(stopwatchLoad.elapsedMilliseconds, lessThan(stopwatchZip.elapsedMilliseconds));
  });
}
