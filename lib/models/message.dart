class Message {
  final String text;
  final bool isUser;
  final bool isTyping;
  final bool typingAnimation;

  Message({
    required this.text,
    required this.isUser,
    this.isTyping = false,
    this.typingAnimation = false,
  });
}
