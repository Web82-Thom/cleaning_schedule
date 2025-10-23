import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditPlanningPage extends StatefulWidget {
  const EditPlanningPage({super.key});

  @override
  State<EditPlanningPage> createState() => _EditPlanningPageState();
}

class _EditPlanningPageState extends State<EditPlanningPage> {
  bool hasUncheckedTasks = false;

  @override
  void initState() {
    super.initState();
    _listenToTasks();
  }

  /// 🔹 Écoute en temps réel des tâches pour détecter si au moins une n’est pas cochée
  void _listenToTasks() {
    FirebaseFirestore.instance.collection('toDoList').snapshots().listen((snapshot) {
      final uncheckedExists = snapshot.docs.any((doc) {
        final data = doc.data();
        return data['checked'] == false; // au moins une tâche non cochée
      });
      if (mounted) {
        setState(() => hasUncheckedTasks = uncheckedExists);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Créer / Gérer un planning"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard(
                icon: Icons.calendar_month,
                title: "Créer un planning",
                description: "Créer un nouveau planning hebdomadaire",
                color: Colors.orange.shade100,
                onTap: () => Navigator.pushNamed(context, '/createdPlanning'),
              ),
              _buildCard(
                icon: Icons.calendar_today,
                title: "Gestions des taches non hebdomadaire",
                description: "Listing par date",
                color: Colors.red.shade100,
                onTap: () => Navigator.pushNamed(context, '/listEventsNoWeekly'),
              ),
              const SizedBox(height: 12),
              _buildCard(
                icon: Icons.location_city,
                title: "Lieux",
                description: "Créer et gérer les lieux de travail (ex: foyer, ESAT...)",
                color: Colors.blue.shade100,
                onTap: () => Navigator.pushNamed(context, '/listPlace'),
              ),
              const SizedBox(height: 12),
              _buildCard(
                icon: Icons.people,
                title: "Travailleurs",
                description: "Gérer les travailleurs en situation de handicap",
                color: Colors.purple.shade100,
                onTap: () => Navigator.pushNamed(context, '/workers'),
              ),
              const SizedBox(height: 12),
              _buildCard(
                icon: Icons.check_box,
                title: "To Do List",
                description: "Noté vos tâches à effectuer",
                color: Colors.purple.shade100,
                hasNotes: hasUncheckedTasks,
                onTap: () => Navigator.pushNamed(context, '/toDoListPage'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 Widget de carte réutilisable
  Widget _buildCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
    bool hasNotes = false,
  }) {
    return Card(
      elevation: 4,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Icon(icon, color: Colors.indigo, size: 30),
                  ),
                  if (hasNotes)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.indigo),
            ],
          ),
        ),
      ),
    );
  }
}
