import 'dart:io';
import 'dart:convert';

void main() {
  final files = ['uz.json', 'uz-Cyrl.json', 'ru.json', 'en.json'];
  final kitchenData = {
    'uz': {
      "title": "Oshxona ekrani",
      "pending": "Yangi",
      "cooking": "Pishirilmoqda",
      "ready": "Tayyor",
      "start_cooking": "Boshlash",
      "mark_ready": "Tayyor",
      "finish": "Olib ketildi",
      "empty": "Buyurtmalar yo'q",
      "table": "Stol: {}",
      "order": "Buyurtma",
      "items": "Taomlar",
      "time_elapsed": "Vaqt: {}"
    },
    'uz-Cyrl': {
      "title": "Ошхона экрани",
      "pending": "Янги",
      "cooking": "Пиширилмоқда",
      "ready": "Тайёр",
      "start_cooking": "Бошлаш",
      "mark_ready": "Тайёр",
      "finish": "Олиб кетилди",
      "empty": "Буюртмалар йўқ",
      "table": "Стол: {}",
      "order": "Буюртма",
      "items": "Таомлар",
      "time_elapsed": "Вақт: {}"
    },
    'ru': {
      "title": "Экран кухни (KDS)",
      "pending": "Новые",
      "cooking": "Готовятся",
      "ready": "Готовы",
      "start_cooking": "Начать",
      "mark_ready": "Готово",
      "finish": "Забрали",
      "empty": "Нет заказов",
      "table": "Стол: {}",
      "order": "Заказ",
      "items": "Блюда",
      "time_elapsed": "Время: {}"
    },
    'en': {
      "title": "Kitchen Display",
      "pending": "New",
      "cooking": "Cooking",
      "ready": "Ready",
      "start_cooking": "Start",
      "mark_ready": "Ready",
      "finish": "Picked up",
      "empty": "No orders",
      "table": "Table: {}",
      "order": "Order",
      "items": "Items",
      "time_elapsed": "Time: {}"
    }
  };

  for (var f in files) {
    final file = File('D:/Desktop/bot/mobile/assets/translations/' + f);
    if (file.existsSync()) {
      var content = file.readAsStringSync();
      var json = jsonDecode(content);
      String lang = f.replaceAll('.json', '');
      
      if (!json.containsKey('kitchen')) {
        json['kitchen'] = kitchenData[lang];
        
        JsonEncoder encoder = new JsonEncoder.withIndent('  ');
        String prettyprint = encoder.convert(json);
        
        file.writeAsStringSync(prettyprint);
        print('Updated ' + f);
      }
    }
  }
}
