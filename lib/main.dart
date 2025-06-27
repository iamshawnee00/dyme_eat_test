import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyme_eat/screens/splash_screen.dart'; // <-- Add this new import


// Your other imports
import 'package:dyme_eat/firebase_options.dart';
import 'package:dyme_eat/ui/theme.dart';

void main() async {
  // This line makes sure Flutter is ready.
  WidgetsFlutterBinding.ensureInitialized();

  
if (Firebase.apps.isEmpty) {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
} else {
    Firebase.app(); // Use the already initialized app
}

  // This line runs your app.
  runApp(const ProviderScope(child: MyApp()));
}

// Your MyApp class remains the same...
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dyme Eat',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
