import 'package:flutter/material.dart';
import 'package:frontend/controller_provider/auth_provider.dart';
import 'package:frontend/services/auth_service.dart';

class EmployerUpdateController extends ChangeNotifier {
  EmployerUpdateController() {
    init();
  }

  bool loading = false;
  String? error;

  final nameController = TextEditingController();

  void init() {
    nameController.text = AuthController().emoloyer.name ?? '';
    notifyListeners();
  }

  Future<void> save() async {
    loading = true;
    notifyListeners();

    await EmployerService().updateUser(name: nameController.text.trim());

    await AuthController().getUser();

    loading = false;
    notifyListeners();
  }
}
