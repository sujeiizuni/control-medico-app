import 'package:flutter/material.dart';
import 'calendar_screen.dart';
import 'global_search_screen.dart';
import 'medications_screen.dart';
import 'security_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7F3), Color(0xFFFFFBF7), Color(0xFFFFF1E8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF0F766E).withValues(alpha: 0.22),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.monitor_heart_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola',
                            style: TextStyle(
                              color: Color(0xFF5F6F6B),
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Tu control medico',
                            style: TextStyle(
                              color: Color(0xFF12312F),
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.22),
                        blurRadius: 26,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                      SizedBox(height: 18),
                      Text(
                        'Organiza tus citas y notas por dia',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Selecciona una fecha, escribe lo importante y vuelve cuando lo necesites.',
                        style: TextStyle(
                          color: Color(0xFFE8FFFB),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _ActionTile(
                  icon: Icons.calendar_month_outlined,
                  title: 'Calendario interactivo',
                  subtitle: 'Notas por fecha, marcadores y seleccion visual.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CalendarScreen()),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _ActionTile(
                  icon: Icons.medication_outlined,
                  title: 'Medicamentos',
                  subtitle: 'Dosis, horarios, tratamientos y recordatorios.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MedicationsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _ActionTile(
                  icon: Icons.search_rounded,
                  title: 'Busqueda global',
                  subtitle: 'Encuentra notas, citas y medicamentos rapido.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GlobalSearchScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _ActionTile(
                  icon: Icons.lock_outline,
                  title: 'Seguridad',
                  subtitle: 'Protege la app con un PIN personal.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SecurityScreen()),
                    );
                  },
                ),
                const SizedBox(height: 14),
                const _InfoStrip(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDD5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: const Color(0xFFF97316)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF12312F),
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF5F6F6B)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF5F6F6B)),
          ],
        ),
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB8E8DF)),
      ),
      child: const Row(
        children: [
          Icon(Icons.tips_and_updates_outlined, color: Color(0xFF0F766E)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tip: usa el calendario para registrar sintomas, medicinas o citas.',
              style: TextStyle(color: Color(0xFF12312F)),
            ),
          ),
        ],
      ),
    );
  }
}
