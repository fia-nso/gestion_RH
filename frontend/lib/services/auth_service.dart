import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:frontend/models/auth_model.dart';
import 'package:frontend/services/base_service.dart';
import 'package:frontend/uttils/api_fetcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmployerService extends BaseService<AuthModel> {
  late ApiFetcher apiFetcher;

  EmployerService() {
    final session = client.auth.currentSession;
    final accessToken = session?.accessToken;
    apiFetcher = ApiFetcher(accessToken: accessToken);
  }

  Future<List<Employer>> getAllEmployees() async {
    try {
      print('Fetching all employees...');
      final roleResponse = await client
          .from('user_roles')
          .select('user_id')
          .eq('role_id', 'employer');

      print('Users with employer role: $roleResponse');
      if (roleResponse.isEmpty) {
        print('No users with employer role found.');
        return [];
      }

      final userIds =
          roleResponse.map((item) => item['user_id'] as String).toList();
      print('Employer user IDs: $userIds');

      final response = await client.from('users').select('''
          id,
          name,
          employer!left(contact, details, photo, start_date, employment_status),
          roles:user_roles(*, app_role!inner(id))
        ''').inFilter('id', userIds);

      print('Raw Supabase response: $response');
      if (response.isEmpty) {
        print('No matching users found in the users table.');
      } else {
        for (var item in response) {
          print('Response item: $item');
          print('Employer field: ${item['employer']}');
        }
      }

      final employees = response.map((map) {
        print('Mapping employee: $map');
        return Employer.fromMap(map);
      }).toList();

      print('Fetched ${employees.length} employees');
      return employees;
    } catch (e) {
      print("getAllEmployees() failed: $e");
      return [];
    }
  }

  Future<bool> updateUser({
    required String userId,
    required String role,
    String? name,
    String? contact,
    String? details,
    XFile? photo,
    DateTime? startDate,
    EmploymentStatus? employmentStatus,
  }) async {
    try {
      if (name != null && name.trim().isEmpty) {
        print('Validation failed: Name cannot be empty');
        return false;
      }
      if (contact != null && !_isValidContact(contact)) {
        print('Validation failed: Invalid contact format');
        return false;
      }

      final currentUser = client.auth.currentUser!;
      final roleResponse = await client
          .from('user_roles')
          .select('app_role(id)')
          .eq('user_id', currentUser.id)
          .single();
      if (roleResponse['app_role']['id'] != 'admin') {
        print('Unauthorized: Only admins can update employees');
        return false;
      }

      final updates = <String, dynamic>{};

      if (name != null) {
        await client
            .from(AuthModel.usersTableName)
            .update({"name": name.trim()}).eq('id', userId);
      }

      if (role == 'employer') {
        if (contact != null) updates['contact'] = contact.trim();
        if (details != null) updates['details'] = details.trim();
        if (startDate != null) updates['start_date'] = startDate.toIso8601String();
        if (employmentStatus != null) updates['employment_status'] = employmentStatus.value;
      }

      if (photo != null) {
        final photoPath =
            '$role/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final photoUrl = await _uploadPhoto(photo, photoPath);
        updates['photo'] = photoUrl;
      }

      if (updates.isNotEmpty) {
        await client.from(role).update(updates).eq('id', userId);
      }

      print('Updated employee: $userId');
      return true;
    } catch (e) {
      print("updateUser() failed: $e");
      return false;
    }
  }

  Future<String> _uploadPhoto(XFile photo, String path) async {
    try {
      print('Uploading photo');
      if (kIsWeb) {
        final Uint8List fileAsBytes = await photo.readAsBytes();
        await client.storage.from('employees').uploadBinary(
              path,
              fileAsBytes,
              fileOptions: FileOptions(
                upsert: true,
                contentType: photo.mimeType,
              ),
            );
        print("Photo uploaded to employees");
      } else {
        final File file = File(photo.path);
        await client.storage.from('employees').upload(
              path,
              file,
              fileOptions:
                  FileOptions(upsert: true, contentType: photo.mimeType),
            );
        print("Photo uploaded to employees");
      }

      final publicUrl = client.storage.from('employees').getPublicUrl(path);
      print('Photo URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print("Photo upload failed: $e");
      rethrow;
    }
  }

  @override
  Future<AuthModel?> getUser() async {
    try {
      final user = client.auth.currentUser!;
      print('Fetching user data for userId: ${user.id}');

      final response = await client
          .from('users')
          .select(
              'id, name, employer(contact, details, photo, start_date, employment_status), roles:user_roles(*, app_role(*))')
          .eq('id', user.id)
          .single();

      print('Supabase response: $response');

      final roleList = List<Map<String, dynamic>>.from(response['roles'] ?? []);
      if (roleList.isEmpty) {
        print('No roles found for user');
        return null;
      }

      final role = roleList
          .map((item) => AppRole.fromMap(item['app_role']))
          .toList()
          .first
          .id;
      print('User role: $role');

      switch (role) {
        case 'employer':
          return Employer.fromMap(response);
        case 'admin':
          await client.from('admin').upsert({'id': user.id}).eq('id', user.id);
          return Admin.fromMap(response);
        case 'assistant':
          await client
              .from('assistant')
              .upsert({'id': user.id}).eq('id', user.id);
          return Assistant.fromMap(response);
        default:
          print('Unknown role: $role');
          return null;
      }
    } catch (e) {
      print("❌ getUser() failed: $e");
      return null;
    }
  }

  Future<bool> deleteUserData(String role, String userId) async {
    try {
      final currentUser = client.auth.currentUser!;
      final roleResponse = await client
          .from('user_roles')
          .select('app_role(id)')
          .eq('user_id', currentUser.id)
          .single();
      if (roleResponse['app_role']['id'] != 'admin') {
        print('Unauthorized: Only admins can delete user data');
        return false;
      }

      final response = await client
          .from(role)
          .select('photo')
          .eq('id', userId)
          .maybeSingle();

      final photoUrl = response?['photo'] as String?;

      await client.from(role).delete().eq('id', userId);
      await client.from('users').delete().eq('id', userId);
      await client.from('user_roles').delete().eq('user_id', userId);

      if (photoUrl != null && photoUrl.isNotEmpty) {
        final path = _extractStoragePath(photoUrl);
        try {
          await client.storage.from('employees').remove([path]);
          print('File deleted successfully');
        } catch (e) {
          print('Error deleting file: $e');
        }
      }

      print('$role data deleted for userId: $userId');
      return true;
    } catch (e) {
      print('deleteUserData() failed: $e');
      return false;
    }
  }

  String _extractStoragePath(String publicUrl) {
    final uri = Uri.parse(publicUrl);
    final pathSegments = uri.pathSegments;
    final index = pathSegments.indexOf('object') + 1;
    return pathSegments.sublist(index).join('/');
  }

  bool _isValidContact(String contact) {
    final phoneRegExp = RegExp(r'^\+?[1-9]\d{1,14}$');
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return phoneRegExp.hasMatch(contact) || emailRegExp.hasMatch(contact);
  }

  Future<bool> createEmployee({
    required String email,
    required String password,
    required String name,
    String? contact,
    String? details,
    DateTime? startDate,
    EmploymentStatus? employmentStatus,
  }) async {
    try {
      final currentUser = client.auth.currentUser!;
      final roleResponse = await client
          .from('user_roles')
          .select('role_id')
          .eq('user_id', currentUser.id)
          .single();
      if (roleResponse['role_id'] != 'admin') {
        print('Non autorisé : seuls les admins peuvent créer des employés');
        return false;
      }

      final session = client.auth.currentSession;
      if (session == null) {
        print('No session found for the current user');
        return false;
      }
      final accessToken = session.accessToken;

      final apiFetcher = ApiFetcher(accessToken: accessToken);

      final fields = {
        'email': email,
        'password': password,
        'name': name,
        'contact': contact,
        'details': details,
        'start_date': startDate?.toIso8601String(),
        'employment_status': employmentStatus?.value ?? EmploymentStatus.active.value,
        'roles': ['employer'],
      };

      final response = await apiFetcher.post('user', fields);

      if (!response.isSuccess) {
        print('Failed to create user via API: ${response.error}');
        return false;
      }

      final responseData = response.data as Map<String, dynamic>;
      if (!responseData['success']) {
        print('API response error: ${responseData['error']}');
        return false;
      }

      final userId = responseData['user']?['user']?['id'] as String?;
      if (userId == null) {
        print('User created but no ID returned');
        return false;
      }

      await client.from('user_roles').insert({
        'user_id': userId,
        'role_id': 'employer',
      });

      print('Employé créé : $userId');
      return true;
    } catch (e) {
      print('createEmployee() a échoué : $e');
      return false;
    }
  }
}