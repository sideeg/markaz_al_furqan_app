import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../models/course.dart';
import '../../services/course_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/course_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/filter_chips.dart';

class AddLogScreen extends ConsumerStatefulWidget {
  final int studentId;
  final String logType;

  const AddLogScreen({
    super.key,
    required this.studentId,
    required this.logType,
  });

  @override
  ConsumerState<AddLogScreen> createState() => _AddLogScreenState();
}

class _AddLogScreenState extends ConsumerState<AddLogScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add ${widget.logType} Log for ${widget.studentId}'),
      ),
      body: const Center(child: Text('Add Log Form')),
    );
  }
}
