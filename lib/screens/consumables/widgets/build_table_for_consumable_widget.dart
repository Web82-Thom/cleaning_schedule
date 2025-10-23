import 'dart:io';
import 'package:cleaning_schedule/controllers/pdf_controller.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';

class BuildTableForConsumableWidget extends StatefulWidget {
  final String title;           // Ex: "Villa" / "Home Of Life"
  final String fileNamePrefix;  // Ex: "villa", "foyerDeVie"
  final String elementName;     // Ex: "T5", "Caisse"
  final String routePdfList;    // Route vers la liste PDF correspondante

  const BuildTableForConsumableWidget({
    super.key,
    required this.title,
    required this.fileNamePrefix,
    required this.elementName,
    required this.routePdfList,
  });

  @override
  State<BuildTableForConsumableWidget> createState() => _BuildTableForConsumableWidgetState();
}

class _BuildTableForConsumableWidgetState extends State<BuildTableForConsumableWidget> {
  List<Map<String, dynamic>> _records = [];
  final PdfController pdfController = PdfController();
  

  @override
  void initState() {
    super.initState();
    _loadConsumablesFirestore();
  }

  /// 🔹 GÉNÉRATION DU PDF
  Future<void> _generatePdf(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Exporter en PDF'),
      content: Text(
          'Voulez-vous générer le PDF ${widget.title} ${widget.elementName} ?'),
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

  if (confirmed != true) return;

  try {
    final pdf = pw.Document();

    final now = DateTime.now();
    final formattedDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    // 🔹 (Optionnel) Chemin du logo local ou réseau
    final logoData = await rootBundle.load('assets/icon/app_icon.png'); // <-- Mets ton logo ici
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    // 🔹 PAGE DE GARDE
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Image(logoImage, width: 100, height: 100),
              pw.SizedBox(height: 24),
              pw.Text(
                widget.title,
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                widget.elementName,
                style: const pw.TextStyle(fontSize: 18),
              ),
              pw.SizedBox(height: 30),
              pw.Text(
                'Rapport de consommation',
                style: pw.TextStyle(
                  fontSize: 20,
                  color: PdfColors.indigo800,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Exporté le $formattedDate',
                style: const pw.TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );

    // 🔹 PAGE DE DONNÉES
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerLeft,
          margin: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                '${widget.title} - ${widget.elementName}',
                style: pw.TextStyle(
                  color: PdfColors.indigo,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              pw.Text(
                formattedDate,
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Page ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ),
        build: (pw.Context context) {
          final List<List<String>> rows = [];

          for (final record in _records) {
            final date = record['date'] ?? '';
            final List<Map<String, dynamic>> produits =
    (record['produits'] as List?)?.cast<Map<String, dynamic>>() ?? [];

            for (final produit in produits) {
              rows.add([
                date,
                produit['nom'] ?? '',
                produit['quantite'] ?? '',
              ]);
            }
          }

          return [
            pw.Table.fromTextArray(
              headers: ['Date', 'Produit', 'Quantité'],
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              data: rows,
            ),
            pw.SizedBox(height: 20),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Généré automatiquement le $formattedDate',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ),
          ];
        },
      ),
    );

    // 🔹 Sauvegarde locale
    final dir = await getApplicationDocumentsDirectory();
    final safePrefix =
        widget.fileNamePrefix.toLowerCase().replaceAll(' ', '_');
    final safeElement =
        widget.elementName.toLowerCase().replaceAll(' ', '_');
    final file = File('${dir.path}/conso_${safePrefix}_$safeElement.pdf');

    if (await file.exists()) await file.delete();
    await file.writeAsBytes(await pdf.save());

    await OpenFilex.open(file.path);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'PDF généré et sauvegardé : ${file.path.split('/').last} ✅'),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la génération PDF : $e')),
      );
    }
  }
}

  /// 🔹 CHARGEMENT DES DONNÉES
  Future<void> _loadConsumablesFirestore() async {
    final doc = await FirebaseFirestore.instance
        .collection('consumables')
        .doc('${widget.fileNamePrefix}_${widget.elementName}')
        .get();

    if (doc.exists && doc.data()?['records'] != null) {
      final records = List<Map<String, dynamic>>.from(doc.data()!['records']);
      setState(() {
        _records = records
            .map((r) => {
                  'date': r['date'] ?? '',
                  'produit': r['produit'] ?? '',
                  'quantite': r['quantite']?.toString() ?? '',
                })
            .toList();
      });
    }
  }

  /// 🔹 Sauvegarde améliorée avec détection du type d’action
Future<void> _saveConsumablesToFirestore({
  String? action, // "ajout", "modif", "suppression"
}) async {
  try {
    await FirebaseFirestore.instance
        .collection('consumables')
        .doc('${widget.fileNamePrefix}_${widget.elementName}')
        .set({
      'records': _records,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    String msg = 'Enregistré sur Firestore ✅';
    if (action == 'ajout') msg = 'Consommable ajouté ✅';
    if (action == 'modif') msg = 'Consommable modifié ✅';
    if (action == 'suppression') msg = 'Consommable supprimé ✅';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de sauvegarde : $e')),
      );
    }
  }
}


  /// 🔹 DIALOGUE D'AJOUT / MODIF
