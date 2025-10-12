import 'package:cleaning_schedule/models/user_model.dart';

class InstructorModel extends UserModel {
  final List<String> lieuxSupervises; // IDs des lieux
  final List<String> travailleurs; // IDs des travailleurs encadrés

  InstructorModel({
    required super.id,
    required super.nom,
    required super.prenom,
    required super.email,
    this.lieuxSupervises = const [],
    this.travailleurs = const [],
  }) : super(role: 'monitrice');

  factory InstructorModel.fromMap(Map<String, dynamic> data, String id) {
    return InstructorModel(
      id: id,
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      email: data['email'] ?? '',
      lieuxSupervises: List<String>.from(data['lieuxSupervises'] ?? []),
      travailleurs: List<String>.from(data['travailleurs'] ?? []),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'lieuxSupervises': lieuxSupervises,
      'travailleurs': travailleurs,
    });
    return map;
  }
}
