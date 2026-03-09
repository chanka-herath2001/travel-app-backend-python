import 'package:flutter/material.dart';
import '../../utils/contants.dart';

class BucketListScreen extends StatelessWidget {
  const BucketListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Bucket List',
        style: TextStyle(color: AppColors.white, fontSize: 20),
      ),
    );
  }
}
