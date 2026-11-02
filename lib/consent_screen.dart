import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'database.dart';
import 'format.dart';
import 'recording_screen.dart';
import 'theme.dart';

// Screen 04: choose course, title and date, and confirm the lecturer's consent.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key, this.courseId});

  // The course to select first (null = the first course in the list).
  final String? courseId;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  final titleController = TextEditingController();
  String? courseId;
  DateTime date = DateTime.now();
  bool lecturerAgreed = false;
  bool classOnly = false;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    courseId = widget.courseId;
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        date = picked;
      });
    }
  }

  // Finds the chosen course in the list. Returns null if there is none.
  Course? chosenCourse(List<Course> courses) {
    for (final course in courses) {
      if (course.id == courseId) {
        return course;
      }
    }
    if (courses.isNotEmpty) {
      return courses[0];
    }
    return null;
  }

  // Checks the form. Returns an error message, or '' when everything is fine.
  String checkForm(Course? course) {
    if (course == null) {
      return 'Add a course first';
    }
    if (titleController.text.trim().isEmpty) {
      return 'Type the lecture title';
    }
    if (!lecturerAgreed || !classOnly) {
      return 'Tick both consent boxes first';
    }
    return '';
  }

  void startRecording(Course? course) {
    final problem = checkForm(course);
    if (problem != '') {
      showMessage(problem);
      return;
    }

    // Replace this screen, so "back" from recording goes to the lecture list.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RecordingScreen(
          course: course!,
          title: titleController.text.trim(),
          date: date,
          lecturerAgreed: lecturerAgreed,
          classOnly: classOnly,
        ),
      ),
    );
  }

  // Backup for demos: use an audio file that is already on the phone.
  Future<void> importAudio(Course? course) async {
    final problem = checkForm(course);
    if (problem != '') {
      showMessage(problem);
      return;
    }

    final files = await FilePicker.pickFiles(type: FileType.audio);
    if (files.isEmpty || files[0].path == null) {
      return; // the user closed the picker
    }
    final picked = files[0];
    final size = await File(picked.path!).length();

    if (size > maxAudioBytes) {
      showMessage(
        'This file is ${megabytes(size)}. '
        'The limit is ${megabytes(maxAudioBytes)} (about one hour).',
      );
      return;
    }

    setState(() {
      busy = true;
    });

    // Copy the file into the app's own folder, so it is not lost if the
    // picker's temporary copy is cleaned up.
    final folder = await getApplicationDocumentsDirectory();
    final newPath =
        '${folder.path}/import_${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
    await File(picked.path!).copy(newPath);

    saveLecture(
      course: course!,
      title: titleController.text.trim(),
      date: date,
      durationSeconds: 0,
      audioPath: newPath,
      audioBytes: size,
      lecturerAgreed: lecturerAgreed,
      classOnly: classOnly,
      imported: true,
    );

    if (!mounted) return;
    showMessage('Audio imported and saved');
    Navigator.pop(context);
  }

  Widget label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget consentCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: primary),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.shield_outlined, color: primary),
                SizedBox(width: 10),
                Text(
                  'Recording consent',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Only record when the lecturer has agreed. The audio stays on your '
              'phone and is deleted after transcription.',
              style: TextStyle(fontSize: 14),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('The lecturer has agreed to this recording'),
              value: lecturerAgreed,
              onChanged: (value) {
                setState(() {
                  lecturerAgreed = value!;
                });
              },
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('I will only share it with my class'),
              value: classOnly,
              onChanged: (value) {
                setState(() {
                  classOnly = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final consentGiven = lecturerAgreed && classOnly;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New recording',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: myCourses().orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Course> courses = [];
          for (final doc in snapshot.data!.docs) {
            courses.add(Course.fromDoc(doc));
          }
          final course = chosenCourse(courses);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              label('Course'),
              DropdownButtonFormField<String>(
                initialValue: course?.id,
                items: [
                  for (final c in courses)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (value) {
                  setState(() {
                    courseId = value;
                  });
                },
              ),
              label('Lecture title'),
              TextField(
                controller: titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Firebase: your app in the cloud',
                ),
              ),
              label('Date'),
              InkWell(
                onTap: pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(longDate(date)),
                ),
              ),
              const SizedBox(height: 14),
              consentCard(),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: recordingRed),
                // Disabled (null) until both consent boxes are ticked.
                onPressed: consentGiven && !busy
                    ? () => startRecording(course)
                    : null,
                icon: const Icon(Icons.fiber_manual_record, size: 16),
                label: const Text('Start recording'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: consentGiven && !busy
                    ? () => importAudio(course)
                    : null,
                icon: const Icon(Icons.upload_file),
                label: const Text('Import an audio file instead'),
              ),
              const Text(
                'Up to 60 minutes per recording',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: textGrey),
              ),
            ],
          );
        },
      ),
    );
  }
}
