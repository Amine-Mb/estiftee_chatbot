import 'package:flutter/material.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../services/dialogflow_service.dart';
import '../widgets/suggestion_chips.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];
  //final DialogflowService _dialogflow = DialogflowService();
  DialogflowService? _dialogflow; // Nullable instead of late final

  String sessionId = const Uuid().v4(); // Generate a unique session ID
  final _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dialogflow = DialogflowService();
    _initializeService();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    // Initialize only once using null coalescing operator
    _dialogflow ??= DialogflowService();

    // Add minimal delay to ensure widget stability
    await Future.delayed(const Duration(milliseconds: 50));

    // Now safe to trigger welcome flow
    if (mounted) _triggerDialogflowWelcome();
  }

  void _triggerDialogflowWelcome() async {
    if (_dialogflow == null) return;

    try {
      setState(() => _isLoading = true);
      final response = await _dialogflow!.sendWelcomeEvent(sessionId);
      _addMessage(
        content: response.message,
        isUser: false,
      );
      _showIntentSuggestions();
    } catch (e, stack) {
      print('Dialogflow Welcome Error: $e\n$stack');
      _addMessage(content: 'Welcome! How can I help you?', isUser: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Rest of your existing code remains unchanged below
  void _addMessage({
    required String content,
    bool isUser = false,
    List<String>? suggestions,
  }) {
    setState(() {
      _messages.add(Message(
        id: const Uuid().v4(),
        content: content,
        timestamp: DateTime.now(),
        isUser: isUser,
        suggestions: suggestions,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String message) async {
    if (!mounted || message.isEmpty) return;

    _addMessage(content: message, isUser: true);
    _controller.clear();

    try {
      setState(() => _isLoading = true);
      final response = await _dialogflow!.detectIntent(message, sessionId);

      if (response.intent == 'Default Fallback Intent') {
        _addMessage(
          content: 'Let me connect you to advanced support...',
          isUser: false,
        );
      } else {
        _addMessage(
          content: response.message,
          isUser: false,
        );
      }

      if (response.intent == 'human_support') {
        _showHumanTransferDialog();
      }
    } catch (e, stack) {
      print('Message Error: $e\n$stack');
      _addMessage(
        content: 'Sorry, I encountered an error. Please try again.',
        isUser: false,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showIntentSuggestions() {
    _addMessage(
      content: "Select an option below:",
      isUser: false,
      suggestions: ["Order Status", "Product Inquiry", "Talk to Human"],
    );
  }

  void onSuggestionSelected(String text) async {
    final response = await sendMessageToDialogflow(text);
    setState(() {
      _messages.add(Message(
        id: const Uuid().v4(),
        isUser: false,
        timestamp: DateTime.now(),
        content: text,
      )); // User message
      _messages.add(Message(
          id: const Uuid().v4(),
          isUser: false,
          timestamp: DateTime.now(),
          content: response)); // Bot response
    });
  }

  final projectId = 'estiftee-chatbot';
  static const _apiVersion = 'v2';

  late ServiceAccountCredentials credentials;

  Future<String> sendMessageToDialogflow(
    String query,
  ) async {
    final client = await clientViaServiceAccount(
      credentials, // ✅ This is now properly assigned
      ['https://www.googleapis.com/auth/cloud-platform'],
    );
    final response = await http.post(
      Uri.parse(
          'https://dialogflow.googleapis.com/$_apiVersion/projects/$projectId/agent/sessions/$sessionId:detectIntent'),
      headers: {
        "Authorization": 'Bearer ${client.credentials.accessToken.data}',
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "queryInput": {
          "text": {
            "text": query,
            "languageCode": "en",
          }
        }
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['queryResult']['fulfillmentText'];
    } else {
      return "Error: Unable to get response from Dialogflow.";
    }
  }

  // Keep your existing UI building methods below
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estiftee Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: _showHumanTransferDialog,
            tooltip: 'Human Support',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Column(
      crossAxisAlignment:
          message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        _buildMessageContainer(
            message), // Separate function for message styling
        if (message.suggestions?.isNotEmpty ?? false)
          _buildSuggestionChips(message.suggestions!)
      ],
    );
  }

  Widget _buildMessageContainer(Message message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color:
            message.isUser ? Theme.of(context).primaryColor : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        message.content,
        style: TextStyle(
          color: message.isUser ? Colors.white : Colors.black,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildSuggestionChips(List<String> suggestions) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 8.0,
        children: suggestions.map((suggestion) {
          return ChoiceChip(
            label: Text(suggestion),
            labelStyle: const TextStyle(color: Colors.white),
            backgroundColor: Theme.of(context).primaryColor,
            selected: false,
            onSelected: (selected) {
              _sendMessage(suggestion);
            },
          );
        }).toList(),
      ),
    );
  }

  // Widget _buildMessageBubble(Message message) {
  //   return Column(
  //     crossAxisAlignment:
  //         message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
  //     children: [
  //       Container(
  //         margin: const EdgeInsets.symmetric(vertical: 4),
  //         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  //         decoration: BoxDecoration(
  //           color: message.isUser
  //               ? Theme.of(context).primaryColor
  //               : Colors.grey[200],
  //           borderRadius: BorderRadius.circular(20),
  //         ),
  //         child: Text(
  //           message.content,
  //           style: TextStyle(
  //             color: message.isUser ? Colors.white : Colors.black,
  //             fontSize: 16,
  //           ),
  //         ),
  //       ),
  //       if (message.suggestions != null && message.suggestions!.isNotEmpty)
  //         Padding(
  //           padding: const EdgeInsets.symmetric(vertical: 8),
  //           child: SuggestionChips(
  //             suggestions: message.suggestions!,
  //             onTap: _sendMessage,
  //           ),
  //         ),
  //     ],
  //   );
  // }

  Widget _buildInputField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text.trim()),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onSubmitted: (value) => _sendMessage(value.trim()),
            ),
          ),
        ],
      ),
    );
  }

  void _showHumanTransferDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Human Support'),
        content: const Text('You\'ll be connected to a human agent'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addMessage(
                content: 'Connecting you to a human agent...',
                isUser: false,
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
