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
    final employer = AuthController().emoloyer;
    nameController.text = employer.name ?? '';
    contactController.text = employer.contact ?? '';
    detailsController.text = employer.details ?? '';
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
      final success = await EmployerService().updateUser(
        name: nameController.text.trim(),
        contact: contactController.text.trim(),
        details: detailsController.text.trim(),
        photo: photo,
      );

      if (success) {
        // Refresh the AuthController to update the employer data
        await AuthController().getUser();
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