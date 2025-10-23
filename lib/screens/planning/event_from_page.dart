import 'package:cleaning_schedule/main.dart';
import 'package:cleaning_schedule/widgets/tasks_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cleaning_schedule/models/event_model.dart';

class EventFormPage extends StatefulWidget {
  final String? eventId; // null = création, non-null = édition
  const EventFormPage({super.key, this.eventId});

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  final _formKey = GlobalKey<FormState>();

  final CollectionReference eventsRef = FirebaseFirestore.instance.collection('events');
  final CollectionReference placesRef = FirebaseFirestore.instance.collection('places');
  final CollectionReference workersRef = FirebaseFirestore.instance.collection('workers');

  bool _loading = true;
  final TasksWidget tasksWidget = TasksWidget();

  // 🔹 Lieux / sous-lieux / workers
  List<Map<String, dynamic>> _places = [];
  Map<String, List<String>> _subPlacesMap = {};
  List<Map<String, dynamic>> _workers = [];

  // 🔹 Champs formulaire
  DateTime? _selectedDate;
  String _timeSlot = 'morning';
  String? _selectedPlace;
  List<String> _selectedSubPlaces = [];
  String? _selectedTask;
  bool _isWeeklyTask = true; // true = aucune pastille
  List<String> _selectedWorkers = [];

  late bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.eventId != null;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadPlaces();
    if (_isEditing) await _loadEventData();
    await _loadWorkers();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _updateWeeklyTaskStatus() {
    setState(() {
      if (_selectedTask == null || _selectedTask!.isEmpty) {
        _isWeeklyTask = true; // aucune tâche = pas de pastille
      } else if (tasksWidget.tasksWeekly.contains(_selectedTask)) {
        _isWeeklyTask = true; // tâche hebdo = pas de pastille
      } else {
        _isWeeklyTask = false; // tâche non hebdo = pastille violette
      }
    });
  }

