import 'package:cleaning_schedule/models/event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreatedEventPage extends StatefulWidget {
  const CreatedEventPage({super.key});

  @override
  State<CreatedEventPage> createState() => _CreatedEventPageState();
}

class _CreatedEventPageState extends State<CreatedEventPage> {
  final _formKey = GlobalKey<FormState>();

  // Firestore
  final CollectionReference eventsRef = FirebaseFirestore.instance.collection(
    'events',
  );
  final CollectionReference placesRef = FirebaseFirestore.instance.collection(
    'places',
  );
  final CollectionReference workersRef = FirebaseFirestore.instance.collection(
    'workers',
  );

  // Form fields
  DateTime? _selectedDate;
  String _timeSlot = 'morning';
  String? _selectedPlace;
  List<String> _selectedSubPlaces = [];

  String _task = '';
  final List<String> _selectedWorkers = [];

  // Data from Firestore
  List<Map<String, dynamic>> _places = [];
  Map<String, List<String>> _subPlacesMap = {}; // place → sous-lieux
  List<Map<String, dynamic>> _workers = [];

  @override
  void initState() {
    super.initState();
    _loadPlaces();
    _loadWorkers();
  }

  Future<void> _loadPlaces() async {
    final snapshot = await placesRef.get();

    List<Map<String, dynamic>> loadedPlaces = [];
    Map<String, List<String>> loadedSubPlaces = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final placeName = (data['name'] ?? '').toString().trim();

      // 🔹 On charge la sous-collection "rooms" du lieu
      final roomsSnapshot = await placesRef
          .doc(doc.id)
          .collection('rooms')
          .get();
      final subPlaces = roomsSnapshot.docs
          .map((r) => (r.data()['name'] ?? '').toString().trim())
          .where((name) => name.isNotEmpty)
          .toList();

      loadedPlaces.add({'id': doc.id, 'name': placeName});
      loadedSubPlaces[placeName] = subPlaces;
    }

    setState(() {
      _places = loadedPlaces;
      _subPlacesMap = loadedSubPlaces;
    });

