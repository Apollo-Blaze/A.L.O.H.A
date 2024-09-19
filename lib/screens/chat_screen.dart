import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/message.dart';
import 'dart:async'; // Required for delay
import 'another_screen.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ValueNotifier<bool> _hasText = ValueNotifier<bool>(false);
  int _selectedDrawerItem = 0;
  bool _showScrollToBottomButton = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.removeListener(_onScroll);
    _hasText.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _hasText.value = _controller.text.isNotEmpty;
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 100) {
      // Show button when not at the bottom
      if (!_showScrollToBottomButton) {
        setState(() {
          _showScrollToBottomButton = true;
        });
      }
    } else {
      // Hide button when at the bottom
      if (_showScrollToBottomButton) {
        setState(() {
          _showScrollToBottomButton = false;
        });
      }
    }
  }

  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _messages.add(Message(text: _controller.text, isUser: true));
      });

      final response = await _sendToApi(_controller.text);

      setState(() {
        _controller.clear();
        _hasText.value = false;
      });
      _scrollToBottom();

      _simulateTyping(response); // Simulate typing effect for API response
    }
  }

  Future<String> _sendToApi(String message) async {
    final url = 'http://192.168.18.170:5000/chat'; // Use your actual Render URL
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

  // Simulate typing effect for API response
  void _simulateTyping(String response) async {
    const typingDelay = Duration(milliseconds: 3); // Delay between each character
    String displayText = '';

    for (int i = 0; i < response.length; i++) {
      await Future.delayed(typingDelay);
      setState(() {
        displayText += response[i];
        // Show the partial message as it's being "typed"
        if (i == 0) {
          _messages.add(Message(text: displayText, isUser: false));
        } else {
          _messages[_messages.length - 1] = Message(text: displayText, isUser: false);
        }
      });
      _scrollToBottom();
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

  void _scrollToBottomNow() {
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: true, // Ensure resizing to avoid keyboard
      appBar: AppBar(
        leading: IconButton(
          icon: CustomMenuIcon(),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          'A.L.O.H.A',
          style: TextStyle(
            fontFamily: 'Audiowide',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
      ),
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          Column(
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
                      child: Row(
                        crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!message.isUser) // Show avatar for bot messages only
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0, top: 10), // Adjusted padding
                              child: Container(
                                padding: const EdgeInsets.all(4.0), // Inner padding for avatar
                                decoration: BoxDecoration(
                                  color: Colors.grey[900], // Background color in case image is not loaded
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 16, // Avatar size
                                  backgroundImage: AssetImage('assets/aloha.png'), // Fallback color in case image is not found
                                ),
                              ),
                            ),
                          // Constrain the message container width
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: message.isUser
                                    ? Colors.white.withOpacity(0.90)
                                    : Colors.black,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                message.text,
                                style: TextStyle(
                                  fontFamily: 'Cousine',
                                  color: message.isUser ? Colors.black : Colors.white,
                                  fontSize: 14,
                                  fontWeight: message.isUser
                                      ? FontWeight.w400
                                      : FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 8, left: 10,top:8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Chat with Aloha',
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
                          contentPadding: EdgeInsets.all(14.0),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: _hasText,
                      builder: (context, hasText, child) {
                        return IconButton(
                          icon: Icon(
                            hasText ? Icons.arrow_upward : Icons.mic, // Change icon based on _hasText
                            color: Colors.white,
                            size: 30.0,
                          ),
                          onPressed: () {
                            if (hasText) {
                              _sendMessage();
                            } else {
                              // Handle microphone action
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showScrollToBottomButton)
            Positioned(
              bottom: 80, // Adjust as needed to position the button above the text input
              right: 16,
              child: Align(
                alignment: Alignment.bottomLeft, // Ensure the button is centered horizontally
                child: FloatingActionButton(
                  onPressed: _scrollToBottomNow,
                  child: Icon(
                    Icons.arrow_downward,
                    color: Colors.white, // Change icon color to white
                  ),
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),

        ],
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget _buildDrawer() {
    return ClipRRect(
      borderRadius: BorderRadius.horizontal(right: Radius.circular(30)),
      child: Drawer(
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChatScreen()), // Navigate to AnotherScreen
                        );
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
                          _selectedDrawerItem = 1; // Set the index for the selected item
                        });
                        Navigator.pop(context);

                        // Custom page transition for AnotherScreen
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => AnotherScreen(),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0); // Start from the right
                              const end = Offset.zero; // End at the center
                              const curve = Curves.easeInOut;

                              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                              var offsetAnimation = animation.drive(tween);

                              return SlideTransition(
                                position: offsetAnimation,
                                child: child,
                              );
                            },
                          ),
                        );
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
    );
  }
}

class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});
}

class CustomMenuIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 4,
            right: 0,
            height: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 25, // Full width
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
          Positioned(
            top: 17,
            left: 4,
            right: 0,
            height: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 20, // Reduced width
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
