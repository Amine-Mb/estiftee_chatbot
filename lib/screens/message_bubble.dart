import 'package:estiftee_chatbot/models/message.dart';
import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final ValueChanged<String> onSuggestionSelected;
  const MessageBubble({
    super.key,
    required this.message,
    required this.onSuggestionSelected,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency, // Maintains background transparency

      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: message.isUser
                  ? Theme.of(context).primaryColor
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
          ),
          if (message.suggestions != null)
            Wrap(
              children: message.suggestions!.map((suggestion) {
                return ActionChip(
                  label: Text(suggestion),
                  onPressed: () => onSuggestionSelected(suggestion),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
