import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/dashboard_stats.dart';
import '../providers/app_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<DashboardStats?> _statsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    final api = Provider.of<AppProvider>(context, listen: false).apiService;
    setState(() {
      _statsFuture = api.getDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = _formattedToday();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<DashboardStats?>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('Gagal memuat data',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: _refresh,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final stats = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DateHeader(today: today),
                const SizedBox(height: 16),
                _StatCard(
                  label: 'Total Pasien Hari Ini',
                  value: stats.totalPasienHariIni,
                  icon: Icons.people_rounded,
                  color: const Color(0xFF1A237E),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Berkas Dikirim',
                        value: stats.berkasDikirimHariIni,
                        icon: Icons.send_rounded,
                        color: Colors.green[700]!,
                        small: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Berkas Kembali',
                        value: stats.berkasKembaliHariIni,
                        icon: Icons.assignment_return_rounded,
                        color: Colors.blue[700]!,
                        small: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StatCard(
                  label: 'Belum Dikirim',
                  value: stats.berkasPending,
                  icon: Icons.pending_actions_rounded,
                  color: Colors.orange[800]!,
                  highlight: stats.berkasPending > 0,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formattedToday() {
    final now = DateTime.now();
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

class _DateHeader extends StatelessWidget {
  final String today;
  const _DateHeader({required this.today});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded,
              size: 18, color: Color(0xFF1A237E)),
          const SizedBox(width: 8),
          Text(
            today,
            style: const TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool small;
  final bool highlight;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.small = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(small ? 16 : 20),
      decoration: BoxDecoration(
        color: highlight ? Colors.orange[50] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? Colors.orange[200]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: small ? 20 : 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: small ? 12 : 13,
                  ),
                ),
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: small ? 24 : 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
