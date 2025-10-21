import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';

class PdfController extends ChangeNotifier {
  /// Génère le PDF du planning hebdomadaire
  static Future<void> generateWeeklyPdf({
    required List<Map<String, dynamic>> events,
    required Map<String, String> workersMap,
    required int weekNumber,
  }) async {
    final pdf = pw.Document();

    final days = events.map((e) => e['day'] as DateTime).toSet().toList()..sort();

    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var e in events) {
      final key = '${DateFormat('yyyy-MM-dd').format(e['day'])}_${e['timeSlot']}';
      grouped.putIfAbsent(key, () => []).add(e);
    }

    const int maxEventsPerCell = 6;

    pw.Widget buildEventList(List<Map<String, dynamic>> list, int startIndex) {
      if (list.isEmpty) return pw.Text('—', style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10));
      final sublist = list.skip(startIndex).take(maxEventsPerCell).toList();

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: sublist.map((e) {
          final workers = (e['workerIds'] as List).map((id) => workersMap[id] ?? 'Inconnu').join(', ');

          String subPlaceText = '';
          if (e['subPlace'] != null) {
            if (e['subPlace'] is List) {
              subPlaceText = (e['subPlace'] as List).whereType<String>().join(', ');
              if (subPlaceText.isNotEmpty) subPlaceText = ' ($subPlaceText)';
            } else if (e['subPlace'] is String && e['subPlace'].trim().isNotEmpty) {
              subPlaceText = ' (${e['subPlace']})';
            }
          }

          final taskText = (e['task'] != null && e['task'].toString().isNotEmpty) ? ' • ${e['task']}' : '';

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                e['place'] ?? 'Lieu inconnu',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue800, fontSize: 11),
              ),
              if (subPlaceText.isNotEmpty)
                pw.Text(subPlaceText, style: const pw.TextStyle(color: PdfColors.indigo, fontSize: 10)),
              if (taskText.isNotEmpty)
                pw.Text(taskText, style: const pw.TextStyle(color: PdfColors.deepPurple, fontSize: 10)),
              pw.Text('Travailleurs : $workers', style: const pw.TextStyle(color: PdfColors.grey800, fontSize: 9)),
              pw.SizedBox(height: 4),
            ],
          );
        }).toList(),
      );
    }

    for (var slot in ['morning', 'afternoon']) {
      int maxChunks = 1;
      Map<String, int> dayChunks = {};

      for (var day in days) {
        final key = '${DateFormat('yyyy-MM-dd').format(day)}_$slot';
        final count = grouped[key]?.length ?? 0;
        final chunks = (count / maxEventsPerCell).ceil();
        dayChunks[key] = chunks;
        if (chunks > maxChunks) maxChunks = chunks;
      }

      for (int chunkIndex = 0; chunkIndex < maxChunks; chunkIndex++) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4.landscape,
            margin: const pw.EdgeInsets.all(16),
            build: (context) => [
              pw.Text(
                '${slot == 'morning' ? 'MATIN' : 'APRÈS-MIDI'} - Semaine $weekNumber',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: slot == 'morning' ? PdfColors.orange800 : PdfColors.teal800,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
                columnWidths: {for (int i = 0; i < days.length; i++) i: const pw.FlexColumnWidth()},
                children: [
                  pw.TableRow(
                    children: days.map((day) {
                      final label = DateFormat('EEEE', 'fr_FR').format(day).toUpperCase();
                      return pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Center(child: pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green, fontSize: 12))),
                      );
                    }).toList(),
                  ),
                  pw.TableRow(
                    children: days.map((day) {
                      final key = '${DateFormat('yyyy-MM-dd').format(day)}_$slot';
                      return pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: buildEventList(grouped[key] ?? [], chunkIndex * maxEventsPerCell),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'planning_week_$weekNumber.pdf';
    final file = File('${dir.path}/scheduleWeeklyCategory/$fileName');
    if (!await file.parent.exists()) await file.parent.create(recursive: true);
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }
  
  ///---------Float message for created PDF---------
  void showFloatingMessage(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    // if (overlay == null) return;

    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: MediaQuery.of(context).size.width * 0.2,
        width: MediaQuery.of(context).size.width * 0.6,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  /// ___________________________________________________ 
  ///|   ---------------PRODUCTS------------------------ |
  ///|___________________________________________________|
  /// Génère un PDF pour un produit
  Future<void> generateListProductByNamePdf(
    String productName, List<Map<String, dynamic>> records) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (context) {
        return pw.Column(
          children: [
            pw.Text(
              'Relevés pour $productName',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Lieu'],
              data: records.map((r) => [r['date'] ?? '', r['place'] ?? '']).toList(),
              cellAlignment: pw.Alignment.centerLeft, // optionnel, style des cellules
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: pw.BoxDecoration(color: PdfColors.blue200),
              cellHeight: 25,
            ),
          ],
        );
      },
    ),
  );

  final pdfBytes = await pdf.save();
  await savePdfToProductsCategory(productName, pdfBytes);
}

  /// Enregistre le PDF dans le dossier productsCategory
  Future<File> savePdfToProductsCategory(String productName, List<int> pdfBytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final categoryDir = Directory('${dir.path}/productsCategory');
    if (!await categoryDir.exists()) await categoryDir.create(recursive: true);

    final file = File('${categoryDir.path}/$productName.pdf');
    await file.writeAsBytes(pdfBytes, flush: true);
    notifyListeners();
    print('PDF généré : ${file.path}');
    return file;
  }

  /// Supprime un PDF dans le dossier productsCategory avec confirmation
  Future<void> deletePdfFromProductsCategory(BuildContext context, String productName) async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    final categoryDir = Directory('${dir.path}/productsCategory');
    
    // Nettoyage du nom du fichier (évite le ".pdf.pdf")
    final cleanName = productName.endsWith('.pdf') 
        ? productName 
        : '$productName.pdf';

    final file = File('${categoryDir.path}/$cleanName');

    if (await file.exists()) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmation'),
          content: Text('Supprimer le fichier "$cleanName" ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await file.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Fichier "$cleanName" supprimé')),
        );
        notifyListeners();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Le fichier "$cleanName" n’existe pas')),
      );
    }
  } catch (e) {
    debugPrint('Erreur lors de la suppression du PDF : $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erreur lors de la suppression ❌')),
    );
  }
}


  //____________________________________________________ 
  //|   ---------------CARS------------------------     |
  //|___________________________________________________|
  /// Génère un PDF pour un véhicule
  /// Génère un PDF clair et structuré pour un véhicule
  Future<void> generateListCarByNamePdf(
    String carName,
    List<Map<String, dynamic>> records,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(20),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              'Relevé kilométrique - $carName',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          ),
          pw.SizedBox(height: 20),

          // ✅ Tableau amélioré et bien formaté
          pw.TableHelper.fromTextArray(
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey500),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
            headerHeight: 25,
            cellHeight: 22,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
            },
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
              color: PdfColors.blue900,
            ),
            cellStyle: const pw.TextStyle(fontSize: 11),
            headers: ['Mois', 'Relevé km', 'Résultat km'],
            data: records.map((r) {
              return [
                r['month'] ?? '',
                (r['value'] != null && r['value'].toString().isNotEmpty)
                    ? r['value']
                    : '-',
                r['diff'] ?? '-',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Généré le ${DateFormat("dd/MM/yyyy à HH:mm", "fr_FR").format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );

    // 🔹 Sauvegarde dans "carsCategory"
    final pdfBytes = await pdf.save();
    final file = await savePdfToCarsCategory(carName, pdfBytes);

    // 🔹 Ouvre le fichier directement
    await OpenFilex.open(file.path);

    debugPrint('✅ PDF généré pour $carName : ${file.path}');
  }

  ///---------Send to firebase---------------
  Future<File> savePdfToCarsCategory(String carName, List<int> pdfBytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final categoryDir = Directory('${dir.path}/carsCategory');

    // Crée le dossier s'il n'existe pas
    if (!await categoryDir.exists()) {
      await categoryDir.create(recursive: true);
    }

    final cleanName = carName.endsWith('.pdf') ? carName : '$carName.pdf';
    final file = File('${categoryDir.path}/$cleanName');
    await file.writeAsBytes(pdfBytes, flush: true);

    print('PDF généré : ${file.path}');
    notifyListeners();
    return file;
  }

  ///---------Supprime un PDF dans le dossier carsCategory avec confirmation-------------
  Future<void> deletePdfFromCarsCategory(BuildContext context, String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final categoryDir = Directory('${dir.path}/carsCategory');
      final file = File('${categoryDir.path}/$fileName');

      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Le fichier "$fileName" n\'existe pas.')),
        );
        return;
      }

      await file.delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF "$fileName" supprimé avec succès 🗑️')),
        );
      }

      notifyListeners();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression : $e')),
        );
      }
      debugPrint('Erreur suppression PDF carsCategory : $e');
    }
  }

}
