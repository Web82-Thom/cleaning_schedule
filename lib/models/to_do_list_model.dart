import 'package:cloud_firestore/cloud_firestore.dart';

class ToDoListModel {
  final String id;
  final String userId;          // Créateur de la tâche
  final String date;            // Date/heure ou texte temporaire
  final String note;            // Note associée
  final bool checked;           // Case cochée
  final String checkedById;     // UID de celui qui a coché
  final String checkedByName;   // Initiales de celui qui a coché
  final Timestamp createdAt;

  ToDoListModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.note,
    this.checked = false,
    this.checkedById = '',
    this.checkedByName = '',
    required this.createdAt,
  });

  factory ToDoListModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ToDoListModel(
      id: id,
      userId: data['userId'] ?? '',
      date: data['date'] ?? '',
      note: data['note'] ?? '',
      checked: data['checked'] ?? false,
      checkedById: data['checkedById'] ?? '',
      checkedByName: data['checkedByName'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'date': date,
      'note': note,
      'checked': checked,
      'checkedById': checkedById,
      'checkedByName': checkedByName,
      'createdAt': createdAt,
    };
  }

  ToDoListModel copyWith({
    String? id,
    String? userId,
    String? date,
    String? note,
    bool? checked,
    String? checkedById,
    String? checkedByName,
    Timestamp? createdAt,
  }) {
    return ToDoListModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      note: note ?? this.note,
      checked: checked ?? this.checked,
      checkedById: checkedById ?? this.checkedById,
      checkedByName: checkedByName ?? this.checkedByName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
