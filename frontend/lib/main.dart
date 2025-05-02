import 'package:flutter/material.dart';
import 'package:frontend/uttils/navigator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/admin_dashboard.dart';
import 'pages/employer_dashboard.dart';
import 'pages/assistant_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://lourroesreukeofjjfox.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvdXJyb2VzcmV1a2VvZmpqZm94Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU4NDM3NDYsImV4cCI6MjA2MTQxOTc0Nn0.fNhd8WJYAN3FLNcDVHCG8f7tVyMCSxsJuj5EkLK4ccw',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion RH',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.globalKey,
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

