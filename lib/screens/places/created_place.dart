import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreatedPlace extends StatefulWidget {
  const CreatedPlace({super.key});

  @override
  State<CreatedPlace> createState() => _CreatedPlaceState();
}

class _CreatedPlaceState extends State<CreatedPlace> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _nomController = TextEditingController();
  bool _contientPieces = false; // ✅ nouvelle variable

  Future<void> _saveLieu() async {
    if (_nomController.text.trim().isEmpty) return;

    await _db.collection('places').add({
      'name': _nomController.text.trim(),
      'containsRooms': _contientPieces, // ✅ sauvegarde l’info
      'dateCreated': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Lieu ajouté avec succès")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Créer un lieu"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: "Nom du lieu",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text("Ce lieu contient des pièces"),
              value: _contientPieces,
              activeThumbColor: Colors.indigo,
              onChanged: (value) {
                setState(() {
                  _contientPieces = value;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saveLieu,
              icon: const Icon(Icons.check),
              label: const Text("Valider"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
