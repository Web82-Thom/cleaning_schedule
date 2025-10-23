import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cleaning_schedule/controllers/edit_instructor_controller.dart';
import 'package:cleaning_schedule/controllers/rdv_controller.dart';
import 'package:cleaning_schedule/models/rdv_model.dart';

class InstructorProfilePage extends StatefulWidget {
  const InstructorProfilePage({super.key});

  @override
  State<InstructorProfilePage> createState() => _InstructorProfilePageState();
}

class _InstructorProfilePageState extends State<InstructorProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final editInstructorController = EditInstructorController();
  final RdvController rdvController = RdvController();

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

  Stream<List<RdvModel>> _userRdvsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('rdvs')
        .where('monitorIds', arrayContains: userId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RdvModel.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Color _getRdvColor(RdvModel rdv) {
    final now = DateTime.now();
    final startWindow = rdv.date.subtract(const Duration(hours: 24));
    final endWindow = rdv.date.add(const Duration(hours: 1));

    if (now.isAfter(startWindow) && now.isBefore(rdv.date)) {
      // RDV dans les prochaines 24h
      return Colors.orange.shade200;
    } else if (now.isAfter(endWindow)) {
      // RDV passé depuis plus d'1h
      return Colors.grey.shade300;
    } else {
      // RDV normal
      return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userName =
        '${_userData!['prenom'] ?? ''} ${_userData!['nom'] ?? ''}'.trim();

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
      body: ListView(
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
                      fontSize: 18, fontWeight: FontWeight.bold),
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

          // 🔹 Liste des RDVs via StreamBuilder
          StreamBuilder<List<RdvModel>>(
            stream: _userRdvsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final rdvs = snapshot.data ?? [];

              if (rdvs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Aucun RDV pour le moment',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return Column(
                children: rdvs.map((rdv) {
                  final day = rdv.date;
                  final bgColor = _getRdvColor(rdv);

                  return Card(
                    color: bgColor,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔹 Titre + actions
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  rdv.motif,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  rdvController
                                      .openRdvFormPage(
                                          context: context, rdvData: rdv)
                                      .then((_) => setState(() {}));
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final deleted =
                                      await rdvController.deleteRdv(context, rdv);
                                  if (deleted) setState(() {});
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // 🔹 Date et heure
                          Text(
                            '${day.day}/${day.month}/${day.year} à ${rdv.heure}',
                            style: const TextStyle(
                                color: Colors.black87, fontSize: 12),
                          ),

                          // 🔹 Lieu
                          if (rdv.lieu != null && rdv.lieu!.isNotEmpty)
                            Text(
                              'Lieu : ${rdv.lieu}',
                              style: const TextStyle(
                                  color: Colors.black87, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
