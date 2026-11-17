import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AppRole {
  owner,
  staff,
}

enum Department {
  none,
  warehouse,
  pos,
  purchases,
  kitchen,
  finance,
}

class EmployeeProfile {
  final String id;
  final String name;
  final Department assignedDepartment;
  final String status;
  final String roleName;

  const EmployeeProfile({
    required this.id,
    required this.name,
    required this.assignedDepartment,
    required this.status,
    required this.roleName,
  });

  EmployeeProfile copyWith({
    String? id,
    String? name,
    Department? assignedDepartment,
    String? status,
    String? roleName,
  }) {
    return EmployeeProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      assignedDepartment: assignedDepartment ?? this.assignedDepartment,
      status: status ?? this.status,
      roleName: roleName ?? this.roleName,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'assignedDepartment': assignedDepartment.name,
    'status': status,
    'roleName': roleName,
  };

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) => EmployeeProfile(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    assignedDepartment: Department.values.firstWhere(
      (d) => d.name == json['assignedDepartment'],
      orElse: () => Department.none,
    ),
    status: json['status'] ?? 'waiting',
    roleName: json['roleName'] ?? 'Xodim',
  );
}

class BossProfile {
  final String id;
  final String name;
  final String roleTitle;
  final String restaurantName;
  final String restaurantId;
  final String address;
  final String phone;
  final String inn;

  const BossProfile({
    required this.id,
    required this.name,
    required this.roleTitle,
    required this.restaurantName,
    required this.restaurantId,
    this.address = '',
    this.phone = '',
    this.inn = '',
  });
}

class SessionManager extends ChangeNotifier {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal() {
    init();
  }

  bool _isLoggedIn = false;
  bool get isLoggedIn {
    try {
      final supabaseUser = Supabase.instance.client.auth.currentUser;
      if (supabaseUser != null) return true;
    } catch (_) {}
    return _isLoggedIn;
  }

  AppRole _currentRole = AppRole.owner;
  AppRole get currentRole => _currentRole;

  BossProfile _bossProfile = const BossProfile(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Rahbar',
    roleTitle: 'Restoran Rahbari (Boshliq)',
    restaurantName: 'ChefControl Restoran',
    restaurantId: '00000000-0000-0000-0000-000000000000',
  );
  BossProfile get bossProfile => _bossProfile;

  final List<EmployeeProfile> _employees = [];
  List<EmployeeProfile> get employees => List.unmodifiable(_employees);

  EmployeeProfile? _currentEmployee;
  EmployeeProfile? get currentEmployee => _currentEmployee;

  Department get activeDepartment {
    if (_currentRole == AppRole.owner) {
      return Department.none;
    }
    return _currentEmployee?.assignedDepartment ?? Department.none;
  }

  bool isDepartmentDelegated(Department dept) {
    if (dept == Department.none) return false;
    return _employees.any(
      (emp) => emp.assignedDepartment == dept && emp.status == 'active',
    );
  }

