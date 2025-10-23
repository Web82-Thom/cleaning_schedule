import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TableDateTaskNoWeeklyWidget extends StatefulWidget {
  final String taskName;

  const TableDateTaskNoWeeklyWidget({
    super.key,
    required this.taskName,
  });

  @override
  State<TableDateTaskNoWeeklyWidget> createState() =>
      _TableDateTaskNoWeeklyWidgetState();
}

class _TableDateTaskNoWeeklyWidgetState
    extends State<TableDateTaskNoWeeklyWidget> {
  final CollectionReference eventsRef =
      FirebaseFirestore.instance.collection('events');

  bool _loading = true;
  List<Map<String, dynamic>> _pastEvents = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      // 🔹 On récupère tous les events sans index ni where
      final snapshot = await eventsRef.get();

      final now = DateTime.now();

      // 🔹 On filtre localement
      final filtered = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final ts = data['day'] as Timestamp?;
        final date = ts?.toDate();

        return {
          'task': data['task'] ?? '',
          'place': data['place'] ?? '',
          'isWeeklyTask': data['isWeeklyTask'] ?? true,
          'day': date,
        };
      }).where((event) {
        final isNoWeekly = event['isWeeklyTask'] == false;
        final sameTask = event['task'] == widget.taskName;
        final date = event['day'];
        final isPast = date != null &&
            DateTime(date.year, date.month, date.day)
                .isBefore(DateTime(now.year, now.month, now.day));

        return isNoWeekly && sameTask && isPast;
      }).toList();

      // 🔹 Tri du plus ancien au plus récent
      filtered.sort((a, b) =>
          (a['day'] as DateTime).compareTo(b['day'] as DateTime));

      setState(() {
        _pastEvents = filtered;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement events: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.taskName),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pastEvents.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun événement passé pour cette tâche.',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _pastEvents.length,
                  itemBuilder: (context, index) {
                    final event = _pastEvents[index];
                    final date = event['day'] as DateTime?;
                    final formattedDate = date != null
                        ? DateFormat('dd MMM yyyy', 'fr_FR').format(date)
                        : '—';

                    // 🔹 Calcul du nombre de jours écoulés
                    final diffDays = date != null
                        ? DateTime.now().difference(date).inDays
                        : 0;

                    final late = diffDays > 10; // ⚠️ Si + de 10 jours

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: late
                            ? Colors.red.withValues(alpha: 0.1)
                            : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 14,
                                color: late ? Colors.red : Colors.black,
                                fontWeight:
                                    late ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              event['place'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: late ? Colors.red : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
