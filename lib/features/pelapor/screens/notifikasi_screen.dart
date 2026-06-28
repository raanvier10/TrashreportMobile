import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class NotifikasiScreen extends StatefulWidget {
  @override
  _NotifikasiScreenState createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _notifikasi = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifikasi();
  }

  Future<void> _fetchNotifikasi() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.dio.get('/pelapor/notifikasi');
      if (response.statusCode == 200) {
        setState(() {
          _notifikasi = response.data['data'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memuat notifikasi')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(int id, int index) async {
    try {
      await _apiClient.dio.post('/pelapor/notifikasi/$id/baca');
      setState(() {
        _notifikasi[index]['sudah_dibaca'] = true;
      });
    } catch (e) {
      // Abaikan jika gagal update read status
    }
  }

  Color _getIconColor(String tipe) {
    if (tipe.toLowerCase() == 'selesai') return const Color(0xFF0D530E);
    if (tipe.toLowerCase() == 'proses' || tipe.toLowerCase() == 'diproses') return const Color(0xFF2563EB);
    if (tipe.toLowerCase() == 'ditolak') return const Color(0xFFDC2626);
    return const Color(0xFFD97706); // info / peringatan / menunggu
  }

  IconData _getIcon(String tipe) {
    if (tipe.toLowerCase() == 'selesai') return Icons.check_circle_rounded;
    if (tipe.toLowerCase() == 'proses' || tipe.toLowerCase() == 'diproses') return Icons.sync_rounded;
    if (tipe.toLowerCase() == 'ditolak') return Icons.cancel_rounded;
    return Icons.notifications_active_rounded;
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFF8F9FA);
    const Color textPrimary = Color(0xFF1A1A1A);
    const Color borderDefault = Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Notifikasi', style: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D530E)))
        : RefreshIndicator(
            onRefresh: _fetchNotifikasi,
            child: _notifikasi.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _notifikasi.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notif = _notifikasi[index];
                    bool isRead = notif['sudah_dibaca'] == true || notif['sudah_dibaca'] == 1;
                    String timeStr = notif['dibuat_pada'] != null ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(notif['dibuat_pada'].toString().endsWith('Z') ? notif['dibuat_pada'].toString() : notif['dibuat_pada'].toString() + 'Z').toLocal()) : '';

                    return GestureDetector(
                      onTap: () {
                        if (!isRead) _markAsRead(notif['id'], index);
                        // Optional: Navigate to LaporanDetail if it's related
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.white : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isRead ? borderDefault : const Color(0xFFBBF7D0)),
                          boxShadow: isRead ? [] : [BoxShadow(color: const Color(0xFF0D530E).withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _getIconColor(notif['tipe'] ?? 'info').withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_getIcon(notif['tipe'] ?? 'info'), color: _getIconColor(notif['tipe'] ?? 'info'), size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notif['judul'] ?? 'Pemberitahuan',
                                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: isRead ? FontWeight.w600 : FontWeight.bold, color: textPrimary),
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          width: 8, height: 8,
                                          margin: const EdgeInsets.only(left: 8),
                                          decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                                        )
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    notif['pesan'] ?? '',
                                    style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF4B5563), height: 1.4),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    timeStr,
                                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), shape: BoxShape.circle),
            child: const Icon(Icons.notifications_off_outlined, size: 64, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 24),
          Text('Belum Ada Notifikasi', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
          const SizedBox(height: 8),
          Text('Semua pembaruan laporan Anda\nakan muncul di sini.', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF6B7280), height: 1.5)),
        ],
      ),
    );
  }
}