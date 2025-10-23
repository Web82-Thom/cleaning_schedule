import 'package:cleaning_schedule/controllers/to_do_list_controller.dart';
import 'package:cleaning_schedule/models/to_do_list_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ToDoListPage extends StatefulWidget {
  const ToDoListPage({super.key});

  @override
  State<ToDoListPage> createState() => _ToDoListPageState();
}

class _ToDoListPageState extends State<ToDoListPage> {
  late final ToDoListController toDoListController;

  @override
  void initState() {
    super.initState();
    toDoListController = ToDoListController();
  }

  String _getUserInitials() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    final names = (user.displayName ?? '').split(' ');
    String initials = '';
    for (var n in names) {
      if (n.isNotEmpty) initials += n[0].toUpperCase();
    }
    return initials.isEmpty ? user.email![0].toUpperCase() : initials;
  }

  void _addTaskDialog() {
    final dateController = TextEditingController();
    final noteController = TextEditingController();
    // DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom + 10,
                          top: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Nouvelle tâche',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            // Sélecteur de date
                            TextField(
                              controller: dateController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Date',
                                suffixIcon: const Icon(Icons.calendar_today, color: Colors.indigo),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onTap: () async {
                                final now = DateTime.now();
                                final pickedDate = await showDatePicker(
                                  context: context,
                                  initialDate: now,
                                  firstDate: now.subtract(const Duration(days: 365)),
                                  lastDate: now.add(const Duration(days: 365)),
                                  locale: const Locale('fr', 'FR'),
                                );
                                if (pickedDate != null) {
                                  setState(() {
                                    // final selectedDate = pickedDate;
                                    dateController.text =
                                        "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}";
                                  });
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            // Champ note
                            TextField(
                              controller: noteController,
                              maxLines: 5,
                              decoration: InputDecoration(
                                labelText: 'Note',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Colors.grey),
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              if (dateController.text.isNotEmpty) {
                                toDoListController.addTask(
                                  date: dateController.text.trim(),
                                  note: noteController.text.trim(),
                                );
                                FocusScope.of(context).unfocus();
                                Navigator.pop(context);
                              }
                            },
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.indigo.shade50,
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 4, child: Text('Note', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildTaskRow(ToDoListModel task) {
    _getUserInitials();
    final initials = task.checkedByName;

    return Card(
      color: task.checked ? Colors.green.shade50 : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(task.date)),
            Expanded(flex: 4, child: Text(task.note)),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: task.checked,
                    onChanged: (val) {
                      if (val == null) return;
                      toDoListController.toggleCheck(
                        task.id,
                        val,
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  initials.isNotEmpty
                      ? CircleAvatar(
                          backgroundColor: Colors.indigo.shade300,
                          radius: 14,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const SizedBox(height: 28),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => toDoListController.deleteTask(context, task.id),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ToDoListController>.value(
      value: toDoListController,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('To Do List'),
          backgroundColor: Colors.indigo,
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.indigo,
          onPressed: _addTaskDialog,
          child: const Icon(Icons.add),
        ),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('toDoList')
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('Aucune tâche pour le moment', style: TextStyle(color: Colors.grey)),
                    );
                  }

                  final tasks = snapshot.data!.docs.map((doc) {
                    final data = doc.data()! as Map<String, dynamic>;
                    return ToDoListModel.fromFirestore(doc.id, data);
                  }).toList();

                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return _buildTaskRow(task);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
