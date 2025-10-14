import 'package:cloud_firestore/cloud_firestore.dart';

class RdvModel {
  final String id;
  final String instructorId;
  final DateTime date;
  final String motif;
  final String? lieu;
  final String heure;
  final Timestamp createdAt;

  RdvModel({
    required this.id,
    required this.instructorId,
    required this.date,
    required this.motif,
    required this.heure,
    this.lieu,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'instructorId': instructorId,
      'date': Timestamp.fromDate(date),
      'motif': motif,
      'lieu': lieu,
      'heure': heure,
      'createdAt': createdAt,
    };
  }

  factory RdvModel.fromFirestore(String id, Map<String, dynamic> data) {
    return RdvModel(
      id: id,
      instructorId: data['instructorId'],
      date: (data['date'] as Timestamp).toDate(),
      motif: data['motif'] ?? '',
      lieu: data['lieu'],
      heure: data['heure'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
