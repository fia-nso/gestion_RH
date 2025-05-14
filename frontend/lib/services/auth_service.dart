import 'package:frontend/models/auth_model.dart';
import 'package:frontend/services/base_service.dart';

class EmployerService extends BaseService<Employer> {
  Future<bool> updateUser({String? name}) async {
    final user = client.auth.currentUser!;

    final userId = user.id;

    try {
      print('updating user');

      if (name != null) {
        await client
            .from(AuthModel.usersTableName)
            .update({"name": name}).eq('id', userId);
      }

      // await client
      //     .from(Employer.tableName)
      //     .update(value.toMap())
      //     .eq('id', userId);

      print('updated employer');
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
          .select('*, roles:user_roles(*,app_role(*))')
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
