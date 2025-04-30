import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/admin_dashboard.dart';
import 'pages/employer_dashboard.dart';
import 'pages/assistant_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://duryqbdoutlzjbghvanl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR1cnlxYmRvdXRsempiZ2h2YW5sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUzMzk3MDYsImV4cCI6MjA2MDkxNTcwNn0.cjBTO3-wdlnJW3d8AkQJW9xzerXIfq2V3geGZiRG0Qo',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion RH',
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/admin-dashboard': (_) => const AdminDashboard(),
        '/employer-dashboard': (_) => const EmployerDashboard(),
        '/assistant-dashboard': (_) => const AssistantDashboard(),
      },
    );
  }
}
