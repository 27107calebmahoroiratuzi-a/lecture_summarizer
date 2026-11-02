import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'login_screen.dart';
import 'theme.dart';

// Lets any part of the app show a message, even after its screen was closed
// (for example "The transcript is ready").
final messengerKey = GlobalKey<ScaffoldMessengerState>();

void showAppMessage(String message) {
  messengerKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // App Check proves to Firebase that a request really comes from THIS app,
  // so nobody else can use our free Gemini quota.
  // Debug builds (flutter run) use a debug token that is registered once in the
  // Firebase console. Release builds use Google Play Integrity.
  AndroidAppCheckProvider androidCheck = const AndroidPlayIntegrityProvider();
  AppleAppCheckProvider appleCheck = const AppleDeviceCheckProvider();
  if (kDebugMode) {
    androidCheck = const AndroidDebugProvider();
    appleCheck = const AppleDebugProvider();
  }
  await FirebaseAppCheck.instance.activate(
    providerAndroid: androidCheck,
    providerApple: appleCheck,
  );

  runApp(const LectureApp());
}

class LectureApp extends StatelessWidget {
  const LectureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lecture Summariser',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      theme: appTheme(),
      home: const AuthGate(),
    );
  }
}

// Shows the login screen when nobody is signed in, otherwise the app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == null) {
          return const LoginScreen();
        }
        return const HomeScreen();
      },
    );
  }
}
