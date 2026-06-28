import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/services/auth_service.dart';
import '../auth/screens/login_screen.dart';
import 'profile_feature_screens.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  String _userEmail = '';
  String _userFoto = '';
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Pengguna';
      _userEmail = prefs.getString('user_email') ?? 'user@trashreport.com';
      _userFoto = prefs.getString('user_foto') ?? '';
    });
  }

  void _logout() async {
    await _authService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0D530E);
    const Color bgColor = Color(0xFFF8F9FA);
    const Color textPrimary = Color(0xFF1A1A1A);
    const Color borderDefault = Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Profil Saya', style: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderDefault),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5EA),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                          image: _userFoto.isNotEmpty ? DecorationImage(image: NetworkImage('https://trashreport.web.id/storage/$_userFoto'), fit: BoxFit.cover) : null,
                        ),
                        child: _userFoto.isEmpty ? const Icon(Icons.person_rounded, size: 60, color: primaryColor) : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(_userName, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
                  const SizedBox(height: 4),
                  Text(_userEmail, style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey.shade500)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        bool? updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                        if (updated == true) _loadProfile();
                      },
                      icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                      label: Text('Edit Profil', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings Menu
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderDefault),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _buildMenuTile(Icons.lock_outline_rounded, 'Keamanan', 'Ubah kata sandi Anda', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
                  }, isTop: true),
                  _buildDivider(),
                  _buildMenuTile(Icons.help_outline_rounded, 'Pusat Bantuan', 'Panduan & FAQ', () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: Text('Pusat Bantuan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        content: Text('Jika Anda mengalami kendala atau membutuhkan bantuan lebih lanjut seputar aplikasi TrashReport, silakan hubungi tim dukungan kami di:\n\nEmail: support@trashreport.com\nTelepon: +62 812-3456-7890\n\nAtau kunjungi halaman FAQ di website kami.', style: GoogleFonts.outfit(height: 1.5)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Tutup', style: GoogleFonts.outfit(color: primaryColor, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    );
                  }),
                  _buildDivider(),
                  _buildMenuTile(Icons.info_outline_rounded, 'Tentang Aplikasi', 'Versi aplikasi 1.0.0', () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'TrashReport',
                      applicationVersion: '1.0.0',
                      applicationIcon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.recycling, color: Colors.white, size: 32),
                      ),
                      children: [
                        const SizedBox(height: 16),
                        Text('TrashReport adalah platform cerdas untuk pelaporan tumpukan sampah dan kerusakan lingkungan berbasis partisipasi masyarakat.', style: GoogleFonts.outfit()),
                        const SizedBox(height: 8),
                        Text('Dikembangkan untuk membangun lingkungan yang lebih bersih dan berkelanjutan.', style: GoogleFonts.outfit()),
                      ],
                    );
                  }, isBottom: true),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEF2F2),
                  foregroundColor: const Color(0xFFDC2626),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: Text('Keluar Akun', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: const Color(0xFFF3F4F6), indent: 56, endIndent: 20);
  }

  Widget _buildMenuTile(IconData icon, String title, String subtitle, VoidCallback onTap, {bool isTop = false, bool isBottom = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(top: Radius.circular(isTop ? 20 : 0), bottom: Radius.circular(isBottom ? 20 : 0)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: const Color(0xFF4B5563), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A))),
                    const SizedBox(height: 2),
                    Text(subtitle, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFD1D5DB)),
            ],
          ),
        ),
      ),
    );
  }
}