// widgets/suggestion_chips.dart
import 'package:flutter/material.dart';

class SuggestionChips extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onTap;

  const SuggestionChips({
    required this.suggestions,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      alignment: WrapAlignment.start,
      children: suggestions
          .map((text) => ActionChip(
                label: Text(text),
                backgroundColor: Colors.blue[50],
                onPressed: () => onTap(text),
              ))
          .toList(),
    );
  }
}
