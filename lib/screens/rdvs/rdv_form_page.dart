import 'package:cleaning_schedule/controllers/auth_controller.dart';
import 'package:cleaning_schedule/controllers/rdv_controller.dart';
import 'package:cleaning_schedule/models/rdv_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RdvFormPage extends StatefulWidget {
  final RdvModel? rdvData;
  final DateTime? initialDate;
  final Map<String, String>? workersMap;
  final Map<String, String>? monitorsMap;

  const RdvFormPage({
    this.rdvData,
    this.initialDate,
    this.workersMap,
    this.monitorsMap,
    Key? key,
  }) : super(key: key);

  @override
  State<RdvFormPage> createState() => _RdvFormPageState();
}

class _RdvFormPageState extends State<RdvFormPage> {
  final _formKey = GlobalKey<FormState>();
  final RdvController _controller = RdvController();
  final AuthController _authController = AuthController();
  final user = FirebaseAuth.instance.currentUser;

  DateTime? selectedDate;
  String motif = '';
  String lieu = '';
  String? selectedWorkerId;
  bool isTeam = false;

  Map<String, String> workersMap = {};
  Map<String, String> monitorsMap = {};
  List<String> selectedMonitorIds = [];

  @override
  void initState() {
    super.initState();
    selectedDate = widget.rdvData?.date ?? widget.initialDate;
    motif = widget.rdvData?.motif ?? '';
    lieu = widget.rdvData?.lieu ?? '';
    selectedWorkerId = widget.rdvData?.workerId;
    selectedMonitorIds = widget.rdvData?.monitorIds ?? [];
    isTeam = selectedWorkerId == 'TEAM';
    workersMap = widget.workersMap ?? {};
    monitorsMap = {}; // vide au départ
  if (isTeam) selectedWorkerId = null;

  _loadMonitors();
  }

  Future<void> _loadMonitors() async {
  monitorsMap = await _authController.loadMonitorsMap();
  setState(() {});
}

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.rdvData == null ? 'Créer un RDV' : 'Modifier un RDV'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // 🗓️ Date & heure
                TextFormField(
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Date & heure',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: (_) =>
                      selectedDate == null ? 'Sélectionnez une date' : null,
                  controller: TextEditingController(
                    text: selectedDate != null
                        ? DateFormat('dd/MM/yyyy HH:mm').format(selectedDate!)
                        : '',
                  ),
                  onTap: () async {
                    final now = DateTime.now();
                    final initial = (selectedDate != null && !selectedDate!.isBefore(now))
                        ? selectedDate!
                        : now;

                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: now,
                      lastDate: DateTime(2100),
                    );

                    if (pickedDate != null) {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate ?? now),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedDate = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),

                // 🧾 Motif
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Motif'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Champ requis' : null,
                  initialValue: motif,
                  onChanged: (value) => motif = value,
                ),
                const SizedBox(height: 12),

                // 📍 Lieu
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Lieu (optionnel)'),
                  initialValue: lieu,
                  onChanged: (value) => lieu = value,
                ),
                const SizedBox(height: 12),

                // 👥 Équipe
                CheckboxListTile(
                  title: const Text('Équipe'),
                  value: isTeam,
                  onChanged: (value) {
                    setState(() {
                      isTeam = value ?? false;
                      if (isTeam) selectedWorkerId = null;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // 👷‍♂️ Travailleur
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Travailleur',
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: workersMap.entries
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  value: isTeam ? null : selectedWorkerId,
                  onChanged: isTeam
                      ? null
                      : (value) {
                          setState(() => selectedWorkerId = value);
                        },
                  validator: (value) {
                    if (!isTeam &&
                        selectedMonitorIds.isEmpty &&
                        (value == null || value.isEmpty)) {
                      return 'Sélectionnez un travailleur ou un moniteur';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 🎓 Moniteurs associés
                if (monitorsMap.isNotEmpty)
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Moniteurs associés',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      ...monitorsMap.entries.map(
        (entry) => CheckboxListTile(
          title: Text(entry.value),
          value: selectedMonitorIds.contains(entry.key),
          onChanged: (checked) {
            setState(() {
              if (checked == true) {
                selectedMonitorIds.add(entry.key);
              } else {
                selectedMonitorIds.remove(entry.key);
              }
            });
          },
        ),
      ),
    ],
  ),

                const SizedBox(height: 24),

                // 💾 Enregistrer
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate() && selectedDate != null) {
                      final rdv = RdvModel(
                        id: widget.rdvData?.id ?? '',
                        instructorId: user!.uid,
                        date: selectedDate!,
                        heure: DateFormat('HH:mm').format(selectedDate!),
                        motif: motif,
                        lieu: lieu,
                        workerId: isTeam ? 'TEAM' : (selectedWorkerId ?? ''),
                        monitorIds: selectedMonitorIds,
                        createdAt: Timestamp.now(),
                      );

                      await _controller.saveRdv(context, rdv);
                      if (context.mounted) Navigator.pop(context, true);
                    }
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
