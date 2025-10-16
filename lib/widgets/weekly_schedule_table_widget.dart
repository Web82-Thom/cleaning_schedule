import 'dart:io';
import 'package:cleaning_schedule/screens/list_pdf_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cleaning_schedule/screens/planning/edit_event_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';

class WeeklyScheduleTableWidget extends StatefulWidget {
  final DateTime initialWeek;

  const WeeklyScheduleTableWidget({super.key, required this.initialWeek});

  @override
  State<WeeklyScheduleTableWidget> createState() =>
      _WeeklyScheduleTableWidgetState();
}

class _WeeklyScheduleTableWidgetState extends State<WeeklyScheduleTableWidget> {
  late DateTime _startOfWeek;
  late DateTime _endOfWeek;

  Map<String, String> _workersMap = {}; // workerId → workerName

  @override
  void initState() {
    super.initState();
    _startOfWeek = _getStartOfWeek(widget.initialWeek);
    _endOfWeek = _startOfWeek.add(const Duration(days: 4));
    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('workers')
        .where('active', isEqualTo: true)
        .get();

    if (!mounted) return;

    setState(() {
      _workersMap = {
        for (var doc in snapshot.docs)
          doc.id: '${doc['firstName']} ${doc['name']}',
      };
    });
  }

  DateTime _getStartOfWeek(DateTime date) =>
      date.subtract(Duration(days: date.weekday - 1));

  List<DateTime> get _weekDays =>
      List.generate(5, (i) => _startOfWeek.add(Duration(days: i)));

