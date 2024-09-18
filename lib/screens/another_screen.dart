import 'package:flutter/material.dart';

class AnotherScreen extends StatelessWidget {
  final String title;

  AnotherScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Content for $title')),
    );
  }
}
