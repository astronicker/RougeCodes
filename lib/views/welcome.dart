import 'package:flutter/material.dart';

/// Welcome screen shown before login, with company branding.
class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.18),

            // Company logo
            Center(
              child: Image.asset('assets/images/rougecodes.png', height: 120),
            ),

            const SizedBox(height: 36.0),

            // Welcome text
            Text(
              'Welcome to Rouge Codes',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Glad to see you again',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'In order to proceed, kindly log in',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 52),

            // Login button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: const Text(
                  'Login',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const Spacer(),

            // Footer
            Align(
              alignment: Alignment.center,
              child: Text(
                'Powered by RougeCodes © 2026',
                style: TextStyle(fontSize: 12, color: colorScheme.outline),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
