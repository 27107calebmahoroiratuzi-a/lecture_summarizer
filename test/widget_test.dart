import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lecture_summarizer/database.dart';
import 'package:lecture_summarizer/format.dart';
import 'package:lecture_summarizer/home_screen.dart';

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

  testWidgets('A tab that is not built yet says which part brings it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ComingSoon(title: 'Groups', part: 6)),
    );

    expect(find.text('Groups comes in Part 6'), findsOneWidget);
  });
}
