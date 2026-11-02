import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Everything private is stored under the signed-in user:
//   users/{uid}                  name, email, createdAt
//   users/{uid}/courses/{id}     name, createdAt
//   users/{uid}/lectures/{id}    courseId, title, date, durationSeconds, consent,
//                                status, audioPath, audioBytes, imported, createdAt
// The audio itself is NOT uploaded: audioPath points to the file on this phone.

class Course {
  Course({required this.id, required this.name});

  final String id;
  final String name;

  static Course fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Course(id: doc.id, name: data['name'] ?? '');
  }
}

String myId() {
  return FirebaseAuth.instance.currentUser!.uid;
}

DocumentReference<Map<String, dynamic>> myUserDoc() {
  return FirebaseFirestore.instance.collection('users').doc(myId());
}

CollectionReference<Map<String, dynamic>> myCourses() {
  return myUserDoc().collection('courses');
}

Future<void> saveNewUser(String name, String email) async {
  await myUserDoc().set({
    'name': name,
    'email': email,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

Future<void> addCourse(String name) async {
  await myCourses().add({
    'name': name,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

Future<void> deleteCourse(Course course) async {
  await myCourses().doc(course.id).delete();
}

class Lecture {
  Lecture({
    required this.id,
    required this.courseId,
    required this.title,
    required this.date,
    required this.durationSeconds,
    required this.status,
    required this.audioPath,
    required this.audioBytes,
    required this.lecturerAgreed,
    required this.classOnly,
  });

  final String id;
  final String courseId;
  final String title;
  final DateTime date;
  final int durationSeconds;
  final String status; // 'recorded' now; Parts 3-4 add 'ready'
  final String audioPath;
  final int audioBytes;
  final bool lecturerAgreed;
  final bool classOnly;

  static Lecture fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    DateTime date = DateTime.now();
    if (data['date'] is Timestamp) {
      date = (data['date'] as Timestamp).toDate();
    }

    Map<String, dynamic> consent = {};
    if (data['consent'] is Map) {
      consent = Map<String, dynamic>.from(data['consent']);
    }

    return Lecture(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      date: date,
      durationSeconds: data['durationSeconds'] ?? 0,
      status: data['status'] ?? 'recorded',
      audioPath: data['audioPath'] ?? '',
      audioBytes: data['audioBytes'] ?? 0,
      lecturerAgreed: consent['lecturerAgreed'] ?? false,
      classOnly: consent['classOnly'] ?? false,
    );
  }
}

CollectionReference<Map<String, dynamic>> myLectures() {
  return myUserDoc().collection('lectures');
}

Query<Map<String, dynamic>> lecturesOf(Course course) {
  return myLectures().where('courseId', isEqualTo: course.id);
}

// Not awaited on purpose: Firestore keeps the write on the phone and uploads it
// when there is internet, so saving still works in a lecture hall with no signal.
void saveLecture({
  required Course course,
  required String title,
  required DateTime date,
  required int durationSeconds,
  required String audioPath,
  required int audioBytes,
  required bool lecturerAgreed,
  required bool classOnly,
  required bool imported,
}) {
  myLectures().add({
    'courseId': course.id,
    'title': title,
    'date': Timestamp.fromDate(date),
    'durationSeconds': durationSeconds,
    'consent': {
      'lecturerAgreed': lecturerAgreed,
      'classOnly': classOnly,
      'givenAt': FieldValue.serverTimestamp(),
    },
    'status': 'recorded',
    'audioPath': audioPath,
    'audioBytes': audioBytes,
    'imported': imported,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

// Removes the details from Firestore and the audio file from the phone.
Future<void> deleteLecture(Lecture lecture) async {
  final file = File(lecture.audioPath);
  if (lecture.audioPath != '' && await file.exists()) {
    await file.delete();
  }
  myLectures().doc(lecture.id).delete(); // not awaited, same reason as saveLecture
}

// "Mobile Programming" -> "MP", "Networks" -> "NE"
String initialsOf(String name) {
  final words = name.trim().split(' ');
  String initials = '';

  for (final word in words) {
    if (word.isNotEmpty && initials.length < 2) {
      initials = initials + word[0];
    }
  }

  if (initials.length == 1 && words[0].length > 1) {
    initials = words[0].substring(0, 2);
  }
  return initials.toUpperCase();
}
