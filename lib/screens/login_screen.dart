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
              padding: const EdgeInsets.all(24.0),
              child: FlutterLogo(size: 100),
            ),
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
