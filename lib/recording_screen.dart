import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'database.dart';
import 'format.dart';
import 'processing_screen.dart';
import 'theme.dart';

// Recording settings: mono speech audio, small files.
// 24 kbps = 3,000 bytes per second, about 10.8 MB for one hour.
// (Part 3 sends the file to Gemini inside one request, which must stay under 20 MB.)
const int bitRate = 24000;
const int maxSeconds = 60 * 60;
const int maxAudioBytes = 14000000;

// Screen 05: records the lecture after consent was given.
class RecordingScreen extends StatefulWidget {
  const RecordingScreen({
    super.key,
    required this.course,
    required this.title,
    required this.date,
    required this.lecturerAgreed,
    required this.classOnly,
  });

  final Course course;
  final String title;
  final DateTime date;
  final bool lecturerAgreed;
  final bool classOnly;

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final recorder = AudioRecorder();
  Timer? timer;
  StreamSubscription<Amplitude>? levelListener;

  int seconds = 0;
  bool started = false;
  bool paused = false;
  bool finishing = false;

  // The last 18 sound levels (0 to 1), drawn as the waveform bars.
  List<double> levels = List.filled(18, 0.1);

  @override
  void initState() {
    super.initState();
    startRecording();
  }

  @override
  void dispose() {
    timer?.cancel();
    levelListener?.cancel();
    recorder.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> startRecording() async {
    final allowed = await recorder.hasPermission();
    if (!allowed) {
      if (!mounted) return;
      showMessage('Allow the microphone to record lectures');
      Navigator.pop(context);
      return;
    }

    final folder = await getApplicationDocumentsDirectory();
    final path =
        '${folder.path}/lecture_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: bitRate,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );

    // Android stops the microphone of apps in the background,
    // so the screen stays on while recording.
    WakelockPlus.enable();

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      tick();
    });

    levelListener = recorder
        .onAmplitudeChanged(const Duration(milliseconds: 200))
        .listen((amplitude) {
          setState(() {
            levels.removeAt(0);
            levels.add(levelFrom(amplitude.current));
          });
        });

    setState(() {
      started = true;
    });
  }

  // The recorder gives loudness in decibels: about -50 (quiet) to 0 (loud).
  double levelFrom(double decibels) {
    double level = (decibels + 50) / 50;
    if (level < 0.05) {
      level = 0.05;
    }
    if (level > 1) {
      level = 1;
    }
    return level;
  }

  void tick() {
    if (paused || finishing) {
      return;
    }
    setState(() {
      seconds = seconds + 1;
    });
    if (seconds >= maxSeconds) {
      showMessage('60 minutes reached: the recording was stopped');
      stopAndSave();
    }
  }

  Future<void> togglePause() async {
    if (paused) {
      await recorder.resume();
    } else {
      await recorder.pause();
    }
    setState(() {
      paused = !paused;
    });
  }

  Future<void> stopAndSave() async {
    if (finishing) return;
    setState(() {
      finishing = true;
    });
    timer?.cancel();
    levelListener?.cancel();

    final path = await recorder.stop();
    WakelockPlus.disable();

    if (path == null) {
      if (!mounted) return;
      showMessage('The recording failed. Please try again.');
      Navigator.pop(context);
      return;
    }

    final bytes = await File(path).length();
    final lecture = saveLecture(
      course: widget.course,
      title: widget.title,
      date: widget.date,
      durationSeconds: seconds,
      audioPath: path,
      audioBytes: bytes,
      lecturerAgreed: widget.lecturerAgreed,
      classOnly: widget.classOnly,
      imported: false,
    );

    if (!mounted) return;
    // Straight on to transcription (screen 06).
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ProcessingScreen(lecture: lecture),
      ),
    );
  }

  void confirmCancel() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Discard this recording?'),
          content: const Text(
            'The audio will be deleted and nothing is saved.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Keep recording'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: recordingRed,
                minimumSize: const Size(0, 40),
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                finishing = true;
                timer?.cancel();
                await recorder.cancel(); // stops and deletes the file
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );
  }

  Widget banner() {
    String text = 'Recording · lecturer consent given';
    if (paused) {
      text = 'Paused · lecturer consent given';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: recordingRed,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, color: Colors.white, size: 10),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget waveform() {
    List<Widget> bars = [];
    for (final level in levels) {
      bars.add(
        Container(
          width: 5,
          height: 8 + level * 62,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: paused ? cardBorder : recordingRed,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );
    }
    return SizedBox(
      height: 80,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: bars),
    );
  }

  Widget roundButton({
    required IconData icon,
    required double size,
    required VoidCallback? onPressed,
    bool red = false,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton.filled(
        style: IconButton.styleFrom(
          backgroundColor: red ? recordingRed : Colors.white,
          foregroundColor: red ? Colors.white : Colors.black,
          side: red ? null : const BorderSide(color: cardBorder),
        ),
        icon: Icon(icon, size: size * 0.4),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final minutesLeft = (maxSeconds - seconds) ~/ 60;
    final sizeSoFar = seconds * bitRate ~/ 8;

    String infoText = '$minutesLeft minutes left · ${megabytes(sizeSoFar)}';
    if (!started) {
      infoText = 'Starting the microphone...';
    } else if (paused) {
      infoText = 'Paused';
    }

    // While recording, the back button asks before throwing the recording away.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !finishing) {
          confirmCancel();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              banner(),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.course.name,
                      style: const TextStyle(fontSize: 13, color: textGrey),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      clock(seconds),
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    waveform(),
                    const SizedBox(height: 20),
                    Text(
                      infoText,
                      style: const TextStyle(fontSize: 13, color: textGrey),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    roundButton(
                      icon: paused ? Icons.play_arrow : Icons.pause,
                      size: 64,
                      onPressed: started && !finishing ? togglePause : null,
                    ),
                    const SizedBox(width: 28),
                    roundButton(
                      icon: Icons.stop,
                      size: 84,
                      red: true,
                      onPressed: started && !finishing ? stopAndSave : null,
                    ),
                    const SizedBox(width: 28),
                    roundButton(
                      icon: Icons.close,
                      size: 64,
                      onPressed: finishing ? null : confirmCancel,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
