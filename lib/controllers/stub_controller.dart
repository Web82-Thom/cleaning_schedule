import 'package:flutter/material.dart';

class StubController extends ChangeNotifier{
  ///Index pour les stubPages
  // int selectedIndex = 0;

  void onFabPressed(BuildContext context) {
    // TODO: ouvrir la page/modal pour créer ou éditer un planning
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ouvrir création / édition de planning')),
    );
  }
}