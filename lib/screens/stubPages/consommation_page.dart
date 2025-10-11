import 'package:flutter/material.dart';

class ConsommationPage extends StatelessWidget {
  const ConsommationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.local_gas_station, size: 72, color: Colors.indigo),
          SizedBox(height: 16),
          Text('Consommation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}