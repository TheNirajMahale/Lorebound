import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart' as dom;
import 'package:epubx/epubx.dart' hide Image;
import '../../domain/models/reader_config.dart';
import '../providers/reader_controller.dart';

class HtmlNodeWidget extends ConsumerWidget {
  final dom.Node node;
  final EpubBook book;
  final bool isFirstNode;

  const HtmlNodeWidget({
    super.key,
    required this.node,
    required this.book,
    this.isFirstNode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readerState = ref.watch(readerControllerProvider);
    final config = readerState.config;

    if (node is dom.Element) {
      final element = node as dom.Element;
      switch (element.localName) {
        case 'p':
        case 'div':
          final spans = _buildTextSpans(element);
          if (spans.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _AnimatedText(
              spans: spans,
              config: config,
              sizeMultiplier: 1.0,
            ),
          );
        case 'h1':
        case 'h2':
        case 'h3':
        case 'h4':
        case 'h5':
        case 'h6':
          final spans = _buildTextSpans(element);
          if (spans.isEmpty) return const SizedBox.shrink();
          double sizeMult = 1.2;
          if (element.localName == 'h1') sizeMult = 2.0;
          if (element.localName == 'h2') sizeMult = 1.7;
          if (element.localName == 'h3') sizeMult = 1.4;
          return Padding(
            padding: EdgeInsets.only(top: isFirstNode ? 0 : 24.0, bottom: 24.0),
            child: _AnimatedText(
              spans: spans,
              config: config,
              sizeMultiplier: sizeMult,
              fontWeight: FontWeight.bold,
            ),
          );
        case 'img':
          return _buildImage(element, config);
        case 'br':
          return const SizedBox(height: 16.0);
        case 'hr':
          return Padding(
            padding: EdgeInsets.only(top: isFirstNode ? 0 : 24.0, bottom: 24.0),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 100,
                height: 1,
                color: config.textColor.withValues(alpha: 0.3),
              ),
            ),
          );
        default:
          final spans = _buildTextSpans(element);
          if (spans.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _AnimatedText(
              spans: spans,
              config: config,
              sizeMultiplier: 1.0,
            ),
          );
      }
    } else if (node is dom.Text) {
      final text = node.text?.trim() ?? '';
      if (text.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: _AnimatedText(
          spans: [TextSpan(text: text)],
          config: config,
          sizeMultiplier: 1.0,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildImage(dom.Element element, ReaderConfig config) {
    final src = element.attributes['src'];
    final alt = element.attributes['alt'] ?? '';

    if (src != null && src.isNotEmpty) {
      final filename = Uri.decodeFull(src.split('/').last.split('#').first);
      
      if (book.Content?.Images != null && book.Content!.Images!.isNotEmpty) {
        final imageKey = book.Content!.Images!.keys.firstWhere(
          (k) => Uri.decodeFull(k.split('/').last).toLowerCase() == filename.toLowerCase(),
          orElse: () => '',
        );

        if (imageKey.isNotEmpty) {
          final imageContent = book.Content!.Images![imageKey];
          if (imageContent != null && imageContent.Content != null && imageContent.Content!.isNotEmpty) {
            return Padding(
              padding: EdgeInsets.only(top: isFirstNode ? 0 : 16.0, bottom: 16.0),
              child: Image.memory(
                Uint8List.fromList(imageContent.Content!),
                key: ValueKey(imageKey),
                gaplessPlayback: true,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => _buildBrokenImageCard(config, alt),
              ),
            );
          }
        }
      }
    }

    // Image not found in book -> render polished fallback placeholder card
    return _buildBrokenImageCard(config, alt);
  }

  Widget _buildBrokenImageCard(ReaderConfig config, String alt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      margin: EdgeInsets.only(top: isFirstNode ? 0 : 16.0, bottom: 16.0),
      decoration: BoxDecoration(
        color: config.textColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: config.textColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: 32,
            color: config.textColor.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 8),
          Text(
            alt.isNotEmpty ? alt : 'Image unavailable',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: config.textColor.withValues(alpha: 0.5),
              fontFamily: config.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildTextSpans(dom.Node node, {TextStyle? inheritedStyle}) {
    List<TextSpan> spans = [];
    
    if (node is dom.Text) {
      final text = node.text;
      if (text.isNotEmpty) {
        final collapsed = text.replaceAll(RegExp(r'\s+'), ' ');
        spans.add(TextSpan(text: collapsed, style: inheritedStyle));
      }
    } else if (node is dom.Element) {
      TextStyle style = inheritedStyle ?? const TextStyle();
      
      switch (node.localName) {
        case 'b':
        case 'strong':
          style = style.copyWith(fontWeight: FontWeight.bold);
          break;
        case 'i':
        case 'em':
          style = style.copyWith(fontStyle: FontStyle.italic);
          break;
        case 'u':
          style = style.copyWith(decoration: TextDecoration.underline);
          break;
        case 'strike':
        case 'del':
        case 's':
          style = style.copyWith(decoration: TextDecoration.lineThrough);
          break;
      }
      
      for (var child in node.nodes) {
        spans.addAll(_buildTextSpans(child, inheritedStyle: style));
      }
    }
    return spans;
  }
}

/// A helper widget that smoothly animates text style changes (font size, color, spacing).
class _AnimatedText extends StatelessWidget {
  final List<TextSpan> spans;
  final ReaderConfig config;
  final double sizeMultiplier;
  final FontWeight? fontWeight;

  const _AnimatedText({
    required this.spans,
    required this.config,
    required this.sizeMultiplier,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      style: TextStyle(
        color: config.textColor,
        fontSize: config.fontSize * sizeMultiplier,
        fontFamily: config.fontFamily,
        height: config.lineSpacing,
        fontWeight: fontWeight ?? FontWeight.normal,
      ),
      child: Text.rich(
        TextSpan(children: spans),
        textScaler: const TextScaler.linear(1.0),
      ),
    );
  }
}
