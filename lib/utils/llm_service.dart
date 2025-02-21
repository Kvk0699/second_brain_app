import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class LLMService {
  // The Hugging Face API key - in a real app, use environment variables
  // or secure storage rather than hardcoding the API key
  final String _apiKey = '<YOUR_HF_TOKEN>';

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
      // Construct the request body
      final requestBody = {
        "model": "Qwen/Qwen2.5-72B-Instruct",
        "messages": [
          {
            "role": "system",
            "content":
                "You are a helpful assistant integrated into a personal information management app called 'Second Brain'. Respond to user questions in a concise, friendly, and helpful manner. For questions you don't have information about, clearly state that the data isn't available rather than making up answers.",
          },
          {
            "role": "user",
            "content": prompt,
          }
        ],
        "temperature": _temperature,
        "max_tokens": _maxTokens,
        "top_p": _topP,
        // remove "stream" or set to false if you don't want streaming
        "stream": false,
      };

      // Make the POST request
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              "Authorization": "Bearer $_apiKey",
              "Content-Type": "application/json",
            },
            body: jsonEncode(requestBody),
          )
          .timeout(
              const Duration(seconds: 30)); // Add timeout to prevent long waits

      // Check for a successful response
      if (response.statusCode == 200) {
        try {
          // Parse the JSON response
          final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

          // Extract content from the response
          final content = jsonResponse['choices'][0]['message']['content'];
          return content;
        } catch (parseError) {
          debugPrint('Error parsing LLM response: $parseError');
          return _getFallbackResponse();
        }
      } else {
        debugPrint('Error status: ${response.statusCode} => ${response.body}');
        return _getFallbackResponse();
      }
    } catch (error) {
      debugPrint('LLM call error: $error');
      return _getFallbackResponse();
    }
  }

  // Get a fallback response if the LLM service fails
  String _getFallbackResponse() {
    return "I'm having trouble accessing my knowledge at the moment. Could you please try again? If this persists, please check your internet connection or try again later.";
  }
}
