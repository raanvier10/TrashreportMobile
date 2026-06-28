import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

import '../services/laporan_service.dart';
import '../services/artikel_service.dart';
import '../screens/riwayat_screen.dart';
import '../screens/create_report_screen.dart';
import '../screens/laporan_detail_screen.dart';
import '../screens/artikel_list_screen.dart';
import '../screens/artikel_detail_screen.dart';
import '../screens/notifikasi_screen.dart';
import '../../profile/profile_screen.dart';
import '../../../core/api/api_client.dart';

const Color primaryColor = Color(0xFF0D530E);
const Color primary400 = Color(0xFF1B6A1C);
const Color primary50 = Color(0xFFEAF5EA);
const Color bgColor = Color(0xFFF8F9FA);
const Color surfaceColor = Colors.white;
const Color neutral50 = Color(0xFFF8F9FA);
const Color borderDefault = Color(0xFFE5E7EB);

const Color textPrimary = Color(0xFF1A1A1A);
const Color textSecondary = Color(0xFF666666);
const Color textTertiary = Color(0xFF999999);

class PelaporDashboard extends StatefulWidget {
  @override
  _PelaporDashboardState createState() => _PelaporDashboardState();
}

class _PelaporDashboardState extends State<PelaporDashboard> {
  int _currentIndex = 0;
  String _userName = 'Pengguna';
  bool _isLoading = true;
  
  List<dynamic> _reports = [];
  List<dynamic> _publicReports = [];
  List<dynamic> _articles = [];
  
  final LaporanService _laporanService = LaporanService();
  final ArtikelService _artikelService = ArtikelService();
  
  final MapController _mapController = MapController();
  LatLng? _currentLocation;

  final MapController _fullMapController = MapController();
  String _mapSearchQuery = '';
  String _mapFilterStatus = 'Semua';
  dynamic _selectedMapReport;

  Map<String, int> _stats = {
    'total': 0,
    'menunggu': 0,
    'diproses': 0,
    'selesai': 0,
    'ditolak': 0,
  };

  String? _riwayatFilter;

