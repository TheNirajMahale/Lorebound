import 'package:html/dom.dart' as dom;

/// Represents a single physical page of content within a chapter.
/// It contains a list of HTML nodes (or chunks of nodes) that exactly
/// fit the physical dimensions of the screen.
class ReaderPage {
  final int chapterIndex;
  final int pageIndex;
  final List<dom.Node> nodes;

  const ReaderPage({
    required this.chapterIndex,
    required this.pageIndex,
    required this.nodes,
  });
}
