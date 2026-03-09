import 'package:flutter/material.dart';
import '../../utils/contants.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Activity',
        style: TextStyle(color: AppColors.white, fontSize: 20),
      ),
    );
  }
}
