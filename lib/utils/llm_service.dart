import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../services/config_service.dart';
import '../models/api_config_model.dart';

class LLMService {
  final ConfigService _config = ConfigService();

  // Model parameters
  final double _temperature = 0.5;
  final int _maxTokens = 2048;
  final double _topP = 0.7;

  /// Send a prompt to the LLM and get a response
  Future<String> getAnswerFromLLM(String prompt) async {
    try {
      final apiConfig = await _config.getActiveApiConfig();
      if (apiConfig == null) {
        throw Exception('No active API configuration found');
      }

      switch (apiConfig.provider) {
        case ApiProvider.huggingFace:
          return await _getHuggingFaceResponse(apiConfig, prompt);
        case ApiProvider.openAI:
          return await _getOpenAIResponse(apiConfig, prompt);
        case ApiProvider.anthropic:
          return await _getAnthropicResponse(apiConfig, prompt);
        case ApiProvider.custom:
          return await _getCustomResponse(apiConfig, prompt);
      }
    } catch (e) {
      debugPrint('Error in LLM service: $e');
      rethrow;
    }
  }

  Future<String> _getHuggingFaceResponse(
      ApiConfigModel config, String prompt) async {
    final String baseUrl =
        config.baseUrl ?? 'https://api-inference.huggingface.co/models';
    final String endpoint = '$baseUrl/${config.modelName}/v1/chat/completions';

    final requestBody = {
      "model": config.modelName,
      "messages": [
        {
          "role": "system",
          "content": _getSystemPrompt(),
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

    final response = await http
        .post(
          Uri.parse(endpoint),
          headers: {
            "Authorization": "Bearer ${config.apiKey}",
            "Content-Type": "application/json",
          },
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['choices'][0]['message']['content'] as String;
    } else {
      throw Exception(
          'Failed to get response: ${response.statusCode} - ${response.body}');
    }
  }

  Future<String> _getOpenAIResponse(
      ApiConfigModel config, String prompt) async {
    final String baseUrl = config.baseUrl ?? 'https://api.openai.com/v1';
    final String endpoint = '$baseUrl/chat/completions';

    final requestBody = {
      "model": config.modelName,
      "messages": [
        {
          "role": "system",
          "content": _getSystemPrompt(),
        },
        {
          "role": "user",
          "content": prompt,
        }
      ],
      "temperature": _temperature,
      "max_tokens": _maxTokens,
      "top_p": _topP,
    };

    final response = await http
        .post(
          Uri.parse(endpoint),
          headers: {
            "Authorization": "Bearer ${config.apiKey}",
            "Content-Type": "application/json",
          },
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['choices'][0]['message']['content'] as String;
    } else {
      throw Exception(
          'Failed to get OpenAI response: ${response.statusCode} - ${response.body}');
    }
  }

  Future<String> _getAnthropicResponse(
      ApiConfigModel config, String prompt) async {
    final String baseUrl = config.baseUrl ?? 'https://api.anthropic.com/v1';
    final String endpoint = '$baseUrl/messages';

    final requestBody = {
      "model": config.modelName,
      "system": _getSystemPrompt(),
      "messages": [
        {
          "role": "user",
          "content": prompt,
        }
      ],
      "temperature": _temperature,
      "max_tokens": _maxTokens,
    };

    final response = await http
        .post(
          Uri.parse(endpoint),
          headers: {
            "x-api-key": config.apiKey,
            "anthropic-version": "2023-06-01",
            "Content-Type": "application/json",
          },
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['content'][0]['text'] as String;
    } else {
      throw Exception(
          'Failed to get Anthropic response: ${response.statusCode} - ${response.body}');
    }
  }

  Future<String> _getCustomResponse(
      ApiConfigModel config, String prompt) async {
    if (config.baseUrl == null || config.baseUrl!.isEmpty) {
      throw Exception('Custom API requires a base URL');
    }

    final String endpoint = config.baseUrl!;

    // For custom APIs, we'll use a generic format that can be adapted
    final requestBody = {
      "model": config.modelName,
      "messages": [
        {
          "role": "system",
          "content": _getSystemPrompt(),
        },
        {
          "role": "user",
          "content": prompt,
        }
      ],
      "temperature": _temperature,
      "max_tokens": _maxTokens,
      "top_p": _topP,
    };

    final response = await http
        .post(
          Uri.parse(endpoint),
          headers: {
            "Authorization": "Bearer ${config.apiKey}",
            "Content-Type": "application/json",
          },
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      // The response format will depend on the custom API
      // Try to extract the response from various common formats
      if (responseData['choices'] != null &&
          responseData['choices'].length > 0 &&
          responseData['choices'][0]['message'] != null) {
        return responseData['choices'][0]['message']['content'] as String;
      } else if (responseData['response'] != null) {
        return responseData['response'] as String;
      } else if (responseData['content'] != null &&
          responseData['content'].length > 0 &&
          responseData['content'][0]['text'] != null) {
        return responseData['content'][0]['text'] as String;
      } else if (responseData['text'] != null) {
        return responseData['text'] as String;
      } else if (responseData['answer'] != null) {
        return responseData['answer'] as String;
      } else {
        return 'Response received but format is unknown. Please check your custom API configuration.';
      }
    } else {
      throw Exception(
          'Failed to get custom API response: ${response.statusCode} - ${response.body}');
    }
  }

  String _getSystemPrompt() {
    return "You are a helpful assistant integrated into a personal information management app called 'Second Brain'. Respond to user questions in a concise, friendly, and helpful manner. For questions you don't have information about, clearly state that the data isn't available rather than making up answers. When referencing specific items in the user's data, use the following format: [[type:id|title]] where type is note, password, or event, id is the item's ID, and title is the display text. For example: [[note:123|Project Notes]]";
  }
}
