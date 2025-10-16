import 'package:cleaning_schedule/models/event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreatedEventPage extends StatefulWidget {
  const CreatedEventPage({super.key});

  @override
  State<CreatedEventPage> createState() => _CreatedEventPageState();
}

class _CreatedEventPageState extends State<CreatedEventPage> {
  final _formKey = GlobalKey<FormState>();

  final CollectionReference eventsRef = FirebaseFirestore.instance.collection(
    'events',
  );
  final CollectionReference placesRef = FirebaseFirestore.instance.collection(
    'places',
  );
  final CollectionReference workersRef = FirebaseFirestore.instance.collection(
    'workers',
  );

  DateTime? _selectedDate;
  String _timeSlot = 'morning';
  String? _selectedPlace;
  List<String> _selectedSubPlaces = [];
  String _task = '';
  List<String> _selectedWorkers = [];

  List<Map<String, dynamic>> _places = [];
  Map<String, List<String>> _subPlacesMap = {};
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
  }

  Future<void> _loadWorkers() async {
    final snapshot = await workersRef.where('active', isEqualTo: true).get();

    List<Map<String, dynamic>> workersList = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'name': '${data['firstName']} ${data['name']}',
        'isAbcent': data['isAbcent'] ?? false,
        'workSchedule': data['workSchedule'] ?? {},
      };
    }).toList();

    // 🔹 Récupérer tous les événements du même jour
    Set<String> busyWorkerIds = {};
    if (_selectedDate != null) {
      final eventsSnapshot = await eventsRef
          .where('day', isEqualTo: Timestamp.fromDate(_selectedDate!))
          .get();

      for (var doc in eventsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final timeSlot = data['timeSlot'] ?? '';
        if (timeSlot == _timeSlot) {
          final ids = List<String>.from(data['workerIds'] ?? []);
          busyWorkerIds.addAll(ids);
        }
      }
    }

    // 🔹 Ajoute la propriété isBusy et trie par nom
    workersList = workersList.map((w) {
      return {...w, 'isBusy': busyWorkerIds.contains(w['id'])};
    }).toList();

    // ✅ Tri alphabétique par nom
    workersList.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

    setState(() {
      _workers = workersList;
    });
  }

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
    await _loadWorkers();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Événement créé avec succès ✅')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Créer un événement')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // 📅 Sélection de date
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
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                      await _loadWorkers();
                    }
                  },
                ),
                const SizedBox(height: 16),
      
                // 🕓 Tranche horaire
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Matin'),
                        value: 'morning',
                        groupValue: _timeSlot,
                        onChanged: (v) {
                          setState(() => _timeSlot = v!);
                          _loadWorkers();
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Après-midi'),
                        value: 'afternoon',
                        groupValue: _timeSlot,
                        onChanged: (v) {
                          setState(() => _timeSlot = v!);
                          _loadWorkers();
                        },
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
      
                // 🏠 Sous-lieux
                if (_selectedPlace != null &&
                    (_subPlacesMap[_selectedPlace!] ?? []).isNotEmpty)
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Sous-lieux (optionnels)',
                      border: OutlineInputBorder(),
                    ),
                    child: Wrap(
                      spacing: 8,
                      children: (_subPlacesMap[_selectedPlace!] ?? []).map((sub) {
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
                  ),
                const SizedBox(height: 16),
      
                // 🧹 Tâche
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Tâche (optionnelle)',
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (v) => _task = v ?? '',
                ),
                const SizedBox(height: 16),
      
                // 👷 Workers
                _workers.isEmpty
                    ? const CircularProgressIndicator()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Assigné aux travailleurs',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ..._workers.map((w) {
                            final isBusy = w['isBusy'] ?? false;
                            final isAbcent = w['isAbcent'] ?? false;
      
                            // 🔹 Jour et créneau pour le schedule
                            final dayName = _selectedDate != null
                                ? DateFormat(
                                    'EEEE',
                                    'fr_FR',
                                  ).format(_selectedDate!)
                                : '';
      
                            final workDay =
                                w['workSchedule']?[dayName.toLowerCase()] ?? {};
      
                            // 🔹 Vérifie si le worker travaille ce créneau
                            final worksThisSlot = _timeSlot == 'morning'
                                ? (workDay['worksMorning'] ?? true)
                                : (workDay['worksAfternoon'] ?? true);
      
                            // 🔹 Horaires aménagés (endTime défini et non vide)
                            final hasSpecialSchedule =
                                workDay['endTime'] != null &&
                                workDay['endTime'].toString().isNotEmpty;
                            return InkWell(
                              onLongPress: isBusy
                                  ? () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: Text('Worker occupé'),
                                          content: Text(
                                            'Voulez-vous assigner ${w['name']} à cet événement quand même ?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Annuler'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text('Oui'),
                                            ),
                                          ],
                                        ),
                                      );
      
                                      if (confirm == true) {
                                        await FirebaseFirestore.instance
                                            .collection('events')
                                            .add({
                                              'day': Timestamp.fromDate(
                                                _selectedDate!,
                                              ),
                                              'timeSlot': _timeSlot,
                                              'place': _selectedPlace,
                                              'subPlace': _selectedSubPlaces,
                                              'task': _task,
                                              'workerIds': [w['id']],
                                              'createdAt': Timestamp.now(),
                                              'updatedAt': Timestamp.now(),
                                            });
      
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '${w['name']} assigné à un nouvel événement ✅',
                                            ),
                                          ),
                                        );
      
                                        _loadWorkers(); // Rafraîchir la liste
                                      }
                                    }
                                  : null,
                              child: CheckboxListTile(
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        w['name'],
                                        style: TextStyle(
                                          color:
                                              (!worksThisSlot ||
                                                  isAbcent ||
                                                  isBusy)
                                              ? Colors.grey
                                              : null,
                                          decoration: isBusy
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (hasSpecialSchedule)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 5),
                                        child: Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: Colors.orange,
                                        ),
                                      ),
                                  ],
                                ),
                                value: _selectedWorkers.contains(w['id']),
                                onChanged: (!worksThisSlot || isAbcent || isBusy)
                                    ? null
                                    : (v) {
                                        setState(() {
                                          if (v == true) {
                                            _selectedWorkers.add(w['id']);
                                          } else {
                                            _selectedWorkers.remove(w['id']);
                                          }
                                        });
                                      },
                              ),
                            );
                          }).toList(),
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
      ),
    );
  }
}
