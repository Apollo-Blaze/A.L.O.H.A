import 'package:flutter/material.dart';
import 'screens/chat_screen.dart'; // Import your chat screen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ALOHA',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        appBarTheme: AppBarTheme(
          color: Colors.grey[700] ?? Colors.grey, // Provide a default color in case Colors.grey[700] is null
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black87),
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: TextStyle(color: Colors.grey[600] ?? Colors.grey), // Fallback color
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[400] ?? Colors.grey), // Fallback color
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[600] ?? Colors.grey), // Fallback color
          ),
        ),
      ),
      home: ChatScreen(),
    );
  }
}
