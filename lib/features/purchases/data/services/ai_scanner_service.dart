import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiScannerService {
  Future<List<Map<String, dynamic>>> scanInvoice(File imageFile) async {
    try {
      final geminiApiKey = dotenv.env['GEMINI_API_KEY'];
      final openAiApiKey = dotenv.env['OPENAI_API_KEY'];
      final visionApiKey = dotenv.env['AI_VISION_API_KEY'];
      
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      if (geminiApiKey != null && geminiApiKey.isNotEmpty) {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$geminiApiKey',
        );

        final payload = {
          "contents": [
            {
              "parts": [
                {
                  "text": "Extract all products, quantities, prices, and units from this invoice. "
                          "Return ONLY a raw JSON array of objects with keys: name (string), quantity (number), price (number), unit (string). "
                          "No markdown tags, no commentary. Example: [{\"name\":\"Go'sht\",\"quantity\":5,\"price\":95000,\"unit\":\"kg\"}]"
                },
                {
                  "inlineData": {
                    "mimeType": "image/jpeg",
                    "data": base64Image
                  }
                }
              ]
            }
          ]
        };

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(utf8.decode(response.bodyBytes));
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text']?.toString().trim() ?? '[]';
          return _parseJsonList(text);
        } else {
          throw Exception('Gemini Vision API xatosi: ${response.statusCode} - ${response.body}');
        }
      }

      final apiKey = openAiApiKey ?? visionApiKey;
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Vision OCR API kaliti topilmadi (.env faylida GEMINI_API_KEY yoki OPENAI_API_KEY kiriting)');
      }

      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      final payload = {
        "model": "gpt-4o-mini",
        "messages": [
          {
            "role": "system",
            "content": "You are a professional invoice parsing AI. Extract products, quantities, prices, and units from invoice image. Output ONLY valid JSON array of objects. Example: [{\"name\": \"Meat\", \"quantity\": 5, \"price\": 100000, \"unit\": \"kg\"}]"
          },
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text": "Please extract the items from this invoice and return them as JSON."
              },
              {
                "type": "image_url",
                "image_url": {
                  "url": "data:image/jpeg;base64,$base64Image"
                }
              }
            ]
          }
        ],
        "temperature": 0.1
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'].toString().trim();
        return _parseJsonList(content);
      } else {
        throw Exception('Vision API xatosi: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('AI_SCAN_ERROR: $e');
      rethrow;
    }
  }

  List<Map<String, dynamic>> _parseJsonList(String raw) {
    String jsonStr = raw.trim();
    if (jsonStr.startsWith('```json')) {
      jsonStr = jsonStr.substring(7);
    }
    if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr.substring(3);
    }
    if (jsonStr.endsWith('```')) {
      jsonStr = jsonStr.substring(0, jsonStr.length - 3);
    }
    final List<dynamic> parsedJson = jsonDecode(jsonStr.trim());
    return List<Map<String, dynamic>>.from(parsedJson);
  }
}
