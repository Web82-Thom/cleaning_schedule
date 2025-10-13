import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ListWorkersPage extends StatefulWidget {
  const ListWorkersPage({super.key});

  @override
  State<ListWorkersPage> createState() => _ListWorkersPageState();
}

class _ListWorkersPageState extends State<ListWorkersPage> {
  final CollectionReference workersRef = FirebaseFirestore.instance.collection(
    'workers',
  );

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isPartTime = false;
  bool _isTherapeutic = false;
  bool _isHalfTime = false;
  bool _isFullTime = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// ➕ Ajouter un travailleur
  Future<void> _addWorker(BuildContext context) async {
    final firstName = _firstNameController.text.trim();
    final name = _nameController.text.trim();

    if (name.isEmpty || firstName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    try {
      await workersRef.add({
        'firstName': firstName[0].toUpperCase() + firstName.substring(1),
        'name': name.toUpperCase(),
        'role': 'Travailleur',
        'active': true,
        'isPartTime': _isPartTime,
        'isTherapeutic': _isTherapeutic,
        'isHalfTime': _isHalfTime,
        'isFullTime': (!_isPartTime && !_isTherapeutic && !_isHalfTime),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Travailleur ajouté avec succès ✅')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : ${e.toString()}')));
    }
  }
  
  /// ✏️ Modifier un travailleur
  Future<void> _updateWorker(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) async {
    final TextEditingController firstNameController = TextEditingController(
      text: data['firstName'] ?? '',
    );
    final TextEditingController nameController = TextEditingController(
      text: data['name'] ?? '',
    );

    bool isPartTime = data['isPartTime'] ?? false;
    bool isTherapeutic = data['isTherapeutic'] ?? false;
    bool isHalfTime = data['isHalfTime'] ?? false;
    bool isFullTime = (!isPartTime && !isTherapeutic && !isHalfTime);
    // ➜ Si un statut est sélectionné, décoche les autres
    if (isPartTime) {
      isTherapeutic = false;
      isHalfTime = false;
    } else if (isTherapeutic) {
      isPartTime = false;
      isHalfTime = false;
    } else if (isHalfTime) {
      isPartTime = false;
      isTherapeutic = false;
    } else {
      // ➜ Si aucun n'est coché, c’est du temps plein
      isFullTime = true;
    }

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  left: 16,
                  right: 16,
                  top: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Modifier le travailleur',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'Prénom',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            title: const Text("Temps partiel"),
                            value: isPartTime,
                            onChanged: (v) {
                              setDialogState(() {
                                if (v == true) {
                                  isPartTime = true;
                                  isTherapeutic = false;
                                  isHalfTime = false;
                                  isFullTime = false;
                                } else {
                                  isPartTime = false;
                                  isFullTime = true;
                                }
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: const Text("Mi-temps thérapeutique"),
                            value: isTherapeutic,
                            onChanged: (v) {
                              setDialogState(() {
                                if (v == true) {
                                  isTherapeutic = true;
                                  isPartTime = false;
                                  isHalfTime = false;
                                  isFullTime = false;
                                } else {
                                  isTherapeutic = false;
                                  isFullTime = true;
                                }
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: const Text("Mi-temps"),
                            value: isHalfTime,
                            onChanged: (v) {
                              setDialogState(() {
                                if (v == true) {
                                  isHalfTime = true;
                                  isPartTime = false;
                                  isTherapeutic = false;
                                  isFullTime = false;
                                } else {
                                  isHalfTime = false;
                                  isFullTime = true;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final firstName = firstNameController.text.trim();
                            final name = nameController.text.trim();

                            if (firstName.isEmpty || name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Veuillez remplir tous les champs',
                                  ),
                                ),
                              );
                              return;
                            }

                            await workersRef.doc(id).update({
                              'firstName':
                                  firstName[0].toUpperCase() +
                                  firstName.substring(1),
                              'name': name.toUpperCase(),
                              'isPartTime': isPartTime,
                              'isTherapeutic': isTherapeutic,
                              'isFullTime':
                                  (!isPartTime &&
                                  !isTherapeutic &&
                                  !isHalfTime),
                              'isHalfTime': isHalfTime,
                              'updatedAt': FieldValue.serverTimestamp(),
                            });

                            if (context.mounted) {
                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Travailleur mis à jour ✅'),
                                ),
                              );
                            }
                          },
                          child: const Text('Mettre à jour'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 🪟 Boîte de dialogue d’ajout
  void _showAddWorkerDialog() {
    _isPartTime = false;
    _isTherapeutic = false;
    _isHalfTime = false;
    _isFullTime = false;
    _firstNameController.clear();
    _nameController.clear();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool _isValid() => _nameController.text.trim().isNotEmpty;

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                        left: 16,
                        right: 16,
                        top: 16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Ajouter un travailleur',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Prénom
                          TextField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'Prénom',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Nom
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nom',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Checkboxes verticales
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                CheckboxListTile(
                                  title: const Text("Temps partiel"),
                                  value: _isPartTime,
                                  onChanged: (v) {
                                    setDialogState(() {
                                      _isPartTime = v ?? false;
                                      if (_isPartTime) _isTherapeutic = false;
                                      if (_isPartTime) _isFullTime = false;
                                      if (_isPartTime) _isHalfTime = false;
                                    });
                                  },
                                ),
                                CheckboxListTile(
                                  title: const Text("Mi-temps thérapeutique"),
                                  value: _isTherapeutic,
                                  onChanged: (v) {
                                    setDialogState(() {
                                      _isTherapeutic = v ?? false;
                                      if (_isTherapeutic) _isPartTime = false;
                                      if (_isTherapeutic) _isFullTime = false;
                                      if (_isTherapeutic) _isHalfTime = false;
                                    });
                                  },
                                ),
                                CheckboxListTile(
                                  title: const Text("Mi-temps"),
                                  value: _isHalfTime,
                                  onChanged: (v) {
                                    setDialogState(() {
                                      _isHalfTime = v ?? false;
                                      if (_isHalfTime) _isPartTime = false;
                                      if (_isHalfTime) _isFullTime = false;
                                      if (_isHalfTime) _isTherapeutic = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                child: const Text('Annuler'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isValid()
                                    ? () => _addWorker(context)
                                    : null,
                                child: const Text('Enregistrer'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  /// 🧾 Supprimer un travailleur
  Future<void> _deleteWorker(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer ce travailleur ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Non'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Oui'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await workersRef.doc(id).delete();

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Travailleur supprimé ❌')));
      }
    }
  }

  /// 🟢 Couleur du statut selon le type
  Color _getStatusColor(Map<String, dynamic> data) {
    if (data['isTherapeutic'] == true) return Colors.blue;
    if (data['isPartTime'] == true) return Colors.orange;
    if (data['isHalfTime'] == true) return Colors.pink;
    return Colors.green;
  }

  /// 🏷️ Texte du statut
  String _getStatusLabel(Map<String, dynamic> data) {
    if (data['isTherapeutic'] == true) return 'Mi-temps thérapeutique';
    if (data['isPartTime'] == true) return 'Temps partiel';
    if (data['isHalfTime'] == true) return 'Mi-temps';
    return 'Temps plein';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Liste des travailleurs")),
      body: StreamBuilder<QuerySnapshot>(
        stream: workersRef.orderBy('firstName', descending: false).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('Aucun travailleur trouvé.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;

              final color = _getStatusColor(data);
              final status = _getStatusLabel(data);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${data['firstName'] ?? ''} ${data['name'] ?? ''}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              _updateWorker(context, id, data);
                            },
                            color: Colors.blueAccent,
                            icon: Icon(Icons.edit),
                          ),
                          IconButton(
                            onPressed: () {
                              _deleteWorker(id);
                            },
                            color: Colors.red,
                            icon: Icon(Icons.delete),
                          ),
                        ],
                      ),
                    ],
                  ),
                  subtitle: Text(status, style: TextStyle(color: color)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddWorkerDialog,
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add),
        label: const Text("Ajouter", style: TextStyle(fontSize: 14)),
      ),
    );
  }
}
