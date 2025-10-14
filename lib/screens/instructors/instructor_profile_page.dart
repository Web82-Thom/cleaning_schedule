import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cleaning_schedule/controllers/edit_instructor_controller.dart';

class InstructorProfilePage extends StatefulWidget {
  const InstructorProfilePage({super.key});

  @override
  State<InstructorProfilePage> createState() => _InstructorProfilePageState();
}

class _InstructorProfilePageState extends State<InstructorProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final editInstructorController = EditInstructorController();

  User? _user;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      setState(() {
        _user = user;
        _userData = doc.data();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userName = '${_userData!['prenom'] ?? ''} ${_userData!['nom'] ?? ''}'
        .trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier le profil',
            onPressed: () {
              editInstructorController.editProfilInstructor(context, _userData!);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => editInstructorController.openAddRdvDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau RDV'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .collection('rdvs')
            .orderBy('debut', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rdvs = snapshot.data?.docs ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 🔹 Profil
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue.shade200,
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      userName.isEmpty ? 'Instructeur' : userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _user!.email ?? '',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Divider(),
              const Text(
                "Mes rendez-vous :",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              if (rdvs.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Aucun RDV pour le moment',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...rdvs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final debut = (data['debut'] as Timestamp).toDate();
                  final fin = (data['fin'] as Timestamp).toDate();
                  final motif = data['motif'] ?? '';
                  final lieu = data['lieu'] ?? '';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔹 Ligne titre + icônes
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  motif,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () =>
                                    editInstructorController.editRdvDialog(
                                      context,
                                      doc.id,
                                      doc.data() as Map<String, dynamic>,
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => editInstructorController
                                    .deleteRdv(context, doc.id),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // 🔹 Date  Heure de début - fin
                          Text(
                            '${debut.day}/${debut.month}/${debut.year} de ${debut.hour.toString().padLeft(2, '0')}h${debut.minute.toString().padLeft(2, '0') } à ${fin.hour.toString().padLeft(2, '0')}h${fin.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.black87, fontSize: 12,),
                          ),
                          // 🔹 Lieu
                          if (lieu.isNotEmpty)
                            Text(
                              'Lieu : $lieu',
                              style: const TextStyle(color: Colors.black87, fontSize: 12,),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
