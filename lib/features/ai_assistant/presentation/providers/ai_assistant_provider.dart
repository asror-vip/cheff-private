import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../domain/entities/ai_message_entity.dart';
import '../../domain/entities/ai_agent_action_entity.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/voice_service.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../../core/audit/audit_service.dart';
import '../../../../core/utils/unit_converter.dart';

class AiAssistantProvider extends ChangeNotifier {
  final AiService _aiService = AiService();
  final VoiceService _voiceService = VoiceService();

  final List<AiMessageEntity> _messages = [];
  List<AiMessageEntity> get messages => List.unmodifiable(_messages);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isListening = false;
  bool get isListening => _isListening;

  double _soundLevel = 0.0;
  double get soundLevel => _soundLevel;

  String _currentRecognizedText = '';
  String get currentRecognizedText => _currentRecognizedText;

  AiAssistantProvider() {
    _initDefaultGreeting();
  }

  void _initDefaultGreeting() {
    if (_messages.isEmpty) {
      _messages.add(
        AiMessageEntity(
          id: 'msg-init',
          text: 'ai_assistant.greeting'.tr(),
          sender: AiMessageSender.assistant,
          type: AiMessageType.text,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  void clearChat() {
    _messages.clear();
    _initDefaultGreeting();
    notifyListeners();
  }

  Future<void> startListening({String? localeId}) async {
    _currentRecognizedText = '';
    _isListening = true;
    _soundLevel = 0.0;
    notifyListeners();

    final ready = await _voiceService.initialize();
    if (!ready) {
      _isListening = false;
      notifyListeners();
      return;
    }

    await _voiceService.startListening(
      localeId: localeId,
      onResult: (text) {
        _currentRecognizedText = text;
        notifyListeners();
      },
      onSoundLevel: (level) {
        _soundLevel = level;
        notifyListeners();
      },
    );
  }

  Future<void> stopListeningAndSend([int durationSeconds = 2]) async {
    await _voiceService.stopListening();
    _isListening = false;
    final textToSend = _currentRecognizedText.trim();
    _currentRecognizedText = '';
    _soundLevel = 0.0;
    notifyListeners();

    if (textToSend.isNotEmpty) {
      await sendVoiceMessage(textToSend, durationSeconds);
    }
  }

  Future<void> cancelListening() async {
    await _voiceService.cancelListening();
    _isListening = false;
    _currentRecognizedText = '';
    _soundLevel = 0.0;
    notifyListeners();
  }

  Future<void> sendTextMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    final userMessage = AiMessageEntity(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      text: clean,
      sender: AiMessageSender.user,
      type: AiMessageType.text,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    _isLoading = true;
    notifyListeners();

    await _processWithAi(clean);
  }

  Future<void> sendVoiceMessage(String text, int durationSeconds) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    final userMessage = AiMessageEntity(
      id: 'usr-v-${DateTime.now().millisecondsSinceEpoch}',
      text: clean,
      sender: AiMessageSender.user,
      type: AiMessageType.voice,
      voiceDurationSeconds: durationSeconds < 1 ? 1 : durationSeconds,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    _isLoading = true;
    notifyListeners();

    await _processWithAi(clean);
  }

  Future<void> _processWithAi(String userPrompt) async {
    final restaurantId = SupabaseService.currentRestaurantId;
    final supabase = SupabaseService.client;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    double totalSalesToday = 0;
    int receiptsCount = 0;
    double totalExpensesToday = 0;
    final List<String> lowStockList = [];
    final List<String> availableDishes = [];

    try {
      // 1. Fetch Today's Sales
      final salesRes = await supabase
          .from('sales')
          .select('total_amount')
          .eq('restaurant_id', restaurantId)
          .eq('status', 'completed')
          .gte('date', today);
      receiptsCount = (salesRes as List).length;
      for (var sale in salesRes) {
        totalSalesToday += (sale['total_amount'] ?? 0).toDouble();
      }

      // 2. Fetch Today's Operating Expenses
      final expRes = await supabase
          .from('expenses')
          .select('amount, category')
          .eq('restaurant_id', restaurantId)
          .gte('expense_date', today);
      for (var row in (expRes as List)) {
        totalExpensesToday += (row['amount'] ?? 0).toDouble();
      }

      // 3. Fetch Low Stock Products
      final lowStockRes = await supabase
          .from('products_with_stock')
          .select('name, current_stock, minimum_stock, unit')
          .eq('restaurant_id', restaurantId)
          .eq('is_active', true)
          .limit(10);
      for (var p in (lowStockRes as List)) {
        final cur = (p['current_stock'] ?? 0).toDouble();
        final min = (p['minimum_stock'] ?? 0).toDouble();
        if (min > 0 && cur <= min) {
          lowStockList.add('${p['name']}: $cur ${p['unit']} (min: $min)');
        }
      }

      // 4. Fetch Available Menu Recipes
      final recipesRes = await supabase
          .from('recipes')
          .select('name')
          .eq('restaurant_id', restaurantId)
          .eq('is_active', true)
          .limit(25);
      for (var r in (recipesRes as List)) {
        availableDishes.add(r['name'].toString());
      }
    } catch (e) {
      debugPrint('AI Context fetch error: $e');
    }

    final List<Map<String, String>> apiMessages = [
      {
        'role': 'system',
        'content':
            'Sen ChefControl AI - restoran boshqaruvi uchun o\'ta aqlli va professional AI agentisan.\n'
            'Restoran egasi (rahbar), oshpaz va xodimlarga biznes tahlil, ombor va operatsion jarayonlarda yordam berasan. O\'zbek tilida qisqa, aniq va foydali javob ber.\n\n'
            'RESTORANNING HOZIRGI REAL KO\'RSATKICHLARI (BUGUN):\n'
            '- Bugungi umumiy savdo: ${NumberFormat('#,###').format(totalSalesToday)} so\'m ($receiptsCount ta chek)\n'
            '- Bugungi operatsion xarajatlar: ${NumberFormat('#,###').format(totalExpensesToday)} so\'m\n'
            '- Menyudagi taomlar: ${availableDishes.isEmpty ? "Mavjud" : availableDishes.join(", ")}\n'
            '- Kam qolgan mahsulotlar (ogohlantirish): ${lowStockList.isEmpty ? "Barcha zaxiralar me`yorida" : lowStockList.join("; ")}\n\n'
            'BUYRUQ VA HARAKATLARNI ISHLATISH QOIDALARI:\n'
            'Agar foydalanuvchi tizimda amaliy harakat so\'rasa, javobing matni oxiriga mos action tegini qo\'sh:\n'
            '1. Taom tayyorlash (ishlab chiqarish): [ACTION:PRODUCE:Taom_Nomi:Miqdori]\n'
            '2. Ombor qoldig\'i: [ACTION:STOCK:Mahsulot_Nomi]\n'
            '3. Kassa va savdo: [ACTION:SALES]\n'
            '4. Kam qolgan tovarlar: [ACTION:LOW_STOCK]\n'
            '5. Moliya va foyda tahlili: [ACTION:FINANCE]\n'
            '6. Xarajat kiritish: [ACTION:EXPENSE:Kategoriya:Summa]\n'
            '7. Chiqit / Spisaniya: [ACTION:WASTE:Mahsulot_Nomi:Miqdori]'
      },
    ];

    final history = _messages.length > 8 ? _messages.sublist(_messages.length - 8) : _messages;
    for (var msg in history) {
      if (msg.id == 'msg-init') continue;
      apiMessages.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
      });
    }

    final rawResponse = await _aiService.sendMessage(apiMessages);
    final actionEntity = await _executeAgentActions(rawResponse);

    var cleanResponse = rawResponse.replaceAll(RegExp(r'\[ACTION:.*?\]'), '').trim();
    if (cleanResponse.isEmpty) {
      cleanResponse = actionEntity != null
          ? actionEntity.details
          : 'ai_assistant.action_done'.tr();
    }

    final assistantMessage = AiMessageEntity(
      id: 'asst-${DateTime.now().millisecondsSinceEpoch}',
      text: cleanResponse,
      sender: AiMessageSender.assistant,
      type: actionEntity != null ? AiMessageType.action : AiMessageType.text,
      actionData: actionEntity?.toMap(),
      timestamp: DateTime.now(),
    );

    _messages.add(assistantMessage);
    _isLoading = false;
    notifyListeners();
  }

  Future<AgentActionEntity?> _executeAgentActions(String response) async {
    final client = SupabaseService.client;
    final restaurantId = SupabaseService.currentRestaurantId;

    // 1. PRODUCE ACTION
    final produceRegex = RegExp(r'\[ACTION:PRODUCE:(.+?):([0-9.]+)\]');
    final produceMatch = produceRegex.firstMatch(response);
    if (produceMatch != null) {
      final recipeName = produceMatch.group(1)?.trim() ?? '';
      final quantity = double.tryParse(produceMatch.group(2) ?? '1') ?? 1.0;

      try {
        final recipesResponse = await client
            .from('recipes')
            .select('id, name, recipe_items(product_id, quantity, unit, products(name, unit))')
            .ilike('name', '%$recipeName%')
            .eq('restaurant_id', restaurantId)
            .limit(1);

        if (recipesResponse.isNotEmpty) {
          final recipe = recipesResponse.first;
          final actualName = recipe['name'] ?? recipeName;
          final items = (recipe['recipe_items'] as List<dynamic>?) ?? [];

          final List<String> deductedSummary = [];
          final List<Map<String, dynamic>> movements = [];

          for (var item in items) {
            final double itemQty = (item['quantity'] ?? 0).toDouble();
            final String recipeUnit = item['unit'] ?? '';
            final prodMap = item['products'] as Map<String, dynamic>?;
            final String prodName = prodMap?['name'] ?? 'Masalliq';
            final String baseUnit = prodMap?['unit'] ?? recipeUnit;
            final String finalUnit = baseUnit.isEmpty ? recipeUnit : baseUnit;

            final double convertedQty = UnitConverter.convert(itemQty, recipeUnit, finalUnit);
            final double totalQty = convertedQty * quantity;

            deductedSummary.add('$prodName: -$totalQty $finalUnit');

            movements.add({
              'restaurant_id': restaurantId,
              'product_id': item['product_id'],
              'quantity': -totalQty,
              'unit': finalUnit,
              'type': 'production_usage',
              'reason': 'ChefControl AI: $actualName x $quantity',
            });
          }

          if (movements.isNotEmpty) {
            await client.from('stock_movements').insert(movements);
          }

          AuditService().logAction(
            department: 'kitchen',
            action: 'Taom tayyorlash (AI)',
            details: '$actualName dan $quantity porsiya tayyorlandi. Ombordan masalliqlar avtomatik yechildi.',
          );

          return AgentActionEntity(
            type: AgentActionType.produce,
            title: '$actualName ($quantity ta)',
            target: actualName,
            quantity: quantity,
            unit: 'ta',
            details: '$actualName muvaffaqiyatli tayyorlandi va ombordan tegishli masalliqlar chegirildi.',
            isSuccess: true,
            impactedItems: deductedSummary,
          );
        } else {
          return AgentActionEntity(
            type: AgentActionType.produce,
            title: recipeName,
            target: recipeName,
            quantity: quantity,
            details: '$recipeName bo\'yicha TTK retsepti topilmadi.',
            isSuccess: false,
            errorMessage: 'TTK topilmadi',
          );
        }
      } catch (e) {
        debugPrint('AI Produce execution error: $e');
        return AgentActionEntity(
          type: AgentActionType.produce,
          title: recipeName,
          target: recipeName,
          details: 'Xatolik yuz berdi: $e',
          isSuccess: false,
          errorMessage: e.toString(),
        );
      }
    }

    // 2. STOCK QUERY
    final stockRegex = RegExp(r'\[ACTION:STOCK:(.+?)\]');
    final stockMatch = stockRegex.firstMatch(response);
    if (stockMatch != null) {
      final query = stockMatch.group(1)?.trim() ?? '';
      try {
        final productsResponse = await client
            .from('products')
            .select('id, name, unit')
            .ilike('name', '%$query%')
            .eq('restaurant_id', restaurantId)
            .limit(5);

        if (productsResponse.isNotEmpty) {
          final productIds = productsResponse.map((p) => p['id']).toList();
          final movementsResponse = await client
              .from('stock_movements')
              .select('product_id, quantity')
              .inFilter('product_id', productIds)
              .eq('restaurant_id', restaurantId);

          final Map<String, double> stockMap = {};
          for (var m in (movementsResponse as List)) {
            final pid = m['product_id']?.toString() ?? '';
            stockMap[pid] = (stockMap[pid] ?? 0.0) + ((m['quantity'] ?? 0).toDouble());
          }

          final List<String> stockList = [];
          for (var p in productsResponse) {
            final pid = p['id']?.toString() ?? '';
            final double currentStock = stockMap[pid] ?? 0.0;
            final String formattedStock = currentStock == currentStock.toInt()
                ? currentStock.toInt().toString()
                : currentStock.toStringAsFixed(2);
            stockList.add('${p['name']}: $formattedStock ${p['unit'] ?? ''}');
          }

          return AgentActionEntity(
            type: AgentActionType.stockQuery,
            title: 'Ombor qoldig\'i: $query',
            target: query,
            details: 'Hozirgi ombordagi qoldiq ko\'rsatkichlari:',
            isSuccess: true,
            impactedItems: stockList,
          );
        } else {
          return AgentActionEntity(
            type: AgentActionType.stockQuery,
            title: 'Ombor qoldig\'i: $query',
            target: query,
            details: '$query nomli mahsulot omborda topilmadi.',
            isSuccess: false,
          );
        }
      } catch (e) {
        debugPrint('AI Stock query error: $e');
      }
    }

    // 3. SALES QUERY
    final salesRegex = RegExp(r'\[ACTION:SALES\]');
    if (salesRegex.hasMatch(response)) {
      try {
        final today = DateTime.now().toIso8601String().substring(0, 10);
        final salesRes = await client
            .from('sales')
            .select('total_amount')
            .eq('restaurant_id', restaurantId)
            .gte('created_at', today);

        double total = 0;
        final count = (salesRes as List).length;
        for (var s in salesRes) {
          total += (s['total_amount'] ?? 0).toDouble();
        }
        final avg = count > 0 ? (total / count).round() : 0;

        AuditService().logAction(
          department: 'pos',
          action: 'Savdo so\'rovi (AI)',
          details: 'Bugungi kassa va tushum ma\'lumoti tekshirildi.',
        );

        return AgentActionEntity(
          type: AgentActionType.salesQuery,
          title: 'Bugungi savdo ko\'rsatkichlari',
          target: 'Bugun',
          details: 'Kassa va tushum holati:',
          isSuccess: true,
          impactedItems: [
            'Jami tushum: ${NumberFormat('#,###').format(total)} so\'m',
            'Cheklar soni: $count ta',
            'O\'rtacha chek: ${NumberFormat('#,###').format(avg)} so\'m',
          ],
        );
      } catch (e) {
        debugPrint('AI Sales query error: $e');
      }
    }

    // 4. LOW STOCK ACTION
    final lowStockRegex = RegExp(r'\[ACTION:LOW_STOCK\]');
    if (lowStockRegex.hasMatch(response)) {
      try {
        final lowStockRes = await client
            .from('products_with_stock')
            .select('name, current_stock, minimum_stock, unit')
            .eq('restaurant_id', restaurantId)
            .eq('is_active', true);

        final List<String> items = [];
        for (var p in (lowStockRes as List)) {
          final cur = (p['current_stock'] ?? 0).toDouble();
          final min = (p['minimum_stock'] ?? 0).toDouble();
          if (min > 0 && cur <= min) {
            items.add('${p['name']}: $cur ${p['unit']} (min: $min)');
          }
        }

        return AgentActionEntity(
          type: AgentActionType.lowStockQuery,
          title: 'Kam qolgan mahsulotlar',
          target: 'Ombor',
          details: items.isEmpty
              ? 'Hozirda barcha mahsulotlar yetarli miqdorda mavjud.'
              : 'Quyidagi mahsulotlar minimal qoldiqdan kam qolgan:',
          isSuccess: true,
          impactedItems: items.isEmpty ? ['Barcha zaxiralar me`yorida'] : items,
        );
      } catch (e) {
        debugPrint('AI Low Stock query error: $e');
      }
    }

    // 5. FINANCE ACTION
    final financeRegex = RegExp(r'\[ACTION:FINANCE\]');
    if (financeRegex.hasMatch(response)) {
      try {
        final now = DateTime.now();
        final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
        final salesRes = await client
            .from('sales')
            .select('total_amount')
            .eq('restaurant_id', restaurantId)
            .eq('status', 'completed')
            .gte('date', startOfMonth);
        double monthlySales = 0;
        for (var s in (salesRes as List)) {
          monthlySales += (s['total_amount'] ?? 0).toDouble();
        }

        final expRes = await client
            .from('expenses')
            .select('amount')
            .eq('restaurant_id', restaurantId)
            .gte('expense_date', startOfMonth);
        double monthlyExp = 0;
        for (var e in (expRes as List)) {
          monthlyExp += (e['amount'] ?? 0).toDouble();
        }

        final estProfit = monthlySales - monthlyExp;
        final margin = monthlySales > 0 ? (estProfit / monthlySales) * 100 : 0.0;

        return AgentActionEntity(
          type: AgentActionType.financeQuery,
          title: 'Oylik moliya va foyda tahlili',
          target: 'Moliya',
          details: 'Shu oydagi moliyaviy holat ko\'rsatkichlari:',
          isSuccess: true,
          impactedItems: [
            'Oylik tushum: ${NumberFormat('#,###').format(monthlySales)} so\'m',
            'Operatsion xarajatlar: ${NumberFormat('#,###').format(monthlyExp)} so\'m',
            'Kutilayotgan foyda: ${NumberFormat('#,###').format(estProfit)} so\'m',
            'Rentabellik: ${margin.toStringAsFixed(1)}%',
          ],
        );
      } catch (e) {
        debugPrint('AI Finance query error: $e');
      }
    }

    // 6. EXPENSE ACTION
    final expenseRegex = RegExp(r'\[ACTION:EXPENSE:(.+?):([0-9.]+)\]');
    final expenseMatch = expenseRegex.firstMatch(response);
    if (expenseMatch != null) {
      final category = expenseMatch.group(1)?.trim() ?? 'Boshqa';
      final amount = double.tryParse(expenseMatch.group(2) ?? '0') ?? 0.0;

      if (amount > 0) {
        try {
          await client.from('expenses').insert({
            'restaurant_id': restaurantId,
            'category': category,
            'amount': amount,
            'expense_date': DateTime.now().toIso8601String(),
          });

          AuditService().logAction(
            department: 'finance',
            action: 'Xarajat kiritildi (AI)',
            details: '$category uchun ${NumberFormat('#,###').format(amount)} so\'m xarajat kiritildi.',
          );

          return AgentActionEntity(
            type: AgentActionType.expense,
            title: 'Xarajat: $category',
            target: category,
            quantity: amount,
            unit: 'so\'m',
            details: '${NumberFormat('#,###').format(amount)} so\'m xarajatlar ro\'yxatiga kiritildi.',
            isSuccess: true,
            impactedItems: [
              'Toifa: $category',
              'Summa: ${NumberFormat('#,###').format(amount)} so\'m',
            ],
          );
        } catch (e) {
          debugPrint('AI Expense action error: $e');
        }
      }
    }

    // 5. WASTE ACTION
    final wasteRegex = RegExp(r'\[ACTION:WASTE:(.+?):([0-9.]+)\]');
    final wasteMatch = wasteRegex.firstMatch(response);
    if (wasteMatch != null) {
      final productName = wasteMatch.group(1)?.trim() ?? '';
      final quantity = double.tryParse(wasteMatch.group(2) ?? '0') ?? 0.0;

      if (quantity > 0) {
        try {
          final productsResponse = await client
              .from('products')
              .select('id, name, unit')
              .ilike('name', '%$productName%')
              .eq('restaurant_id', restaurantId)
              .limit(1);

          if (productsResponse.isNotEmpty) {
            final product = productsResponse.first;
            final actualName = product['name'] ?? productName;
            final unit = product['unit'] ?? 'dona';

            await client.from('stock_movements').insert({
              'restaurant_id': restaurantId,
              'product_id': product['id'],
              'quantity': -quantity,
              'unit': unit,
              'type': 'waste',
              'reason': 'AI orqali spisaniya: $actualName x $quantity',
            });

            AuditService().logAction(
              department: 'warehouse',
              action: 'Chiqit / Spisaniya (AI)',
              details: '$actualName dan $quantity $unit hisobdan chiqarildi.',
            );

            return AgentActionEntity(
              type: AgentActionType.waste,
              title: 'Spisaniya: $actualName',
              target: actualName,
              quantity: quantity,
              unit: unit,
              details: '$actualName ombordan hisobdan chiqarildi (spisaniya).',
              isSuccess: true,
              impactedItems: [
                '$actualName: -$quantity $unit',
              ],
            );
          }
        } catch (e) {
          debugPrint('AI Waste action error: $e');
        }
      }
    }

    return null;
  }
}
