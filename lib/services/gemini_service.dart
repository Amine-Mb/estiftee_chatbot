import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static Future<String> generateResponse(String query) async {
    const apiKey =
        'AIzaSyCGRbW6_XMmXjYfhFy8UjuujfA9KXQAPS8'; // Replace with your key
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    final response = await model.generateContent([Content.text(query)]);
    return response.text ?? "I’m not sure how to respond to that.";
  }
}
