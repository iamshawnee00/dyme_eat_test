import 'package:dyme_eat/providers/auth_provider.dart';
import 'package:dyme_eat/providers/user_provider.dart';
import 'package:dyme_eat/screens/auth/login_screen.dart';
import 'package:dyme_eat/screens/onboarding/onboarding_quiz_screen.dart';
import 'package:dyme_eat/ui/shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // First, watch the Firebase Authentication state
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (firebaseUser) {
        // If there's no Firebase user, they are not logged in.
        if (firebaseUser == null) {
          return const LoginScreen();
        }
        
        // If they ARE logged in, we now need to check their user profile in Firestore.
        // We watch the userProvider, which gets the AppUser document.
        final userDocAsync = ref.watch(userProvider);
        return userDocAsync.when(
          data: (appUser) {
            // This is the moment right after sign-up, before the Firestore doc is created.
            // Show a loading spinner while we wait for the doc to be written.
            if (appUser == null) {
              return const Scaffold(body: Center(child: CircularProgressIndicator(key: Key('user_doc_loading'))));
            }
            
            // The user doc exists. Now, check if they've completed the quiz.
            if (appUser.foodiePersonality == null || appUser.foodiePersonality!.isEmpty) {
              return const OnboardingQuizScreen(); // Direct them to the quiz.
            }
            
            // If they have a personality, they are fully onboarded.
            return const Shell(); 
          },
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(key: Key('user_doc_initial_loading')))),
          error: (e, s) => Scaffold(body: Center(child: Text("Error loading profile: ${e.toString()}"))),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(key: Key('auth_state_loading')))),
      error: (e, s) => Scaffold(body: Center(child: Text("Authentication Error: ${e.toString()}"))),
    );
  }
}