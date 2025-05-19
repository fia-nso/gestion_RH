import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:frontend/controller_provider/auth_provider.dart';
import 'package:frontend/l10n/generated/app_localizations.dart';
import 'package:frontend/pages/splash_screen.dart';
import 'package:frontend/uttils/navigator.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'controller_provider/locale_provider.dart';
import 'pages/home_page.dart';
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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider.value(value: AuthController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(builder: (context, localeProvider, child) {
      return MaterialApp(
        title: 'Gestion RH',
        debugShowCheckedModeBanner: false,
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
        ],
        locale: localeProvider.locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        navigatorKey: AppNavigator.globalKey,
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginPage(),
          '/register': (_) => const RegisterPage(),
          '/home': (_) => const HomePage(),
          // '/admin-dashboard': (_) => const AdminDashboard(),
          // '/employer-dashboard': (_) => const EmployerDashboard(),
          // '/assistant-dashboard': (_) => const AssistantDashboard(),
        },
      );
    });
  }
}
