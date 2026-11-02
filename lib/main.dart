import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
