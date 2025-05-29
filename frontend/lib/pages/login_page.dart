import 'package:flutter/material.dart';
import 'package:frontend/controller_provider/auth_provider.dart';
import 'package:frontend/uttils/navigator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../controller_provider/locale_provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final EmployerService _authService = EmployerService();
  bool _passwordVisible = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      AppNavigator.pushReplacement('/home');
    }
  }

  Future<void> _login() async {
    setState(() {
      _error = null;
    });

    try {
      final authResponse = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      print('AuthResponse data: ${authResponse!.user}');

      if (authResponse.user == null) {
        setState(() {
          _error = 'Échec de la connexion : utilisateur non trouvé.';
        });
        return;
      }

      final user = await _authService.getUser();

      if (user == null) {
        setState(() {
          _error = 'Impossible de récupérer les informations de l\'utilisateur.';
        });
        return;
      }

      AuthController().redirect();
    } catch (e) {
      setState(() {
        if (e.toString().contains('Email not confirmed')) {
          _error = 'Veuillez confirmer votre adresse e-mail pour vous connecter.';
        } else if (e.toString().contains('Invalid login credentials')) {
          _error = 'E-mail ou mot de passe incorrect.';
        } else {
          _error = 'Erreur de connexion : ${e.toString()}';
        }
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    AppNavigator.pushReplacement('/login');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.language),
              onPressed: () {
                final provider = Provider.of<LocaleProvider>(context, listen: false);
                final currentLocale = provider.locale;
                final newLocale = currentLocale.languageCode == 'en'
                    ? const Locale('ar')
                    : const Locale('en');
                provider.changeLocale(newLocale);
              },
              tooltip: 'Change Language',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Image.asset("assets/images/img1.png"),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.email,
                    hintText: AppLocalizations.of(context)!.email,
                    labelStyle: const TextStyle(
                        color: Colors.black, fontSize: 14, fontWeight: FontWeight.w400),
                    prefixIcon: const Icon(
                      Icons.email,
                      color: Color.fromARGB(255, 232, 184, 26),
                      size: 18,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey, width: 0.75),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    floatingLabelStyle: const TextStyle(color: Colors.black, fontSize: 18)),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.password,
                    hintText: AppLocalizations.of(context)!.password,
                    labelStyle: const TextStyle(
                        color: Colors.black, fontSize: 14, fontWeight: FontWeight.w400),
                    prefixIcon: const Icon(
                      Icons.key,
                      color: Color.fromARGB(255, 232, 184, 26),
                      size: 18,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible ? Icons.visibility : Icons.visibility_off,
                        color: const Color.fromARGB(224, 253, 192, 39),
                      ),
                      onPressed: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey, width: 1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.grey, width: 0.75),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    floatingLabelStyle: const TextStyle(color: Colors.black, fontSize: 18)),
                obscureText: !_passwordVisible,
              ),
              const SizedBox(height: 20),
              MaterialButton(
                onPressed: _login,
                height: 45,
                color: const Color.fromARGB(255, 232, 184, 26),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Text(AppLocalizations.of(context)!.se_connecter),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}