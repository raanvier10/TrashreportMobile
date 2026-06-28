import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'laporan_detail_screen.dart';

class RiwayatScreen extends StatefulWidget {
  final List<dynamic> reports;
  final VoidCallback onRefresh;
  final String? initialFilter;

  const RiwayatScreen({Key? key, required this.reports, required this.onRefresh, this.initialFilter}) : super(key: key);

  @override
  _RiwayatScreenState createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  late String _selectedFilter;
  final List<String> _filters = ['Semua Laporan', 'Menunggu', 'Sedang Dibersihkan', 'Selesai', 'Ditolak'];

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter ?? 'Semua Laporan';
  }

  @override
  void didUpdateWidget(RiwayatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFilter != oldWidget.initialFilter && widget.initialFilter != null) {
      _selectedFilter = widget.initialFilter!;
    }
  }

  Color _getStatusColor(String status) {
    String s = status.toLowerCase();
    if (s.contains('menunggu') || s.contains('verifikasi')) return const Color(0xFFD97706);
    if (s.contains('selesai') || s.contains('ditutup')) return const Color(0xFF0D530E);
    if (s.contains('ditolak')) return const Color(0xFFDC2626);
    return const Color(0xFF2563EB); // proses/ditugaskan
  }

  Color _getStatusBg(String status) {
    String s = status.toLowerCase();
    if (s.contains('menunggu') || s.contains('verifikasi')) return const Color(0xFFFEF3C7);
    if (s.contains('selesai') || s.contains('ditutup')) return const Color(0xFFD1FAE5);
    if (s.contains('ditolak')) return const Color(0xFFFEE2E2);
    return const Color(0xFFDBEAFE);
  }

  String _getImageUrl(dynamic report) {
    if (report['gambar'] != null && report['gambar'] is List && report['gambar'].isNotEmpty) {
      for (var g in report['gambar']) {
        if (g['tipe_gambar'] == 'sebelum') {
          return 'https://trashreport.web.id/storage/' + g['jalur_gambar'];
        }
      }
    }
    if (report['foto'] != null) return 'https://trashreport.web.id/storage/' + report['foto'];
    return '';
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFF8F9FA);
    const Color borderDefault = Color(0xFFE5E7EB);
    
    // Filter the reports
    List<dynamic> filteredReports = widget.reports.where((r) {
      if (_selectedFilter == 'Semua Laporan') return true;
      String status = r['status'].toString().toLowerCase();
      if (_selectedFilter == 'Menunggu' && (status.contains('menunggu') || status.contains('verifikasi'))) return true;
      if (_selectedFilter == 'Sedang Dibersihkan' && (status.contains('proses') || status.contains('tugas') || status.contains('jalan') || status.contains('bersih'))) return true;
      if (_selectedFilter == 'Selesai' && (status.contains('selesai') || status.contains('ditutup'))) return true;
      if (_selectedFilter == 'Ditolak' && status.contains('ditolak')) return true;
      return false;
    }).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Riwayat Laporan', style: GoogleFonts.outfit(color: const Color(0xFF1A1A1A), fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
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
                  border: Border.all(color: borderDefault),
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
                        Text('Filter Laporan', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderDefault),
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

              // List
              if (filteredReports.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text('Tidak ada laporan ditemukan.', style: GoogleFonts.outfit(color: Colors.grey)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredReports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final report = filteredReports[index];
                    String imageUrl = _getImageUrl(report);
                    String status = report['status'].toString();
                    String kode = report['kode_laporan'] ?? (report['id'] != null ? 'REP-20260622-${report['id'].toString().padLeft(4, '0').toUpperCase()}C' : 'REP-0000');
                    String kategori = report['kategori'] != null ? (report['kategori'] is String ? report['kategori'] : report['kategori']['nama']) : 'Umum';
                    String wilayah = report['wilayah'] != null ? (report['wilayah'] is String ? report['wilayah'] : report['wilayah']['nama']) : 'Wilayah';
                    String tanggal = report['dilaporkan_pada'] != null ? DateFormat('dd MMM yy').format(DateTime.parse(report['dilaporkan_pada'])) : '';

                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LaporanDetailScreen(report: report))),
                      child: Container(
                        height: 140, // fixed height for nice card aspect ratio
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderDefault),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          children: [
                            // Left Image
                            Container(
                              width: 120,
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                                image: imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
                              ),
                              child: Stack(
                                children: [
                                  if (imageUrl.isEmpty)
                                    const Center(child: Icon(Icons.image, color: Colors.grey, size: 40)),
                                  // Status Badge over image
                                  Positioned(
                                    top: 12, left: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusBg(status),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status.length > 10 ? status.substring(0, 10) + '...' : status,
                                        style: GoogleFonts.outfit(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            // Right Content
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Kode Laporan
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: borderDefault),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(kode, style: GoogleFonts.outfit(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(height: 8),
                                    // Title
                                    Expanded(
                                      child: Text(
                                        report['judul'] ?? '',
                                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A), height: 1.2),
                                        maxLines: 2, overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    // Location
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(wilayah, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF374151)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    // Kategori & Date
                                    Row(
                                      children: [
                                        const Icon(Icons.sell_outlined, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(kategori, style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF374151)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                        Text(tanggal, style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey.shade500)),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
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