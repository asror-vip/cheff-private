import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';

class AiService {
  final String _apiKey = dotenv.env['DEEPSEEK_API_KEY'] ?? '';
  final String _model = dotenv.env['DEEPSEEK_MODEL'] ?? 'deepseek-chat';
  final String _baseUrl = 'https://api.deepseek.com/chat/completions';

  Future<String> sendMessage(List<Map<String, String>> messages) async {
    try {
      if (_apiKey.isEmpty) {
        return 'ai_assistant.error_key_missing'.tr();
      }

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'] ?? '';
      } else if (response.statusCode == 402) {
        return 'ai_assistant.error_402'.tr();
      } else if (response.statusCode == 401) {
        return 'ai_assistant.error_401'.tr();
      } else if (response.statusCode == 429) {
        return 'ai_assistant.error_429'.tr();
      } else if (response.statusCode >= 500) {
        return 'ai_assistant.error_server'.tr();
      } else {
        return '${"common.error".tr()} (${response.statusCode})';
      }
    } catch (_) {
      return 'ai_assistant.error_network'.tr();
    }
  }
}
