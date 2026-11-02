import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'course_screen.dart';
import 'database.dart';
import 'theme.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  String search = '';

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Keeps only the courses whose name contains the search word.
  List<Course> filter(List<Course> courses) {
    final word = search.trim().toLowerCase();
    List<Course> result = [];
    for (final course in courses) {
      if (course.name.toLowerCase().contains(word)) {
        result.add(course);
      }
    }
    return result;
  }

  void openAddDialog(List<Course> courses) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add a course'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Mobile Programming'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  showMessage('Type the course name');
                  return;
                }
                for (final course in courses) {
                  if (course.name.toLowerCase() == name.toLowerCase()) {
                    showMessage('You already have $name');
                    return;
                  }
                }
                Navigator.pop(dialogContext);
                await addCourse(name);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget courseCard(Course course, int index) {
    // The tiles take turns using 4 colours, like in the design.
    final colour = index % 4;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tileBackgrounds[colour],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            initialsOf(course.name),
            style: TextStyle(
              color: tileLetters[colour],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          course.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'No lectures yet',
          style: TextStyle(color: textGrey),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CourseScreen(course: course)),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: myCourses().orderBy('createdAt').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Could not load your courses.\n${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Course> courses = [];
        for (final doc in snapshot.data!.docs) {
          courses.add(Course.fromDoc(doc));
        }
        final shown = filter(courses);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'My courses',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton.outlined(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add course',
                  onPressed: () => openAddDialog(courses),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search courses',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  search = value;
                });
              },
            ),
            const SizedBox(height: 14),
            if (courses.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text(
                  'No courses yet. Tap + to add your first course.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textGrey),
                ),
              ),
            for (int i = 0; i < shown.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: courseCard(shown[i], i),
              ),
          ],
        );
      },
    );
  }
}
