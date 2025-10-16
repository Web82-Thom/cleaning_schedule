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
    final workerRef = FirebaseFirestore.instance.collection('workers').doc(widget.workerId);

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
                      children: [
                        const Icon(
                          Icons.schedule,
                          color: Colors.pinkAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isAbcent ? 'Actuellement absent' : 'Heure aménager',
                          style: TextStyle(
                            color: isAbcent ? Colors.red : Colors.pinkAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                        
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
                        Builder(
                          builder: (context) {
                            final workSchedule = Map<String, dynamic>.from(data['workSchedule']);
                            final orderedDays = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi'];

                            final sortedEntries = orderedDays
                              .where((day) => workSchedule.containsKey(day))
                              .map((day) => MapEntry(day, workSchedule[day]))
                              .where((entry) {
                                final info = Map<String, dynamic>.from(entry.value);
                                final worksMorning = info['worksMorning'] ?? true;
                                final worksAfternoon = info['worksAfternoon'] ?? true;
                                final endTime = info['endTime'];
                                return !worksMorning || !worksAfternoon || endTime != null;
                              }).toList();

                            // 🔹 Si aucun aménagement détecté
                            if (sortedEntries.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.check_circle, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text(
                                      "Rien à signaler",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // 🔹 Sinon, afficher la liste des jours
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: sortedEntries.map((entry) {
                                final day = entry.key;
                                final info = Map<String, dynamic>.from(entry.value);
                                final endTime = info['endTime'];
                                final worksMorning = info['worksMorning'] ?? true;
                                final worksAfternoon = info['worksAfternoon'] ?? true;

                                return Card(
                                  elevation: 3,
                                  margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onLongPress: () => workersController.removeWorkSchedule(
                                      context,
                                      widget.workerId,
                                      day,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            day[0].toUpperCase() + day.substring(1),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.indigo,
                                            ),
                                          ),
                                          const SizedBox(height: 6),

                                          // 🔹 Affiche “Fin à …” seulement si endTime existe
                                          if (endTime != null)
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Flexible(
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.access_time,
                                                          size: 18, color: Colors.grey),
                                                      const SizedBox(width: 6),
                                                      Flexible(
                                                        child: Text(
                                                          'Fin à $endTime',
                                                          overflow: TextOverflow.ellipsis,
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.w500,
                                                            color: Colors.black87,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),

                                          if (!worksMorning || !worksAfternoon)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.start,
                                                children: [
                                                  if (!worksMorning)
                                                    Row(
                                                      children: const [
                                                        Icon(Icons.wb_sunny,
                                                            color: Colors.orange, size: 18),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          'Matin libre',
                                                          style: TextStyle(fontSize: 13),
                                                        ),
                                                      ],
                                                    ),
                                                  if (!worksAfternoon)
                                                    Row(
                                                      children: const [
                                                        Icon(Icons.nights_stay,
                                                            color: Colors.indigo, size: 18),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          'Après-midi libre',
                                                          style: TextStyle(fontSize: 13),
                                                        ),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
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
