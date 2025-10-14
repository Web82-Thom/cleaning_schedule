import 'package:cleaning_schedule/controllers/workers_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DetailsWorkerPage extends StatefulWidget {
  final String workerId;

  const DetailsWorkerPage({super.key, required this.workerId});

  @override
  State<DetailsWorkerPage> createState() => _DetailsWorkerPageState();
}

class _DetailsWorkerPageState extends State<DetailsWorkerPage> {
  final WorkersController workersController = WorkersController();

  @override
  Widget build(BuildContext context) {
    final workerRef =
        FirebaseFirestore.instance.collection('workers').doc(widget.workerId);

    return StreamBuilder<DocumentSnapshot>(
      stream: workerRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
              body: Center(child: Text('Aucune donnée trouvée.')));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final firstName = data['firstName'] ?? '';
        final name = data['name'] ?? '';
        final isPartTime = data['isPartTime'] ?? false;
        final isTherapeutic = data['isTherapeutic'] ?? false;
        final isHalfTime = data['isHalfTime'] ?? false;
        final isAbcent = data['isAbcent'] ?? false;

        String status = 'Temps plein';
        if (isPartTime) status = 'Temps partiel';
        if (isTherapeutic) status = 'Mi-temps thérapeutique';
        if (isHalfTime) status = 'Mi-temps';
        if (isAbcent) status = 'Absent';

        Color statusColor = Colors.green;
        if (isPartTime) statusColor = Colors.orange;
        if (isTherapeutic) statusColor = Colors.blue;
        if (isHalfTime) statusColor = Colors.deepPurpleAccent;
        if (isAbcent) statusColor = Colors.red;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Détails du travailleur"),
            actions: [
              //  Bouton Modifier dans la topbar
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.indigo),
                tooltip: "Modifier le travailleur",
                onPressed: () {
                  workersController.updateWorker(
                    context,
                    widget.workerId,
                    data,
                  );
                },
              ),

              //  Bouton Supprimer
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: "Supprimer le travailleur",
                onPressed: () {
                  workersController.deleteWorker(context, workerRef.id);
                },
              ),
            ],
          ),
          body: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.indigo.shade100,
                        child: const Icon(Icons.person,
                            size: 60, color: Colors.indigo),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$firstName $name',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.badge, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          isAbcent ? 'Actuellement absent' : 'Présent',
                          style: TextStyle(
                            color: isAbcent ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (data['workSchedule'] != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.schedule, color: Colors.indigo),
                        SizedBox(width: 8),
                        Text(
                          'Horaires personnalisés',
                          style: TextStyle(
                            color: Colors.indigo,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // 🔹 Section horaires personnalisés
                    if (!data['isFullTime']) ...[
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Horaires personnalisés',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.schedule),
                        label: const Text("Configurer les horaires"),
                        onPressed: () {
                          workersController.showWorkScheduleDialog(
                              context, workerRef.id, data);
                        },
                      ),
                      const SizedBox(height: 16),

                      if (data['workSchedule'] != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: (data['workSchedule']
                                  as Map<String, dynamic>)
                              .entries
                              .map((entry) {
                            final day = entry.key;
                            final time = entry.value;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                      'Tous les ${day[0].toUpperCase()}${day.substring(1)}'),
                                  Text(
                                    time != null
                                        ? 'Fin à $time'
                                        : '—',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  IconButton(onPressed: () {
                                    workersController.removeWorkSchedule(context, widget.workerId);
                                  }, icon: Icon(Icons.delete, color: Colors.red,), ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                    
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
