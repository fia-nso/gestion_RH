import 'package:frontend/models/auth_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient client = Supabase.instance.client;

  Future<AuthResponse> signIn(
      {required String email, required String password}) async {
    return await client.auth
        .signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(email: email, password: password);
  }

  Future<AuthModel?> getUser() async {
    print("trying to get extra fields for user ");
    final user = client.auth.currentUser;

    final role = user?.userMetadata?['role'];

    print('Rôle : $role');

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
}
