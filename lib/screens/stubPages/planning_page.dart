import 'package:cleaning_schedule/widgets/weekly_schedule_table_widget.dart';
import 'package:flutter/material.dart';

class PlanningPage extends StatelessWidget {
  const PlanningPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // lundi
    // final endOfWeek = startOfWeek.add(const Duration(days: 4)); // vendredi

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: WeeklyScheduleTableWidget(
          initialWeek: startOfWeek,
        ),
      ),
    );
  }
}
