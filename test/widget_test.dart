import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lecture_summarizer/ai.dart';
import 'package:lecture_summarizer/database.dart';
import 'package:lecture_summarizer/format.dart';
import 'package:lecture_summarizer/home_screen.dart';
import 'package:lecture_summarizer/transcript.dart';

void main() {
  test('Course initials come from the first two words', () {
    expect(initialsOf('Mobile Programming'), 'MP');
    expect(initialsOf('System Analysis & Design'), 'SA');
    expect(initialsOf('  network   security '), 'NS');
    expect(initialsOf('Networks'), 'NE');
    expect(initialsOf(''), '');
  });

  test('Dates, times and sizes are written like in the design', () {
    final date = DateTime(2026, 10, 29); // a Thursday
    expect(shortDate(date), 'Thu 29 Oct');
    expect(longDate(date), 'Thursday, 29 October 2026');
    expect(monthLabel(date), 'OCTOBER 2026');
    expect(clock(1477), '24:37');
    expect(clock(5), '00:05');
    expect(minutesText(3480), '58 min');
    expect(minutesText(0), 'imported audio');
    expect(megabytes(6100000), '6.1 MB');
  });

  test('The transcript is cut into timed paragraphs and counted', () {
    const transcript = '''
[00:00] Tonight your mini project moves to the cloud.

[03:12] There are two ways to give an app a backend.
A line without a time.''';
    final paragraphs = splitParagraphs(transcript);
    expect(paragraphs.length, 3);
    expect(paragraphs[0].time, '00:00');
    expect(paragraphs[0].text, 'Tonight your mini project moves to the cloud.');
    expect(paragraphs[1].time, '03:12');
    expect(paragraphs[2].time, '');
    expect(countWords(transcript), 8 + 10 + 5);
    expect(withCommas(8412), '8,412');
    expect(withCommas(999), '999');
    expect(withCommas(1234567), '1,234,567');
  });

  test('Gemini is told the right audio type', () {
    expect(mimeTypeFor('/data/lecture_1.m4a'), 'audio/mp4');
    expect(mimeTypeFor('/data/import_Song.MP3'), 'audio/mpeg');
    expect(mimeTypeFor('/data/talk.wav'), 'audio/wav');
  });

  testWidgets('A tab that is not built yet says which part brings it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ComingSoon(title: 'Groups', part: 6)),
    );

    expect(find.text('Groups comes in Part 6'), findsOneWidget);
  });
}
