import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';

class PdfController {
  /// Génère le PDF du planning
  static Future<void> generateWeeklyPdf({
    required List<Map<String, dynamic>> events,
    required Map<String, String> workersMap,
    required int weekNumber,
  }) async {
    final pdf = pw.Document();

    // Récupère tous les jours de la semaine à partir des events
    final days = events
        .map((e) => e['day'] as DateTime)
        .toSet()
        .toList()
      ..sort();

    // Grouper par jour + créneau
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var e in events) {
      final key =
          '${DateFormat('yyyy-MM-dd').format(e['day'])}_${e['timeSlot']}';
      grouped.putIfAbsent(key, () => []).add(e);
    }

    const int maxEventsPerCell = 6;

    // Fonction pour construire la liste d'events d'une cellule
    pw.Widget buildEventList(List<Map<String, dynamic>> list, int startIndex) {
      if (list.isEmpty) {
        return pw.Text(
          '—',
          style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10),
        );
      }

      final sublist = list.skip(startIndex).take(maxEventsPerCell).toList();

      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: sublist.map((e) {
          final workers = (e['workerIds'] as List)
              .map((id) => workersMap[id] ?? 'Inconnu')
              .join(', ');

          // Gestion subPlace propre
          String subPlaceText = '';
          if (e['subPlace'] != null) {
            if (e['subPlace'] is List) {
              subPlaceText =
                  (e['subPlace'] as List).whereType<String>().join(', ');
              if (subPlaceText.isNotEmpty) subPlaceText = ' ($subPlaceText)';
            } else if (e['subPlace'] is String && e['subPlace'].trim().isNotEmpty) {
              subPlaceText = ' (${e['subPlace']})';
            }
          }

          final taskText =
              (e['task'] != null && e['task'].toString().isNotEmpty)
                  ? ' • ${e['task']}'
                  : '';

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                e['place'] ?? 'Lieu inconnu',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                  fontSize: 11,
                ),
              ),
              if (subPlaceText.isNotEmpty)
                pw.Text(
                  subPlaceText,
                  style: const pw.TextStyle(
                    color: PdfColors.indigo,
                    fontSize: 10,
                  ),
                ),
              if (taskText.isNotEmpty)
                pw.Text(
                  taskText,
                  style: const pw.TextStyle(
                    color: PdfColors.deepPurple,
                    fontSize: 10,
                  ),
                ),
              pw.Text(
                'Travailleurs : $workers',
                style: const pw.TextStyle(
                  color: PdfColors.grey800,
                  fontSize: 9,
                ),
              ),
              pw.SizedBox(height: 4),
            ],
          );
        }).toList(),
      );
    }

    // Création des pages pour chaque créneau
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
            build: (context) {
              return [
                pw.Text(
                  '${slot == 'morning' ? 'MATIN' : 'APRÈS-MIDI'} - Semaine $weekNumber',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: slot == 'morning'
                        ? PdfColors.orange800
                        : PdfColors.teal800,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
                  columnWidths: {
                    for (int i = 0; i < days.length; i++)
                      i: const pw.FlexColumnWidth(),
                  },
                  children: [
                    pw.TableRow(
                      children: days.map((day) {
                        final label = DateFormat(
                          'EEEE',
                          'fr_FR',
                        ).format(day).toUpperCase();
                        return pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Center(
                            child: pw.Text(
                              label,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.green,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    pw.TableRow(
                      children: days.map((day) {
                        final key =
                            '${DateFormat('yyyy-MM-dd').format(day)}_$slot';
                        final eventsForDay = grouped[key] ?? [];
                        return pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: buildEventList(
                            eventsForDay,
                            chunkIndex * maxEventsPerCell,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ];
            },
          ),
        );
      }
    }

    // Sauvegarde et ouverture
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'planning_week_$weekNumber.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    await OpenFilex.open(file.path);
  }
}
