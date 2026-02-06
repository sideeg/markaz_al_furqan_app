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

class GroupStudentsScreen extends ConsumerStatefulWidget {
  final int groupId; // Add this

  const GroupStudentsScreen(
      {super.key, required this.groupId}); // Add parameter

  @override
  ConsumerState<GroupStudentsScreen> createState() =>
      _GroupStudentsScreenState();
}

class _GroupStudentsScreenState extends ConsumerState<GroupStudentsScreen> {
  @override
  Widget build(BuildContext context) {
    // Now you can access widget.groupId
    return Scaffold(
      appBar: AppBar(title: Text('Group ${widget.groupId}')),
      body: const Center(child: Text('Group Students')),
    );
  }
}
