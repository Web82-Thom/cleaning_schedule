import 'package:cleaning_schedule/controllers/pdf_controller.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailsProductPage extends StatefulWidget {
  final String productName;

  const DetailsProductPage({super.key, required this.productName});

  @override
  State<DetailsProductPage> createState() => _DetailsProductPageState();
}

class _DetailsProductPageState extends State<DetailsProductPage> {
  List<Map<String, dynamic>> _records = [];
  PdfController pdfController = PdfController();

  @override
  void initState() {
    super.initState();
    _loadProductsRecordsFirestore();
  }

  // Charger les données depuis Firestore
  Future<void> _loadProductsRecordsFirestore() async {
    final doc = await FirebaseFirestore.instance
      .collection('productsRecords')
      .doc(widget.productName)
      .get();

    if (doc.exists && doc.data()?['records'] != null) {
      final records = List<Map<String, dynamic>>.from(doc.data()!['records']);
      setState(() {
        _records = records.map((r) => {
          'date': r['date'] ?? '',
          'place': r['place'] ?? '',
        }).toList();
      });
    }
  }

  // Dialog pour ajouter ou modifier un relevé
  Future<void> _recordDialog({int? index}) async {
    final dateController = TextEditingController(text: index != null ? _records[index]['date'] : '');
    final placeController = TextEditingController(text: index != null ? _records[index]['place'] : '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(index == null ? 'Ajouter un relevé' : 'Modifier le relevé', style: const TextStyle(fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Date',
                hintText: 'jj/mm/aaaa',
                labelStyle: TextStyle(fontSize: 13),
              ),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: ctx,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  dateController.text =
                    '${picked.day.toString().padLeft(2, '0')}/'
                    '${picked.month.toString().padLeft(2, '0')}/'
                    '${picked.year}';
                }
              },
            ),
            TextField(
              controller: placeController,
              decoration: const InputDecoration(
                labelText: 'Lieu', labelStyle: TextStyle(fontSize: 13)),
            ),
          ],
        ),
        actions: [
          if (index != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (result == true) {
      if (dateController.text.isEmpty && placeController.text.isEmpty) return;

      setState(() {
        if (index != null) {
          _records[index] = {
            'date': dateController.text,
            'place': placeController.text,
          };
        } else {
          _records.add({
            'date': dateController.text,
            'place': placeController.text,
          });
        }
      });
      await _saveProductsRecordsToFirestore();
    } else if (index != null && result == false) {
      // Supprimer la ligne si appui long et "Supprimer"
      setState(() {
        _records.removeAt(index);
      });
      await _saveProductsRecordsToFirestore();
    }
  }

  ///----------- Send firebase productsRecords -----------
  Future<void> _saveProductsRecordsToFirestore() async {
    await FirebaseFirestore.instance
        .collection('productsRecords')
        .doc(widget.productName)
        .set({
      'records': _records,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enregistré sur Firestore ✅')),
      );
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.productName, style: TextStyle(fontSize: 20),),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.blue),
              onPressed: () => _recordDialog(),
            ),
          ],
        ),
        body: _records.isEmpty ?
        const Center(child: Text('Aucun relevé pour le moment')) :
        SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      onPressed: () {
                        pdfController.showFloatingMessage(context, 'Appui long pour creer un Pdf');
                      },
                      onLongPress: () async {
                        final confirmed = await showDialog<bool>(
                          context: context, 
                          builder: (ctx) => AlertDialog(
                            title: const Text('Exporter en PDF'),
                            content: Text('Voulez-vous générer le PDF ${widget.productName}?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Confirmer'),
                              ),
                            ],
                          ),
                        );
                        if(confirmed == true) {
                              pdfController.generateListProductByNamePdf(widget.productName, _records);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(
                              'PDF généré pour la ${widget.productName} ✅')),
                          );
                        }
                        print('Generated PDF');
                        // creer une function pour generer un pdf pour un mois, selection du mois , generer un pdf.
                        // la function sappel generateListProductByNamePdf, a mettre dans mon PdfController

                      }, 
                      icon: Icon(
                        Icons.picture_as_pdf,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/listPdfProducts');
                      },
                      child: Text('list pdf'),
                      ),
                  ],
                ),
              ),
              Table(
                border: TableBorder.all(color: Colors.black26),
                columnWidths: const {
                  0: FlexColumnWidth(2), // Date
                  1: FlexColumnWidth(3), // Lieu
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  // Header
                  TableRow(
                    decoration: BoxDecoration(color: Colors.blue.shade300),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Lieu', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Lignes dynamiques
                  for (var i = 0; i < _records.length; i++)
                    TableRow(
                      decoration: BoxDecoration(
                        color: i % 2 == 0 ? Colors.white : Colors.blue.shade50,
                      ),
                      children: [
                        InkWell(
                          onLongPress: () => _recordDialog(index: i),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(_records[i]['date'] ?? '', style: TextStyle(fontSize: 14),),
                          ),
                        ),
                        InkWell(
                          onLongPress: () => _recordDialog(index: i),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(_records[i]['place'] ?? '', style: TextStyle(fontSize: 14),),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
