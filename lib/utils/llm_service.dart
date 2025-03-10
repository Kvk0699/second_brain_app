import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LLMService {
  // API endpoint
  final String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent';

  // Model parameters
  final double _temperature = 1.0;
  final double _topP = 0.95;
  final int _topK = 40;
  final int _maxOutputTokens = 2048;

  /// Send a prompt to the LLM and get a response
  Future<String> getAnswerFromLLM(String prompt) async {
    try {
      var apiKey = dotenv.env['GOOGLE_API_KEY'];
      if (apiKey == null) {
        throw Exception('API key not found, $apiKey');
      }

      // Construct the request body
      final requestBody = {
        "contents": [
          {
            "role": "user",
            "parts": [
              {"text": prompt}
            ]
          }
        ],
        "generationConfig": {
          "temperature": _temperature,
          "topP": _topP,
          "topK": _topK,
          "maxOutputTokens": _maxOutputTokens,
          "responseMimeType": "text/plain"
        },
        "systemInstruction": {
          "parts": [
            {
              "text":
                  "You are a helpful assistant integrated into a personal information management app called 'Second Brain'. Respond to user questions in a concise, friendly, and helpful manner. For questions you don't have information about, clearly state that the data isn't available rather than making up answers. When referencing specific items in the user's data, use the following format: [[type:id|title]] where type is note, password, or event, id is the item's ID, and title is the display text. For example: [[note:123|Project Notes]]"
            }
          ]
        }
      };

      // Make the POST request
      final uri = Uri.parse('$_baseUrl?key=$apiKey');
      final response = await http
          .post(
            uri,
            headers: {
              "Content-Type": "application/json",
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      // Handle response
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['candidates'][0]['content']['parts'][0]['text']
            as String;
      } else {
        throw Exception(
            'Failed to get response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in LLM service: $e');
      rethrow;
    }
  }
}
