import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String role; // "monitrice" ou "travailleur"
  final bool actif;
  final DateTime dateCreation;

  UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
    this.actif = true,
    DateTime? dateCreation,
  }) : dateCreation = dateCreation ?? DateTime.now();

  // --- Conversion Firestore ---
  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'travailleur',
      actif: data['actif'] ?? true,
      dateCreation: (data['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'role': role,
      'actif': actif,
      'dateCreation': dateCreation,
    };
  }
}
