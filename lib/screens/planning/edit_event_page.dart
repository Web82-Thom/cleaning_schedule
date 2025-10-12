import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditEventPage extends StatefulWidget {
  final String eventId;
  const EditEventPage({super.key, required this.eventId});

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  late DocumentReference eventRef;

  bool _loading = true;

  // Données de Firestore
  List<Map<String, dynamic>> _places = [];
  Map<String, List<String>> _subPlacesMap = {};
  List<Map<String, dynamic>> _workers = [];

  // Champs du formulaire
  DateTime? _selectedDate;
  String _timeSlot = 'morning';
  String? _selectedPlace;
  List<String> _selectedSubPlaces = [];
  String _task = '';
  List<String> _selectedWorkers = [];

  @override
  void initState() {
    super.initState();
    eventRef =
        FirebaseFirestore.instance.collection('events').doc(widget.eventId);
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadPlaces(), _loadWorkers()]);
    await _loadEventData();
  }

  Future<void> _loadEventData() async {
    final doc = await eventRef.get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;

    setState(() {
      _selectedDate = (data['day'] as Timestamp).toDate();
      _timeSlot = data['timeSlot'];
      _selectedPlace = data['place'];
      _task = data['task'];
      _selectedWorkers = List<String>.from(data['workerIds'] ?? []);

      // 🔹 Convertir subPlace (string ou list)
      final subPlaceData = data['subPlace'];
      if (subPlaceData is List) {
        _selectedSubPlaces = List<String>.from(subPlaceData);
      } else if (subPlaceData is String) {
        _selectedSubPlaces = subPlaceData
            .replaceAll('[', '')
            .replaceAll(']', '')
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }

      _loading = false;
    });
  }

  Future<void> _loadPlaces() async {
    final placesRef = FirebaseFirestore.instance.collection('places');
    final snapshot = await placesRef.get();

    List<Map<String, dynamic>> loadedPlaces = [];
    Map<String, List<String>> loadedSubPlaces = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final placeName = (data['name'] ?? '').toString().trim();

      final roomsSnapshot = await placesRef.doc(doc.id).collection('rooms').get();
      final subPlaces = roomsSnapshot.docs
          .map((r) => (r.data()['name'] ?? '').toString().trim())
          .where((name) => name.isNotEmpty)
          .toList();

      loadedPlaces.add({'id': doc.id, 'name': placeName});
      loadedSubPlaces[placeName] = subPlaces;
    }

    _places = loadedPlaces;
    _subPlacesMap = loadedSubPlaces;
  }

  Future<void> _loadWorkers() async {
    final workersRef = FirebaseFirestore.instance.collection('workers');
    final snapshot = await workersRef.where('active', isEqualTo: true).get();

    _workers = snapshot.docs.map((doc) {
      final data = doc.data();
      return {'id': doc.id, 'name': '${data['firstName']} ${data['name']}'};
    }).toList();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      await eventRef.update({
        'day': Timestamp.fromDate(_selectedDate!),
        'timeSlot': _timeSlot,
        'place': _selectedPlace,
        'subPlace': _selectedSubPlaces,
        'task': _task,
        'workerIds': _selectedWorkers,
        'updatedAt': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Événement mis à jour ✅')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer l’événement'),
        content: const Text('Voulez-vous vraiment supprimer cet événement ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await eventRef.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Événement supprimé 🗑️')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier l’événement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteEvent,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 📅 Date
              ListTile(
                title: Text(_selectedDate == null
                    ? 'Sélectionner une date'
                    : 'Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
              ),
              const SizedBox(height: 16),

              // 🕓 Créneau horaire
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

              // 📍 Lieu
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Lieu',
                  border: OutlineInputBorder(),
                ),
                items: _places
                    .map((p) => DropdownMenuItem<String>(
                        value: p['name'], child: Text(p['name'])))
                    .toList(),
                value: _selectedPlace,
                onChanged: (v) {
                  setState(() {
                    _selectedPlace = v;
                    _selectedSubPlaces = [];
                  });
                },
              ),
              const SizedBox(height: 16),

              // 🏠 Sous-lieux
              if (_selectedPlace != null &&
                  (_subPlacesMap[_selectedPlace!] ?? []).isNotEmpty)
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Sous-lieux',
                    border: OutlineInputBorder(),
                  ),
                  child: Wrap(
                    spacing: 8,
                    children: (_subPlacesMap[_selectedPlace!] ?? []).map((sub) {
                      final selected = _selectedSubPlaces.contains(sub);
                      return FilterChip(
                        label: Text(sub),
                        selected: selected,
                        selectedColor: Colors.blue.shade100,
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _selectedSubPlaces.add(sub);
                            } else {
                              _selectedSubPlaces.remove(sub);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 16),

              // 🧹 Tâche
              TextFormField(
                initialValue: _task,
                decoration: const InputDecoration(
                  labelText: 'Tâche',
                  border: OutlineInputBorder(),
                ),
                onSaved: (v) => _task = v ?? '',
              ),
              const SizedBox(height: 16),

              // 👷 Travailleurs
              _workers.isEmpty
                  ? const CircularProgressIndicator()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Assigné aux travailleurs',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        ..._workers.map(
                          (w) => CheckboxListTile(
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
                          ),
                        ),
                      ],
                    ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('Enregistrer les modifications'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
