import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'consent_screen.dart';
import 'database.dart';
import 'format.dart';
import 'theme.dart';

// Screen 03: the lectures of one course, newest first, grouped by month.
class CourseScreen extends StatelessWidget {
  const CourseScreen({super.key, required this.course});

  final Course course;

  void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> confirmDelete(BuildContext context) async {
    // A course that still has lectures cannot be deleted.
    final result = await lecturesOf(course).limit(1).get();
    if (!context.mounted) return;
    if (result.docs.isNotEmpty) {
      showMessage(context, 'Delete the lectures of ${course.name} first');
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Delete ${course.name}?'),
          content: const Text('The course will be removed from your list.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Keep it'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: recordingRed,
                minimumSize: const Size(0, 40),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await deleteCourse(course);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Details of one lecture. In Part 3 tapping a lecture opens processing instead.
  void openLecture(BuildContext context, Lecture lecture) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        String audioText = 'Audio file not found on this phone';
        if (lecture.audioPath != '' && File(lecture.audioPath).existsSync()) {
          audioText = 'Audio on this phone · ${megabytes(lecture.audioBytes)}';
        }

        String consentText = 'Lecturer consent: not given';
        if (lecture.lecturerAgreed && lecture.classOnly) {
          consentText = 'Lecturer agreed · shared with my class only';
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                lecture.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                '${longDate(lecture.date)} · ${minutesText(lecture.durationSeconds)}',
                style: const TextStyle(color: textGrey),
              ),
              const SizedBox(height: 16),
              Text(consentText),
              const SizedBox(height: 4),
              Text(audioText),
              const SizedBox(height: 16),
              const Text(
                'Transcription comes in Part 3.',
                style: TextStyle(color: textGrey),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: recordingRed),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete recording'),
                onPressed: () async {
                  Navigator.pop(sheetContext);
                  await deleteLecture(lecture);
                  if (context.mounted) {
                    showMessage(context, '${lecture.title} deleted');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget statusChip(String status) {
    String text = 'Recorded';
    Color background = const Color(0xFFFDF1D8);
    Color colour = const Color(0xFFA06A00);

    if (status == 'ready') {
      text = 'Ready';
      background = const Color(0xFFE3F5EC);
      colour = success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(color: colour, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget lectureCard(BuildContext context, Lecture lecture) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => openLecture(context, lecture),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lecture.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  statusChip(lecture.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${shortDate(lecture.date)} · ${minutesText(lecture.durationSeconds)}',
                style: const TextStyle(fontSize: 13, color: textGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget monthText(DateTime date) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Text(
        monthLabel(date),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textGrey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          course.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete course',
            onPressed: () => confirmDelete(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: recordingRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.mic_none),
        label: const Text('Record lecture'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConsentScreen(courseId: course.id),
            ),
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: lecturesOf(course).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Could not load the lectures.\n${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Lecture> lectures = [];
          for (final doc in snapshot.data!.docs) {
            lectures.add(Lecture.fromDoc(doc));
          }

          if (lectures.isEmpty) {
            return const Center(
              child: Text(
                'No lectures yet.\nTap Record lecture to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textGrey, fontSize: 16),
              ),
            );
          }

          // Newest first (sorted here, so Firestore needs no extra index).
          lectures.sort((a, b) => b.date.compareTo(a.date));

          // Add a month label each time the month changes.
          List<Widget> items = [];
          String lastMonth = '';
          for (final lecture in lectures) {
            final month = monthLabel(lecture.date);
            if (month != lastMonth) {
              items.add(monthText(lecture.date));
              lastMonth = month;
            }
            items.add(Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: lectureCard(context, lecture),
            ));
          }
          items.add(const SizedBox(height: 80)); // room for the button

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            children: items,
          );
        },
      ),
    );
  }
}
