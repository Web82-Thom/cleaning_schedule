import 'package:cleaning_schedule/screens/consumables/details_other_places_page.dart';
import 'package:cleaning_schedule/screens/consumables/details_transfer_page.dart';
import 'package:cleaning_schedule/screens/consumables/details_cars_page.dart';
import 'package:cleaning_schedule/screens/consumables/details_products_page.dart';
import 'package:cleaning_schedule/screens/consumables/details_home_of_life_page.dart';
import 'package:cleaning_schedule/screens/consumables/details_villas_page.dart';
import 'package:cleaning_schedule/widgets/consumable_widget.dart';
import 'package:flutter/material.dart';

class ConsumablePage extends StatelessWidget {
  const ConsumablePage({super.key});

  @override
  Widget build(BuildContext context) {
    final consumableWidget = ConsumableWidget();

    // Palette de couleurs cycliques
    final colors = [
      Colors.red.shade100,
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.teal.shade100,
      Colors.yellow.shade100,
    ];

    /// Fonction réutilisable pour créer une grille avec un titre
    Widget buildGrid(List<String> items, String title) {
      final isCars = title.toLowerCase().contains('véhicule');
      final isProducts = title.toLowerCase().contains('produits');
      final isHomeOfLife = title.toLowerCase().contains('foyer de vie');
      final isTransfer = title.toLowerCase().contains('transfert');
      final isVillas = title.toLowerCase().contains('villas');
      final isOtherPlaces = title.toLowerCase().contains('autres lieux');

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
              child: Text(
                '<--- ${title.toUpperCase()} --->',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final bgColor = colors[index % colors.length];

              return InkWell(
                onTap: () {
                  if(isProducts) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsProductPage(product: item),
                      ),
                    );
                  } if (isCars) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsCarsPage(carName: item),
                      ),
                    );
                  } if (isHomeOfLife){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsHomeOfLifePage(homeOfLifeName: item),
                      ),
                    );
                  } if (isTransfer){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsTransferPage(transfer: item),
                      ),
                    );
                  } if(isVillas){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsVillasPage(villa: item),
                      ),
                    );
                  } if(isOtherPlaces){
                    print('object');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailsOtherPlacesPage(otherPlacesName: item,),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(12),
                splashColor: Colors.black12,
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: bgColor,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        item,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Les consommables',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            buildGrid(consumableWidget.cars, 'Véhicules'),
            const SizedBox(height: 20),
            buildGrid(consumableWidget.products, 'Produits'),
            const SizedBox(height: 20,),
            buildGrid(consumableWidget.homeOfLife, 'Foyer de vie'),
            const SizedBox(height: 20,),
            buildGrid(consumableWidget.transfer, 'Transferts'),
            const SizedBox(height: 20,),
            buildGrid(consumableWidget.villas, 'Les villas'),
            const SizedBox(height: 20,),
            buildGrid(consumableWidget.otherPlaces, 'Autres lieux'),
          ],
        ),
      ),
    );
  }
}
