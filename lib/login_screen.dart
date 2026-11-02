import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'database.dart';
import 'theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // false = "Log in" form, true = "Create account" form (shows the name field)
  bool creatingAccount = false;
  bool busy = false;
  String error = '';

  String messageFor(String code) {
    if (code == 'email-already-in-use') {
      return 'An account with this email already exists. Log in instead.';
    } else if (code == 'invalid-credential' ||
        code == 'wrong-password' ||
        code == 'user-not-found') {
      return 'Wrong email or password.';
    } else if (code == 'invalid-email') {
      return 'Enter a valid email, like caleb@auca.ac.rw';
    } else if (code == 'weak-password') {
      return 'Choose a stronger password (at least 6 characters).';
    } else if (code == 'network-request-failed') {
      return 'No internet connection.';
    } else {
      return 'Something went wrong ($code).';
    }
  }

  // Checks the form. Returns an error message, or '' when everything is fine.
  String checkForm() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (creatingAccount && name.isEmpty) {
      return 'Type your name';
    }
    if (email.isEmpty) {
      return 'Type your email';
    }
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email, like caleb@auca.ac.rw';
    }
    if (password.length < 6) {
      return 'The password needs at least 6 characters';
    }
    return '';
  }

  Future<void> submit() async {
    final problem = checkForm();
    if (problem != '') {
      setState(() {
        error = problem;
      });
      return;
    }

    setState(() {
      busy = true;
      error = '';
    });

    final auth = FirebaseAuth.instance;
    final email = emailController.text.trim();
    final password = passwordController.text;

    try {
      if (creatingAccount) {
        await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await saveNewUser(nameController.text.trim(), email);
      } else {
        await auth.signInWithEmailAndPassword(email: email, password: password);
      }
      // No navigation here: the AuthGate sees the signed-in user and opens the app.
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          error = messageFor(e.code);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  void switchForm() {
    setState(() {
      creatingAccount = !creatingAccount;
      error = '';
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Widget field(String label, TextEditingController controller,
      {bool hidden = false, TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: hidden,
            keyboardType: type,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String mainLabel = 'Log in';
    String otherLabel = 'Create account';
    if (creatingAccount) {
      mainLabel = 'Create account';
      otherLabel = 'I already have an account';
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.mic_none, color: Colors.white, size: 36),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Lecture Summariser',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Listen in class. Get the transcript, the summary and likely exam questions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: textGrey),
                ),
                const SizedBox(height: 22),
                if (creatingAccount) field('Name', nameController),
                field('Email', emailController, type: TextInputType.emailAddress),
                field('Password', passwordController, hidden: true),
                if (error != '')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(error, style: const TextStyle(color: recordingRed)),
                  ),
                FilledButton(
                  onPressed: busy ? null : submit,
                  child: busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Text(mainLabel),
                ),
                const SizedBox(height: 22),
                OutlinedButton(
                  onPressed: busy ? null : switchForm,
                  child: Text(otherLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
