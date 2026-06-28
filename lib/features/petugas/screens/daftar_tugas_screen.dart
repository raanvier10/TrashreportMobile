import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'task_detail_screen.dart';

class DaftarTugasScreen extends StatefulWidget {
  final List<dynamic> tasks;
  final VoidCallback onRefresh;

  const DaftarTugasScreen({Key? key, required this.tasks, required this.onRefresh}) : super(key: key);

  @override
  _DaftarTugasScreenState createState() => _DaftarTugasScreenState();
}

class _DaftarTugasScreenState extends State<DaftarTugasScreen> {
  final Color primaryColor = const Color(0xFF0D530E);
  final Color infoColor = const Color(0xFF2563eb);
  final Color bgColor = const Color(0xFFF9FAFB);
  final Color inkColor = const Color(0xFF1A1A1A);
  final Color muteColor = const Color(0xFF6B7280);
  final Color hairlineColor = const Color(0xFFE5E7EB);
  final Color warningColor = const Color(0xFFD97706);

  String _selectedFilter = 'Semua Tugas';
  final List<String> _filters = ['Semua Tugas', 'Ditugaskan', 'Dalam Perjalanan', 'Sedang Dibersihkan', 'Selesai'];

  Color _getStatusBg(String status) {
    String s = status.toLowerCase();
    if (s.contains('selesai') || s.contains('ditutup')) return const Color(0xFFD1FAE5);
    if (s.contains('tugas')) return const Color(0xFFFEF3C7);
    return const Color(0xFFDBEAFE);
  }

  Color _getStatusColor(String status) {
    String s = status.toLowerCase();
    if (s.contains('selesai') || s.contains('ditutup')) return primaryColor;
    if (s.contains('tugas')) return warningColor;
    return infoColor;
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredTasks = widget.tasks.where((t) {
      if (_selectedFilter == 'Semua Tugas') return true;
      String status = (t['status'] ?? '').toString().toLowerCase();
      if (_selectedFilter == 'Ditugaskan' && status.contains('ditugaskan')) return true;
      if (_selectedFilter == 'Dalam Perjalanan' && status.contains('jalan')) return true;
      if (_selectedFilter == 'Sedang Dibersihkan' && status.contains('bersih')) return true;
      if (_selectedFilter == 'Selesai' && (status.contains('selesai') || status.contains('ditutup'))) return true;
      return false;
    }).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Daftar Tugas', style: GoogleFonts.outfit(color: inkColor, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: inkColor),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => widget.onRefresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: hairlineColor),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Color(0xFFEAF5EA), shape: BoxShape.circle),
                          child: const Icon(Icons.filter_alt_outlined, color: Color(0xFF0D530E), size: 16),
                        ),
                        const SizedBox(width: 12),
                        Text('Filter Tugas', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: hairlineColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedFilter,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          items: _filters.map((f) => DropdownMenuItem(value: f, child: Text(f, style: GoogleFonts.outfit(fontSize: 14)))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedFilter = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (filteredTasks.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: hairlineColor, shape: BoxShape.circle),
                          child: Icon(Icons.coffee_outlined, size: 48, color: muteColor),
                        ),
                        const SizedBox(height: 16),
                        Text('Belum ada tugas', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: inkColor)),
                        const SizedBox(height: 8),
                        Text('Tidak ada tugas untuk filter ini.', style: GoogleFonts.outfit(color: muteColor)),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTasks.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final tugas = filteredTasks[index];
                    final laporan = tugas;
                    final wilayah = laporan['wilayah'] ?? {};
                    String status = (laporan['status'] ?? 'MENUNGGU').toString().toUpperCase();
                    
                    return GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(tugas: tugas)));
                        if (result == true) widget.onRefresh();
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: hairlineColor),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(color: _getStatusBg(status), borderRadius: BorderRadius.circular(12)),
                                  child: Icon(Icons.assignment_outlined, color: _getStatusColor(status)),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(right: 64), // ruang untuk badge
                                        child: Text(laporan['judul'] ?? 'Tugas Pembersihan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: inkColor, fontSize: 15, height: 1.2)),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8, runSpacing: 6,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(border: Border.all(color: hairlineColor), borderRadius: BorderRadius.circular(4)),
                                            child: Text(laporan['kode_laporan'] ?? '-', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: muteColor, fontSize: 9)),
                                          ),
                                          Icon(Icons.circle, size: 4, color: hairlineColor),
                                          Text(
                                            tugas['updated_at'] != null ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(tugas['updated_at'].toString().endsWith('Z') ? tugas['updated_at'].toString() : tugas['updated_at'].toString() + 'Z').toLocal()) : '-', 
                                            style: GoogleFonts.outfit(color: muteColor, fontSize: 11, fontWeight: FontWeight.w500)
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on_outlined, size: 14, color: muteColor),
                                          const SizedBox(width: 4),
                                          Expanded(child: Text(wilayah['nama'] ?? 'Wilayah Tidak Diketahui', style: GoogleFonts.outfit(color: muteColor, fontSize: 12, fontWeight: FontWeight.w500))),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusBg(status),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status.length > 15 ? status.substring(0, 12) + '...' : status, 
                                style: GoogleFonts.outfit(
                                  color: _getStatusColor(status), 
                                  fontSize: 9, 
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
