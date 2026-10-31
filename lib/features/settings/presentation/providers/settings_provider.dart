import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/audit/audit_service.dart';

class SettingsProvider with ChangeNotifier {
  static final SettingsProvider _instance = SettingsProvider._internal();
  factory SettingsProvider() => _instance;
  SettingsProvider._internal() {
    init();
  }

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  final List<String> _customCategories = [];
  final List<Map<String, String>> _customUnits = [];

  List<String> get categories => [
        'settings.cat_meat'.tr(),
        'settings.cat_vegetables'.tr(),
        'settings.cat_dairy'.tr(),
        'settings.cat_dry'.tr(),
        'settings.cat_oils'.tr(),
        'settings.cat_drinks'.tr(),
        'settings.cat_bakery'.tr(),
        'settings.cat_spices'.tr(),
        ..._customCategories,
      ];

  List<Map<String, String>> get units => [
        {'name': 'settings.unit_kg'.tr(), 'symbol': 'kg'},
        {'name': 'settings.unit_liter'.tr(), 'symbol': 'l'},
        {'name': 'settings.unit_piece'.tr(), 'symbol': 'dona'},
        {'name': 'settings.unit_gram'.tr(), 'symbol': 'g'},
        {'name': 'settings.unit_ml'.tr(), 'symbol': 'ml'},
        {'name': 'settings.unit_portion'.tr(), 'symbol': 'por'},
        {'name': 'settings.unit_box'.tr(), 'symbol': 'quti'},
        ..._customUnits,
      ];

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCats = prefs.getStringList('chefcontrol_custom_categories');
      if (savedCats != null && savedCats.isNotEmpty) {
        _customCategories.clear();
        _customCategories.addAll(savedCats);
      }

      final savedUnits = prefs.getString('chefcontrol_custom_units');
      if (savedUnits != null) {
        final List<dynamic> list = jsonDecode(savedUnits);
        _customUnits.clear();
        for (var item in list) {
          if (item is Map) {
            _customUnits.add({
              'name': item['name']?.toString() ?? '',
              'symbol': item['symbol']?.toString() ?? '',
            });
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading settings from prefs: $e');
    }
  }

  Future<void> _saveCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('chefcontrol_custom_categories', _customCategories);
    } catch (e) {
      debugPrint('Error saving custom categories: $e');
    }
  }

  Future<void> _saveUnits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('chefcontrol_custom_units', jsonEncode(_customUnits));
    } catch (e) {
      debugPrint('Error saving custom units: $e');
    }
  }

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  bool updateProfile({
    required String name,
    required String restaurantName,
    required String address,
    required String phone,
    required String inn,
  }) {
    final cleanName = name.trim();
    final cleanRestName = restaurantName.trim();

    if (cleanName.isEmpty || cleanRestName.isEmpty) {
      return false;
    }

    SessionManager().updateBossProfile(
      name: cleanName,
      restaurantName: cleanRestName,
      address: address.trim(),
      phone: phone.trim(),
      inn: inn.trim(),
    );

    AuditService().logAction(
      department: 'settings',
      action: 'Restoran profili yangilandi',
      details: 'Restoran nomi: "$cleanRestName", Egasi: "$cleanName".',
    );

    notifyListeners();
    return true;
  }

  bool addCategory(String categoryName) {
    final cleanName = categoryName.trim();
    if (cleanName.isEmpty || categories.contains(cleanName)) {
      return false;
    }

    _customCategories.add(cleanName);
    _saveCategories();

    AuditService().logAction(
      department: 'settings',
      action: 'Yangi kategoriya qo`shildi',
      details: 'Kategoriya nomi: "$cleanName".',
    );

    notifyListeners();
    return true;
  }

  bool addUnit({
    required String name,
    required String symbol,
  }) {
    final cleanName = name.trim();
    final cleanSymbol = symbol.trim();

    if (cleanName.isEmpty || cleanSymbol.isEmpty) {
      return false;
    }

    final exists = units.any((u) => u['name'] == cleanName || u['symbol'] == cleanSymbol);
    if (exists) {
      return false;
    }

    _customUnits.add({'name': cleanName, 'symbol': cleanSymbol});
    _saveUnits();

    AuditService().logAction(
      department: 'settings',
      action: 'Yangi o`lchov birligi qo`shildi',
      details: 'Birlik: $cleanName ($cleanSymbol).',
    );

    notifyListeners();
    return true;
  }
}
