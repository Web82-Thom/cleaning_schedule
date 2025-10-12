import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DetailsPlacePage extends StatelessWidget {
  final String placeId;
  final String name;
  final bool containsRooms;

  const DetailsPlacePage({
    super.key,
    required this.placeId,
    required this.name,
    required this.containsRooms,
  });

  @override
  Widget build(BuildContext context) {
    final roomsRef = FirebaseFirestore.instance
        .collection('places')
        .doc(placeId)
        .collection('rooms');

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),

      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: containsRooms
            ? StreamBuilder<QuerySnapshot>(
                stream: roomsRef.orderBy('name').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No rooms found.\nTap + to add one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  final rooms = snapshot.data!.docs;

                  return ListView.builder(
  itemCount: rooms.length,
  itemBuilder: (context, index) {
    final data = rooms[index].data() as Map<String, dynamic>;
    final roomName = data['name'] ?? 'Unnamed';
    final id = rooms[index].id;

    // 👇 On capture le contexte parent du Scaffold
    final scaffoldContext = context;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.meeting_room, color: Colors.blue),
        title: Text(
          roomName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () async {
            await roomsRef.doc(id).delete();

            // ✅ On affiche le SnackBar avec un contexte valide
            if (scaffoldContext.mounted) {
              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                const SnackBar(
                  content: Text('Room deleted'),
                  duration: Duration(seconds: 1),
                ),
              );
            }
          },
        ),
      ),
    );
  },
);

                },
              )
            : const Center(
                child: Text(
                  'This place has no rooms.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
      ),

      floatingActionButton: containsRooms
          ? FloatingActionButton.extended(
              onPressed: () => _showAddRoomDialog(context, roomsRef),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une pièce'),
              backgroundColor: Colors.indigo,
            )
          : null,
    );
  }
  /// ✅ Add Room Dialog
  void _showAddRoomDialog(
      BuildContext context, CollectionReference roomsRef) {
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nouvelle pièce'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Nom de la pièce',
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Ajouter'),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                await roomsRef.add({'name': name});
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
