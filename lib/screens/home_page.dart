import 'package:cleaning_schedule/controllers/auth_controller.dart';
import 'package:cleaning_schedule/controllers/stub_controller.dart';
import 'package:cleaning_schedule/screens/stubPages/consommation_page.dart';
import 'package:cleaning_schedule/screens/stubPages/view_tasks_no_weekly_page.dart';
import 'package:cleaning_schedule/screens/stubPages/planning_page.dart';
import 'package:cleaning_schedule/screens/stubPages/rdv_calendar_page.dart';
import 'package:cleaning_schedule/widgets/build_tab_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  final FirebaseAuth auth;

   HomePage({Key? key, FirebaseAuth? auth})
      : auth = auth ?? FirebaseAuth.instance,
        super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  AuthController authController = AuthController();
  StubController stubController = StubController();
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    PlanningPage(),
    RdvCalendarPage(),
    ViewTasksNoWeeklyPage(),
    ConsommationPage(),
  ];

  final _tabs = [
    {'icon': Icons.calendar_today, 'label': 'Planning'},
    {'icon': Icons.event, 'label': 'RDV'},
    {'icon': Icons.category, 'label': 'Divers'},
    {'icon': Icons.local_drink, 'label': 'Consommation'},
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atelier de nettoyage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_sharp),
            tooltip: 'Profil',
            onPressed: () => {
              Navigator.pushNamed(context, '/profileInstructor'),
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => authController.signOut(context),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      // FAB centré
      floatingActionButton: FloatingActionButton(
        heroTag: null, //evite le conflit
        onPressed: () => stubController.onFabPressed(context),
        tooltip: 'Nouveau planning',
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.edit),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // BottomAppBar avec notch pour FAB
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final tab = _tabs[index];
            return Expanded(
              child: BuildTabItemWidget(
                icon: tab['icon'] as IconData,
                isSelected: _selectedIndex == index,
                onTap: () => _onItemTapped(index),
              ),
            );
          }),
        ),
      ),
    );
  }
}