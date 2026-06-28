import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'artikel_detail_screen.dart';
import '../services/artikel_service.dart';

class ArtikelScreen extends StatefulWidget {
  @override
  _ArtikelScreenState createState() => _ArtikelScreenState();
}

class _ArtikelScreenState extends State<ArtikelScreen> {
  final ArtikelService _artikelService = ArtikelService();
  List<dynamic> _artikelList = [];

  @override
  void initState() {
    super.initState();
    _fetchArtikel();
  }

  void _fetchArtikel() async {
    final data = await _artikelService.fetchArtikel();
    setState(() => _artikelList = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Artikel & Edukasi', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _artikelList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _artikelList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final artikel = _artikelList[index];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArtikelDetailScreen(artikel: artikel))),
                  child: Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (artikel['gambar_sampul'] != null)
                          Container(
                            height: 150, width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              image: DecorationImage(image: NetworkImage(artikel['gambar_sampul'].toString().startsWith('http') ? artikel['gambar_sampul'] : (artikel['gambar_sampul'].toString().startsWith('/storage/') ? 'https://trashreport.web.id' + artikel['gambar_sampul'] : (artikel['gambar_sampul'].toString().startsWith('storage/') ? 'https://trashreport.web.id/' + artikel['gambar_sampul'] : (artikel['gambar_sampul'].toString().startsWith('/') ? 'https://trashreport.web.id/storage' + artikel['gambar_sampul'] : 'https://trashreport.web.id/storage/' + artikel['gambar_sampul'])))), fit: BoxFit.cover),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(artikel['judul'] ?? '', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
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