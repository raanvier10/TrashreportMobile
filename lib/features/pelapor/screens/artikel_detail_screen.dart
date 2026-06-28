import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_html/flutter_html.dart';

class ArtikelDetailScreen extends StatelessWidget {
  final dynamic artikel;

  const ArtikelDetailScreen({Key? key, required this.artikel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String judul = artikel['judul'] ?? 'Artikel Tanpa Judul';
    String konten = artikel['isi'] ?? 'Tidak ada konten.';
    String rawGambar = artikel['gambar_sampul']?.toString() ?? '';
    String imgUrl = rawGambar.isEmpty ? '' : (rawGambar.startsWith('http') ? rawGambar : (rawGambar.startsWith('/storage/') ? 'https://trashreport.web.id$rawGambar' : (rawGambar.startsWith('storage/') ? 'https://trashreport.web.id/$rawGambar' : (rawGambar.startsWith('/') ? 'https://trashreport.web.id/storage$rawGambar' : 'https://trashreport.web.id/storage/$rawGambar'))));
    String date = artikel['diterbitkan_pada'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(artikel['diterbitkan_pada'])) : 'Baru';

    final Color textPrimary = const Color(0xFF0F172A);
    final Color textSecondary = const Color(0xFF64748B);
    final Color bgColor = const Color(0xFFF8F9FA);
    final Color borderDefault = const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        title: Text(
          'Detail Artikel',
          style: GoogleFonts.outfit(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              judul,
              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w800, color: textPrimary, height: 1.2, letterSpacing: -0.5),
            ),
            const SizedBox(height: 16),
            
            // Meta Information
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: textSecondary),
                const SizedBox(width: 6),
                Text(date, style: GoogleFonts.outfit(color: textSecondary, fontSize: 13)),
                const SizedBox(width: 20),
                Icon(Icons.person_outline_rounded, size: 16, color: textSecondary),
                const SizedBox(width: 6),
                Text('Admin TrashReport', style: GoogleFonts.outfit(color: textSecondary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 24),
            
            // Image
            if (imgUrl.isNotEmpty)
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(image: NetworkImage(imgUrl), fit: BoxFit.cover),
                ),
              ),
            if (imgUrl.isNotEmpty) const SizedBox(height: 32),
            
            // Content
            Html(
              data: konten,
              style: {
                "body": Style(
                  fontFamily: 'Outfit',
                  fontSize: FontSize(15.0),
                  color: const Color(0xFF334155),
                  lineHeight: LineHeight(1.8),
                  padding: HtmlPaddings.zero,
                  margin: Margins.zero,
                ),
                "h2": Style(
                  fontSize: FontSize(20.0),
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                "p": Style(
                  margin: Margins.only(bottom: 12.0),
                )
              },
            ),
            
            const SizedBox(height: 40),
            Divider(color: borderDefault, thickness: 1),
            const SizedBox(height: 24),
            
            // Share Section
            Text('Bagikan artikel ini', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildShareButton(Icons.chat_outlined, 'WhatsApp', const Color(0xFF25D366)),
                const SizedBox(width: 12),
                _buildShareButton(Icons.link_rounded, 'Salin Link', textSecondary),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF475569))),
        ],
      ),
    );
  }
}