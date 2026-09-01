import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import "home.dart";
import "package:firebase_auth/firebase_auth.dart";


class sdttF extends StatefulWidget {
  const sdttF({super.key});
  @override
  State<sdttF> createState() => _sdttState();
}

class _sdttState extends State<sdttF> {
  final TextEditingController emailController=
  TextEditingController();

  final TextEditingController passwordController=
  TextEditingController();
  void signup(String username,String password){
    final auth=FirebaseAuth.instance;
    final response=auth.createUserWithEmailAndPassword(email: username, password: password);

  }



  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      home:Scaffold(
        body: Padding(padding: EdgeInsetsGeometry.all(20),
        child: Column(
      children: [


      TextField(
      controller: emailController,
        decoration: const InputDecoration(
            labelText: "Email",
            hintText: "Enter your email",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email)
        ),
      ),
        const SizedBox(height:20),
        TextField(
          controller:passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "password",
            border: OutlineInputBorder(),

        ),

        ),
        const SizedBox(height:20),
        ElevatedButton(onPressed: (){
          signup(emailController.text, passwordController.text);
          Navigator.push(context, MaterialPageRoute(builder: (context)=>sdtt()));
        }, child: Text("LOGIN"))
        ])
      )
    )
    );
  }
}
