import 'dart:convert';
import 'package:http/http.dart' as http;

// You could store these in a separate constants file
class APIConstants {
  static const String HF_API_KEY = '<YOUR_HF_TOKEN>';
  static const String BASE_URL =
      'https://api-inference.huggingface.co/models/Qwen/Qwen2.5-72B-Instruct/v1/chat/completions';

  static const double DEFAULT_TEMPERATURE = 0.5;
  static const int DEFAULT_MAX_TOKENS = 2048;
  static const double DEFAULT_TOP_P = 0.7;
}

class LLMService {
  final String _apiKey = APIConstants.HF_API_KEY;
  final String _baseUrl = APIConstants.BASE_URL;

  /// Example method to send a prompt to the Qwen model
  Future<String> getAnswerFromLLM(String prompt) async {
    try {
      // Construct the request body
      final requestBody = {
        "model": "Qwen/Qwen2.5-72B-Instruct",
        "messages": [
          {
            "role": "user",
            "content": prompt,
          }
        ],
        "temperature": APIConstants.DEFAULT_TEMPERATURE,
        "max_tokens": APIConstants.DEFAULT_MAX_TOKENS,
        "top_p": APIConstants.DEFAULT_TOP_P,
        // remove "stream" or set to false if you don't want streaming
        "stream": false,
      };

      // Make the POST request
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      // Check for a successful response
      if (response.statusCode == 200) {
        // Parse the JSON response
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        // Adjust the parsing logic if the HF response structure differs
        final content = jsonResponse['choices'][0]['message']['content'];
        return content;
      } else {
        throw Exception('Error: ${response.statusCode} => ${response.body}');
      }
    } catch (error) {
      print('LLM call error: $error');
      return "Sorry, I'm having trouble accessing the LLM at the moment.";
    }
  }
}
