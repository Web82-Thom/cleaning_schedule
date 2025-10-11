import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeeklyScheduleTableWidget extends StatelessWidget {
  final DateTime startOfWeek; // Lundi
  final DateTime endOfWeek;   // Vendredi

  const WeeklyScheduleTableWidget({
    super.key,
    required this.startOfWeek,
    required this.endOfWeek,
  });

  /// Génère la liste des jours de la semaine (Lundi → Vendredi)
  List<DateTime> get _weekDays =>
      List.generate(5, (i) => startOfWeek.add(Duration(days: i)));

  /// Génère les tranches horaires de 8h00 à 17h15 (incrément 30 min)
  List<TimeOfDay> get _timeSlots {
    List<TimeOfDay> slots = [];
    TimeOfDay start = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 17, minute: 15);

    var current = start;
    while (current.hour < end.hour ||
        (current.hour == end.hour && current.minute <= end.minute)) {
      slots.add(current);

      final nextMinute = current.minute + 30;
      final nextHour = current.hour + (nextMinute ~/ 60);
      current = TimeOfDay(hour: nextHour, minute: nextMinute % 60);
    }
    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final weekNumber = weekOfYear(startOfWeek);
    final title =
        'Semaine $weekNumber — du ${DateFormat('dd/MM').format(startOfWeek)} au ${DateFormat('dd/MM').format(endOfWeek)}';
    final days = _weekDays;
    final slots = _timeSlots;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          scaleEnabled: true,
          minScale: 0.4,
          maxScale: 2.5,
          /// 🔹 limite les déplacements : on laisse un peu de marge
          boundaryMargin: const EdgeInsets.all(0),
          constrained: false,
          child: ClipRect( // 🔹 empêche de sortir visuellement du cadre
            child: DataTable(
              border: TableBorder.all(color: Colors.grey.shade400),
              columnSpacing: 32,
              columns: [
                const DataColumn(label: Text('Heure')),
                ...days.map(
                  (d) => DataColumn(
                    label: Text(
                      DateFormat('EEEE', 'fr_FR').format(d).toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
              rows: slots.map((time) {
                return DataRow(
                  cells: [
                    DataCell(Text(
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    )),
                    ...days.map(
                      (_) => const DataCell(
                        SizedBox(
                          width: 100,
                          height: 40,
                          child: Center(child: Text('')),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  /// Calcule le numéro de semaine (ISO 8601)
  int weekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysOffset = firstDayOfYear.weekday - DateTime.monday;
    final firstMonday = firstDayOfYear.subtract(Duration(days: daysOffset));
    return ((date.difference(firstMonday).inDays) / 7).ceil() + 1;
  }
}
