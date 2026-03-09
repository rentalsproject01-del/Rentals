import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rentals/firebase_options.dart';

import 'package:rentals/widgets/navbar.dart';
import 'package:rentals/views/auth/login_page.dart';
import 'package:rentals/views/profile/account_setup_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF113F67)),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // 1. Show loading indicator while waiting for Auth state
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Check if user is logged in
        final User? user = authSnapshot.data;

        if (user == null) {
          // If no user is authenticated, route to Login
          return const LoginPage();
        }

        // 3. If user exists, check Firestore for their profile document
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, firestoreSnapshot) {
            // 4. Show loading indicator while checking Firestore
            if (firestoreSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Handle potential Firestore errors gracefully
            if (firestoreSnapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: Text("Error loading profile. Please try again."),
                ),
              );
            }

            // 5. Route based on whether the Firestore document exists
            if (firestoreSnapshot.hasData && firestoreSnapshot.data!.exists) {
              return const Navbar(); // Profile exists, go to main app
            } else {
              return const AccountSetupPage(); // Profile does NOT exist, go to setup
            }
          },
        );
      },
    );
  }
}
