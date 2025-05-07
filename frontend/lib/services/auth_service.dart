import 'package:frontend/models/auth_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient client = Supabase.instance.client;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    AuthResponse auth;
    auth = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return auth;
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(email: email, password: password);
  }

  Future<AuthModel?> getUser() async {
    print("trying to get extra fields for user ");
    final user = client.auth.currentUser;

    final roles = user?.userMetadata?['roles'];

    print('Rôle : $roles');

    print("getting user current ${user!.email}");

    if (user == null) return null;

    final response = await client
        .from('users')
        .select('*, roles:user_roles(*,app_role(*))')
        .eq('id', user.id)
        .single();
    print("getting response ${response}");
    return AuthModel.fromMap(
      response,
    );
  }
  // Future<void> resendConfirmationEmail(String email) async {
  //   await client.auth.resend(
  //     type: OtpType.signup,
  //     email: email,
  //   );
  // }
}
