import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import '../services/tugas_service.dart';
import '../screens/task_detail_screen.dart';
import '../screens/peta_rute_screen.dart';
import '../screens/daftar_tugas_screen.dart';
import '../screens/notifikasi_petugas_screen.dart';
import '../../profile/profile_screen.dart';
import '../../../core/api/api_client.dart';

class PetugasDashboard extends StatefulWidget {
  @override
  _PetugasDashboardState createState() => _PetugasDashboardState();
}

class _PetugasDashboardState extends State<PetugasDashboard> {
  final AuthService _authService = AuthService();
  final TugasService _tugasService = TugasService();
  
  String _userName = 'Pekerja Lapangan';
  int _currentIndex = 0;
  
  bool _isLoading = true;
  List<dynamic> _tasks = [];
  Map<String, int> _stats = {
    'baru': 0,
    'dikerjakan': 0,
    'selesai': 0,
  };

  int _unreadNotifCount = 0;
  final ApiClient _apiClient = ApiClient();

  // Warna persis Tailwind TrashReport
  final Color primaryColor = const Color(0xFF0D530E);
  final Color infoColor = const Color(0xFF2563eb);
  final Color errorColor = const Color(0xFFdc2626);
  final Color warningColor = const Color(0xFFd97706);
  final Color bgColor = const Color(0xFFF9FAFB);
  final Color inkColor = const Color(0xFF111827);
  final Color bodyColor = const Color(0xFF374151);
  final Color muteColor = const Color(0xFF6B7280);
  final Color hairlineColor = const Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _loadUser();
    _fetchData();
  }

  void _loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Pekerja Lapangan';
    });
  }

  void _fetchData({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    final result = await _tugasService.fetchTugas();
    
    try {
      final notifResp = await _apiClient.dio.get('/petugas/notifikasi');
      if (notifResp.statusCode == 200) {
        _unreadNotifCount = notifResp.data['unread_count'] ?? 0;
      }
    } catch (_) {}
    
    int baru = 0;
    int dikerjakan = 0;
    int selesai = 0;

    for (var t in result) {
      String status = (t['status'] ?? '').toString().toLowerCase();
      if (status == 'ditugaskan') baru++;
      else if (status == 'dalam perjalanan' || status == 'sedang dibersihkan') dikerjakan++;
      else if (status == 'selesai') selesai++;
    }

    setState(() {
      _tasks = result;
      _stats = {
        'baru': baru,
        'dikerjakan': dikerjakan,
        'selesai': selesai,
      };
      _isLoading = false;
    });
  }

  void _logout() async {
    await _authService.logout();
    Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(builder: (_) => LoginScreen()), 
      (route) => false
    );
  }

  Widget _buildStatCard(String title, String subtitle, int count, Color color, IconData icon, bool showPing) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                if (showPing && count > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(count.toString(), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: inkColor, height: 1)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(subtitle.toUpperCase(), style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w800, color: muteColor, letterSpacing: 0.5), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(title, style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w800, color: muteColor, letterSpacing: 0.5, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeranda() {
    return _isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : RefreshIndicator(
            onRefresh: () async => _fetchData(showLoading: true),
            color: primaryColor,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Banner Petugas
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [primaryColor, const Color(0xFF094009)]),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text('Siap Bertugas, \n$_userName?', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5, height: 1.1)),
                                const SizedBox(height: 12),
                                Text('Pantau penugasan baru dan kelola jadwal pembersihanmu hari ini. Setiap tumpukan sampah yang dibersihkan membawa senyum bagi masyarakat.', 
                                  style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.5, fontWeight: FontWeight.w500)
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.2))
                            ),
                            child: const Icon(Icons.verified_user_outlined, color: Colors.white, size: 32),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Statistik Petugas (Total Selesai di atas, 2 di bawah)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D4C13), // Dark green matching pelapor dashboard
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D4C13).withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            right: -10,
                            bottom: -20,
                            child: Icon(
                              Icons.check_circle,
                              size: 80,
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'TOTAL DISELESAIKAN',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _stats['selesai']!.toString(),
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      'TUGAS',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatCard('MENUNGGU EKSEKUSI', 'Tugas', _stats['baru']!, Colors.red.shade400, Icons.notifications_active_outlined, true),
                        const SizedBox(width: 8),
                        _buildStatCard('SEDANG DIPROSES', 'Tugas', _stats['dikerjakan']!, warningColor, Icons.autorenew, false),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tugas Terbaru
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: hairlineColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Tugas Terbaru', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: inkColor, letterSpacing: -0.5)),
                                      const SizedBox(height: 4),
                                      Text('Daftar penugasan terakhir yang diamanatkan ke Anda.', style: GoogleFonts.outfit(fontSize: 12, color: muteColor)),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text('Lihat Semua', style: GoogleFonts.outfit(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                    const SizedBox(width: 4),
                                    Icon(Icons.arrow_forward, size: 14, color: primaryColor),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: hairlineColor),
                          if (_tasks.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                              child: Center(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.coffee_outlined, size: 32, color: muteColor),
                                    ),
                                    const SizedBox(height: 20),
                                    Text('Belum Ada Tugas', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: inkColor)),
                                    const SizedBox(height: 8),
                                    Text('Anda bisa bersantai sejenak. Saat ini tidak ada laporan yang ditugaskan ke Anda.', style: GoogleFonts.outfit(fontSize: 12, color: muteColor, height: 1.5), textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: _tasks.length,
                              separatorBuilder: (c, i) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final tugas = _tasks[index];
                                final laporan = tugas;
                                final wilayah = laporan['wilayah'] ?? {};
                                
                                return GestureDetector(
                                  onTap: () async {
                                    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(tugas: tugas)));
                                    if (result == true) _fetchData(showLoading: false);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: hairlineColor),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 48, height: 48,
                                          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                                          child: Icon(Icons.location_on_outlined, color: muteColor),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(laporan['judul'] ?? 'Tugas Pembersihan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: inkColor, fontSize: 14)),
                                              const SizedBox(height: 6),
                                              Wrap(
                                                spacing: 6, runSpacing: 6,
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(border: Border.all(color: hairlineColor), borderRadius: BorderRadius.circular(4)),
                                                    child: Text(laporan['kode_laporan'] ?? '-', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: inkColor, fontSize: 9)),
                                                  ),
                                                  Icon(Icons.circle, size: 4, color: muteColor),
                                                  Text(
                                                    tugas['updated_at'] != null ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(tugas['updated_at'].toString().endsWith('Z') ? tugas['updated_at'].toString() : tugas['updated_at'].toString() + 'Z').toLocal()) : '-', 
                                                    style: GoogleFonts.outfit(color: muteColor, fontSize: 10, fontWeight: FontWeight.w500)
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(wilayah['nama'] ?? 'Wilayah Tidak Diketahui', style: GoogleFonts.outfit(color: bodyColor, fontSize: 11, fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                        // Status Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: (laporan['status'] ?? '').toString().toLowerCase() == 'selesai' ? primaryColor.withOpacity(0.1) : warningColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(100),
                                            border: Border.all(color: hairlineColor)
                                          ),
                                          child: Text((laporan['status'] ?? 'MENUNGGU').toString().toUpperCase(), style: GoogleFonts.outfit(color: (laporan['status'] ?? '').toString().toLowerCase() == 'selesai' ? primaryColor : warningColor, fontWeight: FontWeight.w800, fontSize: 9, letterSpacing: 0.5)),
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
                  ],
                ),
              ),
            );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _currentIndex == 0 ? AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/images/Group 4.png', width: 32, height: 32, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.eco, color: Color(0xFF0D530E))),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Portal Petugas', style: GoogleFonts.outfit(color: inkColor, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: -0.5)),
                Text('Area Operasional', style: GoogleFonts.outfit(color: muteColor, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.notifications_none, color: inkColor),
                if (_unreadNotifCount > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: errorColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => NotifikasiPetugasScreen()));
              _fetchData(showLoading: false); // Refresh unread count on return
            },
          ),
          const SizedBox(width: 8),
        ],
      ) : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildBeranda(),
          DaftarTugasScreen(tasks: _tasks, onRefresh: () => _fetchData(showLoading: true)),
          PetaRuteScreen(tugas: _tasks),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: muteColor,
        selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 11),
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index != 3) {
            _fetchData(showLoading: false); // Silent refresh when switching tabs
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Daftar Tugas'),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Peta Rute'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
