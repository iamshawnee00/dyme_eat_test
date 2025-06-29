import 'package:flutter/material.dart';

class TagFilter extends StatefulWidget {
  final List<String> availableTags;
  final Function(List<String>) onSelectionChanged;

  const TagFilter({
    super.key,
    required this.availableTags,
    required this.onSelectionChanged,
  });

  @override
  State<TagFilter> createState() => _TagFilterState();
}

class _TagFilterState extends State<TagFilter> {
  final List<String> _selectedTags = [];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.availableTags.length,
        itemBuilder: (context, index) {
          final tag = widget.availableTags[index];
          final isSelected = _selectedTags.contains(tag);

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
                // Notify the parent widget of the change
                widget.onSelectionChanged(_selectedTags);
              },
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          );
        },
      ),
    );
  }
}
