import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class sdtt extends StatefulWidget {
  const sdtt({super.key});

  @override
  State<sdtt> createState() => _sdttState();
}

class _sdttState extends State<sdtt> {
  late  bool yess=false;
  final auth=LocalAuthentication();
  Future auther() async{
    final prasanth= await auth.authenticate(localizedReason: "PLEASE AUTHENTICATE TO CONTINUE");
    if(prasanth){
     setState(() {
       yess=true;
     });
    }
    else{
      debugPrint("hello error");
    }

  }
  @override
  void initState(){
    super.initState();
    auther();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            child: Center(
              child: Text("WELCOME TO ONE OF THE FAMOUS ATTENDANCE SYSTEM WHERE CAPTURING OF ATTENDANCE IS IN MILLISECONDS AND YOU CAN WONDER HOW BUT THIS IS POSSIABLE BY THE FAMOUS CODER PRASANTH "),
            ),
          ),
          Container(
            height: double.infinity,
            width: double.infinity,
            color: yess?Colors.transparent:Colors.white,
          )
        ],
      ),
    );
  }
}
