import 'package:flutter/material.dart';

class SearchHighlightedText extends StatelessWidget {
  const SearchHighlightedText({
    super.key,
    required this.text,
    required this.query,
    this.style,
  });

  final String text;
  final String query;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return SelectableText(text, style: style);
    }

    return SelectableText.rich(
      TextSpan(
        style: style,
        children: _buildSpans(context, normalizedQuery),
      ),
    );
  }

  List<TextSpan> _buildSpans(BuildContext context, String normalizedQuery) {
    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = normalizedQuery.toLowerCase();
    final highlightStyle = TextStyle(
      color: Theme.of(context).colorScheme.onPrimaryContainer,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      fontWeight: FontWeight.w700,
    );

    var start = 0;
    while (start < text.length) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      final end = index + normalizedQuery.length;
      spans.add(
        TextSpan(
          text: text.substring(index, end),
          style: highlightStyle,
        ),
      );
      start = end;
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: text));
    }
    return spans;
  }
}
