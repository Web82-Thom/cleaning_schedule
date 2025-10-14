import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WorkersController extends ChangeNotifier{
  final CollectionReference workersRef = FirebaseFirestore.instance.collection(
    'workers',
  );

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  bool _isPartTime = false;
  bool _isTherapeutic = false;
  bool _isHalfTime = false;
  bool _isFullTime = false;
  bool _isAbcent = false;

  /// 🟢 Couleur du statut selon le type
  Color getStatusColor(Map<String, dynamic> data) {
    if (data['isTherapeutic'] == true) return Colors.blue;
    if (data['isPartTime'] == true) return Colors.orange;
    if (data['isHalfTime'] == true) return Colors.deepPurpleAccent;
    if (data['isAbcent'] == true) return Colors.black;
    return Colors.green;
  }

  /// 🏷️ Texte du statut
  String getStatusLabel(Map<String, dynamic> data) {
    if (data['isTherapeutic'] == true) return 'Mi-temps thérapeutique';
    if (data['isPartTime'] == true) return 'Temps partiel';
    if (data['isHalfTime'] == true) return 'Mi-temps';
    return 'Temps plein';
  }

  /// Modifier un travailleur
  Future<void> updateWorker(
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
    bool isAbcent = data['isAbcent'] ?? false;
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
                          CheckboxListTile(
                            title: const Text("Absent"),
                            value: isAbcent,
                            onChanged: (v) {
                              setDialogState(() {
                                isAbcent = v ?? false;
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
                              'isAbcent': isAbcent,
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
  
  /// Supprimer un travailleur
  Future<void> deleteWorker(BuildContext context,  id) async {
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
      Navigator.pop(context, true);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Travailleur supprimé ❌')));
      }
    }
  }

/// ➕ Ajouter un travailleur
  Future<void> _addWorker(BuildContext context, BuildContext dialogContext) async {
  final firstName = firstNameController.text.trim();
  final name = nameController.text.trim();

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
      'isAbcent': _isAbcent,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      Navigator.of(dialogContext).pop(); // 🔹 on ferme uniquement le Dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Travailleur ajouté avec succès ✅')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Erreur : ${e.toString()}')));
  }
}

  /// 🪟 Boîte de dialogue d’ajout
  void showAddWorkerDialog(BuildContext context) {
    _isPartTime = false;
    _isTherapeutic = false;
    _isHalfTime = false;
    _isFullTime = false;
    _isAbcent = false;
    firstNameController.clear();
    nameController.clear();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool _isValid() => nameController.text.trim().isNotEmpty;

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
                            controller: firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'Prénom',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Nom
                          TextField(
                            controller: nameController,
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
                                CheckboxListTile(
                                  title: const Text("Absent"),
                                  value: _isAbcent,
                                  onChanged: (v) {
                                    setDialogState(() {
                                      _isAbcent = v ?? false;
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
                                    ? () => _addWorker(context, dialogContext)
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

void showWorkScheduleDialog(
  BuildContext context,
  String workerId,
  Map<String, dynamic> data,
) {
  final days = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi'];
  Map<String, String?> workSchedule = {};

  // Charger les horaires existants s’ils existent
  if (data['workSchedule'] != null) {
    workSchedule = Map<String, String?>.from(data['workSchedule']);
  }

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> pickTime(String day) async {
            final initial = TimeOfDay.now();
            final picked = await showTimePicker(
              context: dialogContext,
              initialTime: initial,
            );
            if (picked != null) {
              setState(() {
                workSchedule[day] = picked.format(context);
              });
            }
          }

          return AlertDialog(
            title: const Text('Configurer les horaires'),
            content: SingleChildScrollView(
              child: Column(
                children: days.map((day) {
                  return ListTile(
                    title: Text(day[0].toUpperCase() + day.substring(1)),
                    subtitle: Text(
                      workSchedule[day] ?? 'Non défini',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.access_time),
                      onPressed: () => pickTime(day),
                    ),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('workers')
                      .doc(workerId)
                      .update({'workSchedule': workSchedule});

                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Horaires mis à jour ✅'),
                      ),
                    );
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Supprime les horaires personnalisés d'un travailleur avec confirmation
Future<void> removeWorkSchedule(BuildContext context, String workerId) async {
  // Affiche une boîte de dialogue de confirmation
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment supprimer les horaires personnalisés ?'),
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

  if (confirm != true) return; // Annule si l’utilisateur clique sur "Non"

  try {
    await workersRef.doc(workerId).update({
      'workSchedule': FieldValue.delete(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Horaires personnalisés supprimés ✅')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression : ${e.toString()}')),
      );
    }
  }
}


}