  int get _weekNumber => _getWeekNumber(_startOfWeek);

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysOffset = firstDayOfYear.weekday - DateTime.monday;
    final firstMonday = firstDayOfYear.subtract(Duration(days: daysOffset));
    return ((date.difference(firstMonday).inDays) / 7).ceil() + 1;
  }

  void _nextWeek() {
    setState(() {
      _startOfWeek = _startOfWeek.add(const Duration(days: 7));
      _endOfWeek = _startOfWeek.add(const Duration(days: 4));
    });
  }

  void _previousWeek() {
    setState(() {
      _startOfWeek = _startOfWeek.subtract(const Duration(days: 7));
      _endOfWeek = _startOfWeek.add(const Duration(days: 4));
    });
  }

  Future<void> _generateWeeklyPdf(List<Map<String, dynamic>> events) async {
    final pdf = pw.Document();

    // Jours de la semaine
    final days = _weekDays;
    final dayLabels =
        days.map((d) => DateFormat('EEEE', 'fr_FR').format(d)).toList();

    // Grouper les événements par jour + créneau
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var e in events) {
      final key =
          '${DateFormat('yyyy-MM-dd').format(e['day'])}_${e['timeSlot']}';
      grouped.putIfAbsent(key, () => []).add(e);
    }

    // Fonction de formatage avec couleurs
    pw.Widget buildEventList(List<Map<String, dynamic>> list) {
      if (list.isEmpty) {
        return pw.Text('—', style: const pw.TextStyle(color: PdfColors.grey));
      }
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: list.map((e) {
          final workers = (e['workerIds'] as List)
              .map((id) => _workersMap[id] ?? 'Inconnu')
              .join(', ');
          final subPlace = (e['subPlace'] != null && e['subPlace'] != '')
              ? ' (${e['subPlace']})'
              : '';
          final task = (e['task'] != null && e['task'] != '')
              ? '\nTâche : ${e['task']}'
              : '';

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 6),
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: e['place'] ?? 'Lieu inconnu',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                      fontSize: 11,
                    ),
                  ),
                  if (subPlace.isNotEmpty)
                    pw.TextSpan(
                      text: subPlace,
                      style: const pw.TextStyle(color: PdfColors.indigo),
                    ),
                  if (task.isNotEmpty)
                    pw.TextSpan(
                      text: task,
                      style: const pw.TextStyle(color: PdfColors.deepPurple),
                    ),
                  pw.TextSpan(
                    text: '\nTravailleurs : $workers',
                    style: const pw.TextStyle(color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }

    // Fonction pour une page (matin ou après-midi)
    pw.MultiPage buildPage(String title, String slot) {
      return pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return [
            pw.Text(
              'Planning semaine $_weekNumber - $title',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: slot == 'morning' ? PdfColors.orange800 : PdfColors.teal800,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Du ${DateFormat('dd/MM').format(_startOfWeek)} au ${DateFormat('dd/MM').format(_endOfWeek)}',
              style: const pw.TextStyle(color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 20),

            // Tableau
            pw.Table(
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
              columnWidths: {
                for (int i = 0; i < days.length; i++)
                  i: const pw.FlexColumnWidth(),
              },
              children: [
                // Ligne des jours
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: dayLabels
                      .map(
                        (label) => pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Center(
                            child: pw.Text(
                              label.toUpperCase(),
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.green,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                // Ligne du contenu
                pw.TableRow(
                  children: days.map((day) {
                    final key =
                        '${DateFormat('yyyy-MM-dd').format(day)}_$slot';
                    final eventsForDay = grouped[key] ?? [];
                    return pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: buildEventList(eventsForDay),
                    );
                  }).toList(),
                ),
              ],
            ),
          ];
        },
      );
    }

    // Génération des deux pages
    pdf.addPage(buildPage('MATIN', 'morning'));
    pdf.addPage(buildPage('APRÈS-MIDI', 'afternoon'));

    // Sauvegarde du fichier
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'planning_week_$_weekNumber.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    await OpenFilex.open(file.path);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF généré : $fileName ✅')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _weekDays;
    final title =
        'Semaine $_weekNumber — du ${DateFormat('dd/MM').format(_startOfWeek)} au ${DateFormat('dd/MM').format(_endOfWeek)}';

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where(
            'day',
            isGreaterThanOrEqualTo: Timestamp.fromDate(
              DateTime(
                _startOfWeek.year,
                _startOfWeek.month,
                _startOfWeek.day,
                0,
                0,
                0,
              ),
            ),
          )
          .where(
            'day',
            isLessThanOrEqualTo: Timestamp.fromDate(
              DateTime(
                _endOfWeek.year,
                _endOfWeek.month,
                _endOfWeek.day,
                23,
                59,
                59,
              ),
            ),
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final events = snapshot.data!.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'day': (data['day'] as Timestamp).toDate(),
            'timeSlot': data['timeSlot'],
            'place': data['place'],
            'subPlace': data['subPlace'],
            'task': data['task'],
            'workerIds': List<String>.from(data['workerIds'] ?? []),
          };
        }).toList();
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                // 🟢 Bouton PDF
                IconButton(
                  icon: const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.redAccent,
                  ),
                  tooltip: 'Voir les PDF enregistrés',
                  onLongPress: () async {
                    // Affiche le dialogue de confirmation
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text(
                          'Exporter en PDF',
                          style: TextStyle(fontSize: 14),
                        ),
                        content: Text(
                          'Voulez-vous générer le PDF du planning de la semaine $_weekNumber ?',
                        ),
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
                      _generateWeeklyPdf(events);
                    }
                  },
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ListPdfPage()),
                    );
                  },
                ),
                const SizedBox(width: 8),

                // 🟢 Texte de la semaine + swipe
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        // const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Semaine précédente',
                onPressed: _previousWeek,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Semaine suivante',
                onPressed: _nextWeek,
              ),
            ],
          ),

          body: StreamBuilder<QuerySnapshot>(
            // 🔹 Nouvelle requête : filtre par date, plus par numéro de semaine
            stream: FirebaseFirestore.instance
                .collection('events')
                .where(
                  'day',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(
                    DateTime(
                      _startOfWeek.year,
                      _startOfWeek.month,
                      _startOfWeek.day,
                      0,
                      0,
                      0,
                    ),
                  ),
                )
                .where(
                  'day',
                  isLessThanOrEqualTo: Timestamp.fromDate(
                    DateTime(
                      _endOfWeek.year,
                      _endOfWeek.month,
                      _endOfWeek.day,
                      23,
                      59,
                      59,
                    ),
                  ),
                )
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final events = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {
                  'id': doc.id,
                  'day': (data['day'] as Timestamp).toDate(),
                  'timeSlot': data['timeSlot'],
                  'place': data['place'],
                  'subPlace': data['subPlace'],
                  'task': data['task'],
                  'workerIds': List<String>.from(data['workerIds'] ?? []),
                };
              }).toList();

              // 🔹 Grouper les events par jour + créneau
              Map<String, List<Map<String, dynamic>>> grouped = {};
              for (var e in events) {
                final key =
                    '${DateFormat('yyyy-MM-dd').format(e['day'])}_${e['timeSlot']}';
                grouped.putIfAbsent(key, () => []).add(e);
              }

              return InteractiveViewer(
                panEnabled: true,
                scaleEnabled: true,
                minScale: 0.5,
                maxScale: 2.0,
                constrained: false,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 En-tête des jours
                      Row(
                        children: [
                          const SizedBox(width: 40),
                          ...days.map(
                            (d) => Container(
                              width: 180,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                DateFormat(
                                  'EEEE',
                                  'fr_FR',
                                ).format(d).toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 🔹 Matin / Après-midi
                      for (var period in ['morning', 'afternoon'])
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 330,
                              color: Colors.grey.shade300,
                              child: Center(
                                child: Transform.rotate(
                                  angle: -3.14 / 2,
                                  child: Text(
                                    period == 'morning'
                                        ? 'MATIN'
                                        : 'APRÈS-MIDI',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                    softWrap: false,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ),
                            ),
                            ...days.map((day) {
                              final key =
                                  '${DateFormat('yyyy-MM-dd').format(day)}_$period';
                              final cellEvents = grouped[key] ?? [];

                              return Container(
                                width: 180,
                                height: 330,
                                margin: const EdgeInsets.all(2),
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: period == 'morning'
                                      ? Colors.blue.shade100
                                      : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: cellEvents.isEmpty
                                ? const Center(
                                    child: Text(
                                      '—',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                  )
                                : Stack(
                                    children: [
                                      ListView(
                                        children: cellEvents.map((e) {
                                          final sub = (e['subPlace'] != null && e['subPlace'] is List && (e['subPlace'] as List).isNotEmpty)
                                            ? ' ${(e['subPlace'] as List).join(", ")}'
                                            : '';
                                          final workerNames = e['workerIds']
                                              .map<String>((id) => _workersMap[id] ?? 'Inconnu')
                                              .join(', ');

                                          final place = e['place'] ?? 'Inconnu';
                                          final colorIndex = (place.hashCode % Colors.primaries.length);
                                          final baseColor = Colors.primaries[colorIndex].shade200;

                                          return InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => EditEventPage(eventId: e['id']),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.only(bottom: 6),
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: baseColor,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.black12),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '• $place',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  
                                                  if (sub.isNotEmpty) 
   Text(
    ' - $sub',
    style: const TextStyle(
      fontSize: 12,
      color: Colors.black87
    ),
  )
 else 
   const SizedBox.shrink(), // ne rien afficher si sub est vide

                                                  if (workerNames.isNotEmpty)
                                                  Text(
                                                      'Travailleurs:',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                    Text(
                                                      '$workerNames',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  Text(
                                                    e['task'] == '' ? '' : 'Tâche: ${e['task']}',
                                                    style: const TextStyle(fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),

                                      // 🔽 Petite flèche d'indication
                                      if (cellEvents.length > 3)
                                        const Positioned(
                                          bottom: 2,
                                          left: 0,
                                          right: 0,
                                          child: Center(
                                            child: Icon(
                                              Icons.keyboard_arrow_down,
                                              size: 25,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),

                              );
                            }),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
