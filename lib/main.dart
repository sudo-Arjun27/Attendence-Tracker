import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'home_combined.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  String? savedRole = await getSavedRole();
  String? savedUsername = await getSavedUsername();
  String? savedSubject = await getSavedSubject();

  runApp(
    MyApp(
      initialRole: savedRole,
      initialUsername: savedUsername,
      initialSubject: savedSubject,
    ),
  );
}

Future<String?> getSavedRole() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    // Fetch user role from Firestore (or Firebase Database)
    var docSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    return docSnapshot.data()?['role'];
  }
  return null;
}

Future<String?> getSavedUsername() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    var docSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    return docSnapshot.data()?['username'];
  }
  return null;
}

Future<String?> getSavedSubject() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    var docSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    return docSnapshot.data()?['subject'];
  }
  return null;
}

class User with ChangeNotifier {
  String role;
  String username;
  String subject;

  User({this.role = '', this.username = '', this.subject = ''});

  void loginAs(
    String newRole,
    String newUsername, [
    String newSubject = '',
  ]) async {
    role = newRole;
    username = newUsername;
    subject = newSubject;

    // Save user data in Firebase Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'role': role,
        'username': username,
        'subject': subject,
      }, SetOptions(merge: true));
    }
    notifyListeners();
  }

  void logout() async {
    role = '';
    username = '';
    subject = '';

    // Firebase logout
    await FirebaseAuth.instance.signOut();

    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  final String? initialRole;
  final String? initialUsername;
  final String? initialSubject;

  const MyApp({
    super.key,
    required this.initialRole,
    required this.initialUsername,
    required this.initialSubject,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => User(
            role: initialRole ?? '',
            username: initialUsername ?? '',
            subject: initialSubject ?? '',
          ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'College App',
        home:
            (initialRole == null || initialRole == '')
                ? LoginPage()
                : HomeCombined(),
      ),
    );
  }
}
