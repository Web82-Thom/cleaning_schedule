import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthController {
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
      // ✅ On revient à la page précédente (AuthWrapper redirigera automatiquement)
      if (context.mounted) {
        Navigator.pop(context); 
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Erreur d’inscription')),
      );
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Erreur de connexion')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> signOut(BuildContext context) async {
    await _auth.signOut();
  }
}
