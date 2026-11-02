import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lecture_summarizer/database.dart';
import 'package:lecture_summarizer/home_screen.dart';

void main() {
  test('Course initials come from the first two words', () {
    expect(initialsOf('Mobile Programming'), 'MP');
    expect(initialsOf('System Analysis & Design'), 'SA');
    expect(initialsOf('  network   security '), 'NS');
    expect(initialsOf('Networks'), 'NE');
    expect(initialsOf(''), '');
  });

  testWidgets('A tab that is not built yet says which part brings it',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ComingSoon(title: 'Groups', part: 6)),
    );

    expect(find.text('Groups comes in Part 6'), findsOneWidget);
  });
}