  Future<void> _loadEventData() async {
    if (widget.eventId == null) return;
    final doc = await eventsRef.doc(widget.eventId).get();
    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    if (!mounted) return;
    setState(() {
      _selectedDate = (data['day'] as Timestamp).toDate();
      _timeSlot = data['timeSlot'] ?? 'morning';
      _selectedPlace = data['place'];
      _selectedTask = data['task'];
      _selectedWorkers = List<String>.from(data['workerIds'] ?? []);
      _isWeeklyTask = data['isWeeklyTask'] ?? true;

      final subPlaceData = data['subPlace'];
      if (subPlaceData is List) {
        _selectedSubPlaces = List<String>.from(subPlaceData);
      } else if (subPlaceData is String) {
        _selectedSubPlaces = subPlaceData
            .replaceAll(RegExp(r'[\[\]]'), '')
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      // Assure la cohérence avec la liste des tâches
      _updateWeeklyTaskStatus();
    });
  }

  Future<void> _loadPlaces() async {
    final snapshot = await placesRef.get();
    List<Map<String, dynamic>> loadedPlaces = [];
    Map<String, List<String>> loadedSubPlaces = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final placeName = (data['name'] ?? '').toString().trim();

      final roomsSnapshot = await placesRef.doc(doc.id).collection('rooms').get();
      final subPlaces = roomsSnapshot.docs
          .map((r) => (r.data()['name'] ?? '').toString().trim())
          .where((n) => n.isNotEmpty)
          .toList();

      loadedPlaces.add({'id': doc.id, 'name': placeName});
      loadedSubPlaces[placeName] = subPlaces;
    }
    if (!mounted) return;
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

    // 🔹 Vérifie combien de fois chaque worker est occupé dans ce créneau
    Map<String, int> busyCount = {};
    if (_selectedDate != null) {
      final eventsSnapshot = await eventsRef.where('day', isEqualTo: Timestamp.fromDate(_selectedDate!)).get();
      for (var doc in eventsSnapshot.docs) {
        if (_isEditing && doc.id == widget.eventId) continue;
        final data = doc.data() as Map<String, dynamic>;
        final timeSlot = data['timeSlot'] ?? '';
        if (timeSlot == _timeSlot) {
          final workerIds = List<String>.from(data['workerIds'] ?? []);
          for (var wid in workerIds) {
            busyCount[wid] = (busyCount[wid] ?? 0) + 1;
          }
        }
      }
    }

    workersList = workersList.map((w) {
      final busyTimes = busyCount[w['id']] ?? 0;
      return {
        ...w,
        'busyCount': busyTimes,
        'isBusy': busyTimes > 0,
      };
    }).toList();

    workersList.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    if (!mounted) return;
    setState(() => _workers = workersList);
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
        const SnackBar(content: Text('Veuillez sélectionner une date et un lieu')),
      );
      return;
    }
    _formKey.currentState?.save();

    final event = EventModel(
      id: widget.eventId ?? '',
      day: _selectedDate!,
      timeSlot: _timeSlot,
      place: _selectedPlace!,
      subPlace: _selectedSubPlaces.toString(),
      task: _selectedTask ?? '',
      workerIds: _selectedWorkers,
      createdAt: Timestamp.now(),
      weekNumber: _getWeekNumber(_selectedDate!),
      isWeeklyTask: _isWeeklyTask,
    );

    if (_isEditing && widget.eventId != null) {
      await eventsRef.doc(widget.eventId).update(event.toFirestore());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Événement mis à jour ✅')));
    } else {
      await eventsRef.add(event.toFirestore());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Événement créé ✅')));
    }

    Navigator.of(context).pop();
  }

  Future<void> _deleteEvent() async {
    if (!_isEditing || widget.eventId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer l’événement'),
        content: const Text('Voulez-vous vraiment supprimer cet événement ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );

    if (confirm == true) {
      await eventsRef.doc(widget.eventId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Événement supprimé 🗑️')));
      Navigator.pop(context);
    }
  }

  void _showTooltip(BuildContext context, String message, GlobalKey key) {
    final overlay = Overlay.of(context);
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx + size.width / 2 - 75,
        top: offset.dy - 50,
        width: 150,
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                child: Center(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              CustomPaint(size: const Size(20, 10), painter: _TriangleDownPainter()),
            ],
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () => overlayEntry.remove());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final allTasks = [...tasksWidget.tasksWeekly, ...tasksWidget.tasksNoWeekly];
    final taskItems = allTasks.toSet().toList();
    if (_selectedTask != null && !taskItems.contains(_selectedTask)) taskItems.add(_selectedTask!);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Modifier l’événement' : 'Créer un événement'),
          actions: [
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.delete),
                color: Colors.red,
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
                  title: Text(
                    _selectedDate == null
                        ? 'Sélectionner une date'
                        : 'Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                      await _loadWorkers();
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 🕑 Créneau horaire
                RadioGroup<String>(
                  groupValue: _timeSlot,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _timeSlot = newValue);
                      _loadWorkers();
                    }
                  },
                  child: Row(
                    children: [
                      Expanded(child: RadioListTile<String>(title: const Text('Matin'), value: 'morning')),
                      Expanded(child: RadioListTile<String>(title: const Text('Après-midi'), value: 'afternoon')),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 📍 Lieu
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Lieu', border: OutlineInputBorder()),
                  items: _places.map((p) => DropdownMenuItem<String>(value: p['name'], child: Text(p['name']))).toList(),
                  initialValue: _selectedPlace,
                  onChanged: (v) {
                    setState(() {
                      _selectedPlace = v;
                      _selectedSubPlaces = [];
                    });
                  },
                  validator: (v) => v == null ? 'Sélectionner un lieu' : null,
                ),
                const SizedBox(height: 16),

                // 🏠 Sous-lieux
                if (_selectedPlace != null && (_subPlacesMap[_selectedPlace!] ?? []).isNotEmpty)
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Sous-lieux (optionnels)', border: OutlineInputBorder()),
                    child: Wrap(
                      spacing: 8,
                      children: (_subPlacesMap[_selectedPlace!] ?? []).map((sub) {
                        final isSelected = _selectedSubPlaces.contains(sub);
                        return FilterChip(
                          label: Text(sub),
                          selected: isSelected,
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
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Tâche (optionnelle)', border: OutlineInputBorder()),
                  initialValue: _selectedTask,
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('Aucune tâche', style: TextStyle(color: Colors.grey)),
                    ),
                    const DropdownMenuItem<String>(
                      enabled: false,
                      child: Text('— Tâches hebdomadaires', style: TextStyle(fontWeight: FontWeight.normal, color: Colors.grey)),
                    ),
                    ...([...tasksWidget.tasksWeekly]..sort()).map((task) => DropdownMenuItem(value: task, child: Text(task))),
                    const DropdownMenuItem<String>(
                      enabled: false,
                      child: Text('— Tâches non hebdomadaires', style: TextStyle(fontWeight: FontWeight.normal, color: Colors.grey)),
                    ),
                    ...([...tasksWidget.tasksNoWeekly]..sort()).map((task) => DropdownMenuItem(value: task, child: Text(task))),
                  ],
                  onChanged: (value) {
                    if (value == _selectedTask) return;
                    setState(() {
                      _selectedTask = value;
                      _updateWeeklyTaskStatus(); // ✅ met à jour la pastille violette
                    });
                  },
                ),
                const SizedBox(height: 16),
                // 👷 Workers
                _workers.isEmpty?
                const CircularProgressIndicator() : 
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Assigné aux travailleurs', style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._workers.map((w) {
                      final isAbcent = w['isAbcent'] ?? false;
                      final workerKey = GlobalKey();
                      final dayName = _selectedDate != null
                          ? DateFormat('EEEE', 'fr_FR').format(_selectedDate!)
                          : '';
                      final workDay = w['workSchedule']?[dayName.toLowerCase()] ?? {};
                      final worksThisSlot = _timeSlot == 'morning'
                          ? (workDay['worksMorning'] ?? true)
                          : (workDay['worksAfternoon'] ?? true);
                      final hasSpecialSchedule = workDay['endTime'] != null && workDay['endTime'].toString().isNotEmpty;

                      return GestureDetector(
                        onLongPress: () async {
                          final isBusy = w['isBusy'] ?? false;
                          if (isBusy) {
                            final timeText = _timeSlot == 'morning' ? 'ce matin' : 'cet après-midi';
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Travailleur déjà occupé'),
                                content: Text('${w['name']} est déjà occupé $timeText.\nVoulez-vous l’assigner quand même à cet événement ?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Non')),
                                  ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Oui')),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              setState(() {
                                if (!_selectedWorkers.contains(w['id'])) _selectedWorkers.add(w['id']);
                              });
                              if (!mounted) return;
                              ScaffoldMessenger.maybeOf(navigatorKey.currentContext!)?.showSnackBar(
                                  SnackBar(content: Text('${w['name']} ajouté à un autre événement ✅')));
                            }
                          }
                        },
                        child: CheckboxListTile(
                          key: workerKey,
                          title: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        w['name'],
                                        style: TextStyle(
                                          color: (!worksThisSlot || isAbcent || (w['busyCount'] ?? 0) > 0) ? Colors.grey : null,
                                          decoration: (w['busyCount'] ?? 0) > 0 ? TextDecoration.lineThrough : null,
                                          decorationThickness: (1.0 + ((w['busyCount'] ?? 0) - 1) * 0.7).clamp(1.0, 4.0),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    if (hasSpecialSchedule)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: GestureDetector(
                                          onTap: () {
                                            final endTime = workDay['endTime'] ?? '??:??';
                                            _showTooltip(context, '${w['name']} fini à $endTime aujourd’hui', workerKey);
                                          },
                                          child: const Icon(Icons.access_time, size: 16, color: Colors.orange),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) => ScaleTransition(
                                  scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                                  child: FadeTransition(opacity: animation, child: child),
                                ),
                                child: (w['busyCount'] ?? 0) > 1
                                    ? Container(
                                        key: ValueKey<int>(w['busyCount']),
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                                        child: Text('×${w['busyCount']}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                          value: _selectedWorkers.contains(w['id']),
                          onChanged: (!worksThisSlot || isAbcent) ?
                          null:  // worker ne peut pas travailler → désactivé
                          (v) {
                            setState(() {
                              final isBusy = w['isBusy'] ?? false;

                              if (v == true) {
                                // Ajouter seulement si le worker n'est pas occupé
                                if (!isBusy && !_selectedWorkers.contains(w['id'])) {
                                  _selectedWorkers.add(w['id']);
                                }
                              } else {
                                // Toujours possible de désélectionner
                                _selectedWorkers.remove(w['id']);
                              }

                              // Mise à jour de la pastille violette après toute modification
                              _updateWeeklyTaskStatus();
                            });
                          },

                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: Text(_isEditing ? 'Enregistrer les modifications' : 'Créer l’événement'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TriangleDownPainter extends CustomPainter {
  final Color color = Colors.black87;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
