import 'package:cloud_firestore/cloud_firestore.dart';

class ConsumableRecord {
  final String id; // optional local id, can be Firestore id
  final DateTime date;
  final String produit;
  final int quantite;
  final String category;     // ex: "villa", "home_of_life"
  final String elementName;  // ex: "T4", "Caisse"
  final Timestamp createdAt;

  ConsumableRecord({
    required this.id,
    required this.date,
    required this.produit,
    required this.quantite,
    required this.category,
    required this.elementName,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'produit': produit,
      'quantite': quantite,
      'category': category,
      'elementName': elementName,
      'createdAt': createdAt,
    };
  }

  factory ConsumableRecord.fromFirestore(String id, Map<String, dynamic> data) {
    return ConsumableRecord(
      id: id,
      date: (data['date'] as Timestamp).toDate(),
      produit: data['produit'] ?? '',
      quantite: (data['quantite'] is int) ? data['quantite'] : int.tryParse('${data['quantite']}') ?? 0,
      category: data['category'] ?? '',
      elementName: data['elementName'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
