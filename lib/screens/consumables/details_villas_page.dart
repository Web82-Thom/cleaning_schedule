import 'package:cleaning_schedule/screens/consumables/widgets/build_table_for_consumable_widget.dart';
import 'package:flutter/material.dart';

class DetailsVillasPage extends StatelessWidget {
  final String villa;

  const DetailsVillasPage({super.key, required this.villa});

  @override
  Widget build(BuildContext context) {
    return BuildTableForConsumableWidget(
      title: 'Villas',
      fileNamePrefix: 'Villas',
      elementName: villa,
      routePdfList: '/listPdfVillas',
    );
  }
}
