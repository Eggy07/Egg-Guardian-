import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  bool isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> registerUser() async {
    setState(() => isLoading = true);

    try {
      // Create user with Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      final user = userCredential.user;

      if (user != null) {
        // Update user display name
        await user.updateDisplayName(nameController.text.trim());

        // Store additional user info in Firestore
        await _firestore.collection('user').doc(user.uid).set({
          'full_name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'role': 'user', // Default role for new users
          'created_at': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created! Please log in.')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        message = 'Email is already in use.';
      }
      if (e.code == 'weak-password') {
        message = 'Password should be at least 6 characters.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 30,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFC400),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'CREATE ACCOUNT',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              SizedBox(
                height: 300,
                width: 300,
                child: Image.asset(
                  'assets/EG.png',
                  fit: BoxFit.contain, // or BoxFit.fill if you want stretching
                ),
              ),
              const SizedBox(height: 30),

              // Input Form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    // Full name input
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        filled: true,
                        fillColor: const Color(0xFFFFF3CD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Email input
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        filled: true,
                        fillColor: const Color(0xFFFFF3CD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Password input
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        filled: true,
                        fillColor: const Color(0xFFFFF3CD),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Loading button or regular button
                    isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: registerUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFC400),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 50,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                          ),
                    const SizedBox(height: 20),
                    // Redirect to login page if user already has an account
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        );
                      },
                      child: const Text(
                        "Already have an account? Log in",
                        style: TextStyle(color: Colors.black),
                      ),
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