  EmployeeProfile? getEmployeeForDepartment(Department dept) {
    try {
      return _employees.firstWhere(
        (emp) => emp.assignedDepartment == dept && emp.status == 'active',
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final employeesJson = prefs.getString('chefcontrol_employees');
      if (employeesJson != null) {
        final List<dynamic> list = jsonDecode(employeesJson);
        final loaded = list.map((e) => EmployeeProfile.fromJson(e)).toList();
        if (loaded.isNotEmpty) {
          _employees.clear();
          _employees.addAll(loaded);
        }
      }

      final bossName = prefs.getString('chefcontrol_boss_name');
      final restName = prefs.getString('chefcontrol_rest_name');
      final restId = prefs.getString('chefcontrol_rest_id');
      final restAddress = prefs.getString('chefcontrol_rest_address');
      final restPhone = prefs.getString('chefcontrol_rest_phone');
      final restInn = prefs.getString('chefcontrol_rest_inn');
      
      if (bossName != null || restName != null || restId != null) {
        _bossProfile = BossProfile(
          id: _bossProfile.id,
          name: bossName ?? _bossProfile.name,
          roleTitle: _bossProfile.roleTitle,
          restaurantName: restName ?? _bossProfile.restaurantName,
          restaurantId: restId ?? _bossProfile.restaurantId,
          address: restAddress ?? _bossProfile.address,
          phone: restPhone ?? _bossProfile.phone,
          inn: restInn ?? _bossProfile.inn,
        );
      }
      final isLoggedInPref = prefs.getBool('chefcontrol_is_logged_in');
      if (isLoggedInPref != null) {
        _isLoggedIn = isLoggedInPref;
      }
      notifyListeners();
      fetchEmployeesFromSupabase();
    } catch (e) {
      debugPrint('Error initializing session: $e');
    }
  }

  Future<void> fetchEmployeesFromSupabase() async {
    try {
      final client = Supabase.instance.client;
      final restId = _bossProfile.restaurantId;
      final response = await client
          .from('users')
          .select()
          .eq('restaurant_id', restId);
          
      if (response.isNotEmpty) {
        final list = <EmployeeProfile>[];
        for (final row in response) {
          final role = (row['role'] ?? 'Xodim').toString();
          if (role.toLowerCase() == 'owner' || role.toLowerCase() == 'boss') {
            continue;
          }
          final id = (row['employee_code'] ?? row['id'] ?? '').toString();
          final name = (row['full_name'] ?? row['name'] ?? 'Xodim').toString();
          final deptStr = (row['department'] ?? 'none').toString();
          final status = (row['status'] ?? 'active').toString();
          
          list.add(EmployeeProfile(
            id: id,
            name: name,
            assignedDepartment: Department.values.firstWhere(
              (d) => d.name == deptStr,
              orElse: () => Department.none,
            ),
            status: status,
            roleName: role,
          ));
        }
        _employees.clear();
        _employees.addAll(list);
        await _saveEmployees();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching employees from Supabase: $e');
    }
  }

  Future<void> _saveEmployees() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_employees.map((e) => e.toJson()).toList());
      await prefs.setString('chefcontrol_employees', data);
    } catch (e) {
      debugPrint('Error saving employees: $e');
    }
  }

  Future<void> _saveBoss() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('chefcontrol_boss_name', _bossProfile.name);
      await prefs.setString('chefcontrol_rest_name', _bossProfile.restaurantName);
      await prefs.setString('chefcontrol_rest_id', _bossProfile.restaurantId);
      await prefs.setString('chefcontrol_rest_address', _bossProfile.address);
      await prefs.setString('chefcontrol_rest_phone', _bossProfile.phone);
      await prefs.setString('chefcontrol_rest_inn', _bossProfile.inn);
    } catch (e) {
      debugPrint('Error saving boss: $e');
    }
  }

  void _syncEmployeeToSupabase(EmployeeProfile emp) {
    try {
      final client = Supabase.instance.client;
      final isUuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(emp.id);
      final payload = <String, dynamic>{
        'restaurant_id': _bossProfile.restaurantId,
        'name': emp.name,
        'full_name': emp.name,
        'role': emp.roleName,
        'department': emp.assignedDepartment.name,
        'status': emp.status,
        'employee_code': emp.id,
      };
      if (isUuid) {
        payload['id'] = emp.id;
      }
      client.from('users').upsert(payload).catchError((e) {
        debugPrint('Supabase employee sync error: $e');
      });
    } catch (_) {}
  }

  void _syncRestaurantToSupabase() {
    try {
      final client = Supabase.instance.client;
      client.from('restaurants').update({
        'name': _bossProfile.restaurantName,
        'address': _bossProfile.address,
        'phone': _bossProfile.phone,
        'inn': _bossProfile.inn,
      }).eq('id', _bossProfile.restaurantId).catchError((e) {
        debugPrint('Supabase restaurant sync error: $e');
      });
    } catch (_) {}
  }

  void switchToBoss() {
    _isLoggedIn = true;
    _currentRole = AppRole.owner;
    _currentEmployee = null;
    _saveLoginState(true);
    notifyListeners();
  }

  void switchToEmployee(String employeeId) {
    _isLoggedIn = true;
    _saveLoginState(true);
    final emp = _employees.firstWhere(
      (e) => e.id.toLowerCase() == employeeId.toLowerCase(),
      orElse: () => EmployeeProfile(
        id: employeeId.toUpperCase(),
        name: 'Xodim $employeeId',
        assignedDepartment: Department.none,
        status: 'waiting',
        roleName: 'Biriktirilmagan',
      ),
    );
    if (!_employees.any((e) => e.id == emp.id)) {
      _employees.add(emp);
      _saveEmployees();
    }
    _currentRole = AppRole.staff;
    _currentEmployee = emp;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    _isLoggedIn = false;
    _currentEmployee = null;
    _currentRole = AppRole.owner;
    await _saveLoginState(false);
    notifyListeners();
  }

  Future<void> _saveLoginState(bool val) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('chefcontrol_is_logged_in', val);
    } catch (_) {}
  }

  void assignDepartment(String employeeId, Department department) {
    final index = _employees.indexWhere((e) => e.id == employeeId);
    if (index != -1) {
      String roleName = 'Biriktirilmagan';
      switch (department) {
        case Department.warehouse:
          roleName = 'Ombor mudiri';
          break;
        case Department.pos:
          roleName = 'Kassir (POS)';
          break;
        case Department.purchases:
          roleName = 'Ta`minotchi (Xaridlar)';
          break;
        case Department.kitchen:
          roleName = 'Oshpaz';
          break;
        case Department.finance:
          roleName = 'Hisobchi';
          break;
        case Department.none:
          roleName = 'Biriktirilmagan';
          break;
      }

      final updated = _employees[index].copyWith(
        assignedDepartment: department,
        status: department == Department.none ? 'waiting' : 'active',
        roleName: roleName,
      );
      _employees[index] = updated;

      if (_currentEmployee?.id == employeeId) {
        _currentEmployee = updated;
      }
      _saveEmployees();
      _syncEmployeeToSupabase(updated);
      notifyListeners();
    }
  }

  EmployeeProfile registerNewEmployee({
    required String name,
    String? roleName,
    Department? department,
  }) {
    final nextIdNum = 100 + _employees.length + 1;
    final newId = 'EMP-$nextIdNum';
    final dept = department ?? Department.none;
    final newEmp = EmployeeProfile(
      id: newId,
      name: name,
      assignedDepartment: dept,
      status: dept == Department.none ? 'waiting' : 'active',
      roleName: roleName ?? (dept == Department.none ? 'Yangi xodim' : 'Xodim'),
    );
    _employees.add(newEmp);
    _saveEmployees();
    _syncEmployeeToSupabase(newEmp);
    notifyListeners();
    return newEmp;
  }

  Future<void> updateEmployee({
    required String id,
    required String name,
    required String roleName,
    required Department department,
    String? status,
  }) async {
    final index = _employees.indexWhere((e) => e.id == id);
    if (index != -1) {
      final updated = _employees[index].copyWith(
        name: name,
        roleName: roleName,
        assignedDepartment: department,
        status: status ?? _employees[index].status,
      );
      _employees[index] = updated;
      if (_currentEmployee?.id == id) {
        _currentEmployee = updated;
      }
      await _saveEmployees();
      _syncEmployeeToSupabase(updated);
      notifyListeners();
    }
  }

  Future<void> deleteEmployee(String id) async {
    _employees.removeWhere((e) => e.id == id);
    if (_currentEmployee?.id == id) {
      _currentEmployee = null;
    }
    await _saveEmployees();
    notifyListeners();
    try {
      final client = Supabase.instance.client;
      await client.from('users').delete().eq('employee_code', id);
    } catch (e) {
      debugPrint('Error deleting employee from Supabase: $e');
    }
  }

  Future<void> toggleEmployeeStatus(String id) async {
    final index = _employees.indexWhere((e) => e.id == id);
    if (index != -1) {
      final current = _employees[index];
      final newStatus = current.status == 'active' ? 'waiting' : 'active';
      final updated = current.copyWith(status: newStatus);
      _employees[index] = updated;
      await _saveEmployees();
      _syncEmployeeToSupabase(updated);
      notifyListeners();
    }
  }

  void updateBossProfile({
    String? name,
    String? restaurantName,
    String? restaurantId,
    String? address,
    String? phone,
    String? inn,
  }) {
    _bossProfile = BossProfile(
      id: _bossProfile.id,
      name: name ?? _bossProfile.name,
      roleTitle: _bossProfile.roleTitle,
      restaurantName: restaurantName ?? _bossProfile.restaurantName,
      restaurantId: restaurantId ?? _bossProfile.restaurantId,
      address: address ?? _bossProfile.address,
      phone: phone ?? _bossProfile.phone,
      inn: inn ?? _bossProfile.inn,
    );
    _saveBoss();
    _syncRestaurantToSupabase();
    notifyListeners();
  }

  String getInviteLink([String? employeeId]) {
    if (employeeId != null && employeeId.isNotEmpty) {
      return 'https://chefcontrol.ai/join?code=$employeeId&rest=${_bossProfile.restaurantId}';
    }
    return 'https://chefcontrol.ai/join?rest=${_bossProfile.restaurantId}';
  }
}
