import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'database.dart';
import 'format.dart';
import 'home_screen.dart';
import 'theme.dart';
import 'transcript.dart';

// Screens 07-09: one lecture with three tabs: Summary, Transcript, Ask.
// Part 3 fills the Transcript tab; Parts 4 and 5 fill the other two.
class LectureScreen extends StatelessWidget {
  const LectureScreen({super.key, required this.lectureId});

  final String lectureId;

  Widget tabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EAF0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.black,
        unselectedLabelColor: textGrey,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
        ),
        tabs: const [
          Tab(text: 'Summary', height: 36),
          Tab(text: 'Transcript', height: 36),
          Tab(text: 'Ask', height: 36),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: myLectures().doc(lectureId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Text('Could not load the lecture.\n${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final lecture = Lecture.fromDoc(snapshot.data!);

        return DefaultTabController(
          length: 3,
          initialIndex: 1, // Transcript, until Part 4 adds the summary
          child: Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lecture.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${shortDate(lecture.date)} · ${withCommas(lecture.words)} words',
                    style: const TextStyle(fontSize: 13, color: textGrey),
                  ),
                ],
              ),
            ),
            body: Column(
              children: [
                tabs(),
                Expanded(
                  child: TabBarView(
                    children: [
                      const ComingSoon(title: 'The summary', part: 4),
                      TranscriptView(transcript: lecture.transcript),
                      const ComingSoon(title: 'Asking questions', part: 5),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Screen 08: the transcript in paragraphs, with a search box.
class TranscriptView extends StatefulWidget {
  const TranscriptView({super.key, required this.transcript});

  final String transcript;

  @override
  State<TranscriptView> createState() => _TranscriptViewState();
}

class _TranscriptViewState extends State<TranscriptView> {
  String search = '';

  // Splits the text into pieces and makes the pieces that match the search blue.
  List<TextSpan> highlight(String text) {
    final word = search.trim().toLowerCase();
    if (word.isEmpty) {
      return [TextSpan(text: text)];
    }

    List<TextSpan> pieces = [];
    final lower = text.toLowerCase();
    int start = 0;
    int found = lower.indexOf(word, start);
    while (found != -1) {
      pieces.add(TextSpan(text: text.substring(start, found)));
      pieces.add(
        TextSpan(
          text: text.substring(found, found + word.length),
          style: const TextStyle(color: primary, fontWeight: FontWeight.w600),
        ),
      );
      start = found + word.length;
      found = lower.indexOf(word, start);
    }
    pieces.add(TextSpan(text: text.substring(start)));
    return pieces;
  }

  @override
  Widget build(BuildContext context) {
    final word = search.trim().toLowerCase();

    // Keep only the paragraphs that contain the search word.
    List<Paragraph> shown = [];
    for (final paragraph in splitParagraphs(widget.transcript)) {
      if (paragraph.text.toLowerCase().contains(word)) {
        shown.add(paragraph);
      }
    }

    List<Widget> items = [];
    for (final paragraph in shown) {
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (paragraph.time != '')
                Text(
                  paragraph.time,
                  style: const TextStyle(fontSize: 13, color: textGrey),
                ),
              Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Colors.black,
                  ),
                  children: highlight(paragraph.text),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.transcript.isEmpty) {
      items.add(const Text('This lecture has no transcript yet.'));
    } else if (shown.isEmpty) {
      items.add(Text('"$search" is not in this transcript.'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search in transcript',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              search = value;
            });
          },
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items,
            ),
          ),
        ),
      ],
    );
  }
}
