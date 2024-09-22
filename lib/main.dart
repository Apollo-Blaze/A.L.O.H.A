import 'package:flutter/material.dart';
import 'screens/chat_screen.dart'; // Import the ChatScreen file
import 'screens/another_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: ChatScreen(), // Set ChatScreen as the home screen
    );
  }
}
