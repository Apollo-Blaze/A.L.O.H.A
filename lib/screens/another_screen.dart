import 'package:alohapp/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/message.dart';
import 'dart:async'; // Required for delay
import 'package:lottie/lottie.dart';

class AnotherScreen extends StatefulWidget {
  @override
  _AnotherScreenState createState() => _AnotherScreenState();
}

class _AnotherScreenState extends State<AnotherScreen> {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ValueNotifier<bool> _hasText = ValueNotifier<bool>(false);
  List<Map<String, dynamic>> _conversationHistory = [{
    "role": "user",
    "parts": [
      {
        "text": "Your name is aloha and if i ask you what your name is you are supposed to respond with the Hi, I am aloha, customize your response but include your name aloha, also include emojis"
      }
    ]
  },
    {
      "role": "model",
      "parts": [
        {
          "text": "My name is Aloha. \n"
        }
      ]
    }];
  int _selectedDrawerItem = 0;
  bool _showScrollToBottomButton = false;
  bool _isLoading = false;
  bool _userIsScrolling = false;
  bool _allowAutoScroll = true;

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

    // Check if the user is scrolling
    if (_scrollController.position.userScrollDirection != ScrollDirection.idle) {
      _userIsScrolling = true;
      _allowAutoScroll = false; // Disable auto-scroll when user scrolls manually
    } else {
      _userIsScrolling = false;
      _allowAutoScroll = true; // Enable auto-scroll again when user stops scrolling
    }
  }


  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      final messageText = _controller.text;
      _controller.clear();
      _hasText.value = false;

      final userMessage = {
        "role": "user",
        "parts": [
          {"text": messageText}
        ]
      };

      setState(() {
        _messages.add(Message(text: messageText, isUser: true));
        _conversationHistory.add(userMessage);
        _isLoading = true; // Set loading state to true
      });

      _scrollToBottom();

      final response = await _sendToApi();

      setState(() {
        _isLoading = false; // Set loading state to false
      });

      _simulateTyping(response);
    }
  }

  Future<String> _sendToApi() async {
    final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=AIzaSyAvIksHyZSzk3hG7El_sS4yO0W3vJBP2CI'; // Replace with your actual API key
    final payload = {
      "contents": _conversationHistory,
      "generationConfig": {
        "temperature": 1,
        "topK": 64,
        "topP": 0.95,
        "maxOutputTokens": 5000,
        "responseMimeType": "text/plain"
      }
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      return text ?? 'Sorry, I didn\'t understand that.';
    } else {
      return 'Failed to get response from API.';
    }
  }

  void _simulateTyping(String response) async {
    const typingDelay = Duration(milliseconds: 15); // Adjust delay for smoother typing
    const scrollInterval = 5; // Scroll every few characters
    String displayText = '';

    for (int i = 0; i < response.length; i++) {
      await Future.delayed(typingDelay);
      setState(() {
        displayText += response[i];

        // Add or update the displayed message
        if (i == 0) {
          _messages.add(Message(text: displayText, isUser: false));
        } else {
          _messages[_messages.length - 1] = Message(text: displayText, isUser: false);
        }
      });

      // Scroll only every few characters for smoothness
      if ((i % scrollInterval == 0 || i == response.length - 1) && _allowAutoScroll) {
        Future.microtask(() => _scrollToBottom());
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients && _allowAutoScroll) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 200), // Smooth scroll duration
        curve: Curves.easeOut, // Smooth scrolling curve
      );
    }
  }

  void _scrollToBottomNow() {
    // Immediate scroll to bottom when button is clicked
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 200), // Smooth scroll duration
        curve: Curves.easeOut, // Smooth scrolling curve
      );
    } else {
      print("ScrollController has no clients.");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: CustomMenuIcon(),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          ' Scholar A.L.O.H.A',
          style: TextStyle(
            fontFamily: 'Audiowide',
            fontSize: 18,
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
                          if (!message.isUser)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0, top: 10),
                              child: Container(
                                padding: const EdgeInsets.all(4.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundImage: AssetImage('assets/aloha.png'),
                                ),
                              ),
                            ),
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
                padding: EdgeInsets.only(bottom: 8, left: 20, top: 8,right:10),
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
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0,right:2), // Add right padding here
                          child: IconButton(
                            icon: Icon(
                              hasText ? Icons.arrow_upward : Icons.mic,
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
                          ),
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
              bottom: 80,
              right: 16,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: FloatingActionButton(
                  onPressed: _scrollToBottomNow,
                  child: Icon(
                    Icons.arrow_downward,
                    color: Colors.white,
                  ),
                  backgroundColor: Colors.transparent,
                ),
              ),
            ),
          if (_isLoading)
            Stack(
              children: [
                // Other widgets like your chat or content go here
                Positioned(
                  left: 0, // Adjust this value for spacing from the left
                  bottom: 65, // Adjust this value for spacing above the input bar
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Shrink wrap the row
                    children: [
                      SizedBox(
                        width: 75, // Adjust width as needed
                        height: 75, // Adjust height as needed
                        child: Lottie.asset(
                          'assets/space.json',
                          fit: BoxFit.fill,
                        ),
                      ),
                      SizedBox(width: 4), // Space between loader and text
                      Text(
                        'Lemme think...',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Cousine',
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )

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
                      tileColor: _selectedDrawerItem == 1 ? Colors.grey[800] : null,
                      onTap: () {
                        setState(() {
                          _selectedDrawerItem = 1; // Set the index for the selected item (1 for Personal Assistant)
                        });
                        FocusScope.of(context).unfocus();

                        // Delay the closing of the drawer
                        Future.delayed(Duration(milliseconds: 0), () {
                          Navigator.pop(context);

                          // Custom page transition for ChatScreen
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                const begin = Offset(0.90, 0.0); // Start from the right
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
                        });
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
                      tileColor: _selectedDrawerItem == 0 ? Colors.grey[800] : null,
                      onTap: () {
                        setState(() {
                          _selectedDrawerItem = 1;
                        });
                        FocusScope.of(context).unfocus();
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AnotherScreen()), // Navigate to AnotherScreen
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
                        FocusScope.of(context).unfocus();
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
