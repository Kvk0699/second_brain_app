import 'package:flutter/foundation.dart';

enum ApiProvider { huggingFace, openAI, anthropic, custom }

class ApiConfigModel {
  final String id;
  final ApiProvider provider;
  final String apiKey;
  final String modelName;
  final String? baseUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ApiConfigModel({
    required this.id,
    required this.provider,
    required this.apiKey,
    required this.modelName,
    this.baseUrl,
    this.isActive = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();

  factory ApiConfigModel.fromJson(Map<String, dynamic> json) {
    return ApiConfigModel(
      id: json['id'] as String,
      provider: ApiProvider.values.firstWhere(
        (e) => e.toString() == json['provider'],
        orElse: () => ApiProvider.huggingFace,
      ),
      apiKey: json['api_key'] as String,
      modelName: json['model_name'] as String,
      baseUrl: json['base_url'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider': provider.toString(),
      'api_key': apiKey,
      'model_name': modelName,
      'base_url': baseUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ApiConfigModel copyWith({
    String? id,
    ApiProvider? provider,
    String? apiKey,
    String? modelName,
    String? baseUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ApiConfigModel(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      modelName: modelName ?? this.modelName,
      baseUrl: baseUrl ?? this.baseUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods to get provider-specific info
  String get providerName {
    switch (provider) {
      case ApiProvider.huggingFace:
        return 'Hugging Face';
      case ApiProvider.openAI:
        return 'OpenAI';
      case ApiProvider.anthropic:
        return 'Anthropic';
      case ApiProvider.custom:
        return 'Custom API';
    }
  }

  String get defaultBaseUrl {
    switch (provider) {
      case ApiProvider.huggingFace:
        return 'https://api-inference.huggingface.co/models';
      case ApiProvider.openAI:
        return 'https://api.openai.com/v1';
      case ApiProvider.anthropic:
        return 'https://api.anthropic.com/v1';
      case ApiProvider.custom:
        return baseUrl ?? '';
    }
  }

  String get defaultModelName {
    switch (provider) {
      case ApiProvider.huggingFace:
        return 'Qwen/Qwen2.5-72B-Instruct';
      case ApiProvider.openAI:
        return 'gpt-4o';
      case ApiProvider.anthropic:
        return 'claude-3-5-sonnet-20240620';
      case ApiProvider.custom:
        return modelName;
    }
  }
}
