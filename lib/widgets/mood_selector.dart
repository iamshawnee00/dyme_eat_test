import 'package:flutter/material.dart';

// A simple data class for our mood options
class Mood {
  final String name;
  final IconData icon;
  final List<String> associatedTags;

  Mood({
    required this.name,
    required this.icon,
    required this.associatedTags,
  });
}

// The UI widget for the mood selector
class MoodSelector extends StatefulWidget {
  final Function(Mood?) onMoodSelected;

  const MoodSelector({super.key, required this.onMoodSelected});

  @override
  State<MoodSelector> createState() => _MoodSelectorState();
}

class _MoodSelectorState extends State<MoodSelector> {
  // A predefined list of moods and their associated filter tags
  final List<Mood> _moods = [
    Mood(name: "Cozy", icon: Icons.cloud_queue , associatedTags: ['Soup', 'Noodles', 'Comfort Food']),
    Mood(name: "Celebration", icon: Icons.celebration, associatedTags: ['Fine Dining', 'Steak', 'Japanese']),
    Mood(name: "Quick Bite", icon: Icons.timer, associatedTags: ['Fast Food', 'Sandwich', 'Bakery']),
    Mood(name: "Healthy", icon: Icons.eco, associatedTags: ['Salad', 'Vegetarian', 'Vegan']),
  ];

  Mood? _selectedMood;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _moods.length,
        itemBuilder: (context, index) {
          final mood = _moods[index];
          final isSelected = _selectedMood == mood;

          return GestureDetector(
            onTap: () {
              setState(() {
                // If the same mood is tapped again, deselect it. Otherwise, select the new mood.
                if (isSelected) {
                  _selectedMood = null;
                } else {
                  _selectedMood = mood;
                }
              });
              widget.onMoodSelected(_selectedMood);
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest
,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    mood.icon,
                    color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mood.name,
                    style: TextStyle(
                      color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
