import 'package:flutter/material.dart';
import 'package:frontend/models/auth_model.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  String? _error;

  Future<void> _login() async {
    try {
      await _authService.signIn(
        _emailController.text,
        _passwordController.text,
      );

      final user = await _authService.getUserRole();

      if (user == null) return;
      AuthModel? customUser = await _authService.getUserRole();
      print(customUser?.roles[0].role);

      if (user.roles.any((role) => role.role == 'admin')) {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else if (user.roles.any((role) => role.role == 'employer')) {
        Navigator.pushReplacementNamed(context, '/employer-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/assistant-dashboard');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Se connecter'),
            ),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
