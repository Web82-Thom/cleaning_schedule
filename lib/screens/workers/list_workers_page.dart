import 'package:cleaning_schedule/controllers/workers_controller.dart';
import 'package:cleaning_schedule/screens/workers/details_worker_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ListWorkersPage extends StatefulWidget {
  const ListWorkersPage({super.key});

  @override
  State<ListWorkersPage> createState() => _ListWorkersPageState();
}

class _ListWorkersPageState extends State<ListWorkersPage> {
  final CollectionReference workersRef = FirebaseFirestore.instance.collection(
    'workers',
  );
   
  WorkersController workersController = WorkersController();

  @override
  void dispose() {
    workersController.firstNameController.dispose();
    workersController.nameController.dispose();
    super.dispose();
  }

  
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text("Liste des travailleurs")),
        body: StreamBuilder<QuerySnapshot>(
          stream: workersRef.orderBy('firstName', descending: false).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
      
            final docs = snapshot.data?.docs ?? [];
      
            if (docs.isEmpty) {
              return const Center(child: Text('Aucun travailleur trouvé.'));
            }
      
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final id = docs[index].id;
      
                final status = workersController.getStatusLabel(data);
                final isAbsentData = data['isAbcent'] == true;
      
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DetailsWorkerPage(workerId: id)),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                  
                    child: ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${data['firstName'] ?? ''} ${data['name'] ?? ''}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          // Icône horloge si le worker a un workSchedule
                          if (data['workSchedule'] != null)
                          const Icon(
                            Icons.schedule,
                            color: Colors.pinkAccent,
                            size: 20,
                          ),
                        ],
                      ),
                      subtitle: RichText(
                        text: TextSpan(
                          children: [
                            if (!isAbsentData)
                              TextSpan(
                                text: status,
                                style: TextStyle(
                                  color: workersController.getStatusColor(data),
                                  fontSize: 12,
                                ),
                              ),
                            // Ajoute " / Absent" uniquement si le worker n'est pas en plein temps ou si absent
                            if (isAbsentData) 
                            const TextSpan(
                              text: 'ABSENT',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => workersController.showAddWorkerDialog(context),
          backgroundColor: Colors.indigo,
          icon: const Icon(Icons.add),
          label: const Text("Ajouter", style: TextStyle(fontSize: 14)),
        ),
      ),
    );
  }
}
