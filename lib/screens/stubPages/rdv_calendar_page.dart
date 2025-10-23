import 'package:cleaning_schedule/controllers/auth_controller.dart';
import 'package:cleaning_schedule/controllers/rdv_controller.dart';
import 'package:cleaning_schedule/controllers/workers_controller.dart';
import 'package:cleaning_schedule/models/rdv_model.dart';
import 'package:cleaning_schedule/screens/rdvs/rdv_form_page.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class RdvCalendarPage extends StatefulWidget {
  const RdvCalendarPage({super.key});

  @override
  State<RdvCalendarPage> createState() => _RdvCalendarPageState();
}

class _RdvCalendarPageState extends State<RdvCalendarPage> {
  final RdvController _rdvController = RdvController();
  final WorkersController _workersController = WorkersController();
  final AuthController _authController = AuthController();

  Map<DateTime, List<RdvModel>> rdvEvents = {};
  Map<String, String> monitorsMap = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRdvs();
    _loadWorkers();
    _loadMonitors();
  }

  Future<void> _loadRdvs() async {
    setState(() => _loading = true);
    rdvEvents = await _rdvController.loadRdvs();
    if(!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _loadWorkers() async {
    await _workersController.loadWorkers();
    setState(() {});
  }

  Future<void> _loadMonitors() async {
    monitorsMap = await _authController.loadMonitorsMap();
    setState(() {});
  }

  List<RdvModel> _getEventsForDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return rdvEvents[d] ?? [];
  }

  Future<bool> _openRdvForm({RdvModel? rdv, DateTime? initialDate}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RdvFormPage(
          rdvData: rdv,
          initialDate: initialDate,
          workersMap: _workersController.workersMap,
          monitorsMap: monitorsMap,
        ),
      ),
    );
    return result == true;
  }

  String getRdvLabel(RdvModel rdv) {
    if (rdv.workerId == "TEAM") return "Équipe";
    if (rdv.workerId.isNotEmpty) {
      return _workersController.workersMap[rdv.workerId] ?? "Inconnu";
    }
    if (rdv.monitorIds.isNotEmpty) return "Moniteur(s)";
    return "Inconnu";
  }

  String getRdvSubtitle(RdvModel rdv) {
    String text = rdv.heure;
    if (rdv.lieu?.isNotEmpty == true) text += " • ${rdv.lieu}";
    if (rdv.monitorIds.isNotEmpty) {
      final monitorsNames = rdv.monitorIds
          .map((id) => monitorsMap[id] ?? "Inconnu")
          .join(", ");
      text += " • $monitorsNames";
    }
    return text;
  }

  Future<void> _openDayRdvsPage(DateTime day) async {
    final dayKey = DateTime(day.year, day.month, day.day);
    List<RdvModel> events = List.from(_getEventsForDay(dayKey));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Rendez-vous du ${DateFormat('dd/MM/yyyy').format(day)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...events.map(
                    (rdv) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text('${getRdvLabel(rdv)} • ${rdv.motif}'),
                        subtitle: Text(getRdvSubtitle(rdv)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.blueAccent,
                              ),
                              onPressed: () async {
                                final result = await _openRdvForm(rdv: rdv);
                                if (result) {
                                  final updatedEvents = await _rdvController
                                      .loadRdvs();
                                  setState(() => rdvEvents = updatedEvents);
                                  setModalState(() {
                                    events = List.from(rdvEvents[dayKey] ?? []);
                                  });
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () async {
                                final deleted = await _rdvController.deleteRdv(
                                  context,
                                  rdv,
                                );
                                if (deleted) {
                                  rdvEvents[dayKey]?.removeWhere(
                                    (e) => e.id == rdv.id,
                                  );
                                  /// Pour forcer TableCalendar à se rebuild
                                  setState(() {});
                                  setModalState(() {
                                    events.removeWhere((e) => e.id == rdv.id);
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Ajouter un RDV'),
                    onTap: () async {
                      final result = await _openRdvForm(initialDate: day);
                      if (result) {
                        final updatedEvents = await _rdvController.loadRdvs();
                        setState(() => rdvEvents = updatedEvents);
                        setModalState(() {
                          events = List.from(rdvEvents[dayKey] ?? []);
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading){
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rendez-vous', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Column(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 600),
                  child: TableCalendar<RdvModel>(
                    rowHeight: 60,
                    daysOfWeekHeight: 30,
                    locale: 'fr_FR',
                    firstDay: DateTime(DateTime.now().year - 1),
                    lastDay: DateTime(DateTime.now().year + 2),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    eventLoader: _getEventsForDay,
                    headerStyle: const HeaderStyle(formatButtonVisible: false),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() => _focusedDay = focusedDay);
                      _selectedDay = selectedDay;
                      final events = _getEventsForDay(selectedDay);
                      if (events.isNotEmpty) {
                        _openDayRdvsPage(selectedDay);
                      } else {
                        _openRdvForm(initialDate: selectedDay).then((result) {
                          if (result) _loadRdvs();
                        });
                      }
                    },
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders<RdvModel>(
                      markerBuilder: (context, day, events) {
                        final rdvs = events.cast<RdvModel>();
                        if (rdvs.isEmpty) return const SizedBox.shrink();

                        List<Widget> markers = [];

                        // Travailleur seul → noir
                        if (rdvs.any(
                          (r) =>
                              r.workerId.isNotEmpty &&
                              r.workerId != "TEAM" &&
                              r.monitorIds.isEmpty,
                        )) {
                          markers.add(
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }

                        // Moniteur seul → rose
                        if (rdvs.any(
                          (r) =>
                              (r.workerId.isEmpty || r.workerId == "TEAM") &&
                              r.monitorIds.isNotEmpty,
                        )) {
                          markers.add(
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.pink,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }

                        // Travailleur + moniteur → demi noir/rose
                        if (rdvs.any(
                          (r) =>
                              r.workerId.isNotEmpty && r.monitorIds.isNotEmpty,
                        )) {
                          markers.add(
                            const SizedBox(
                              width: 6,
                              height: 6,
                              child: CustomPaint(painter: HalfCirclePainter()),
                            ),
                          );
                        }

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: markers
                              .map(
                                (m) => Padding(
                                  padding: const EdgeInsets.only(right: 2),
                                  child: m,
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Demi-point noir/rose
class HalfCirclePainter extends CustomPainter {
  const HalfCirclePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paintLeft = Paint()..color = Colors.black;
    final paintRight = Paint()..color = Colors.pink;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect, 3.14 / 2, 3.14, true, paintLeft); // gauche noir
    canvas.drawArc(rect, -3.14 / 2, 3.14, true, paintRight); // droite rose
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
