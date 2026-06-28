import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'artikel_detail_screen.dart';

class ArtikelListScreen extends StatelessWidget {
  final List<dynamic> articles;
  
  const ArtikelListScreen({Key? key, required this.articles}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF093B09);
    const Color bgColor = Color(0xFFF8F9FA);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edukasi & Info',
          style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: articles.isEmpty
          ? const Center(child: Text('Belum ada artikel.'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: articles.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                var article = articles[index];
                String rawGambar = article['gambar_sampul']?.toString() ?? '';
                String imageUrl = rawGambar.isEmpty ? '' : (rawGambar.startsWith('http') ? rawGambar : (rawGambar.startsWith('/storage/') ? 'https://trashreport.web.id$rawGambar' : (rawGambar.startsWith('storage/') ? 'https://trashreport.web.id/$rawGambar' : (rawGambar.startsWith('/') ? 'https://trashreport.web.id/storage$rawGambar' : 'https://trashreport.web.id/storage/$rawGambar'))));
                String date = article['diterbitkan_pada'] != null ? DateFormat('dd MMM yyyy').format(DateTime.parse(article['diterbitkan_pada'])) : 'Baru';
                
                // Variasi kategori untuk tampilan
                List<String> categories = ['Tips', 'Lingkungan', 'Edukasi', 'Bahaya', 'Inovasi'];
                String category = categories[index % categories.length];
                
                return GestureDetector(
                  onTap: () {
                     try {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => ArtikelDetailScreen(artikel: article)));
                     } catch(e) {
                       print('ArtikelDetailScreen error: $e');
                     }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100, width: 1.0),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Image Box (Soft green box with icon as requested)
                        Container(
                          width: 100,
                          height: 120,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            image: imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover) : null,
                          ),
                          child: imageUrl.isEmpty 
                            ? Center(child: Icon(Icons.newspaper_rounded, color: primaryColor.withOpacity(0.5), size: 36))
                            : null,
                        ),
                        const SizedBox(width: 16),
                        
                        // Right Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Category & Date
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      category,
                                      style: GoogleFonts.outfit(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade400),
                                      const SizedBox(width: 4),
                                      Text(date, style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                                    ],
                                  )
                                ],
                              ),
                              const SizedBox(height: 10),
                              
                              // Title
                              Text(
                                article['judul'] ?? 'Tanpa Judul',
                                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1A1D1F), height: 1.2),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              
                              // Description / Subtitle
                              Text(
                                article['isi'] != null ? article['isi'].toString().replaceAll(RegExp(r'<[^>]*>'), '') : 'Deskripsi singkat artikel ini tidak tersedia.',
                                style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey.shade500, height: 1.4),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
    );
  }
}
