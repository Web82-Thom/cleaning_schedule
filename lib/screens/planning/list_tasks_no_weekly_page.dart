import 'package:cleaning_schedule/screens/planning/event_from_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NoWeeklyTasksPage extends StatelessWidget {
  final CollectionReference eventsRef = FirebaseFirestore.instance.collection(
    'events',
  );

  NoWeeklyTasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tâches non hebdomadaires')),
      body: StreamBuilder<QuerySnapshot>(
        stream: eventsRef.where('isWeeklyTask', isEqualTo: false).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Aucune tâche non hebdomadaire pour le moment.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          // Trie par date sans les heures : de la plus ancienne à la plus récente
          docs.sort((a, b) {
            final dateA =
                (a.data() as Map<String, dynamic>)['day'] as Timestamp;
            final dateB =
                (b.data() as Map<String, dynamic>)['day'] as Timestamp;
            final dA = DateTime(
              dateA.toDate().year,
              dateA.toDate().month,
              dateA.toDate().day,
            );
            final dB = DateTime(
              dateB.toDate().year,
              dateB.toDate().month,
              dateB.toDate().day,
            );
            return dA.compareTo(dB);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              final Timestamp timestamp = data['day'] as Timestamp;
              final DateTime date = timestamp.toDate();
              final String formattedDate = DateFormat(
                'EEEE d MMMM yyyy',
                'fr_FR',
              ).format(date);

              final bool isOver10Days =
                DateTime.now().difference(DateTime(date.year, date.month, date.day)).inDays > 10;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: isOver10Days ? Colors.red.shade50 : null,
                child: ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['task'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isOver10Days ? Colors.red : null,
                          ),
                        ),
                      ),
                      if (isOver10Days)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.warning, color: Colors.red),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    '${data['place'] ?? ''}\n$formattedDate',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  leading: const Icon(Icons.cleaning_services_outlined),
                  onTap: isOver10Days
                  ? () {
                      // ✅ Ouvre le formulaire pour reprogrammer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventFormPage(eventId: docs[index].id),
                        ),
                      );
                    }
                  : null, // non cliquable si pas rouge
                ),
              );
            },
          );
        },
      ),
    );
  }
}
