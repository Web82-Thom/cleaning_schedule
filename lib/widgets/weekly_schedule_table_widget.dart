import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeeklyScheduleTableWidget extends StatefulWidget {
  final DateTime initialWeek;

  const WeeklyScheduleTableWidget({super.key, required this.initialWeek});

  @override
  State<WeeklyScheduleTableWidget> createState() =>
      _WeeklyScheduleTableWidgetState();
}

class _WeeklyScheduleTableWidgetState extends State<WeeklyScheduleTableWidget> {
  late DateTime _startOfWeek;
  late DateTime _endOfWeek;

  Map<String, String> _workersMap = {}; // workerId → workerName

  @override
  void initState() {
    super.initState();
    _startOfWeek = _getStartOfWeek(widget.initialWeek);
    _endOfWeek = _startOfWeek.add(const Duration(days: 4));
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('workers')
        .where('active', isEqualTo: true)
        .get();

    if (!mounted) return;

    setState(() {
      _workersMap = {
        for (var doc in snapshot.docs)
          doc.id: '${doc['firstName']} ${doc['name']}',
      };
    });
  }

  DateTime _getStartOfWeek(DateTime date) =>
      date.subtract(Duration(days: date.weekday - 1));

  List<DateTime> get _weekDays =>
      List.generate(5, (i) => _startOfWeek.add(Duration(days: i)));

  int get _weekNumber => _getWeekNumber(_startOfWeek);

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysOffset = firstDayOfYear.weekday - DateTime.monday;
    final firstMonday = firstDayOfYear.subtract(Duration(days: daysOffset));
    return ((date.difference(firstMonday).inDays) / 7).ceil() + 1;
  }

  void _nextWeek() {
    setState(() {
      _startOfWeek = _startOfWeek.add(const Duration(days: 7));
      _endOfWeek = _startOfWeek.add(const Duration(days: 4));
    });
  }

  void _previousWeek() {
    setState(() {
      _startOfWeek = _startOfWeek.subtract(const Duration(days: 7));
      _endOfWeek = _startOfWeek.add(const Duration(days: 4));
    });
  }

  @override
  Widget build(BuildContext context) {
    final days = _weekDays;
    final title =
        'Semaine $_weekNumber — du ${DateFormat('dd/MM').format(_startOfWeek)} au ${DateFormat('dd/MM').format(_endOfWeek)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Semaine précédente',
            onPressed: _previousWeek,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Semaine suivante',
            onPressed: _nextWeek,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🔹 Nouvelle requête : filtre par date, plus par numéro de semaine
        stream: FirebaseFirestore.instance
            .collection('events')
            .where(
              'day',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                DateTime(
                  _startOfWeek.year,
                  _startOfWeek.month,
                  _startOfWeek.day,
                  0,
                  0,
                  0,
                ),
              ),
            )
            .where('day',isLessThanOrEqualTo: Timestamp.fromDate(
              DateTime(_endOfWeek.year, _endOfWeek.month, _endOfWeek.day, 23, 59, 59,),
              ),
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'day': (data['day'] as Timestamp).toDate(),
              'timeSlot': data['timeSlot'],
              'place': data['place'],
              'subPlace': data['subPlace'],
              'task': data['task'],
              'workerIds': List<String>.from(data['workerIds'] ?? []),
            };
          }).toList();

          // 🔹 Grouper les events par jour + créneau
          Map<String, List<Map<String, dynamic>>> grouped = {};
          for (var e in events) {
            final key =
                '${DateFormat('yyyy-MM-dd').format(e['day'])}_${e['timeSlot']}';
            grouped.putIfAbsent(key, () => []).add(e);
          }

          return InteractiveViewer(
            panEnabled: true,
            scaleEnabled: true,
            minScale: 0.5,
            maxScale: 2.0,
            constrained: false,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 En-tête des jours
                  Row(
                    children: [
                      const SizedBox(width: 120),
                      ...days.map(
                        (d) => Container(
                          width: 180,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            DateFormat('EEEE', 'fr_FR').format(d).toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 🔹 Matin / Après-midi
                  for (var period in ['morning', 'afternoon'])
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          alignment: Alignment.center,
                          color: Colors.grey.shade300,
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            period == 'morning' ? 'MATIN' : 'APRÈS-MIDI',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        ...days.map((day) {
                          final key =
                              '${DateFormat('yyyy-MM-dd').format(day)}_$period';
                          final cellEvents = grouped[key] ?? [];

                          return Container(
                            width: 180,
                            height: 180,
                            margin: const EdgeInsets.all(2),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: period == 'morning'
                                  ? Colors.blue.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: cellEvents.isEmpty
                                ? const Center(
                                    child: Text(
                                      '—',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  )
                                : ListView(
                                    children: cellEvents.map((e) {
                                      final subPlacesText = e['subPlace']
                                          ?.toString()
                                          .replaceAll('[', '')
                                          .replaceAll(']', '');
                                      final workerNames = e['workerIds']
                                          .map<String>(
                                            (id) =>
                                                _workersMap[id] ?? 'Inconnu',
                                          )
                                          .join(', ');

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '• ${e['place']}${subPlacesText != null && subPlacesText.isNotEmpty ? ' ($subPlacesText)' : ''}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
                                            ),
                                            if (workerNames.isNotEmpty)
                                              Text(
                                                '  Travailleurs: $workerNames',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            if ((e['task'] ?? '').isNotEmpty)
                                              Text(
                                                '  Tâche: ${e['task']}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          );
                        }),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
