import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String selectedRole = 'admin';

  final roles = ['admin', 'employer', 'assistant'];

  Future<void> signUp() async {
    final supabase = Supabase.instance.client;
    final email = emailController.text;
    final password = passwordController.text;

    final response = await supabase.auth.signUp(email: email, password: password);

    if (response.user != null) {
      await supabase.from('profiles').insert({
        'user_id': response.user!.id,
        'role': selectedRole,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Inscription réussie')));
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : ${response.session?.accessToken}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Mot de passe'), obscureText: true),
            DropdownButton<String>(
              value: selectedRole,
              onChanged: (value) => setState(() => selectedRole = value!),
              items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            ),
            ElevatedButton(onPressed: signUp, child: const Text('S’inscrire')),
          ],
        ),
      ),
    );
  }
}
