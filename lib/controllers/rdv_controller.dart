import 'package:cleaning_schedule/models/rdv_model.dart';
import 'package:cleaning_schedule/screens/rdvs/rdv_form_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RdvController extends ChangeNotifier{
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;

  /// Pour récupérer les RDVs du user sous forme groupée par jour
  Future<Map<DateTime, List<RdvModel>>> loadCurrentUserRdvsByDay() async {

  // 🔹 Requête sans orderBy
  final snapshot = await FirebaseFirestore.instance
      .collection('rdvs')
      .where('monitorIds', arrayContains: currentUserId)
      .get();

  // 🔹 Transformer les docs en modèles
  final rdvs = snapshot.docs
      .map((doc) => RdvModel.fromFirestore(doc.id, doc.data()))
      .toList();

  // 🔹 Trier par date côté Flutter
  rdvs.sort((a, b) => a.date.compareTo(b.date));

  // 🔹 Grouper par jour
  final Map<DateTime, List<RdvModel>> events = {};
  for (var rdv in rdvs) {
    final day = DateTime(rdv.date.year, rdv.date.month, rdv.date.day);
    events[day] = events[day] ?? [];
    events[day]!.add(rdv);
  }

  return events;
}


  /// Charge tous les RDVs et retourne une Map par jour
  Future<Map<DateTime, List<RdvModel>>> loadRdvs() async {
    final snapshot = await _firestore.collection('rdvs').orderBy('date').get();
    final Map<DateTime, List<RdvModel>> events = {};

    for (var doc in snapshot.docs) {
      final rdv = RdvModel.fromFirestore(doc.id, doc.data());
      final day = DateTime(rdv.date.year, rdv.date.month, rdv.date.day);
      events[day] = events[day] ?? [];
      events[day]!.add(rdv);
    }

    return events;
  }

  /// Ouvre la page de création ou modification de RDV
  Future<void> openRdvFormPage({
    required BuildContext context,
    RdvModel? rdvData,
    DateTime? initialDate,
    Map<String, String>? workersMap,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RdvFormPage(
          rdvData: rdvData,
          initialDate: initialDate,
          workersMap: workersMap,
        ),
      ),
    );
  }

  /// Supprime un RDV après confirmation
  Future<bool> deleteRdv(BuildContext context, RdvModel rdv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le rendez-vous'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce rendez-vous ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestore.collection('rdvs').doc(rdv.id).delete();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Rendez-vous supprimé ✅')));
        return true;
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur lors de la suppression : $e')));
        return false;
      }
    }
    return false;
  }

  /// Crée ou met à jour un RDV dans Firestore
  Future<void> saveRdv(BuildContext context, RdvModel rdv) async {
    try {
      if (rdv.id.isEmpty) {
        // Création
        await _firestore.collection('rdvs').add(rdv.toFirestore());
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Rendez-vous ajouté ✅')));
      } else {
        // Mise à jour
        await _firestore.collection('rdvs').doc(rdv.id).update(rdv.toFirestore());
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Rendez-vous modifié ✅')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }
}
