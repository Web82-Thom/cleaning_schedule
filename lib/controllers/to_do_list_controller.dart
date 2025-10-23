import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/to_do_list_model.dart';

class ToDoListController extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ToDoListModel> _tasks = [];
  List<ToDoListModel> get tasks => _tasks;

  /// 🔹 Charger toutes les tâches (optionnel si StreamBuilder utilisé)
  Future<void> loadTasks() async {
    try {
      final snapshot = await _firestore
          .collection('toDoList')
          .orderBy('createdAt', descending: false)
          .get();

      _tasks = snapshot.docs
          .map((doc) => ToDoListModel.fromFirestore(doc.id, doc.data()))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur chargement tâches: $e');
    }
  }

  /// 🔹 Ajouter une nouvelle tâche
  Future<void> addTask({required String date, String note = ''}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final docRef = await _firestore.collection('toDoList').add({
        'date': date,
        'note': note,
        'checked': false,
        'checkedById': '',
        'checkedByName': '',
        'userId': user.uid,
        'createdAt': Timestamp.now(),
      });

      // Mise à jour locale (optionnelle, le StreamBuilder fera le reste)
      _tasks.add(ToDoListModel(
        id: docRef.id,
        date: date,
        note: note,
        checked: false,
        checkedById: '',
        checkedByName: '',
        userId: user.uid,
        createdAt: Timestamp.now(),
      ));

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur ajout tâche: $e');
    }
  }

  /// 🔹 Supprimer une tâche avec confirmation
  Future<bool> deleteTask(BuildContext context, String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Boîte de confirmation
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: const Text('Voulez-vous vraiment supprimer cette tâche ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );

      if (confirmed != true) return false;

      await _firestore.collection('toDoList').doc(taskId).delete();

      // Mise à jour locale (optionnelle)
      _tasks.removeWhere((t) => t.id == taskId);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('Erreur suppression tâche: $e');
      return false;
    }
  }

  /// 🔹 Toggle "checked" avec initiales, multi-device safe
  Future<void> toggleCheck(String taskId, bool value) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Récupération des initiales
      final names = (user.displayName ?? '').split(' ');
      String initials = '';
      for (var n in names) {
        if (n.isNotEmpty) initials += n[0].toUpperCase();
      }
      if (initials.isEmpty) initials = user.email![0].toUpperCase();

      final updateData = {
        'checked': value,
        'checkedById': value ? user.uid : '',
        'checkedByName': value ? initials : '',
      };

      await _firestore.collection('toDoList').doc(taskId).update(updateData);

      // Mise à jour locale (optionnelle)
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final task = _tasks[index];
        _tasks[index] = task.copyWith(
          checked: value,
          checkedById: value ? user.uid : '',
          checkedByName: value ? initials : '',
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur toggle check: $e');
    }
  }

  /// 🔹 Nettoyer le cache local
  void clear() {
    _tasks = [];
    notifyListeners();
  }
}
