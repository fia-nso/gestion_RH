import 'package:flutter/material.dart';
import 'package:frontend/models/auth_model.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/base_service.dart';
import 'package:frontend/uttils/navigator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends ChangeNotifier {
  static AuthController? _instance;

  AuthController._();

  factory AuthController() {
    _instance ??= AuthController._();
    return _instance!;
  }

  final client = Supabase.instance.client;

  BaseService? _service;
  AuthModel? _user;

  BaseService get service => _service!;

  AuthModel get user => _user!;
  Employer get employer => user as Employer;
  Admin get admin => user as Admin;
  Assistant get assistant => user as Assistant;

  bool loading = true;
  String? error;

  Future<void> redirect() async {
    try {
      final response = await client.auth.getUser();

      if (response.user == null) {
        return AppNavigator.pushReplacement('/login');
      }

      // final role = response.user!.userMetadata!['roles'][0];

      _service = EmployerService();

      await getUserAndPushToHome();
    } catch (e) {
      return AppNavigator.pushReplacement('/login');
    }
  }

  Future<void> getUserAndPushToHome() async {
    await getUser();

    if (_user != null) {
      pushToHome();
    }
  }

  Future<void> getUser() async {
    try {
      loading = true;
      notifyListeners();

      final response = await service.getUser();

      if (response == null) {
        throw 'User doesn\'t exist';
      }

      _user = response;

      loading = false;
      notifyListeners();
    } catch (e) {
      loading = false;
      error = e.toString();
      notifyListeners();
    }
  }

  void pushToHome() {
    AppNavigator.pushReplacement('/home');
  }
}