// Employee Management Controller
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/auth_model.dart';
import '../services/auth_service.dart';

class EmployeeManagementController extends ChangeNotifier {
  final EmployerService _service = EmployerService();

  List<Employer> employees = [];
  bool loading = false;
  String? error;

  Future<void> loadEmployees() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      employees = await _service.getAllEmployees();
      loading = false;
      notifyListeners();
    } catch (e) {
      error = 'Échec du chargement des employés : $e';
      loading = false;
      notifyListeners();
    }
  }

  Future<void> createEmployee({
    required String name,
    required String email,
    required String password,
    String? contact,
    String? details,
    DateTime? startDate,
    Status? status,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
try {
  print('🔄 Controller: Début création employé');

  final success = await _service.createEmployee(
    name: name,
    email: email,
    password: password,
    contact: contact,
    details: details,
    startDate: startDate,
    status: status,
  );

  print('✅ Controller: Résultat service = $success');

  if (success) {
    print('🔄 Controller: Rechargement des employés...');
    await loadEmployees();
    loading = false;
    notifyListeners();
  } else {
    throw Exception('Le service a retourné false');
  }
} catch (e) {
  print('💥 Controller: Erreur = $e');
  error = 'Échec de la création de l\'employé : $e';
  loading = false;
  notifyListeners();
}
  }

  Future<void> updateEmployee({
    required String id,
    String? name,
    String? contact,
    String? details,
    XFile? photo,
    DateTime? startDate,
    Status? status,
  }) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.updateUser(
        userId: id,
        role: 'employer',
        name: name,
        contact: contact,
        details: details,
        photo: photo,
        startDate: startDate,
        status: status,
      );
      if (success) {
        await loadEmployees();
      } else {
        throw Exception('Échec de la mise à jour');
      }
    } catch (e) {
      error = 'Échec de la mise à jour de l\'employé : $e';
      loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteEmployee(String id) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final success = await _service.deleteUserData('employer', id);
      if (success) {
        await loadEmployees();
      } else {
        throw Exception('Échec de la suppression');
      }
    } catch (e) {
      error = 'Échec de la suppression de l\'employé : $e';
      loading = false;
      notifyListeners();
    }
  }
}