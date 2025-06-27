// lib/screens/wrapper.dart
import 'package:dyme_eat/providers/auth_provider.dart';
import 'package:dyme_eat/screens/auth/login_screen.dart';
import 'package:dyme_eat/screens/onboarding/onboarding_screen.dart';
import 'package:dyme_eat/ui/shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dyme_eat/providers/user_provider.dart';
import 'package:dyme_eat/screens/onboarding/onboarding_quiz_screen.dart';


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

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (authState.hasError) {
      return Scaffold(body: Center(child: Text('Auth Error: ${authState.error}')));
    }

    if (authState.value != null) {
      final onboardingComplete = ref.watch(onboardingCompleteProvider);

      return onboardingComplete.when(
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, __) => const Scaffold(body: Center(child: Text("Error loading onboarding status"))),
        data: (isComplete) {
          if (!isComplete) return const OnboardingScreen();

          // ✅ Now check if the user has completed the foodie personality quiz
          final userDocStream = ref.watch(userProvider);
          return userDocStream.when(
            data: (user) {
              if (user == null) return const LoginScreen(); // Shouldn’t happen, but safe fallback
              if (user.foodiePersonality == null || user.foodiePersonality!.isEmpty) {
                return const OnboardingQuizScreen(); // Needs quiz
              }
              return const Shell(); // All good
            },
            loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
            error: (_, __) => const Scaffold(body: Center(child: Text("Error loading user data"))),
          );
        },
      );
    } else {
      return const LoginScreen();
    }
  }
}
