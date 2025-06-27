// lib/screens/wrapper.dart
import 'package:dyme_eat/providers/auth_provider.dart';
import 'package:dyme_eat/screens/auth/login_screen.dart';
import 'package:dyme_eat/screens/onboarding/onboarding_screen.dart';
import 'package:dyme_eat/ui/shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// This provider will check if onboarding is complete
final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboardingComplete') ?? false;
});


class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
  final authState = ref.watch(authStateProvider);

  // First, handle the authentication provider's loading and error states.
  if (authState.isLoading) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }

  if (authState.hasError) {
    return Scaffold(body: Center(child: Text('Auth Error: ${authState.error}')));
  }

  // If we get here, we have data. Check if the user exists.
  if (authState.value != null) {
    // User is logged in. Now, let's check their onboarding status.
    final onboardingComplete = ref.watch(onboardingCompleteProvider);

    // Handle the onboarding provider's states.
    return onboardingComplete.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text("Error loading onboarding status"))),
      data: (isComplete) {
        // We have the onboarding data. Show the correct screen.
        if (isComplete) {
          return const Shell(); // Go to main app
        } else {
          return const OnboardingScreen(); // Go to onboarding
        }
      },
    );
  } else {
    // User is not logged in (authState.value is null).
    return const LoginScreen();
  }
  }
}
