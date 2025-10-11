import 'package:cleaning_schedule/controllers/auth_controller.dart';
import 'package:cleaning_schedule/controllers/stub_controller.dart';
import 'package:cleaning_schedule/screens/stubPages/consommation_page.dart';
import 'package:cleaning_schedule/screens/stubPages/divers_page.dart';
import 'package:cleaning_schedule/screens/stubPages/planning_page.dart';
import 'package:cleaning_schedule/screens/stubPages/rdv_page.dart';
import 'package:cleaning_schedule/widgets/build_tab_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AuthController authController = AuthController();
  StubController stubController = StubController();
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    PlanningPage(),
    RdvPage(),
    DiversPage(),
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
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atelier de nettoyage'),
        actions: [
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
        onPressed: () => stubController.onFabPressed(context),
        tooltip: 'Nouveau planning',
        child: const Icon(Icons.edit),
        backgroundColor: Colors.indigo,
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