    print('✅ Lieux chargés : $_places');
    print('✅ Sous-lieux map : $_subPlacesMap');
  }

  Future<void> _loadWorkers() async {
    final snapshot = await workersRef.where('active', isEqualTo: true).get();
    setState(() {
      _workers = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': '${data['firstName']} ${data['name']}',
          'isAbcent': data['isAbcent'] ?? false,
        };
      }).toList();
    });
  }

  ///Recupere le numero de la semaine
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysOffset = firstDayOfYear.weekday - DateTime.monday;
    final firstMonday = firstDayOfYear.subtract(Duration(days: daysOffset));
    return ((date.difference(firstMonday).inDays) / 7).ceil() + 1;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_selectedDate == null || _selectedPlace == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une date et un lieu'),
        ),
      );
      return;
    }

    _formKey.currentState?.save();

    final event = EventModel(
      id: '',
      day: _selectedDate!,
      timeSlot: _timeSlot,
      place: _selectedPlace!,
      subPlace: _selectedSubPlaces.toString(),
      task: _task,
      workerIds: _selectedWorkers,
      createdAt: Timestamp.now(),
      weekNumber: _getWeekNumber(_selectedDate!),
    );

    await eventsRef.add(event.toFirestore());

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Événement créé avec succès ✅')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un événement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // DatePicker
              ListTile(
                title: Text(
                  _selectedDate == null
                      ? 'Sélectionner une date'
                      : 'Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
              ),
              const SizedBox(height: 16),

              // Tranche horaire
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Matin'),
                      value: 'morning',
                      groupValue: _timeSlot,
                      onChanged: (v) => setState(() => _timeSlot = v!),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Après-midi'),
                      value: 'afternoon',
                      groupValue: _timeSlot,
                      onChanged: (v) => setState(() => _timeSlot = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Lieu
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Lieu',
                  border: OutlineInputBorder(),
                ),
                items: _places
                    .map(
                      (p) => DropdownMenuItem<String>(
                        value: p['name'],
                        child: Text(p['name']),
                      ),
                    )
                    .toList(),
                value: _selectedPlace,
                onChanged: (v) {
                  setState(() {
                    _selectedPlace = v?.toString().trim();
                    _selectedSubPlaces = [];
                  });
                },
                validator: (v) => v == null ? 'Sélectionner un lieu' : null,
              ),
              const SizedBox(height: 16),

              // 🔹 Sélecteur multiple de sous-lieux
              if (_selectedPlace != null &&
                  (_subPlacesMap[_selectedPlace!] ?? []).isNotEmpty) ...[
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Sous-lieux (optionnels)',
                    border: OutlineInputBorder(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: (_subPlacesMap[_selectedPlace!] ?? []).map((
                          sub,
                        ) {
                          final isSelected = _selectedSubPlaces.contains(sub);
                          return FilterChip(
                            label: Text(sub),
                            selected: isSelected,
                            selectedColor: Colors.blue.shade100,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedSubPlaces.add(sub);
                                } else {
                                  _selectedSubPlaces.remove(sub);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      if (_selectedSubPlaces.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Aucun sous-lieu sélectionné',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sous-lieux sélectionnés :',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ..._selectedSubPlaces.map(
                                (sub) => Text('• $sub'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              //               // Sous-lieu dropdown si existant
              // if (_selectedPlace != null && _subPlacesMap.containsKey(_selectedPlace))
              //   DropdownButtonFormField<String>(
              //     decoration: const InputDecoration(
              //       labelText: 'Sous-lieu (optionnel)',
              //       border: OutlineInputBorder(),
              //     ),
              //     initialValue: _selectedSubPlace,
              //     items: _subPlacesMap[_selectedPlace]!
              //         .map((sub) => DropdownMenuItem<String>(
              //               value: sub,
              //               child: Text(sub),
              //             ))
              //         .toList(),
              //     onChanged: (v) => setState(() => _selectedSubPlace = v),
              //   ),

              // Tâche
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Tâche (optionnelle)',
                  border: OutlineInputBorder(),
                ),
                onSaved: (v) => _task = v ?? '',
              ),
              const SizedBox(height: 16),

              // Workers assignés
              _workers.isEmpty
                  ? const CircularProgressIndicator()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Assigné aux travailleurs'),

                        // Trier et séparer présents / absents
                        Builder(
                          builder: (context) {
                            final presentWorkers =
                                _workers
                                    .where((w) => w['isAbcent'] != true)
                                    .toList()
                                  ..sort(
                                    (a, b) => (a['name'] ?? '').compareTo(
                                      b['name'] ?? '',
                                    ),
                                  );

                            final absentWorkers =
                                _workers
                                    .where((w) => w['isAbcent'] == true)
                                    .toList()
                                  ..sort(
                                    (a, b) => (a['name'] ?? '').compareTo(
                                      b['name'] ?? '',
                                    ),
                                  );

                            List<Widget> workerWidgets = [];

                            // Présents
                            workerWidgets.addAll(
                              presentWorkers.map<Widget>((w) {
                                return CheckboxListTile(
                                  title: Text(w['name']),
                                  value: _selectedWorkers.contains(w['id']),
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        _selectedWorkers.add(w['id']);
                                      } else {
                                        _selectedWorkers.remove(w['id']);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            );

                            // Séparateur
                            if (absentWorkers.isNotEmpty) {
                              workerWidgets.add(
                                const Divider(
                                  color: Colors.black38,
                                  thickness: 0.5,
                                ),
                              );
                            }
                            // Absents
                            workerWidgets.addAll(
                              absentWorkers.map<Widget>((w) {
                                return CheckboxListTile(
                                  title: Text(
                                    w['name'],
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                  value: false,
                                  onChanged: null, // case désactivée
                                );
                              }).toList(),
                            );

                            return Column(children: workerWidgets);
                          },
                        ),
                      ],
                    ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Créer l’événement'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
