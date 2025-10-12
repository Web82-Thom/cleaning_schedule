import 'package:cleaning_schedule/screens/places/created_place.dart';
import 'package:cleaning_schedule/screens/places/details_place_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ListPlace extends StatefulWidget {
  const ListPlace({super.key});

  @override
  State<ListPlace> createState() => _ListPlaceState();
}

class _ListPlaceState extends State<ListPlace> {
  @override
  Widget build(BuildContext context) {
    final lieuxRef = FirebaseFirestore.instance.collection('places');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des lieux'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          )
        ],
      ),

      // --- Corps : liste des lieux
      body: StreamBuilder<QuerySnapshot>(
        stream: lieuxRef.orderBy('name').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Aucun lieu trouvé.\nAppuyez sur + pour en ajouter un.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final places = snapshot.data!.docs;

          return ListView.builder(
            itemCount: places.length,
            itemBuilder: (context, index) {
              final data = places[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Sans nom';
              final containsRooms = data['containsRooms'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.indigo),
                  title: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    containsRooms ? 'Contient des pièces' : 'Lieu simple',
                    style: TextStyle(
                      color: containsRooms ? Colors.green : Colors.grey[700],
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DetailsPlacePage(
        placeId: places[index].id,
        name: name,
        containsRooms: containsRooms,
      ),
    ),
  );
},
                ),
              );
            },
          );
        },
      ),

      // --- Bouton Ajouter
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatedPlace()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un lieu'),
        backgroundColor: Colors.indigo,
      ),
    );
  }
}
