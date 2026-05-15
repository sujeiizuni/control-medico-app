import 'package:flutter/material.dart';
import 'calendar_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Abrir calendario'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CalendarScreen(),
              ),
            );
          },
        ),
      ),
    );
  }
}