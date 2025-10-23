import 'package:cleaning_schedule/screens/consumables/widgets/build_table_for_consumable_widget.dart';
import 'package:flutter/material.dart';

class DetailsHomeOfLifePage extends StatelessWidget {
  final String homeOfLifeName;

  const DetailsHomeOfLifePage({super.key, required this.homeOfLifeName});

  @override
  Widget build(BuildContext context) {
    return BuildTableForConsumableWidget(
      title: 'Foyer de vie',
      fileNamePrefix: 'foyerDeVie',
      elementName: homeOfLifeName,
      routePdfList: '/listPdfHomeOfLife',
    );
  }
}
