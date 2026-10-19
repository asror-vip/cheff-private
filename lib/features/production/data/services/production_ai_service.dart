import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProductionAiService {
  final String _apiKey = dotenv.env['DEEPSEEK_API_KEY'] ?? '';
  final String _model = dotenv.env['DEEPSEEK_MODEL'] ?? 'deepseek-chat';
  final String _baseUrl = 'https://api.deepseek.com/chat/completions';

  Future<Map<String, dynamic>?> parseProductionText(String text, List<String> availableRecipes) async {
    try {
      if (_apiKey.isEmpty) return null;

      final prompt = """
Foydalanuvchi restoranda ovqat tayyorlaganini aytdi. Uni tahlil qil.
Faqat quyidagi retseptlar ro'yxatidan eng mosini top: ${availableRecipes.join(', ')}
Natijani faqat JSON formatida qaytar. Boshqa so'z qo'shma.
Format: {"recipe_name": "...", "quantity": 123}
Agar tushunarsiz bo'lsa: {"error": "Tushunarsiz buyruq"}
Foydalanuvchi matni: $text
""";

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': 'You are a JSON parser. Output only JSON.'},
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        String content = data['choices'][0]['message']['content'];
        content = content.replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(content);
      }
      return null;
    } catch (e) {
      debugPrint('AI parsing error: $e');
      return null;
    }
  }
}
