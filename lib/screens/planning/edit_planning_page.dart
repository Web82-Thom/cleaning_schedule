import 'package:flutter/material.dart';

class EditPlanningPage extends StatefulWidget {
  const EditPlanningPage({super.key});

  @override
  State<EditPlanningPage> createState() => _EditPlanningPageState();
}

class _EditPlanningPageState extends State<EditPlanningPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Créer / Gérer un planning"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCard(
              icon: Icons.calendar_month,
              title: "Créer un planning",
              description: "Créer un nouveau planning hebdomadaire",
              color: Colors.orange.shade100,
              onTap: () => Navigator.pushNamed(context, '/createPlanning'),
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
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
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
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Icon(icon, color: Colors.indigo, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
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
