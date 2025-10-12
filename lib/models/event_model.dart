import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final DateTime day;
  final String timeSlot;
  final String place;
  final String? subPlace;
  final String task;
  final List<String> workerIds;
  final Timestamp createdAt;
  final int weekNumber;

  EventModel({
    required this.id,
    required this.day,
    required this.timeSlot,
    required this.place,
    this.subPlace,
    required this.task,
    required this.workerIds,
    required this.createdAt,
    required this.weekNumber, 
  });

  Map<String, dynamic> toFirestore() => {
        'day': day,
        'timeSlot': timeSlot,
        'place': place,
        'subPlace': subPlace,
        'task': task,
        'workerIds': workerIds,
        'createdAt': createdAt,
        'weekNumber': weekNumber,
      };

  factory EventModel.fromFirestore(String id, Map<String, dynamic> data) {
    return EventModel(
      id: id,
      day: (data['day'] as Timestamp).toDate(),
      timeSlot: data['timeSlot'] ?? '',
      place: data['place'] ?? '',
      subPlace: data['subPlace'],
      task: data['task'] ?? '',
      workerIds: List<String>.from(data['workerIds'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      weekNumber: data['weekNumber'] ?? 0,
    );
  }
}
