import 'package:flutter/material.dart';
import '../../utils/contants.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Chat',
        style: TextStyle(color: AppColors.white, fontSize: 20),
      ),
    );
  }
}
