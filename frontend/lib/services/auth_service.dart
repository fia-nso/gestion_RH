import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:frontend/models/auth_model.dart';
import 'package:frontend/services/base_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerService extends BaseService<Employer> {
  Future<bool> updateUser(
      {String? name, String? contact, String? details, XFile? photo}) async {
    final user = client.auth.currentUser!;
    final userId = user.id;
    final updates = <String, dynamic>{};

    try {
      print('Updating user');

      if (name != null) {
        await client
            .from(AuthModel.usersTableName)
            .update({"name": name}).eq('id', userId);
      }

      if (contact != null) {
        updates['contact'] = contact;
      }

      if (details != null) {
        updates['details'] = details;
      }

      if (photo != null) {
        final photoPath =
            'employees/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final photoUrl = await _uploadPhoto(photo, photoPath);
        updates['photo'] = photoUrl;
      }

      if (updates.isNotEmpty) {
        await client.from(Employer.tableName).update(updates).eq('id', userId);
      }

      print('Updated employer');
      return true;
    } catch (e) {
      print(" updateUser() failed: $e");
      return false;
    }
  }

  Future<String> _uploadPhoto(XFile photo, String path) async {
    try {
      print('Hello');
      if (kIsWeb) {
        final Uint8List fileAsBytes = await photo.readAsBytes();
        await client.storage.from('employees').uploadBinary(path, fileAsBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: photo.mimeType,
            ));
      } else {
        final File file = File(photo.path);
        await client.storage.from('profile-pictures').upload(
              path,
              file,
              fileOptions:
                  FileOptions(upsert: true, contentType: photo.mimeType),
            );
      }

      final publicUrl = client.storage.from('employees').getPublicUrl(path);

      print('jello ${publicUrl}');
      return publicUrl;
    } catch (e) {
      print(" Photo upload failed: $e");
      rethrow;
    }
  }

  @override
  Future<Employer?> getUser() async {
    try {
      final user = client.auth.currentUser!;

      final response = await client
          .from('users')
          .select(
              'id, name, employer(contact, details), roles:user_roles(*, app_role(*))')
          .eq('id', user.id)
          .single();

      return Employer.fromMap(response);
    } catch (e) {
      print("❌ getUser() failed: $e");
      return null;
    }
  }

  // Future<void> resendConfirmationEmail(String email) async {
  //   await client.auth.resend(
  //     type: OtpType.signup,
  //     email: email,
  //   );
  // }
}
