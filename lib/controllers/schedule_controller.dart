import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ScheduleController extends ChangeNotifier {
  /// Charge tous les events depuis Firestore
  Future<List<Map<String, dynamic>>> loadAllEvents() async {
    final eventsSnapshot =
        await FirebaseFirestore.instance.collection('events').get();

    final events = eventsSnapshot.docs.map((doc) {
      final data = doc.data();
      dynamic subPlace = data['subPlace'];
      if (subPlace == null) {
        subPlace = <String>[];
      } else if (subPlace is String) {
        if (subPlace.trim().isEmpty || subPlace.trim() == '[]') {
          subPlace = <String>[];
        } else {
          subPlace = [subPlace];
        }
      } else if (subPlace is! List) {
        subPlace = <String>[];
      }

      return {
        'id': doc.id,
        'day': (data['day'] as Timestamp).toDate(),
        'timeSlot': data['timeSlot'] ?? 'morning',
        'place': data['place'] ?? '',
        'subPlace': subPlace,
        'task': data['task'] ?? '',
        'workerIds': List<String>.from(data['workerIds'] ?? []),
        'isWeeklyTask': data['isWeeklyTask'] ?? true,
      };
    }).toList();

    return [...events];
  }
}
