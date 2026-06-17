import 'package:flutter/material.dart';

import '../screens/chatbot_screen.dart';

class ChatbotFloatingButton extends StatelessWidget {
  const ChatbotFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Colors.white,
      elevation: 4,
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ChatbotScreen()),
        );
      },
      child: const Icon(
        Icons.smart_toy_rounded,
        color: Color(0xFF347DFF),
        size: 30,
      ),
    );
  }
}
