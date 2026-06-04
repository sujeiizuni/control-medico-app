import 'package:flutter/material.dart';

import '../database/pin_database.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final pinController = TextEditingController();
  final confirmController = TextEditingController();

  bool hasPin = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadSecurity();
  }

  @override
  void dispose() {
    pinController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> loadSecurity() async {
    final enabled = await PinDatabase.instance.hasPin();

    if (!mounted) return;

    setState(() {
      hasPin = enabled;
      isLoading = false;
    });
  }

  Future<void> savePin() async {
    final pin = pinController.text.trim();
    final confirm = confirmController.text.trim();

    if (pin.length < 4) {
      showMessage('El PIN debe tener minimo 4 numeros');
      return;
    }

    if (pin != confirm) {
      showMessage('Los PIN no coinciden');
      return;
    }

    await PinDatabase.instance.savePin(pin);
    pinController.clear();
    confirmController.clear();
    await loadSecurity();
    showMessage('PIN activado');
  }

  Future<void> removePin() async {
    await PinDatabase.instance.removePin();
    await loadSecurity();
    showMessage('PIN desactivado');
  }

  void showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: hasPin
                          ? const Color(0xFFE0F7F3)
                          : const Color(0xFFFFEDD5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasPin
                              ? Icons.verified_user_outlined
                              : Icons.lock_open_outlined,
                          color: hasPin
                              ? const Color(0xFF0F766E)
                              : const Color(0xFFF97316),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            hasPin
                                ? 'La app pedira tu PIN despues de iniciar sesion.'
                                : 'Activa un PIN para proteger tus datos medicos.',
                            style: const TextStyle(color: Color(0xFF12312F)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Nuevo PIN',
                      counterText: '',
                      prefixIcon: Icon(Icons.pin_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: confirmController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar PIN',
                      counterText: '',
                      prefixIcon: Icon(Icons.check_circle_outline),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: savePin,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(hasPin ? 'Cambiar PIN' : 'Activar PIN'),
                    ),
                  ),
                  if (hasPin) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: removePin,
                        icon: const Icon(Icons.lock_open_outlined),
                        label: const Text('Desactivar PIN'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
