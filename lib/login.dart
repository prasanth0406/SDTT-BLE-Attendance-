import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home.dart';

class sdttF extends StatefulWidget {
  const sdttF({super.key});

  @override
  State<sdttF> createState() => _sdttState();
}

class _sdttState extends State<sdttF> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Google Sign-In instance
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;

  bool isGoogleInitialized = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    initializeGoogleSignIn();
  }

  // Initialize Google Sign-In
  Future<void> initializeGoogleSignIn() async {
    try {
      await googleSignIn.initialize(
        serverClientId:
            '881788650274-ni2ttl14ji24dlj8envm1lfa8k1s8h87.apps.googleusercontent.com',
      );

      if (mounted) {
        setState(() {
          isGoogleInitialized = true;
        });
      }

      print('Google Sign-In initialized successfully');
    } catch (e) {
      print('Google Sign-In initialization error: $e');
    }
  }

  // Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (!isGoogleInitialized) {
        print('Google Sign-In is not initialized yet');
        return null;
      }

      setState(() {
        isLoading = true;
      });

      // Open Google account selection
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      // Get Google authentication details
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create Firebase credential using Google ID token
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      print('Google Login Successful');
      print('Name: ${userCredential.user?.displayName}');
      print('Email: ${userCredential.user?.email}');
      print('UID: ${userCredential.user?.uid}');

      return userCredential;
    } on GoogleSignInException catch (e) {
      print('Google Sign-In Error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In failed: ${e.description}')),
        );
      }

      return null;
    } on FirebaseAuthException catch (e) {
      print('Firebase Authentication Error: ${e.message}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firebase login failed: ${e.message}')),
        );
      }

      return null;
    } catch (e) {
      print('Login Error: $e');

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
      }

      return null;
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Email/Password Signup
  Future<void> signup(String email, String password) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Account created successfully');
    } on FirebaseAuthException catch (e) {
      print('Signup Error: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: Scaffold(
        appBar: AppBar(title: const Text('Login')),

        body: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            children: [
              // Email
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),

              const SizedBox(height: 20),

              // Password
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),

              const SizedBox(height: 20),

              // Google Login
              SizedBox(
                width: double.infinity,
                height: 50,

                child: ElevatedButton(
                  onPressed: (!isGoogleInitialized || isLoading)
                      ? null
                      : () async {
                          final UserCredential? user = await signInWithGoogle();

                          if (user != null && mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => sdtt()),
                            );
                          }
                        },

                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'LOGIN WITH GOOGLE',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 10),

              if (!isGoogleInitialized)
                const Text(
                  'Initializing Google Sign-In...',
                  style: TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
