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

class SheikhDashboardScreen extends ConsumerStatefulWidget {
  const SheikhDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SheikhDashboardScreen> createState() =>
      _SheikhDashboardScreenState();
}

class _SheikhDashboardScreenState extends ConsumerState<SheikhDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    // TODO: Implement your widget tree here
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Log'),
      ),
      body: Center(
        child: Text('Add Log Screen Content'),
      ),
    );
  }
}
