import 'package:cleaning_schedule/controllers/pdf_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DetailsCarsPage extends StatefulWidget {
  final String carName;

  const DetailsCarsPage({super.key, required this.carName});

  @override
  State<DetailsCarsPage> createState() => _DetailsCarsPageState();
}

class _DetailsCarsPageState extends State<DetailsCarsPage> {
  int _selectedYear = DateTime.now().year;
  PdfController pdfController = PdfController();

  final List<String> months = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre'
  ];

  final Map<int, List<TextEditingController>> _controllersByYear = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers(_selectedYear);
  }

  void _initializeControllers(int year) {
    if (!_controllersByYear.containsKey(year)) {
      _controllersByYear[year] =
          List.generate(12, (_) => TextEditingController());
    }
    _loadDataFromFirestore(year);
  }

  Future<void> _loadDataFromFirestore(int year) async {
    final docId = '${widget.carName}_$year';
    final doc =
        await FirebaseFirestore.instance.collection('carsMileage').doc(docId).get();

    if (doc.exists && doc.data()?['records'] != null) {
      final records = Map<String, dynamic>.from(doc.data()!['records']);
      for (var i = 0; i < months.length; i++) {
        final month = months[i];
        _controllersByYear[year]![i].text = records[month]?.toString() ?? '';
      }
      setState(() {});
    }
  }

  Future<void> _saveDataToFirestore() async {
    final docId = '${widget.carName}_$_selectedYear';
    final records = {
      for (var i = 0; i < months.length; i++)
        months[i]: _controllersByYear[_selectedYear]![i].text,
    };

    await FirebaseFirestore.instance.collection('carsMileage').doc(docId).set({
      'carName': widget.carName,
      'year': _selectedYear,
      'records': records,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Relevés enregistrés sur Firestore ✅')),
      );
    }
  }

  void _changeYear(int delta) {
    setState(() {
      _selectedYear += delta;
      _initializeControllers(_selectedYear);
    });
  }

  /// Calcule les différences entre mois consécutifs
  List<String> _computeDifferences(List<TextEditingController> controllers) {
    List<String> diffs = [];
    for (var i = 0; i < controllers.length; i++) {
      final current = double.tryParse(controllers[i].text) ?? 0;
      final previous = i > 0 ? double.tryParse(controllers[i - 1].text) ?? 0 : 0;
      final diff = (current > 0 && previous > 0) ? (current - previous) : 0;
      diffs.add(diff > 0 ? diff.toStringAsFixed(0) : '-');
    }
    return diffs;
  }

  @override
  Widget build(BuildContext context) {
    final controllers = _controllersByYear[_selectedYear]!;
    final diffs = _computeDifferences(controllers);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeYear(-1),
              ),
              Expanded(child: Text('Année $_selectedYear', style: TextStyle(
                fontSize: 15,
              ),)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeYear(1),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Text(widget.carName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),),
                SizedBox(height: 5,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      onPressed: () {
                        pdfController.showFloatingMessage(context, 'Appui long pour creer un Pdf.');
                      },
                      onLongPress: () async {
                        final confirmed = await showDialog<bool>(
                          context: context, 
                          builder: (ctx) => AlertDialog(
                            title: const Text('Exporter en PDF'),
                            content: Text('Voulez-vous générer le PDF ${widget.carName}?'),
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

                        if (confirmed == true) {
                          // 🔹 Construction automatique des données à exporter
                          final _records = List.generate(
                            months.length,
                            (i) => {
                              'month': months[i],
                              'year': _selectedYear,
                              'value': _controllersByYear[_selectedYear]![i].text,
                              'diff': _computeDifferences(_controllersByYear[_selectedYear]!)[i],
                            },
                          );

                          await pdfController.generateListCarByNamePdf(widget.carName, _records);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('PDF généré pour la ${widget.carName} ✅')),
                            );
                          }
                        }
                        },
                        icon: Icon(Icons.picture_as_pdf),
                      ),
                      TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/listPdfCars');
                        print('open list');
                        
                      },
                      child: Text('list pdf'),
                    ),
                  ],
                ),
                SizedBox(height: 5,),
                Table(
                  border: TableBorder.all(color: Colors.black26),
                  columnWidths: const {
                    0: FlexColumnWidth(2), // Mois
                    1: FlexColumnWidth(2), // Relevé km
                    2: FlexColumnWidth(2), // Résultat km
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    // Ligne d'en-tête
                    TableRow(
                      decoration: BoxDecoration(color: Colors.blue.shade300),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Mois',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Relevé km',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Résultat km',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Lignes des mois avec alternance de couleurs
                    for (var i = 0; i < months.length; i++)
                    TableRow(
                      decoration: BoxDecoration(
                        color: i % 2 == 0 ? Colors.blue.shade50 : Colors.white70,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('${months[i]}-${_selectedYear.toString().substring(2)}', style: TextStyle(fontSize: 12),),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: controllers[i],
                            keyboardType: TextInputType.number,
                            style: TextStyle(fontSize: 12),
                            decoration: const InputDecoration(
                              hintText: 'km',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}), // recalcul live
                            onSubmitted: (_) async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Valider le kilométrage'),
                                  content: Text(
                                    'Voulez-vous enregistrer le relevé pour ${months[i]} ?'),
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
                              if (confirm == true) {
                                await _saveDataToFirestore();
                              }
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            diffs[i],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15,),
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
      ),
    );
  }
}
