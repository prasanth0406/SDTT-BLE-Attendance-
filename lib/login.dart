import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import "home.dart";

class sdttF extends StatefulWidget {
  const sdttF({super.key});

  @override
  State<sdttF> createState() => _sdttState();
}

class _sdttState extends State<sdttF> {
  final auth=LocalAuthentication();
  Future auther() async{
     final prasanth= await auth.authenticate(localizedReason: "PLEASE AUTHENTICATE TO CONTINUE");
     if(prasanth){
       Navigator.push(context,MaterialPageRoute(builder: (context)=>sdtt()));
     }
     else{
       debugPrint("hello error");
     }

  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      home:Scaffold(
        body: Center(
            child: ElevatedButton(onPressed: auther,
                child: Text("LOGIN"))
        ),
      )
    );
  }
}
