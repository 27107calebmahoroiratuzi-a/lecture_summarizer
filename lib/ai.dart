import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';

import 'transcript.dart';

// All AI goes through Gemini, using Firebase AI Logic (Gemini Developer API).
// gemini-3.5-flash: understands audio, free tier (no Blaze plan needed),
// supported until at least May 2027.
const String geminiModel = 'gemini-3.5-flash';

GenerativeModel gemini() {
  return FirebaseAI.googleAI().generativeModel(model: geminiModel);
}

const String transcribePrompt = '''
Transcribe this lecture recording word for word, in the language that is spoken.
Write only what is said: no summary, no comments, no headings.
Start a new paragraph about every minute, or when the topic changes.
Begin every paragraph on a new line with the time it starts, like [03:12].
If nobody speaks in the recording, reply with exactly: NO SPEECH''';

// Gemini must be told what kind of audio file it receives.
String mimeTypeFor(String path) {
  final name = path.toLowerCase();
  if (name.endsWith('.m4a') || name.endsWith('.mp4')) {
    return 'audio/mp4';
  } else if (name.endsWith('.mp3')) {
    return 'audio/mpeg';
  } else if (name.endsWith('.wav')) {
    return 'audio/wav';
  } else if (name.endsWith('.aac')) {
    return 'audio/aac';
  } else if (name.endsWith('.flac')) {
    return 'audio/flac';
  } else if (name.endsWith('.ogg') || name.endsWith('.opus')) {
    return 'audio/opus';
  } else if (name.endsWith('.webm')) {
    return 'audio/webm';
  } else {
    return 'audio/mpeg';
  }
}

// Sends the audio file to Gemini and returns the transcript.
// The answer arrives in pieces (a stream), so onProgress can show the
// number of words received so far.
Future<String> transcribe(
  String audioPath,
  void Function(int words) onProgress,
) async {
  final bytes = await File(audioPath).readAsBytes();
  final prompt = TextPart(transcribePrompt);
  final audio = InlineDataPart(mimeTypeFor(audioPath), bytes);

  String transcript = '';
  final pieces = gemini().generateContentStream([
    Content.multi([prompt, audio]),
  ]);
  await for (final piece in pieces) {
    transcript = transcript + (piece.text ?? '');
    onProgress(countWords(transcript));
  }

  transcript = transcript.trim();
  if (transcript.isEmpty || transcript == 'NO SPEECH') {
    throw Exception('No speech was found in this recording.');
  }
  return transcript;
}

// Turns an error into a sentence the student understands.
String aiErrorMessage(Object error) {
  if (error is QuotaExceeded) {
    return 'The free AI limit was reached. Wait a minute, then tap Retry.';
  } else if (error is ServiceApiNotEnabled) {
    return 'Firebase AI Logic is not enabled for this Firebase project yet.';
  } else if (error.toString().contains('SocketException')) {
    // no connection: the phone could not reach the server
    return 'No internet. The recording is kept on your phone. '
        'Tap Retry when you are back online.';
  } else if (error is ServerException) {
    return 'The AI service had a problem: ${error.message}';
  } else {
    return error.toString().replaceFirst('Exception: ', '');
  }
}
