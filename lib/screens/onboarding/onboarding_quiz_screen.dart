import 'package:cloud_functions/cloud_functions.dart';
import 'package:dyme_eat/screens/wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- Add this important import
import 'package:flutter/material.dart';

class OnboardingQuizScreen extends StatefulWidget {
  const OnboardingQuizScreen({super.key});

  @override
  State<OnboardingQuizScreen> createState() => _OnboardingQuizScreenState();
}

class _OnboardingQuizScreenState extends State<OnboardingQuizScreen> {
  final PageController _pageController = PageController();
  final Map<String, String> _answers = {};
  final List<String> _allergies = [];
  bool _isLoading = false;

  final List<String> _allergyOptions = ["Seafood", "Nuts", "Dairy", "Gluten", "Belacan"];

  void _onAnswerSelected(String questionId, String answerKey) {
    setState(() {
      _answers[questionId] = answerKey;
    });
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
  }

  Future<void> _submitQuiz() async {
    setState(() => _isLoading = true);
    try {
      // FIX: Force a refresh of the user's auth token before calling the function.
      // This ensures the backend recognizes the user as authenticated.
      await FirebaseAuth.instance.currentUser?.getIdToken(true);

      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('processOnboardingQuiz');
      await callable.call({
        'answers': _answers,
        'allergies': _allergies,
        'preferences': [], // Add preferences page later
      });
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildQuestionPage("q1", "A new, mysterious food truck pulls up...", "Cuba Dulu!", "Check Reviews First", "try-it", "check-reviews"),
          _buildQuestionPage("q2", "Nasi Lemak: The ultimate debate.", "Ayam Goreng Berempah", "Rendang Daging", "ayam-goreng", "rendang"),
          _buildQuestionPage("q3", "You see a new stall with a long queue...", "Join the line (FOMO!)", "Come back another day", "long-queue", "come-back"),
          _buildQuestionPage("q4", "It's 10 PM. You're heading out for...", "Sesi Mamak", "Kopitiam Kopi O", "mamak", "kopitiam"),
          _buildAllergyPage(),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(String id, String title, String optionA, String optionB, String answerKeyA, String answerKeyB) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 40),
          ElevatedButton(onPressed: () => _onAnswerSelected(id, answerKeyA), child: Text(optionA)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => _onAnswerSelected(id, answerKeyB), child: Text(optionB)),
        ]),
      ),
    );
  }

  Widget _buildAllergyPage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text("Ada alahan makanan?", style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8.0,
            children: _allergyOptions.map((allergy) {
              final isSelected = _allergies.contains(allergy);
              return FilterChip(
                label: Text(allergy),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) { _allergies.add(allergy); } 
                    else { _allergies.remove(allergy); }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(onPressed: _submitQuiz, child: const Text("Finish Setup")),
        ]),
      ),
    );
  }
}
