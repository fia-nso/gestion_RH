import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://lourroesreukeofjjfox.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvdXJyb2VzcmV1a2VvZmpqZm94Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU4NDM3NDYsImV4cCI6MjA2MTQxOTc0Nn0.fNhd8WJYAN3FLNcDVHCG8f7tVyMCSxsJuj5EkLK4ccw',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Connexion à Supabase établie')),
      ),
    );
  }
}