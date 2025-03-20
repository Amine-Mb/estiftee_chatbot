import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'dart:async'; // Add this import at the top

class DialogflowService {
  final String projectId = 'estiftee-chatbot';
  static const _apiVersion = 'v2';
  late final ServiceAccountCredentials _credentials;
  late final Future<void> _initialized;

  DialogflowService() {
    _initialized = _initializeCredentials();
  }

  Future<void> _initializeCredentials() async {
    final jsonString =
        await rootBundle.loadString('assets/service_account.json');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    _credentials = ServiceAccountCredentials.fromJson(json);
  }

  Future<DialogflowResponse> detectIntent(
      String query, String sessionId) async {
    await _initialized; // Wait for credentials initialization

    final client = await clientViaServiceAccount(
      _credentials,
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

    return _parseResponse(response);
  }

  Future<DialogflowResponse> sendWelcomeEvent(String sessionId) async {
    final client = await clientViaServiceAccount(
      _credentials,
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
          "event": {
            "name": "WELCOME",
            "languageCode": "en",
          }
        }
      }),
    );

    return _parseResponse(response);
  }

  DialogflowResponse _parseResponse(http.Response response) {
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final fulfillmentText =
          jsonResponse['queryResult']['fulfillmentText'] ?? '';
      final intent = jsonResponse['queryResult']['intent']['displayName'] ?? '';
      return DialogflowResponse(message: fulfillmentText, intent: intent);
    } else {
      throw Exception('Failed to get Dialogflow response');
    }
  }
}

class DialogflowResponse {
  final String message;
  final String intent;

  DialogflowResponse({required this.message, required this.intent});
}

class QueryResult {
  final String fulfillmentText;
  final String intent;
  final List<dynamic> fulfillmentMessages;

  QueryResult({
    required this.fulfillmentText,
    required this.intent,
    required this.fulfillmentMessages,
  });

  factory QueryResult.fromJson(Map<String, dynamic> json) {
    return QueryResult(
      fulfillmentText: json['fulfillmentText'] ?? '',
      intent: json['intent']?['displayName'] ?? 'Default Intent',
      fulfillmentMessages: json['fulfillmentMessages'] ?? [],
    );
  }
}
