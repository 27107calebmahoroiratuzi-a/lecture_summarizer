import 'dart:io';

import 'package:flutter/material.dart';

import 'ai.dart';
import 'database.dart';
import 'format.dart';
import 'lecture_screen.dart';
import 'main.dart';
import 'theme.dart';
import 'transcript.dart';

// Screen 06: sends the recording to Gemini and shows the steps.
// Three states: loading (working), error (with Retry) and data (done).
class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key, required this.lecture});

  final Lecture lecture;

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  String state = 'working'; // 'working', 'error' or 'done'
  String error = '';
  int words = 0;

  @override
  void initState() {
    super.initState();
    run();
  }

  void retry() {
    setState(() {
      state = 'working';
      error = '';
      words = 0;
    });
    run();
  }

  Future<void> run() async {
    final lecture = widget.lecture;

    final audioExists =
        lecture.audioPath != '' && await File(lecture.audioPath).exists();
    if (!audioExists) {
      setState(() {
        state = 'error';
        error =
            'The audio file is no longer on this phone, '
            'so this lecture cannot be transcribed.';
      });
      return;
    }

    setStatus(lecture, 'transcribing');
    try {
      final transcript = await transcribe(lecture.audioPath, (count) {
        if (mounted) {
          setState(() {
            words = count;
          });
        }
      });

      // Save the text, then delete the audio: it never leaves the phone.
      saveTranscript(lecture, transcript, countWords(transcript));
      await File(lecture.audioPath).delete();

      if (mounted) {
        setState(() {
          state = 'done';
        });
      } else {
        // The student left this screen, so tell them with a message.
        showAppMessage('The transcript of ${lecture.title} is ready');
      }
    } catch (e) {
      setStatus(lecture, 'recorded'); // so it can be tried again later
      if (mounted) {
        setState(() {
          state = 'error';
          error = aiErrorMessage(e);
        });
      } else {
        showAppMessage('${lecture.title}: ${aiErrorMessage(e)}');
      }
    }
  }

  void openLecture() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LectureScreen(lectureId: widget.lecture.id),
      ),
    );
  }

  // One line of the steps card: a circle, a name and a note on the right.
  // stepState is 'done', 'now' or 'next'.
  Widget step(String name, String stepState, String note) {
    Widget circle;
    if (stepState == 'done') {
      circle = const CircleAvatar(
        radius: 14,
        backgroundColor: success,
        child: Icon(Icons.check, size: 16, color: Colors.white),
      );
    } else if (stepState == 'now') {
      circle = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: primarySoft,
          shape: BoxShape.circle,
          border: Border.all(color: primary, width: 2),
        ),
      );
    } else {
      circle = Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: cardBorder, width: 2),
        ),
      );
    }

    Color textColour = Colors.black;
    if (stepState == 'next') {
      textColour = textGrey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          circle,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 15,
                color: textColour,
                fontWeight: stepState == 'now'
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
          Text(note, style: const TextStyle(fontSize: 13, color: textGrey)),
        ],
      ),
    );
  }

  Widget errorCard() {
    return Card(
      color: const Color(0xFFFDE7E8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFF6C3C5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Something failed',
              style: TextStyle(
                color: recordingRed,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(error),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: retry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String transcribeState = 'now';
    String transcribeNote = '${withCommas(words)} words';
    if (state == 'done') {
      transcribeState = 'done';
    } else if (state == 'error') {
      transcribeState = 'next';
      transcribeNote = '';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Preparing your lecture',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  step(
                    'Recording saved',
                    'done',
                    minutesText(widget.lecture.durationSeconds),
                  ),
                  step('Transcribing', transcribeState, transcribeNote),
                  if (state == 'working')
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(minHeight: 8),
                    ),
                  step('Writing the summary', 'next', 'Part 4'),
                  step('Exam questions', 'next', 'Part 4'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (state == 'working')
            const Text(
              'You can leave this screen. We will tell you when it is ready.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textGrey),
            ),
          if (state == 'done')
            FilledButton(
              onPressed: openLecture,
              child: const Text('Open transcript'),
            ),
          if (state == 'error') errorCard(),
        ],
      ),
    );
  }
}
