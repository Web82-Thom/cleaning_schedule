import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RdvPage extends StatefulWidget {
  const RdvPage({super.key});

  @override
  State<RdvPage> createState() => _RdvPageState();
}

class _RdvPageState extends State<RdvPage> {
  Map<String, String> workersMap = {}; // workerId → nom complet

  @override
  void initState() {
    super.initState();
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('workers')
        .where('active', isEqualTo: true)
        .get();
    if (!mounted) return;

    setState(() {
      workersMap = {
        for (var doc in snapshot.docs)
          doc.id: '${doc['firstName']} ${doc['name']}',
      };
    });
  }

  Future<void> _showUpdateRdvForm(
    BuildContext context,
    String rdvId,
    Map<String, dynamic> rdvData,
  ) async {
    final _formKey = GlobalKey<FormState>();
    DateTime? selectedDate = rdvData['date'];
    String motif = rdvData['motif'] ?? '';
    String lieu = rdvData['lieu'] ?? '';
    String? selectedWorkerId = rdvData['workerId'];

    // Charge les travailleurs
    final workersSnapshot = await FirebaseFirestore.instance
        .collection('workers')
        .where('active', isEqualTo: true)
        .get();
    final workersMap = {
      for (var doc in workersSnapshot.docs)
        doc.id: '${doc['firstName']} ${doc['name']}',
    };

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Modifier le rendez-vous',
          style: TextStyle(fontSize: 15),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date & heure
                  TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Date & heure',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (value) =>
                        selectedDate == null ? 'Sélectionnez une date' : null,
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                            selectedDate ?? DateTime.now(),
                          ),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            selectedDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                    controller: TextEditingController(
                      text: selectedDate != null
                          ? DateFormat('dd/MM/yyyy HH:mm').format(selectedDate!)
                          : '',
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Motif
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Motif'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Champ requis' : null,
                    initialValue: motif,
                    onChanged: (value) => motif = value,
                  ),

                  const SizedBox(height: 12),

                  // Lieu
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Lieu (optionnel)',
                    ),
                    initialValue: lieu,
                    onChanged: (value) => lieu = value,
                  ),

                  const SizedBox(height: 12),

                  // Travailleur
                  SizedBox(
                    width: double.infinity,
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Travailleur',
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: workersMap.entries
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e.key,
                              child: Text(
                                e.value,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      value: selectedWorkerId,
                      onChanged: (value) {
                        setState(() {
                          selectedWorkerId = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Sélectionnez un travailleur' : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate() &&
                  selectedDate != null &&
                  selectedWorkerId != null) {
                await FirebaseFirestore.instance
                    .collection('rdvs')
                    .doc(rdvId)
                    .update({
                      'date': selectedDate,
                      'motif': motif,
                      'lieu': lieu,
                      'workerId': selectedWorkerId,
                    });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRdv(BuildContext context, String rdvId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le rendez-vous'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce rendez-vous ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('rdvs').doc(rdvId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Rendez-vous supprimé ✅')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rendez-vous')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddRdvForm(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rdvs')
            .orderBy('date', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: Text('Aucun RDV'));

          final rdvs = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final workerId = data['workerId'] ?? '';
            return {
              'id': doc.id,
              'date': (data['date'] as Timestamp).toDate(),
              'motif': data['motif'],
              'lieu': data['lieu'] ?? '',
              'workerId': workerId,
              'workerName': workersMap[workerId] ?? 'Inconnu',
            };
          }).toList();

          if (rdvs.isEmpty)
            return const Center(child: Text('Aucun rendez-vous'));

          return ListView.builder(
            itemCount: rdvs.length,
            itemBuilder: (context, index) {
              final rdv = rdvs[index];
              return ListTile(
                leading: const Icon(Icons.event_note),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nom/Prénom
                    Expanded(
                      child: Text(
                        rdv['workerName'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Boutons edit / delete
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            // Appelle la fonction de modification
                            _showUpdateRdvForm(context, rdv['id'], rdv);
                          },
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blueAccent,
                          ),
                          tooltip: 'Modifier',
                        ),
                        IconButton(
                          onPressed: () {
                            _deleteRdv(context, rdv['id']);
                          },
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          tooltip: 'Supprimer',
                        ),
                      ],
                    ),
                  ],
                ),
                subtitle: Text(
                  '${DateFormat('dd/MM/yyyy HH:mm').format(rdv['date'])}'
                  '${rdv['motif'].isNotEmpty ? ' • ${rdv['motif']}' : ''}'
                  '${rdv['lieu'].isNotEmpty ? ' • ${rdv['lieu']}' : ''}',
                  style: const TextStyle(fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddRdvForm(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();
    DateTime? selectedDate;
    String motif = '';
    String lieu = '';
    String? selectedWorkerId;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Ajouter un rendez-vous',
          style: TextStyle(fontSize: 15),
        ),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date & heure
                  TextFormField(
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Date & heure',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    validator: (value) =>
                        selectedDate == null ? 'Sélectionnez une date' : null,
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            selectedDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                    controller: TextEditingController(
                      text: selectedDate != null
                          ? DateFormat('dd/MM/yyyy HH:mm').format(selectedDate!)
                          : '',
                    ),
                  ),

                  // Motif
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Motif'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Champ requis' : null,
                    onChanged: (value) => motif = value,
                  ),

                  // Lieu
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Lieu (optionnel)',
                    ),
                    onChanged: (value) => lieu = value,
                  ),

                  const SizedBox(height: 12),
                  // Travailleur (obligatoire)
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 1,
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Travailleur',
                        labelStyle: TextStyle(fontSize: 15),
                      ),
                      isExpanded: true,
                      items: workersMap.entries
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      initialValue: selectedWorkerId,
                      onChanged: (value) {
                        setState(() {
                          selectedWorkerId = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Sélectionnez un travailleur' : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate() && selectedDate != null) {
                await FirebaseFirestore.instance.collection('rdvs').add({
                  'date': selectedDate,
                  'motif': motif,
                  'lieu': lieu,
                  'workerId': selectedWorkerId,
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
