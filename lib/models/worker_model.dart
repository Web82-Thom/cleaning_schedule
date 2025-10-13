import 'package:cleaning_schedule/models/user_model.dart';

class WorkerModel extends UserModel {
  final String? lieuId;
  final String? monitriceId;
  final String statut; 

  WorkerModel({
    required super.id,
    required super.nom,
    required super.prenom,
    required super.email,
    this.lieuId,
    this.monitriceId,
    this.statut = 'Plein temps',
  }) : super(role: 'WorkerModel');

  factory WorkerModel.fromMap(Map<String, dynamic> data, String id) {
    return WorkerModel(
      id: id,
      nom: data['nom'] ?? '',
      prenom: data['prenom'] ?? '',
      email: data['email'] ?? '',
      lieuId: data['lieuId'],
      monitriceId: data['monitriceId'],
      statut: data['statut'] ?? 'Plein temps',
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'lieuId': lieuId,
      'monitriceId': monitriceId,
      'statut': statut,
    });
    return map;
  }
}
