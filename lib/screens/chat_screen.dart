import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedDrawerItem = 0;

  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _messages.add(Message(text: _controller.text, isUser: true));
      });

      final response = await _sendToApi(_controller.text);

      setState(() {
        _messages.add(Message(text: response, isUser: false));
        _controller.clear();
      });
      _scrollToBottom();
    }
  }

  Future<String> _sendToApi(String message) async {
    final url = 'https://a-l-o-h-a.onrender.com/chat'; // Use your actual Render URL
    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"message": message}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['response'] ?? 'Sorry, I didn\'t understand that.';
    } else {
      return 'Failed to get response from API.';
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          'A.L.O.H.A',
          style: TextStyle(
            fontFamily: 'Audiowide',
            fontSize: 30,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
      ),
      drawer: Drawer(
        backgroundColor: Color(0xFF171717),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              height: 150,
              color: Color(0xFF171717),
              child: DrawerHeader(
                decoration: BoxDecoration(
                  color: Color(0xFF171717),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 0),
                    child: Text(
                      'Menu',
                      style: TextStyle(
                        fontFamily: 'Cousine',
                        color: Colors.white,
                        fontSize: 36,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: ListTile(
                      title: Text(
                        'Personal Assistant',
                        style: TextStyle(
                          fontFamily: 'Cousine',
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      tileColor: _selectedDrawerItem == 0 ? Colors.grey[800] : null,
                      onTap: () {
                        setState(() {
                          _selectedDrawerItem = 0;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: ListTile(
                      title: Text(
                        'Wiki',
                        style: TextStyle(
                          fontFamily: 'Cousine',
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      tileColor: _selectedDrawerItem == 1 ? Colors.grey[800] : null,
                      onTap: () {
                        setState(() {
                          _selectedDrawerItem = 1;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(
                        'Schedule',
                        style: TextStyle(
                          fontFamily: 'Cousine',
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      tileColor: _selectedDrawerItem == 2 ? Colors.grey[700] : null,
                      onTap: () {
                        setState(() {
                          _selectedDrawerItem = 2;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: AnimatedPadding(
        padding: EdgeInsets.only(bottom: isKeyboardVisible ? keyboardHeight : 0),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: false,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Align(
                    alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: message.isUser ? Colors.white.withOpacity(0.90) : Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          fontFamily: 'Cousine',
                          color: message.isUser ? Colors.black : Colors.white,
                          fontSize: 14,
                          fontWeight: message.isUser ? FontWeight.w400 : FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        hintStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.grey[850],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.all(16.0),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.black,
    );
  }
}
