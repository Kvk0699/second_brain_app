import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../services/config_service.dart';

class LLMService {
  final ConfigService _config = ConfigService();
  
  // API endpoint
  final String _baseUrl =
      'https://api-inference.huggingface.co/models/Qwen/Qwen2.5-72B-Instruct/v1/chat/completions';

  // Model parameters
  final double _temperature = 0.5;
  final int _maxTokens = 2048;
  final double _topP = 0.7;

  /// Send a prompt to the LLM and get a response
  Future<String> getAnswerFromLLM(String prompt) async {
    try {
      final apiKey = await _config.getApiKey();
      if (apiKey == null) {
        throw Exception('API key not found');
      }

      // Construct the request body
      final requestBody = {
        "model": "Qwen/Qwen2.5-72B-Instruct",
        "messages": [
          {
            "role": "system",
            "content":
                "You are a helpful assistant integrated into a personal information management app called 'Second Brain'. Respond to user questions in a concise, friendly, and helpful manner. For questions you don't have information about, clearly state that the data isn't available rather than making up answers. When referencing specific items in the user's data, use the following format: [[type:id|title]] where type is note, password, or event, id is the item's ID, and title is the display text. For example: [[note:123|Project Notes]]",
          },
          {
            "role": "user",
            "content": prompt,
          }
        ],
        "temperature": _temperature,
        "max_tokens": _maxTokens,
        "top_p": _topP,
        "stream": false,
      };

      // Make the POST request
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              "Authorization": "Bearer $apiKey",
              "Content-Type": "application/json",
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      // Handle response
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['choices'][0]['message']['content'] as String;
      } else {
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in LLM service: $e');
      rethrow;
    }
  }
}