Future<void> _recordDialog({int? index}) async {
  final dateController = TextEditingController(
    text: index != null ? _records[index]['date'] : '',
  );

  // 🔹 On récupère la liste des produits existants (sinon on crée une liste vide)
  List<Map<String, String>> produits = [];
  if (index != null && _records[index]['produits'] != null) {
    produits = List<Map<String, String>>.from(_records[index]['produits']);
  } else {
    produits.add({'nom': '', 'quantite': ''});
  }

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(index == null
                ? 'Ajouter un consommable'
                : 'Modifier le consommable'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9, // 🔹 plein écran
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Date
                    TextField(
                      controller: dateController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Date'),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
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
                    const SizedBox(height: 12),

                    // 🔹 Liste dynamique produits + quantités
                    Column(
                      children: [
                        for (int i = 0; i < produits.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    decoration: const InputDecoration(
                                        labelText: 'Produit'),
                                    onChanged: (v) =>
                                        produits[i]['nom'] = v.trim(),
                                    controller: TextEditingController(
                                        text: produits[i]['nom']),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    decoration: const InputDecoration(
                                        labelText: 'Quantité'),
                                    keyboardType: TextInputType.number,
                                    onChanged: (v) =>
                                        produits[i]['quantite'] = v.trim(),
                                    controller: TextEditingController(
                                        text: produits[i]['quantite']),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle,
                                      color: Colors.red),
                                  onPressed: () {
                                    setStateDialog(() {
                                      produits.removeAt(i);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () {
                              setStateDialog(() {
                                produits.add({'nom': '', 'quantite': ''});
                              });
                            },
                            icon: const Icon(Icons.add, color: Colors.indigo),
                            label: const Text('Ajouter un produit'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              if (index != null)
                TextButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c2) => AlertDialog(
                        title: const Text('Supprimer cette fiche ?'),
                        content: const Text(
                            'Voulez-vous vraiment supprimer ce consommable ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c2, false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(c2, true),
                            child: const Text('Supprimer',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      Navigator.pop(ctx);
                      setState(() {
                        _records.removeAt(index);
                      });
                      await _saveConsumablesToFirestore(action: 'suppression');
                    }
                  },
                  child: const Text('Supprimer',
                      style: TextStyle(color: Colors.red)),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  setState(() {
                    final data = {
                      'date': dateController.text,
                      'produits': produits,
                    };
                    if (index != null) {
                      _records[index] = data;
                    } else {
                      _records.add(data);
                    }
                  });
                  await _saveConsumablesToFirestore(
                    action: index != null ? 'modif' : 'ajout',
                  );
                },
                child: const Text('Valider'),
              ),
            ],
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title} - ${widget.elementName}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        onPressed: () => _recordDialog(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // 🔹 HEADER FIXE (PDF + Liste)
          Container(
            color: Colors.indigo.shade50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf,
                      color: Colors.indigo, size: 30),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Appui long pour créer un PDF.')),
                  ),
                  onLongPress: () => _generatePdf(context),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    widget.routePdfList,
                    arguments: {
                      'title': widget.title,
                      'fileNamePrefix': widget.fileNamePrefix,
                      'elementName': widget.elementName,
                    },
                  ),
                  child: const Text(
                    'Liste PDF',
                    style: TextStyle(color: Colors.indigo),
                  ),
                ),
              ],
            ),
          ),

          // 🔹 EN-TÊTE DU TABLEAU
          Container(
            color: Colors.indigo.shade100,
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 3, child: Text('Produit', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text('Qté', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),

          // 🔹 LISTE DÉFILANTE
          Expanded(
            child: _records.isEmpty
              ? const Center(child: Text('Aucun consommable'))
              : ListView.builder(
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final record = _records[index];
                    final List<Map<String, dynamic>> produits =
                        (record['produits'] as List?)?.cast<Map<String, dynamic>>() ?? [];

                    return InkWell(
                      onDoubleTap: () => _recordDialog(index: index),
                      onLongPress: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Supprimer cette fiche'),
                            content: const Text('Voulez-vous vraiment supprimer cette fiche ?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text(
                                  'Supprimer',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          setState(() {
                            _records.removeAt(index);
                          });
                          await _saveConsumablesToFirestore(action: 'suppression');
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔹 Date
                              Expanded(
                                flex: 2,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    record['date'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                ),
                              ),

                              // 🔹 Produits
                              Expanded(
                                flex: 3,
                                child: produits.isEmpty
                                    ? const Text('—', style: TextStyle(color: Colors.grey))
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: produits
                                            .map(
                                              (p) => Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(vertical: 2),
                                                child: Text('• ${p['nom'] ?? ''}'),
                                              ),
                                            )
                                            .toList(),
                                      ),
                              ),

                              // 🔹 Quantités
                              Expanded(
                                flex: 1,
                                child: produits.isEmpty
                                    ? const Text('—',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.grey))
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: produits
                                            .map(
                                              (p) => Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(vertical: 2),
                                                child: Text(
                                                  p['quantite']?.toString() ?? '',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.w600),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
