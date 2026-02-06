import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class ProgressChip extends StatelessWidget {
  final int progress;

  const ProgressChip({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: AppColors.surfaceVariant,
            color: AppColors.primary,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$progress%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
