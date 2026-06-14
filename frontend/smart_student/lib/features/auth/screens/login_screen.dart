import 'package:flutter/material.dart';
import 'package:smart_student/features/auth/services/auth_api_service.dart';
import 'package:smart_student/features/home/home_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  bool isLoading = false;

  Future<void> login() async {
    setState(() {
      isLoading = true;
    });

    try {
      print("STEP 1");

      final userCredential = await _authService.signInWithGoogle();

      print("STEP 2");

      if (userCredential != null) {
        final user = userCredential.user!;

        await AuthApiService().login(
          firebaseUid: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? '',
          photoUrl: user.photoURL ?? '',
        );
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (_) => const HomeScreen(),
  ),
);
        print("BACKEND LOGIN SUCCESS");
        print("LOGIN SUCCESS");
        print(userCredential.user?.email);
      } else {
        print("USER CANCELLED");
      }
    } catch (e) {
      print("ERROR => $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: login,
                child: const Text('Continue with Google'),
              ),
      ),
    );
  }
}
