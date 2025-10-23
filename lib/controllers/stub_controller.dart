import 'package:flutter/material.dart';
import 'package:cleaning_schedule/screens/planning/edit_planning_page.dart';

class StubController extends ChangeNotifier {
  ///--------OPEN EDIT GESTION--------------
  void onFabPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditPlanningPage()),
    );
  }
}
