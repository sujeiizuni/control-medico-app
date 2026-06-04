import 'package:flutter/material.dart';

import '../database/pin_database.dart';
import 'home_screen.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final pinController = TextEditingController();

  Future<void> unlock() async {
    final success = await PinDatabase.instance.verifyPin(
      pinController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      pinController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN incorrecto')),
      );
    }
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7F3), Color(0xFFFFF1E8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F7F3),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF0F766E),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Desbloquear app',
                      style: TextStyle(
                        color: Color(0xFF12312F),
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'PIN de seguridad',
                        counterText: '',
                        prefixIcon: Icon(Icons.pin_outlined),
                      ),
                      onSubmitted: (_) => unlock(),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: unlock,
                        icon: const Icon(Icons.lock_open_outlined),
                        label: const Text('Entrar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
