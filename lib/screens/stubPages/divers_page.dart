import 'package:flutter/material.dart';

class DiversPage extends StatelessWidget {
  const DiversPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.more_horiz, size: 72, color: Colors.indigo),
          SizedBox(height: 16),
          Text('Divers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}