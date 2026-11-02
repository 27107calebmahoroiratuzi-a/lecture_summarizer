import 'package:flutter/material.dart';

import 'courses_screen.dart';
import 'profile_screen.dart';

// The four tabs of the bottom navigation bar.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;

  Widget currentPage() {
    if (tab == 0) {
      return const CoursesScreen();
    } else if (tab == 1) {
      return const ComingSoon(title: 'Groups', part: 6);
    } else if (tab == 2) {
      return const ComingSoon(title: 'Flashcards', part: 7);
    } else {
      return const ProfileScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: currentPage()),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: tab,
        onDestinationSelected: (index) {
          setState(() {
            tab = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: 'Flashcards',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Placeholder for tabs that are built in a later part.
class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key, required this.title, required this.part});

  final String title;
  final int part;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title comes in Part $part',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
