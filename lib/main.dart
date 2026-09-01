import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';
import "login.dart";
import 'firebase_options.dart';

Future main()
async{
  WidgetsFlutterBinding.ensureInitialized();
   await Firebase.initializeApp(
   options: DefaultFirebaseOptions.currentPlatform,
   );
  runApp(mainb());

}
class mainb extends StatefulWidget {
  const mainb ({super.key});

  @override
  State<mainb> createState() => _sdttState();
}

class _sdttState extends State<mainb> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(

      home: sdttF(),

    );
  }
}
