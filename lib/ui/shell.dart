import 'package:dyme_eat/screens/contribute/contribute_screen.dart';
import 'package:dyme_eat/screens/discover/discover_screen.dart';
import 'package:dyme_eat/screens/groups/groups_list_screen.dart';
import 'package:dyme_eat/screens/home/home_screen.dart'; // <-- Import the new home screen
import 'package:dyme_eat/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _selectedIndex = 0;

  // Update the list of screens to include HomeScreen first.
  // We use 'final' instead of 'const' because the widgets themselves are not constant values.
  final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(), // <-- Default screen is now HomeScreen
    const DiscoverScreen(),
    const ContributeScreen(),
    const GroupsListScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // This is important for handling more than 3 items
        items: const <BottomNavigationBarItem>[
          // Update the navigation items to match the new screen order
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.add_comment), label: 'Contribute'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Groups'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
