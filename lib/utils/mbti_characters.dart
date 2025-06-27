import 'package:flutter/material.dart';

// A simple class to hold the properties of a Foodie Character.
class MbtiCharacter {
  final String name;
  final String description;
  final IconData icon;

  MbtiCharacter({
    required this.name,
    required this.description,
    required this.icon,
  });
}

// This map acts as our local "database" for the 16 Malaysian Foodie Personalities.
// It links the 4-letter code calculated by our Cloud Function to a displayable character.
final Map<String, MbtiCharacter> foodieCharacters = {
  // --- Example Characters (You would define all 16 here) ---
  
  // C = Cuba Dulu (Try First), R = Rancang Dulu (Plan First)
  // A = Asli (Original), M = Moden (Modern)
  // K = Kembara (Adventurous), S = Santai (Relaxed)
  // M = Mamak, K = Kopitiam

  "CAMK": MbtiCharacter(
    name: "Raja Lepak",
    description: "Values atmosphere and good company. Finds the best spots to 'lepak' for hours.",
    icon: Icons.chair_alt_outlined,
  ),
  "CAMS": MbtiCharacter(
    name: "Pahlawan Pagi",
    description: "A purist who believes in the sanctity of the perfect Nasi Lemak or Kaya Toast.",
    icon: Icons.free_breakfast_outlined,
  ),
  "RAKK": MbtiCharacter(
    name: "Harimau Sambal",
    description: "Adventurous, bold, and always seeking the spiciest challenge.",
    icon: Icons.local_fire_department_outlined,
  ),
  "RAMS": MbtiCharacter(
    name: "Sang Kancil Cendol",
    description: "Clever and knows where to find the best, most authentic desserts.",
    icon: Icons.icecream_outlined,
  ),
  
  // A default character to show if a user's MBTI code is not found in the map.
  "default": MbtiCharacter(
    name: "Foodie Baru",
    description: "Just starting their taste journey!",
    icon: Icons.person_outline,
  ),
};