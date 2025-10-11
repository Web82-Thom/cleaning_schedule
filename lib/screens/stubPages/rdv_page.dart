import 'package:flutter/material.dart';

class RdvPage extends StatelessWidget {
  const RdvPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.calendar_today, size: 72, color: Colors.indigo),
          SizedBox(height: 16),
          Text('RDV', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}