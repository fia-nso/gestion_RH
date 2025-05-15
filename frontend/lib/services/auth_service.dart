import 'package:frontend/models/auth_model.dart';
import 'package:frontend/services/base_service.dart';

class EmployerService extends BaseService<Employer> {
  Future<bool> updateUser(
      {String? name, String? contact, String? details}) async {
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

      if (updates.isNotEmpty) {
        await client.from(Employer.tableName).update(updates).eq('id', userId);
      }

      print('Updated employer');
      return true;
    } catch (e) {
      print("❌ updateUser() failed: $e");
      return false;
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