  int _unreadNotifCount = 0;
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchData();
    _fetchArticles();
    _getUserLocation();
  }

  void _loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Pengguna';
      if (_userName.contains(' ')) {
        _userName = _userName.split(' ')[0];
      }
    });
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _laporanService.fetchLaporan(),
      _laporanService.fetchLaporanPublik()
    ]);
    final result = results[0];
    final resultPublic = results[1];
    
    try {
      final notifResp = await _apiClient.dio.get('/pelapor/notifikasi');
      if (notifResp.statusCode == 200) {
        _unreadNotifCount = notifResp.data['unread_count'] ?? 0;
      }
    } catch (_) {}
    
    int menunggu = 0;
    int diproses = 0;
    int selesai = 0;
    int ditolak = 0;

    for (var r in result) {
      String status = (r['status'] ?? '').toString().toLowerCase();
      if (status == 'menunggu verifikasi' || status == 'menunggu') menunggu++;
      else if (status == 'ditugaskan' || status == 'dalam perjalanan' || status == 'sedang dibersihkan') diproses++;
      else if (status == 'selesai') selesai++;
      else if (status == 'ditolak') ditolak++;
    }

    if (mounted) {
      setState(() {
        _reports = result;
        _publicReports = resultPublic;
        _stats = {
          'total': result.length,
          'menunggu': menunggu,
          'diproses': diproses,
          'selesai': selesai,
          'ditolak': ditolak,
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchArticles() async {
    try {
      final result = await _artikelService.fetchArtikel();
      if (mounted) {
        setState(() {
          _articles = result;
        });
      }
    } catch (e) {
      print('Gagal memuat artikel: $e');
    }
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (mounted) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _mapController.move(_currentLocation!, 15.0);
      });
    }
  }

  Widget _buildBeranda() {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // Sticky Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: borderDefault, width: 1)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset('assets/images/Group 4.png', height: 32, errorBuilder: (context, error, stackTrace) => const Icon(Icons.eco, color: primaryColor)),
                    const SizedBox(width: 8),
                    Text('TrashReport', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor)),
                  ],
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: primaryColor, size: 28),
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => NotifikasiScreen()));
                        _fetchData(); // Refresh setelah kembali
                      },
                    ),
                    if (_unreadNotifCount > 0)
                      Positioned(
                        top: 12, right: 12,
                        child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                      )
                  ],
                )
              ],
            ),
          ),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _fetchData();
                await _fetchArticles();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            // Greeting Card (Green Gradient)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [primaryColor, primary400], begin: Alignment.centerLeft, end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Halo, $_userName 👋', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('Mari bersama wujudkan kota yang bersih dan asri hari ini.', style: GoogleFonts.outfit(fontSize: 15, color: Colors.white.withOpacity(0.9))),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      bool? created = await Navigator.push(context, MaterialPageRoute(builder: (_) => CreateReportScreen()));
                      if (created == true) _fetchData();
                    },
                    icon: const Icon(Icons.add_circle, color: primaryColor),
                    label: Text('Lapor Sekarang', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: primaryColor)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Statistik Laporan Minimalis
            Text('Statistik Laporan', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5)),
            const SizedBox(height: 16),
            
            // Total Laporan Card
            GestureDetector(
              onTap: () {
                setState(() {
                  _riwayatFilter = 'Semua Laporan';
                  _currentIndex = 3; // Go to Riwayat tab
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color: primaryColor, // Dark green
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: -10, bottom: -30,
                      child: Icon(Icons.description_rounded, size: 100, color: Colors.white.withOpacity(0.08)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.description_outlined, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text('TOTAL LAPORAN', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('${_stats['total']}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, height: 1)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Small Stats Grid (2x2) Minimalis
            GridView.count(
              padding: EdgeInsets.zero,
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.9,
              children: [
                _buildSmallStatCard('MENUNGGU', _stats['menunggu']!, Icons.access_time_rounded, const Color(0xFFD97706), 'Menunggu'),
                _buildSmallStatCard('SEDANG DIBERSIHKAN', _stats['diproses']!, Icons.blur_on, const Color(0xFF2563EB), 'Sedang Dibersihkan'),
                _buildSmallStatCard('SELESAI', _stats['selesai']!, Icons.check_circle_outline_rounded, primaryColor, 'Selesai'),
                _buildSmallStatCard('DITOLAK', _stats['ditolak']!, Icons.cancel_outlined, const Color(0xFFDC2626), 'Ditolak'),
              ],
            ),
            const SizedBox(height: 20),

            // Riwayat Terbaru (Minimalist Card List)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderDefault, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Riwayat Terbaru', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5)),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _riwayatFilter = 'Semua Laporan';
                                  _currentIndex = 3;
                                });
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Lihat Semua', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_rounded, size: 16, color: primaryColor),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Pantau status laporan terakhir Anda', style: GoogleFonts.outfit(fontSize: 13, color: textSecondary)),
                      ],
                    ),
                  ),
                  Divider(color: Colors.grey.shade200, height: 1, thickness: 1.5),
                  
                  // List Items
                  if (_reports.isEmpty)
                    const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Belum ada laporan.')))
                  else
                    Column(
                      children: _reports.take(5).toList().asMap().entries.map((entry) {
                        int index = entry.key;
                        var report = entry.value;
                        bool isLast = index == (_reports.length > 5 ? 4 : _reports.length - 1);
                        return _buildMinimalistReportItem(report, isLast);
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Peta Lokasi Laporan
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Peta Laporan Sekitar', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5)),
                    GestureDetector(
                      onTap: () => setState(() => _currentIndex = 1),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Lihat Semua', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 16, color: primaryColor),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Lihat lokasi laporan Anda di peta', style: GoogleFonts.outfit(fontSize: 13, color: textSecondary)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderDefault, width: 1.5),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentLocation ?? const LatLng(-6.200000, 106.816666),
                    initialZoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.trashreport.app',
                    ),
                    MarkerLayer(
                      markers: (_publicReports.isNotEmpty ? _publicReports : _reports).map((r) {
                        if (r['lintang'] != null && r['bujur'] != null) {
                          double lat = double.tryParse(r['lintang'].toString()) ?? 0;
                          double lng = double.tryParse(r['bujur'].toString()) ?? 0;
                          Color markerColor = _getStatusColor(r['status'].toString());
                          return Marker(
                            point: LatLng(lat, lng),
                            width: 16,
                            height: 16,
                            child: Container(
                              decoration: BoxDecoration(
                                color: markerColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [BoxShadow(color: markerColor.withOpacity(0.4), blurRadius: 4, spreadRadius: 1)],
                              ),
                            ),
                          );
                        }
                        return Marker(point: const LatLng(0,0), child: const SizedBox());
                      }).toList(),
                    ),
                    if (_currentLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentLocation!,
                            child: Container(
                              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.3), shape: BoxShape.circle),
                              child: const Center(child: Icon(Icons.my_location, color: Colors.blue, size: 20)),
                            ),
                          )
                        ],
                      )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Edukasi & Info (Artikel Carousel)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Edukasi & Info.', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.5)),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ArtikelListScreen(articles: _articles)));
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Lihat Semua', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: primaryColor),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 4),
            Text('Baca artikel terbaru seputar pengelolaan limbah.', style: GoogleFonts.outfit(fontSize: 13, color: textSecondary)),
            const SizedBox(height: 16),

            // Carousel Section
            if (_articles.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: primaryColor)))
            else
              _ArtikelCarousel(articles: _articles),
                  ],
                ), // Column
              ), // SingleChildScrollView
            ), // RefreshIndicator
          ), // Expanded
        ], // children
      ), // Column
    ); // SafeArea
  }

  Widget _buildSmallStatCard(String title, int count, IconData icon, Color color, String filterValue) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _riwayatFilter = filterValue;
          _currentIndex = 3; // Go to Riwayat tab
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: neutral50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderDefault, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(title, style: GoogleFonts.outfit(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('$count', style: GoogleFonts.outfit(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold, height: 1)),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    String s = status.toLowerCase();
    if (s.contains('menunggu') || s.contains('verifikasi')) return const Color(0xFFD97706);
    if (s.contains('selesai') || s.contains('ditutup')) return primaryColor;
    if (s.contains('ditolak')) return const Color(0xFFDC2626);
    return const Color(0xFF2563EB);
  }

  Widget _buildMinimalistReportItem(dynamic report, bool isLast) {
    String status = report['status'].toString();
    Color statusColor;
    Color statusBg;
    
    if (status.toLowerCase().contains('menunggu')) {
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFFF7ED);
    } else if (status.toLowerCase() == 'selesai') {
      statusColor = primaryColor;
      statusBg = primary50;
    } else if (status.toLowerCase() == 'ditolak') {
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEF2F2);
    } else {
      statusColor = const Color(0xFF2563EB);
      statusBg = const Color(0xFFEFF6FF);
    }

    String date = report['dilaporkan_pada'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(report['dilaporkan_pada'])) : '';
    // Buat tracking ID tiruan jika tidak ada
    String trackingId = report['id'] != null ? 'TR-2026-${report['id'].toString().padLeft(4, '0')}' : 'TR-0000';

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LaporanDetailScreen(report: report))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: isLast ? null : const Border(bottom: BorderSide(color: borderDefault, width: 1.5)),
        ),
        child: Row(
          children: [
            // Minimalist Icon Box
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08), // Background hijau sangat lembut
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.description_outlined, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(report['judul'] ?? 'Laporan Tanpa Judul', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                        child: Text(trackingId, style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                      ),
                      Text('•', style: TextStyle(color: Colors.grey.shade300)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 11, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(date, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.length > 10 ? status.substring(0, 10) + '...' : status, 
                style: GoogleFonts.outfit(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFullMap() {
    List<dynamic> sourceReports = _publicReports.isNotEmpty ? _publicReports : _reports;
    List<dynamic> filteredReports = sourceReports.where((r) {
      String status = r['status'].toString().toLowerCase();
      bool matchStatus = false;
      if (_mapFilterStatus == 'Semua') {
        matchStatus = true;
      } else if (_mapFilterStatus == 'Menunggu') {
        matchStatus = status.contains('menunggu') || status.contains('verifikasi');
      } else if (_mapFilterStatus == 'Diproses') {
        matchStatus = status.contains('diproses') || status.contains('ditugaskan') || status.contains('proses');
      } else if (_mapFilterStatus == 'Selesai') {
        matchStatus = status.contains('selesai') || status.contains('ditutup');
      } else if (_mapFilterStatus == 'Ditolak') {
        matchStatus = status.contains('ditolak');
      }
      bool matchSearch = _mapSearchQuery.isEmpty || 
          (r['judul']?.toString().toLowerCase().contains(_mapSearchQuery.toLowerCase()) ?? false) ||
          (r['deskripsi']?.toString().toLowerCase().contains(_mapSearchQuery.toLowerCase()) ?? false) ||
          (r['alamat']?.toString().toLowerCase().contains(_mapSearchQuery.toLowerCase()) ?? false);
      return matchStatus && matchSearch;
    }).toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _fullMapController,
          options: MapOptions(
            initialCenter: _currentLocation ?? const LatLng(-6.200000, 106.816666),
            initialZoom: 14.0,
            onTap: (tapPosition, point) {
              if (_selectedMapReport != null) setState(() => _selectedMapReport = null);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.trashreport.app',
            ),
            MarkerLayer(
              markers: filteredReports.map((r) {
                if (r['lintang'] != null && r['bujur'] != null) {
                  double lat = double.tryParse(r['lintang'].toString()) ?? 0;
                  double lng = double.tryParse(r['bujur'].toString()) ?? 0;
                  Color markerColor = _getStatusColor(r['status'].toString());
                  bool isSelected = _selectedMapReport == r;
                  return Marker(
                    point: LatLng(lat, lng),
                    width: isSelected ? 32 : 24,
                    height: isSelected ? 32 : 24,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedMapReport = r);
                        _fullMapController.move(LatLng(lat, lng), _fullMapController.camera.zoom);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: markerColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: isSelected ? 4 : 3),
                          boxShadow: [BoxShadow(color: markerColor.withOpacity(0.6), blurRadius: 6, spreadRadius: isSelected ? 3 : 1)],
                        ),
                      ),
                    ),
                  );
                }
                return Marker(point: const LatLng(0,0), child: const SizedBox());
              }).toList(),
            ),
            if (_currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentLocation!,
                    child: Container(
                      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.3), shape: BoxShape.circle),
                      child: const Center(child: Icon(Icons.my_location, color: Colors.blue, size: 20)),
                    ),
                  )
                ],
              )
          ],
        ),

        // TOP: Search & Filters
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Search Bar
                Container(
                  margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _mapSearchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Cari laporan...',
                      hintStyle: GoogleFonts.outfit(color: textSecondary),
                      border: InputBorder.none,
                      icon: const Icon(Icons.search, color: textSecondary),
                    ),
                  ),
                ),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: ['Semua', 'Menunggu', 'Diproses', 'Selesai', 'Ditolak'].map((status) {
                      bool isActive = _mapFilterStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(status, style: GoogleFonts.outfit(color: isActive ? Colors.white : textSecondary, fontWeight: FontWeight.bold)),
                          selected: isActive,
                          selectedColor: primaryColor,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isActive ? primaryColor : borderDefault)),
                          showCheckmark: false,
                          onSelected: (val) {
                            if (val) setState(() {
                              _mapFilterStatus = status;
                              _selectedMapReport = null;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),

        // RIGHT: Zoom Controls & Location
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          right: 16,
          bottom: _selectedMapReport != null ? 190 : 32,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'btnLoc',
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: primaryColor),
                onPressed: () {
                  if (_currentLocation != null) {
                    _fullMapController.move(_currentLocation!, 15.0);
                  }
                },
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'btnZoomIn',
                backgroundColor: Colors.white,
                child: const Icon(Icons.add, color: textPrimary),
                onPressed: () {
                  _fullMapController.move(_fullMapController.camera.center, _fullMapController.camera.zoom + 1);
                },
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'btnZoomOut',
                backgroundColor: Colors.white,
                child: const Icon(Icons.remove, color: textPrimary),
                onPressed: () {
                  _fullMapController.move(_fullMapController.camera.center, _fullMapController.camera.zoom - 1);
                },
              ),
            ],
          ),
        ),

        // BOTTOM: Selected Report Info Card
        if (_selectedMapReport != null)
          Positioned(
            left: 16, right: 16, bottom: 24,
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => LaporanDetailScreen(report: _selectedMapReport)));
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderDefault, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 12))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(_selectedMapReport['status'].toString()).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _selectedMapReport['status'].toString(),
                            style: GoogleFonts.outfit(
                              color: _getStatusColor(_selectedMapReport['status'].toString()), 
                              fontSize: 11, 
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Date if available
                        if (_selectedMapReport['dilaporkan_pada'] != null)
                          Text(
                            DateFormat('dd MMM yyyy').format(DateTime.parse(_selectedMapReport['dilaporkan_pada'])),
                            style: GoogleFonts.outfit(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: neutral50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderDefault),
                          ),
                          child: const Icon(Icons.report_problem_rounded, color: primaryColor, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedMapReport['judul'] ?? 'Tanpa Judul',
                                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary, height: 1.2),
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 12, color: textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _selectedMapReport['alamat'] ?? 'Lokasi tidak diketahui',
                                      style: GoogleFonts.outfit(fontSize: 12, color: textSecondary),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: primaryColor))
        : IndexedStack(
            index: _currentIndex,
            children: [
              _buildBeranda(),
              _buildFullMap(), // Map view
              Container(), // Placeholder for FAB
              RiwayatScreen(reports: _reports, onRefresh: _fetchData, initialFilter: _riwayatFilter),
              ProfileScreen(),
            ],
          ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 8, top: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: borderDefault, width: 1.0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildTabIcon(Icons.home_filled, 'Beranda', 0),
            _buildTabIcon(Icons.map_rounded, 'Peta', 1), 
            // Middle Add Button (Sejajar)
            InkWell(
              onTap: () async {
                bool? created = await Navigator.push(context, MaterialPageRoute(builder: (_) => CreateReportScreen()));
                if (created == true) _fetchData();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 4),
                  Text('Lapor', style: GoogleFonts.outfit(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            _buildTabIcon(Icons.history_rounded, 'Riwayat', 3),
            _buildTabIcon(Icons.person_rounded, 'Profil', 4),
          ],
        ),
      ),
    );
  }

  Widget _buildTabIcon(IconData icon, String label, int index) {
    bool isSelected = _currentIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _currentIndex = index);
        // Refresh data secara diam-diam (background) tiap pindah tab
        if (index == 0 || index == 1 || index == 3) {
          _fetchData();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? primaryColor : Colors.grey.shade400, size: 28),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.outfit(
            color: isSelected ? primaryColor : Colors.grey.shade400,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          )),
        ],
      ),
    );
  }
}

