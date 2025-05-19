import 'package:flutter/material.dart';
import 'package:frontend/controller_provider/auth_provider.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';

class EmployerUpdateController extends ChangeNotifier {
  EmployerUpdateController() {
    init();
  }

  bool loading = false;
  String? error;

  final nameController = TextEditingController();
  final contactController = TextEditingController();
  final detailsController = TextEditingController();
  XFile? photo;

  void init() {
    final authController = AuthController();
    final role = authController.user.currentRole.id;
    switch (role) {
      case 'employer':
        final employer = authController.employer;
        nameController.text = employer.name ?? '';
        contactController.text = employer.contact ?? '';
        detailsController.text = employer.details ?? '';
        break;
      case 'admin':
        final admin = authController.admin;
        nameController.text = admin.name ?? '';
        break;
      case 'assistant':
        final assistant = authController.assistant;
        nameController.text = assistant.name ?? '';
        break;
    }
    notifyListeners();
  }

  Future<void> pickPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      photo = pickedFile;
      notifyListeners();
    }
  }

  Future<void> save() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final authController = AuthController();
      final role = authController.user.currentRole.id;
      final userId = authController.user.id;

      final success = await EmployerService().updateUser(
        userId: userId,
        role: role,
        name: nameController.text.trim(),
        contact: role == 'employer' ? contactController.text.trim() : null,
        details: role == 'employer' ? detailsController.text.trim() : null,
        photo: photo,
      );

      if (success) {
        await authController.getUser();
      } else {
        error = 'Failed to update profile';
      }
    } catch (e) {
      error = 'Error updating profile: $e';
      print('Save error: $e');
    }

    loading = false;
    notifyListeners();
  }
}