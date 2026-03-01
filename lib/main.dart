import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rentals/firebase_options.dart';
import 'package:rentals/navbar.dart';

// Note: You will need to create login_page.dart next for this import to work
// import 'package:rentals/login_page.dart';

void main() async {
  // Ensures Flutter is ready before initializing Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initializes Firebase using your firebase_options.dart
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rentals App',
      theme: ThemeData(
        // Using your established Navy Blue as the primary theme seed
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF113F67),
          primary: const Color(0xFF113F67),
        ),
        useMaterial3: true,
      ),
      // The Auth Gate: Automatically routes the user based on login status
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
      builder: (context, snapshot) {
        // 1. If the connection is still loading, show a splash/loading indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. If the user is logged in, send them to the main app (Navbar)
        if (snapshot.hasData) {
          return const Navbar();
        }

        // 3. If no user is logged in, show the Login Page
        // For now, I'm returning a placeholder so it doesn't crash until you build login_page.dart
        return const PlaceholderLoginPage();
      },
    );
  }
}

// Temporary placeholder until we create your real login_page.dart
class PlaceholderLoginPage extends StatelessWidget {
  const PlaceholderLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF113F67),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Welcome to Rentals",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // We will implement actual Firebase Login here next
              },
              child: const Text("Go to Login UI"),
            ),
          ],
        ),
      ),
    );
  }
}
