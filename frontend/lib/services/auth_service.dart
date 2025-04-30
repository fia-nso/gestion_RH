import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient client = Supabase.instance.client;

  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(email: email, password: password);
  }

  Future<String?> getUserRole() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final response = await client
        .from('profiles')
        .select('role')
        .eq('user_id', user.id)
        .single();
  
    return response['role'] as String?;
  }
}
