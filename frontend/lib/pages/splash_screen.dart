import 'package:flutter/material.dart';
import 'package:frontend/controller_provider/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<void> redirect() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AuthController().redirect();
    });
  }

  @override
  void initState() {
    redirect();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Loading'),
    );
  }
}
