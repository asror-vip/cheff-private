import 'dart:io';

void main() {
  final file = File('lib/core/session/session_manager.dart');
  var content = file.readAsStringSync();

  content = content.replaceAll(
    'void updateBossProfile({\n    String? name,\n    String? restaurantName,\n    String? restaurantId,\n  }) {\n    _bossProfile = BossProfile(',
    'void updateBossProfile({\n    String? name,\n    String? restaurantName,\n    String? restaurantId,\n    String? address,\n    String? phone,\n    String? inn,\n  }) {\n    _bossProfile = BossProfile(\n      address: address ?? _bossProfile.address,\n      phone: phone ?? _bossProfile.phone,\n      inn: inn ?? _bossProfile.inn,'
  );

  content = content.replaceAll(
    'await prefs.setString(\\'chefcontrol_rest_name\\', _bossProfile.restaurantName);\n      await prefs.setString(\\'chefcontrol_rest_id\\', _bossProfile.restaurantId);',
    'await prefs.setString(\\'chefcontrol_rest_name\\', _bossProfile.restaurantName);\n      await prefs.setString(\\'chefcontrol_rest_id\\', _bossProfile.restaurantId);\n      await prefs.setString(\\'chefcontrol_rest_address\\', _bossProfile.address);\n      await prefs.setString(\\'chefcontrol_rest_phone\\', _bossProfile.phone);\n      await prefs.setString(\\'chefcontrol_rest_inn\\', _bossProfile.inn);'
  );

  content = content.replaceAll(
    'restaurantName: savedRestName ?? \\'Milliy Taomlar\\',\n        restaurantId: savedRestId ?? SupabaseService.currentRestaurantId,\n      );',
    'restaurantName: savedRestName ?? \\'Milliy Taomlar\\',\n        restaurantId: savedRestId ?? SupabaseService.currentRestaurantId,\n        address: prefs.getString(\\'chefcontrol_rest_address\\') ?? \\'\\',\n        phone: prefs.getString(\\'chefcontrol_rest_phone\\') ?? \\'\\',\n        inn: prefs.getString(\\'chefcontrol_rest_inn\\') ?? \\'\\',\n      );'
  );

  content = content.replaceAll(
    'client.from(\\'restaurants\\').upsert({\n        \\'id\\': _bossProfile.restaurantId,\n        \\'name\\': _bossProfile.restaurantName,\n      })',
    'client.from(\\'restaurants\\').upsert({\n        \\'id\\': _bossProfile.restaurantId,\n        \\'name\\': _bossProfile.restaurantName,\n        \\'address\\': _bossProfile.address,\n        \\'phone\\': _bossProfile.phone,\n        \\'inn\\': _bossProfile.inn,\n      })'
  );

  file.writeAsStringSync(content);
}