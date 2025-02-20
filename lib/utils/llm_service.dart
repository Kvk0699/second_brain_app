import 'package:openai_api/openai_api.dart';
import 'constants.dart';

class OpenAIClient {
  late final OpenaiClient client;

  // Singleton pattern
  static final OpenAIClient _instance = OpenAIClient._internal();

  factory OpenAIClient() {
    return _instance;
  }

  OpenAIClient._internal() {
    client = OpenaiClient(
      config: OpenaiConfig(
        apiKey: APIConstants.HF_API_KEY,
        baseUrl: APIConstants.BASE_URL,
      ),
    );
  }

  Future<String> complete(String prompt) async {
    try {
      // final response = await client.completions.create(
      //   model: 'Qwen/Qwen2.5-72B-Instruct',
      //   messages: [
      //     ChatMessage(
      //       role: ChatMessageRole.user,
      //       content: prompt,
      //     ),
      //   ],
      //   temperature: APIConstants.DEFAULT_TEMPERATURE,
      //   maxTokens: APIConstants.DEFAULT_MAX_TOKENS,
      //   topP: APIConstants.DEFAULT_TOP_P,
      // );

      // return response.choices.first.message.content;
      return 'Hello';
    } catch (e) {
      print('Error during API call: $e');
      rethrow;
    }
  }

  void dispose() {
    // Clean up if needed
  }
}

// Usage example in LLMService
class LLMService {
  final OpenAIClient _openai = OpenAIClient();

  Future<String> getAnswerFromLLM(String prompt) async {
    try {
      return await _openai.complete(prompt);
    } catch (error) {
      print('LLM call error: $error');
      return "Sorry, I'm having trouble accessing the LLM at the moment.";
    }
  }

  void dispose() {
    _openai.dispose();
  }
}
