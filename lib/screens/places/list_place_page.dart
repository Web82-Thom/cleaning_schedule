import 'package:cleaning_schedule/screens/places/created_place.dart';
import 'package:cleaning_schedule/screens/places/list_sub_places_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ListPlace extends StatefulWidget {
  const ListPlace({super.key});

  @override
  State<ListPlace> createState() => _ListPlaceState();
}

class _ListPlaceState extends State<ListPlace> {
  final CollectionReference lieuxRef =
      FirebaseFirestore.instance.collection('places');

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Liste des lieux', style: TextStyle(fontSize: 15),),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {}),
            ),
          ],
        ),
      
        // --- Corps : liste des lieux ---
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
      
            return Padding(
              padding: const EdgeInsets.only(bottom: 58.0),
              child: ListView.builder(
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final data = places[index].data() as Map<String, dynamic>;
                  final id = places[index].id;
                  final name = data['name'] ?? 'Sans nom';
                  final containsRooms = data['containsRooms'] ?? false;
                    
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    elevation: 3,
                    child: ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.indigo),
                      title: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            containsRooms ? 'Contient des pièces' : 'Lieu simple',
                            style: TextStyle(
                              color: containsRooms ? Colors.green : Colors.grey[700],
                              fontSize: 10,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                                tooltip: 'Modifier le nom',
                                onPressed: () => _showEditDialog(context, id, name, lieuxRef),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                tooltip: 'Supprimer le lieu',
                                onPressed: () => _confirmDeletePlace(context, id, name, lieuxRef),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ListSubPlacesPage(
                              placeId: id,
                              name: name,
                              containsRooms: containsRooms,
                            ),
                          ),
                        );
                      },
                    ),
                  );


                },
              ),
            );
            
          },
        ),
      
        // --- Bouton Ajouter ---
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.black, width: 1), // bordure noire
            borderRadius: BorderRadius.circular(8), // coins arrondis
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreatedPlace()),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un lieu', style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
            fontSize: 14,
          ),),
          // backgroundColor: Colors.indigo,
        ),
      ),
    );
  }

  /// ✅ Modifier un lieu
  void _showEditDialog(BuildContext context, String id, String oldName,
      CollectionReference lieuxRef) {
    final TextEditingController controller =
        TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Modifier le nom du lieu'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Nouveau nom'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isEmpty) return;
                await lieuxRef.doc(id).update({'name': newName});
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nom du lieu mis à jour'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// ✅ Supprimer un lieu avec confirmation
  Future<void> _confirmDeletePlace(BuildContext context, String id,
      String name, CollectionReference lieuxRef) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Supprimer le lieu',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Voulez-vous vraiment supprimer le lieu "$name" ?\nCette action est irréversible.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Supprimer'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);

    if (!confirm) return;

    try {
      await lieuxRef.doc(id).delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lieu supprimé avec succès'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
