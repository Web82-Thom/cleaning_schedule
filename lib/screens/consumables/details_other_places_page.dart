import 'package:cleaning_schedule/screens/consumables/widgets/build_table_for_consumable_widget.dart';
import 'package:flutter/material.dart';

class DetailsOtherPlacesPage extends StatelessWidget {
  final String otherPlacesName;

  const DetailsOtherPlacesPage({super.key, required this.otherPlacesName,});

  @override
  Widget build(BuildContext context) {
    return BuildTableForConsumableWidget(
      title: 'Autres lieux',
      fileNamePrefix: 'Autre lieux',
      elementName: otherPlacesName,
      routePdfList: '/listPdfOtherPlaces',
    );
  }
}
