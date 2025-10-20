import 'package:cleaning_schedule/widgets/table_date_task_no_weekly_widget.dart';
import 'package:cleaning_schedule/widgets/tasks_widget.dart';
import 'package:flutter/material.dart';

class ViewTasksNoWeeklyPage extends StatelessWidget {
  const ViewTasksNoWeeklyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tasksWidget = TasksWidget();

    return Scaffold(
      appBar: AppBar(title: const Text('Suivi des tâches non hebdomadaire', style:TextStyle(fontSize: 14, fontWeight: FontWeight.bold),)),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: List.generate(tasksWidget.tasksNoWeekly.length, (index) {
            final task = tasksWidget.tasksNoWeekly[index];

            // Liste de couleurs à cycle automatique
            final colors = [
              Colors.red.shade100,
              Colors.blue.shade100,
              Colors.green.shade100,
              Colors.orange.shade100,
              Colors.purple.shade100,
              Colors.teal.shade100,
              Colors.yellow.shade100,
            ];
            final bgColor = colors[index % colors.length];

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TableDateTaskNoWeeklyWidget(taskName: task),
                  ),
                );
              },
              child: Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: bgColor, // couleur de fond
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      task,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),

      ),
    );
  }
}
