import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeeklyScheduleTableWidget extends StatelessWidget {
  final DateTime startOfWeek;
  final DateTime endOfWeek;

  const WeeklyScheduleTableWidget({
    super.key,
    required this.startOfWeek,
    required this.endOfWeek,
  });

  List<DateTime> get _weekDays =>
      List.generate(5, (i) => startOfWeek.add(Duration(days: i)));

  @override
  Widget build(BuildContext context) {
    final days = _weekDays;
    final weekNumber = weekOfYear(startOfWeek);
    final title =
        'Semaine $weekNumber — du ${DateFormat('dd/MM').format(startOfWeek)} au ${DateFormat('dd/MM').format(endOfWeek)}';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: InteractiveViewer(
        panEnabled: true,
        scaleEnabled: true,
        minScale: 0.01,
        maxScale: 2.0,
        constrained: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- En-tête jours
              Row(
                children: [
                  SizedBox(
                      width: 100,
                      child: Container()), // colonne vide pour Matin/Après-midi
                  ...days.map((d) => Container(
                        width: 120,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          DateFormat('EEEE', 'fr_FR')
                              .format(d)
                              .toUpperCase(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                      )),
                ],
              ),
              // --- Lignes Matin / Après-midi
              Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100,
                        alignment: Alignment.center,
                        color: Colors.grey.shade300,
                        padding: const EdgeInsets.all(8),
                        child: const Text(
                          'MATIN',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      ...days.map((_) => Container(
                            width: 120,
                            height: 200,
                            margin: const EdgeInsets.all(2),
                            color: Colors.blue.shade100,
                          )),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100,
                        alignment: Alignment.center,
                        color: Colors.grey.shade300,
                        padding: const EdgeInsets.all(8),
                        child: const Text(
                          'APRES-MIDI',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      ...days.map((_) => Container(
                            width: 120,
                            height: 200,
                            margin: const EdgeInsets.all(2),
                            color: Colors.orange.shade100,
                          )),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  int weekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysOffset = firstDayOfYear.weekday - DateTime.monday;
    final firstMonday = firstDayOfYear.subtract(Duration(days: daysOffset));
    return ((date.difference(firstMonday).inDays) / 7).ceil() + 1;
  }
}
