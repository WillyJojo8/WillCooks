import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/login_page.dart';
import 'screens/home_screen.dart';
import 'screens/premium_info_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _checkIsPremium(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc['isPremium'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WillCooks',
      theme: ThemeData(
        primarySwatch: Colors.green,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontSize: 20.0),
          titleLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          labelLarge: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (!snapshot.hasData) {
            return const LoginPage();
          }

          final user = snapshot.data!;
          return FutureBuilder<bool>(
            future: _checkIsPremium(user.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              final isPremium = snapshot.data!;
              if (isPremium) {
                return const HomeScreen();       // Premium -> acceso total
              } else {
                return const PremiumInfoPage();  // No premium -> solo info
              }
            },
          );
        },
      ),
    );
  }
}
