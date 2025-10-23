import 'package:cleaning_schedule/screens/consumables/widgets/build_table_for_consumable_widget.dart';
import 'package:flutter/material.dart';

class DetailsProductPage extends StatelessWidget {
  final String product;

  const DetailsProductPage({super.key, required this.product});

@override
  Widget build(BuildContext context) {
    return BuildTableForConsumableWidget(
      title: 'Produit',
      fileNamePrefix: 'Produits',
      elementName: product,
      routePdfList: '/listPdfProduc',
    );
  }
}
