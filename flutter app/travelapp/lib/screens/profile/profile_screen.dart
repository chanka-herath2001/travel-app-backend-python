import 'package:flutter/material.dart';
import '../../utils/contants.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Profile',
        style: TextStyle(color: AppColors.white, fontSize: 20),
      ),
    );
  }
}
