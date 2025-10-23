import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthController extends ChangeNotifier{
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Inscription monitrice moniteur uniquement
  Future<void> registerInstructor({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required BuildContext context,
  }) async {
      try {
        showDialog(
        context: context,
        barrierDismissible: false, // empêche de fermer le loader
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.indigo),
        ),
      );
      // Crée le compte Firebase Auth
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) throw Exception('Erreur de création du compte.');

      // Sauvegarde dans Firestore
      await _db.collection('users').doc(user.uid).set({
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'role': 'instructor',
        'actif': true,
        'dateCreation': FieldValue.serverTimestamp(),
      });
      // ✅ Ferme le loader avant de continuer
      if (context.mounted) Navigator.pop(context);
      // ✅ On revient à la page précédente (AuthWrapper redirigera automatiquement)
      if (context.mounted) {
        Navigator.pop(context); 
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Erreur d’inscription')),
      );
      }
    }
  }
  
  Map<String, String> monitorIds = {};
  ///Chargement de tous les moniteurs
  Future<Map<String, String>> loadMonitors() async {
    final snapshot = await _db
        .collection('users')
        .where('role', isEqualTo: 'instructor')
        .where('actif', isEqualTo: true)
        .get();

    return monitorIds = {
      for (var doc in snapshot.docs)
        doc.id: '${doc['prenom']} ${doc['nom']}',
    };
  }

  //  Charge la liste des moniteurs (instructors) actifs depuis Firestore
  Future<Map<String, String>> loadMonitorsMap() async {
    final Map<String, String> monitorsMap = {};

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'instructor')
          .where('actif', isEqualTo: true)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final nom = data['nom'] ?? '';
        final prenom = data['prenom'] ?? '';
        monitorsMap[doc.id] = '$prenom $nom';
      }
    } catch (e) {
      debugPrint('Erreur chargement des moniteurs: $e');
    }

    return monitorsMap;
  }

  // --- Connexion : vérifie le rôle avant d'autoriser l’accès
  Future<void> signIn({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc = await _db.collection('users').doc(cred.user!.uid).get();

      if (!userDoc.exists || userDoc['role'] != 'instructor' || userDoc['actif'] == false) {
        await _auth.signOut();
        throw Exception("Accès réservé aux monitrices et moniteurs actifs.");
      }

    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Erreur de connexion')),
      );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      }
    }
  }

  Future<void> signOut(BuildContext context) async {
    await _auth.signOut();
  }
}
