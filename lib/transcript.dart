// Helpers for the transcript text that Gemini writes, for example:
//   [00:00] Tonight your mini project moves to the cloud...
//   [03:12] There are two ways to give an app a backend...

class Paragraph {
  Paragraph({required this.time, required this.text});

  final String time; // "03:12", or '' when the line has no time
  final String text;
}

// Cuts the transcript into paragraphs, one per line.
List<Paragraph> splitParagraphs(String transcript) {
  List<Paragraph> paragraphs = [];

  for (final rawLine in transcript.split('\n')) {
    final line = rawLine.trim();
    if (line.isEmpty) {
      continue;
    }

    final close = line.indexOf(']');
    if (line.startsWith('[') && close > 1 && close < 10) {
      paragraphs.add(
        Paragraph(
          time: line.substring(1, close),
          text: line.substring(close + 1).trim(),
        ),
      );
    } else {
      paragraphs.add(Paragraph(time: '', text: line));
    }
  }
  return paragraphs;
}

// Counts the spoken words (the [03:12] times are not words).
int countWords(String transcript) {
  int count = 0;
  for (final paragraph in splitParagraphs(transcript)) {
    for (final word in paragraph.text.split(' ')) {
      if (word.trim().isNotEmpty) {
        count = count + 1;
      }
    }
  }
  return count;
}

// 8412 -> "8,412"
String withCommas(int number) {
  final digits = number.toString();
  String result = '';
  for (int i = 0; i < digits.length; i++) {
    final fromEnd = digits.length - i;
    if (i > 0 && fromEnd % 3 == 0) {
      result = '$result,';
    }
    result = result + digits[i];
  }
  return result;
}
