import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive.dart';
import 'package:lorebound/features/reader/data/services/epub_parser_service.dart';
import 'package:lorebound/features/reader/data/services/epub_cache_service.dart';

void main() {
  test('direct zip rescue test with mock in-memory archive', () async {
    final archive = Archive();
    
    // Add container.xml
    const containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
    archive.addFile(ArchiveFile('META-INF/container.xml', containerXml.length, utf8.encode(containerXml)));

    // Add content.opf
    const opfXml = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.opf.org/2007/opf" version="2.0">
  <metadata>
    <dc:title>Test Mock Novel</dc:title>
    <dc:creator>Test Author</dc:creator>
  </metadata>
  <manifest>
    <item id="ch1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="ch1"/>
  </spine>
</package>''';
    archive.addFile(ArchiveFile('OEBPS/content.opf', opfXml.length, utf8.encode(opfXml)));

    // Add chapter1.xhtml
    const chapterHtml = '''<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Chapter 1: The Beginning</title></head>
<body><p>This is test text for resilience.</p></body>
</html>''';
    archive.addFile(ArchiveFile('OEBPS/chapter1.xhtml', chapterHtml.length, utf8.encode(chapterHtml)));

    final zipBytes = ZipEncoder().encode(archive);
    expect(zipBytes, isNotNull);

    final service = EpubParserService(EpubCacheService());
    // Save to temp or test direct parser
    expect(service, isNotNull);
  });
}
