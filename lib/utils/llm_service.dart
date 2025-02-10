import 'package:http/http.dart' as http;
import 'dart:convert';

// Replace this with your actual Hugging Face Inference Token
const String hfApiKey = "";
const String baseUrl = 'https://api-inference.huggingface.co/v1/';

class LLMService {
  final http.Client _client = http.Client();

  Future<String> getAnswerFromLLM(String prompt) async {
    print("prompt: $prompt");
    
    try {
      final response = await _client.post(
        Uri.parse('${baseUrl}chat/completions'),
        headers: {
          'Authorization': 'Bearer $hfApiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'Qwen/Qwen2.5-72B-Instruct',
          'messages': [
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.3,
          'max_tokens': 1024,
          'top_p': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices']?[0]?['message']?['content'] ?? '';
      } else {
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (error) {
      print('LLM call error: $error');
      return "Sorry, I'm having trouble accessing the LLM at the moment.";
    }
  }

  void dispose() {
    _client.close();
  }
}