// ── Widget Carousel Artikel Edukasi Otomatis ───────────────────────────────
class _ArtikelCarousel extends StatefulWidget {
  final List<dynamic> articles;
  const _ArtikelCarousel({required this.articles});

  @override
  State<_ArtikelCarousel> createState() => _ArtikelCarouselState();
}

class _ArtikelCarouselState extends State<_ArtikelCarousel> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && widget.articles.isNotEmpty) {
        int nextPage = _currentPage + 1;
        if (nextPage >= widget.articles.length) {
          nextPage = 0;
          _pageController.animateToPage(nextPage, duration: const Duration(milliseconds: 600), curve: Curves.fastOutSlowIn);
        } else {
          _pageController.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.fastOutSlowIn);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.articles.isEmpty) return const SizedBox();
    
    return Column(
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: widget.articles.length,
            itemBuilder: (context, index) {
              var article = widget.articles[index];
              String rawGambar = article['gambar_sampul']?.toString() ?? '';
              String imageUrl = rawGambar.isEmpty ? '' : (rawGambar.startsWith('http') ? rawGambar : (rawGambar.startsWith('/storage/') ? 'https://trashreport.web.id$rawGambar' : (rawGambar.startsWith('storage/') ? 'https://trashreport.web.id/$rawGambar' : (rawGambar.startsWith('/') ? 'https://trashreport.web.id/storage$rawGambar' : 'https://trashreport.web.id/storage/$rawGambar'))));
              String date = article['diterbitkan_pada'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(article['diterbitkan_pada'])) : 'Baru';

              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.05)).clamp(0.0, 1.0);
                  }
                  return Center(
                    child: Transform.scale(
                      scale: Curves.easeOut.transform(value),
                      child: child,
                    ),
                  );
                },
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ArtikelDetailScreen(artikel: article)));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderDefault, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        Expanded(
                          flex: 3,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                              image: imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
                            ),
                            child: imageUrl.isEmpty ? const Center(child: Icon(Icons.article, size: 40, color: Colors.grey)) : null,
                          ),
                        ),
                        // Content
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(date, style: GoogleFonts.outfit(fontSize: 10, color: textTertiary, fontWeight: FontWeight.w600)),
                                    const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('•', style: TextStyle(color: textTertiary))),
                                    Text('Admin TrashReport', style: GoogleFonts.outfit(fontSize: 10, color: textTertiary)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  article['judul'] ?? 'Artikel Tanpa Judul',
                                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary, height: 1.2),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Dot Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.articles.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index ? primaryColor : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
