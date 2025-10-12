import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final DateTime day;              // Date de l'événement
  final String timeSlot;           // "morning" ou "afternoon"
  final String place;              // Lieu principal
  final String? subPlace;          // Sous-lieu (optionnel)
  final String task;               // Tâche à effectuer
  final List<String> workerIds;    // Liste des IDs des travailleurs
  final Timestamp createdAt;       // Date de création Firestore

  EventModel({
    required this.id,
    required this.day,
    required this.timeSlot,
    required this.place,
    this.subPlace,
    required this.task,
    required this.workerIds,
    required this.createdAt,
  });

  /// Crée un EventModel à partir d'un document Firestore
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      day: (data['day'] as Timestamp).toDate(),
      timeSlot: data['timeSlot'] ?? 'morning',
      place: data['place'] ?? '',
      subPlace: data['subPlace'],
      task: data['task'] ?? '',
      workerIds: List<String>.from(data['workers'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  /// Convertit l'objet EventModel en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'day': Timestamp.fromDate(day),
      'timeSlot': timeSlot,
      'place': place,
      'subPlace': subPlace,
      'task': task,
      'workers': workerIds,
      'createdAt': createdAt,
    };
  }
}
