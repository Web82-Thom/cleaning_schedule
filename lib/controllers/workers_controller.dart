import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WorkersController extends ChangeNotifier {
  final CollectionReference workersRef = FirebaseFirestore.instance.collection(
    'workers',
  );

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  bool _isPartTime = false;
  bool _isTherapeutic = false;
  bool _isHalfTime = false;
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

  Map<String, String> workersMap = {};

  /// Chargement des travailleurs
  Future<Map<String, String>> loadWorkers() async {
  final snapshot = await workersRef.where('active', isEqualTo: true).get();
  workersMap = {
    for (var doc in snapshot.docs)
      doc.id: '${doc['firstName']} ${doc['name']}',
  };
  notifyListeners(); 
  return workersMap;
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
                    _buildTextField(
                      controller: firstNameController,
                      label: 'Prénom',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: nameController,
                      label: 'Nom',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),
                    _buildStatusCheckboxes(
                      setDialogState,
                      isPartTime,
                      isTherapeutic,
                      isHalfTime,
                      isAbcent,
                      (v) => isPartTime = v,
                      (v) => isTherapeutic = v,
                      (v) => isHalfTime = v,
                      (v) => isAbcent = v,
                    ),
                    const SizedBox(height: 16),
                    _buildUpdateActions(
                      context,
                      dialogContext,
                      firstNameController,
                      nameController,
                      id,
                      isPartTime,
                      isTherapeutic,
                      isHalfTime,
                      isAbcent,
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
  Future<void> deleteWorker(BuildContext context, id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
      ),
    );

    if (confirm != true) return;
    if (confirm != true) return;
    
      await workersRef.doc(id).delete();
    
    Navigator.pop(context, true);

    if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Travailleur supprimé ❌')));
    
  }

  /// ➕ Ajouter un travailleur
  Future<void> _addWorkerFromButton(
    BuildContext context,
    BuildContext dialogContext,
  ) async {
    final firstName = firstNameController.text.trim();
    final name = nameController.text.trim();

    if (firstName.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    try {
      // Calcul dynamique de isFullTime
      final isFullTime = !_isPartTime && !_isTherapeutic && !_isHalfTime;

      await workersRef.add({
        'firstName': firstName[0].toUpperCase() + firstName.substring(1),
        'name': name.toUpperCase(),
        'role': 'Travailleur',
        'active': true,
        'isPartTime': _isPartTime,
        'isTherapeutic': _isTherapeutic,
        'isHalfTime': _isHalfTime,
        'isFullTime': isFullTime,
        'isAbcent': _isAbcent,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.of(dialogContext).pop();
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

  /// 🪟 Boîte de dialogue d’ajout
  void showAddWorkerDialog(BuildContext context) {
    // Réinitialiser le formulaire
    _isPartTime = false;
    _isTherapeutic = false;
    _isHalfTime = false;
    _isAbcent = false;
    firstNameController.clear();
    nameController.clear();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            bool isValid() => nameController.text.trim().isNotEmpty;
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
                          _buildTextField(
                            controller: firstNameController,
                            label: 'Prénom',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: nameController,
                            label: 'Nom',
                            icon: Icons.person,
                          ),
                          const SizedBox(height: 16),
                          // Checkboxes avec gestion dynamique de isFullTime
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
                                      if (_isPartTime) {
                                        _isTherapeutic = false;
                                        _isHalfTime = false;
                                      }
                                    });
                                  },
                                ),
                                CheckboxListTile(
                                  title: const Text("Mi-temps thérapeutique"),
                                  value: _isTherapeutic,
                                  onChanged: (v) {
                                    setDialogState(() {
                                      _isTherapeutic = v ?? false;
                                      if (_isTherapeutic) {
                                        _isPartTime = false;
                                        _isHalfTime = false;
                                      }
                                    });
                                  },
                                ),
                                CheckboxListTile(
                                  title: const Text("Mi-temps"),
                                  value: _isHalfTime,
                                  onChanged: (v) {
                                    setDialogState(() {
                                      _isHalfTime = v ?? false;
                                      if (_isHalfTime) {
                                        _isPartTime = false;
                                        _isTherapeutic = false;
                                      }
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
                                onPressed: isValid()
                                    ? () => _addWorkerFromButton(
                                        context,
                                        dialogContext,
                                      )
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

  /// Boîte de dialogue ajout/configuration horaires aménagés
  void showWorkScheduleDialog(
    BuildContext context,
    String workerId,
    Map<String, dynamic> data,
  ) {
    final days = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi'];

    Map<String, Map<String, dynamic>> workSchedule = {};

    if (data['workSchedule'] != null) {
      final rawSchedule = data['workSchedule'];
      if (rawSchedule is Map) {
        rawSchedule.forEach((key, value) {
          if (value is String) {
            workSchedule[key] = {
              'endTime': value,
              'worksMorning': true,
              'worksAfternoon': true,
            };
          } else if (value is Map) {
            workSchedule[key] = {
              'endTime': value['endTime'],
              'worksMorning': value['worksMorning'] ?? true,
              'worksAfternoon': value['worksAfternoon'] ?? true,
            };
          }
        });
      }
    }

    for (var day in days) {
      workSchedule.putIfAbsent(
        day,
        () => {'endTime': null, 'worksMorning': true, 'worksAfternoon': true},
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxHeight = MediaQuery.of(dialogContext).size.height * 0.85;
              final maxWidth = constraints.maxWidth < 600
                  ? constraints.maxWidth
                  : 600.0;

              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: maxHeight,
                  maxWidth: maxWidth,
                ),
                child: StatefulBuilder(
                  builder: (context, setState) {
                    Future<void> pickTime(String day) async {
                      final initial = TimeOfDay.now();
                      final picked = await showTimePicker(
                        context: dialogContext,
                        initialTime: initial,
                      );
                      if (picked != null) {
                        setState(() {
                          workSchedule[day]!['endTime'] = picked.format(
                            dialogContext,
                          );
                        });
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Configurer les horaires aménagés',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    Navigator.of(dialogContext).pop(),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: days.map((day) {
                                  final info = workSchedule[day]!;

                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            day[0].toUpperCase() +
                                                day.substring(1),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Expanded(
                                                flex: 2,
                                                child: Text("Fin de journée :"),
                                              ),
                                              Expanded(
                                                flex: 3,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        info['endTime'] ??
                                                            'Non défini',
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.access_time,
                                                      ),
                                                      onPressed: () =>
                                                          pickTime(day),
                                                      constraints:
                                                          const BoxConstraints(),
                                                      padding: EdgeInsets.zero,
                                                    ),
                                                    if (info['endTime'] != null)
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.clear,
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            info['endTime'] =
                                                                null;
                                                          });
                                                        },
                                                        constraints:
                                                            const BoxConstraints(),
                                                        padding:
                                                            EdgeInsets.zero,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text("Travaille le matin"),
                                              Switch(
                                                value:
                                                    info['worksMorning'] ??
                                                    true,
                                                onChanged: (val) {
                                                  setState(() {
                                                    info['worksMorning'] = val;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                "Travaille l’après-midi",
                                              ),
                                              Switch(
                                                value:
                                                    info['worksAfternoon'] ??
                                                    true,
                                                onChanged: (val) {
                                                  setState(() {
                                                    info['worksAfternoon'] =
                                                        val;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
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
                                onPressed: () async {
                                  try {
                                    await workersRef.doc(workerId).update({
                                      'workSchedule': workSchedule,
                                    });

                                    if (context.mounted) {
                                      Navigator.of(dialogContext).pop();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Horaires aménagés enregistrés ✅',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Erreur lors de l’enregistrement : ${e.toString()}',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Enregistrer'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Supprime un jour spécifique du workSchedule avec confirmation
  void removeWorkSchedule(
    BuildContext context,
    String workerId,
    String day,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer ce jour"),
        content: Text("Voulez-vous vraiment supprimer l’horaire du $day ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final docRef = workersRef.doc(workerId);
    final snap = await docRef.get();
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;
    final schedule = Map<String, dynamic>.from(data['workSchedule'] ?? {});
    schedule.remove(day);

    await docRef.update({'workSchedule': schedule});

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Horaire du $day supprimé ✅')));
    }
  }

  /// 🛠 Helpers
  // void _resetForm() {
  //   _isPartTime = false;
  //   _isTherapeutic = false;
  //   _isHalfTime = false;
  //   _isAbcent = false;
  //   firstNameController.clear();
  //   nameController.clear();
  // }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildStatusCheckboxes(
    void Function(void Function()) setState,
    bool isPartTime,
    bool isTherapeutic,
    bool isHalfTime,
    bool isAbcent,
    void Function(bool) onPartTimeChanged,
    void Function(bool) onTherapeuticChanged,
    void Function(bool) onHalfTimeChanged,
    void Function(bool) onAbcentChanged,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          CheckboxListTile(
            title: const Text("Temps partiel"),
            value: isPartTime,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  onPartTimeChanged(true);
                  onTherapeuticChanged(false);
                  onHalfTimeChanged(false);
                } else {
                  onPartTimeChanged(false);
                }
              });
            },
          ),
          CheckboxListTile(
            title: const Text("Mi-temps thérapeutique"),
            value: isTherapeutic,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  onTherapeuticChanged(true);
                  onPartTimeChanged(false);
                  onHalfTimeChanged(false);
                } else {
                  onTherapeuticChanged(false);
                }
              });
            },
          ),
          CheckboxListTile(
            title: const Text("Mi-temps"),
            value: isHalfTime,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  onHalfTimeChanged(true);
                  onPartTimeChanged(false);
                  onTherapeuticChanged(false);
                } else {
                  onHalfTimeChanged(false);
                }
              });
            },
          ),
          CheckboxListTile(
            title: const Text("Absent"),
            value: isAbcent,
            onChanged: (v) => setState(() => onAbcentChanged(v ?? false)),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateActions(
    BuildContext context,
    BuildContext dialogContext,
    TextEditingController firstNameController,
    TextEditingController nameController,
    String id,
    bool isPartTime,
    bool isTherapeutic,
    bool isHalfTime,
    bool isAbcent,
  ) {
    return Row(
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
                  content: Text('Veuillez remplir tous les champs'),
                ),
              );
              return;
            }

            await workersRef.doc(id).update({
              'firstName': firstName[0].toUpperCase() + firstName.substring(1),
              'name': name.toUpperCase(),
              'isPartTime': isPartTime,
              'isTherapeutic': isTherapeutic,
              'isFullTime': (!isPartTime && !isTherapeutic && !isHalfTime),
              'isHalfTime': isHalfTime,
              'isAbcent': isAbcent,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            if (context.mounted) {
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Travailleur mis à jour ✅')),
              );
            }
          },
          child: const Text('Mettre à jour'),
        ),
      ],
    );
  }
}
