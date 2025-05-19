import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 48.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 200,
                  maxHeight: 200,
                ),
                child: Image.asset(
                  Theme.of(context).brightness == Brightness.dark
                      ? 'assets/logo_dark.png'
                      : 'assets/logo_light.png',
                  fit: BoxFit.contain,
                  errorBuilder:
                      (context, error, stackTrace) => Text(error.toString()),
                ),
              ),
            ),
            SizedBox(height: 25),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              child: SupaEmailAuth(
                onSignInComplete: (response) {
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                onSignUpComplete: (response) {
                  Navigator.of(context).pushReplacementNamed('/home');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
