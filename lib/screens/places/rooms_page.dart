import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RoomsPage extends StatefulWidget {
  final String lieuId;
  final String lieuNom;

  const RoomsPage({super.key, required this.lieuId, required this.lieuNom});

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _showAddPieceDialog() async {
    final TextEditingController nomController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nouvelle pièce"),
        content: TextField(
          controller: nomController,
          decoration: const InputDecoration(labelText: "Nom de la pièce"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomController.text.isNotEmpty) {
                await _db
                    .collection('lieux')
                    .doc(widget.lieuId)
                    .collection('pieces')
                    .add({
                  'nom': nomController.text.trim(),
                  'dateCreation': FieldValue.serverTimestamp(),
                });
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Créer"),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePiece(String id) async {
    await _db
        .collection('lieux')
        .doc(widget.lieuId)
        .collection('pieces')
        .doc(id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pièces — ${widget.lieuNom}"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('lieux')
            .doc(widget.lieuId)
            .collection('pieces')
            .orderBy('dateCreation', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Aucune pièce ajoutée pour ce lieu."),
            );
          }

          final pieces = snapshot.data!.docs;

          return ListView.builder(
            itemCount: pieces.length,
            itemBuilder: (context, index) {
              final piece = pieces[index];
              final data = piece.data() as Map<String, dynamic>;
              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.meeting_room, color: Colors.indigo),
                  title: Text(data['nom'] ?? 'Sans nom'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deletePiece(piece.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPieceDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
