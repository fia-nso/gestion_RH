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
  final contactController = TextEditingController();
  final detailsController = TextEditingController();

  void init() {
    final employer = AuthController().emoloyer;
    nameController.text = employer.name ?? '';
    contactController.text = employer.contact ?? '';
    detailsController.text = employer.details ?? '';
    notifyListeners();
  }

  Future<void> save() async {
    loading = true;
    notifyListeners();

    await EmployerService().updateUser(name: nameController.text.trim(),contact: contactController.text.trim(), details: detailsController.text.trim());

    await AuthController().getUser();   

    loading = false;
    notifyListeners();
  }
}
