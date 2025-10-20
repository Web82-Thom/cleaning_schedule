import 'package:cloud_firestore/cloud_firestore.dart';

class RdvModel {
  final String id;
  final String instructorId; // Moniteur qui a créé le RDV
  final String workerId;     // Travailleur assigné ou "TEAM"
  final DateTime date;
  final String motif;
  final String? lieu;
  final String heure;
  final Timestamp createdAt;
  final List<String> monitorIds; // 👈 Liste des moniteurs associés

  RdvModel({
    required this.id,
    required this.instructorId,
    required this.workerId,
    required this.date,
    required this.motif,
    required this.heure,
    this.lieu,
    required this.createdAt,
    required this.monitorIds,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'instructorId': instructorId,
      'workerId': workerId,
      'date': Timestamp.fromDate(date),
      'motif': motif,
      'lieu': lieu ?? '',
      'heure': heure,
      'createdAt': createdAt,
      'monitorIds': monitorIds, // ✅ clé correcte et cohérente
    };
  }

  factory RdvModel.fromFirestore(String id, Map<String, dynamic> data) {
    return RdvModel(
      id: id,
      instructorId: data['instructorId'] ?? '',
      workerId: data['workerId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      motif: data['motif'] ?? '',
      lieu: data['lieu'] ?? '',
      heure: data['heure'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      monitorIds: (data['monitorIds'] as List?)?.map((e) => e.toString()).toList() ?? [], // ✅ toujours une liste
    );
  }

  RdvModel copyWith({
    String? id,
    String? instructorId,
    String? workerId,
    DateTime? date,
    String? motif,
    String? lieu,
    String? heure,
    Timestamp? createdAt,
    List<String>? monitorIds,
  }) {
    return RdvModel(
      id: id ?? this.id,
      instructorId: instructorId ?? this.instructorId,
      workerId: workerId ?? this.workerId,
      date: date ?? this.date,
      motif: motif ?? this.motif,
      lieu: lieu ?? this.lieu,
      heure: heure ?? this.heure,
      createdAt: createdAt ?? this.createdAt,
      monitorIds: monitorIds ?? this.monitorIds,
    );
  }

  String get displayLabel {
    final lieuPart = (lieu != null && lieu!.isNotEmpty) ? ' • $lieu' : '';
    return '$motif$lieuPart';
  }
}
