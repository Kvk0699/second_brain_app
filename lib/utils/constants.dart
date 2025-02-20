class APIConstants {
  static const String HF_API_KEY = 'your-hugging-face-api-key';
  static const String BASE_URL = 'https://api-inference.huggingface.co/v1';
  
  // Model settings
  static const double DEFAULT_TEMPERATURE = 0.7;
  static const int DEFAULT_MAX_TOKENS = 1024;
  static const double DEFAULT_TOP_P = 0.9;
  
  // Model name
  static const String MODEL_NAME = 'Qwen/Qwen2.5-72B-Instruct';
  
  // Optional configuration
  static const Map<String, dynamic> DEFAULT_CONFIG = {
    'dangerouslyAllowBrowser': true,
    'defaultHeaders': {
      'Content-Type': 'application/json',
    },
  };
} 