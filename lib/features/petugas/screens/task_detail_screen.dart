import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/api_client.dart';

class TaskDetailScreen extends StatefulWidget {
  final dynamic tugas;
  const TaskDetailScreen({Key? key, required this.tugas}) : super(key: key);

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final ApiClient _apiClient = ApiClient();
  int _currentStep = 0;
  bool _isLoading = false;
  File? _image;
  final TextEditingController _keteranganController = TextEditingController();

  final Color primaryColor = const Color(0xFF0D530E);
  final Color bgColor = const Color(0xFFF9FAFB);
  final Color inkColor = const Color(0xFF111827);
  final Color muteColor = const Color(0xFF6B7280);
  final Color hairlineColor = const Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    final laporan = widget.tugas;
    String status = (laporan['status'] ?? '').toString().toLowerCase();
    if (status == 'dalam perjalanan') _currentStep = 1;
    if (status == 'sedang dibersihkan' || status == 'sedang dikerjakan') _currentStep = 2;
    if (status == 'selesai' || status == 'ditutup') _currentStep = 2;
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  void _updateStatus(String status) async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.dio.post(
        '/petugas/tugas/${widget.tugas['id']}/verifikasi',
        data: {'status': status},
      );
      if (response.statusCode == 200) {
        setState(() {
          if (status == 'Dalam Perjalanan') _currentStep = 1;
          if (status == 'Sedang Dibersihkan') _currentStep = 2;
          widget.tugas['laporan']['status'] = status;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status diperbarui')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memperbarui status')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _submitSelesai() async {
    if (_image == null || _keteranganController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto dan keterangan wajib diisi!')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      String fileName = _image!.path.split('/').last;
      FormData formData = FormData.fromMap({
        'status': 'Selesai',
        'keterangan': _keteranganController.text,
        'foto_bukti': await MultipartFile.fromFile(_image!.path, filename: fileName),
      });

      final response = await _apiClient.dio.post(
        '/petugas/tugas/${widget.tugas['id']}/verifikasi',
        data: formData,
      );

      if (response.statusCode == 200) {
        setState(() {
          _currentStep = 2;
          widget.tugas['laporan']['status'] = 'Selesai';
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tugas Selesai!')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyelesaikan tugas')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka Google Maps')));
    }
  }

  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    if (status == 'selesai') return primaryColor;
    if (status == 'dalam perjalanan' || status == 'sedang dibersihkan') return const Color(0xFF2563EB);
    return const Color(0xFFD97706); // ditugaskan/menunggu
  }

  @override
  Widget build(BuildContext context) {
    final laporan = widget.tugas;
    final status = (laporan['status'] ?? 'DITUGASKAN').toString().toUpperCase();
    final isSelesai = status == 'SELESAI' || status == 'DITUTUP';

    double lat = double.tryParse(laporan['lintang'].toString()) ?? -6.200000;
    double lng = double.tryParse(laporan['bujur'].toString()) ?? 106.816666;
    LatLng location = LatLng(lat, lng);

    String imgSebelum = '';
    String imgSesudah = '';
    
    if (laporan['gambar'] != null && laporan['gambar'] is List) {
      for (var g in laporan['gambar']) {
        if (g['tipe_gambar'] == 'sebelum' && imgSebelum.isEmpty) imgSebelum = 'https://trashreport.web.id/storage/' + g['jalur_gambar'];
        if (g['tipe_gambar'] == 'sesudah' && imgSesudah.isEmpty) imgSesudah = 'https://trashreport.web.id/storage/' + g['jalur_gambar'];
      }
    }
    if (imgSebelum.isEmpty && laporan['foto'] != null) imgSebelum = 'https://trashreport.web.id/storage/' + laporan['foto'];
    if (imgSesudah.isEmpty && laporan['foto_sesudah'] != null) imgSesudah = 'https://trashreport.web.id/storage/' + laporan['foto_sesudah'];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Kembali ke Daftar Tugas', style: GoogleFonts.outfit(color: inkColor, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: inkColor),
        titleSpacing: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: _buildLeftColumn(laporan, location, status, imgSebelum, imgSesudah)),
                  const SizedBox(width: 24),
                  Expanded(flex: 4, child: _buildRightColumn(isSelesai)),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLeftColumn(laporan, location, status, imgSebelum, imgSesudah),
                const SizedBox(height: 16),
                _buildRightColumn(isSelesai),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, dynamic imageSource, {bool isFile = false}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (BuildContext context) {
        return Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: isFile 
                ? Image.file(imageSource as File, fit: BoxFit.contain, width: double.infinity, height: double.infinity)
                : Image.network(imageSource.toString(), fit: BoxFit.contain, width: double.infinity, height: double.infinity),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLeftColumn(dynamic laporan, LatLng location, String status, String imgSebelum, String imgSesudah) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Info Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: hairlineColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map Area
              SizedBox(
                height: 250,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: location,
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.trashreport.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: location,
                            width: 60, height: 60,
                            child: const Column(
                              children: [
                                Icon(Icons.location_on, color: Color(0xFF0D530E), size: 40),
                              ],
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(laporan['kode_laporan'] ?? '-', style: GoogleFonts.outfit(color: muteColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.outfit(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(laporan['judul'] ?? 'Sampah Liar', style: GoogleFonts.outfit(color: inkColor, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    // Grey Info Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: hairlineColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 14, color: primaryColor),
                                        const SizedBox(width: 6),
                                        Text('ALAMAT / PATOKAN', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: muteColor)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(laporan['alamat'] ?? 'Titik Koordinat: ${location.latitude}, ${location.longitude}', style: GoogleFonts.outfit(fontSize: 13, color: inkColor, height: 1.4)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.person_outline, size: 14, color: primaryColor),
                                        const SizedBox(width: 6),
                                        Text('PELAPOR', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: muteColor)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(laporan['user']?['name'] ?? 'Masyarakat', style: GoogleFonts.outfit(fontSize: 13, color: inkColor)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.description_outlined, size: 14, color: primaryColor),
                              const SizedBox(width: 6),
                              Text('DESKRIPSI LAPORAN', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: muteColor)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(laporan['deskripsi'] ?? '-', style: GoogleFonts.outfit(fontSize: 13, color: inkColor, height: 1.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Google Maps Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor.withOpacity(0.1),
                          foregroundColor: primaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: primaryColor.withOpacity(0.3)),
                          ),
                        ),
                        icon: const Icon(Icons.near_me_outlined),
                        label: Text('Buka Navigasi Peta (Google Maps)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        onPressed: () => _openGoogleMaps(location.latitude, location.longitude),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Bukti Foto Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: hairlineColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bukti Foto', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: inkColor)),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 400;
                  final content = [
                    Expanded(
                      flex: isWide ? 1 : 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SEBELUM (DARI PELAPOR)', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: muteColor)),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 180, width: double.infinity,
                              color: bgColor,
                              child: imgSebelum.isNotEmpty
                                ? GestureDetector(
                                    onTap: () => _showFullScreenImage(context, imgSebelum),
                                    child: Image.network(imgSebelum, fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.image_not_supported, color: muteColor)),
                                  )
                                : Icon(Icons.image_not_supported, color: muteColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 16),
                    Expanded(
                      flex: isWide ? 1 : 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SESUDAH (HASIL EKSEKUSI)', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: muteColor)),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 180, width: double.infinity,
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: hairlineColor, style: BorderStyle.solid),
                              ),
                              child: _image != null 
                                ? GestureDetector(
                                    onTap: () => _showFullScreenImage(context, _image!, isFile: true),
                                    child: Image.file(_image!, fit: BoxFit.cover),
                                  )
                                : (imgSesudah.isNotEmpty
                                  ? GestureDetector(
                                      onTap: () => _showFullScreenImage(context, imgSesudah),
                                      child: Image.network(imgSesudah, fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.image_not_supported, color: muteColor)),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.access_time, color: muteColor, size: 32),
                                        const SizedBox(height: 8),
                                        Text('Belum ada foto sesudah', style: GoogleFonts.outfit(color: muteColor, fontSize: 12)),
                                      ],
                                    )),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ];
                  
                  if (isWide) {
                    return Row(children: content);
                  } else {
                    return Column(children: content);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightColumn(bool isSelesai) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: hairlineColor),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Panel Eksekusi', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: inkColor)),
          const SizedBox(height: 4),
          Text('Ikuti tahapan di bawah ini sesuai urutan kerja di lapangan.', style: GoogleFonts.outfit(fontSize: 12, color: muteColor)),
          const SizedBox(height: 24),
          Divider(height: 1, color: hairlineColor),
          const SizedBox(height: 16),
          
          Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: primaryColor),
            ),
            child: Stepper(
              physics: const NeverScrollableScrollPhysics(),
              currentStep: _currentStep,
              controlsBuilder: (context, details) => const SizedBox.shrink(),
              margin: EdgeInsets.zero,
              steps: [
                Step(
                  title: Text('Berangkat ke Lokasi', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: inkColor)),
                  subtitle: Text(_currentStep == 0 ? 'Klik ini saat Anda mulai berangkat agar pelapor tahu.' : 'Selesai', style: GoogleFonts.outfit(color: muteColor, fontSize: 11)),
                  content: _currentStep == 0 
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            minimumSize: const Size(double.infinity, 44),
                          ),
                          icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.near_me, color: Colors.white, size: 18),
                          label: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Mulai Perjalanan', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: _isLoading ? null : () => _updateStatus('Dalam Perjalanan'),
                        ),
                      )
                    : const SizedBox.shrink(),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: Text('Mulai Eksekusi', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: inkColor)),
                  subtitle: Text(_currentStep == 1 ? 'Klik ini jika Anda sudah mulai bekerja di lokasi.' : (_currentStep < 1 ? 'Menunggu tahap sebelumnya' : 'Selesai'), style: GoogleFonts.outfit(color: muteColor, fontSize: 11)),
                  content: _currentStep == 1
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            minimumSize: const Size(double.infinity, 44),
                          ),
                          icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.cleaning_services, color: Colors.white, size: 18),
                          label: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Mulai Eksekusi', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: _isLoading ? null : () => _updateStatus('Sedang Dibersihkan'),
                        ),
                      )
                    : const SizedBox.shrink(),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                ),
                Step(
                  title: Text('Penutupan Tugas', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: inkColor)),
                  subtitle: Text(_currentStep < 2 ? 'Form akan terbuka setelah tahap sebelumnya selesai.' : (isSelesai ? 'Tugas diselesaikan' : 'Ambil foto bukti pekerjaan'), style: GoogleFonts.outfit(color: muteColor, fontSize: 11)),
                  content: (_currentStep == 2 && !isSelesai)
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                height: 160, width: double.infinity,
                                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: hairlineColor), image: _image != null ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover) : null),
                                child: _image == null ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.camera_alt, color: muteColor, size: 40), const SizedBox(height: 12), Text('Ambil Foto Bukti Sesudah', style: GoogleFonts.outfit(color: muteColor, fontSize: 13))]) : null,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(controller: _keteranganController, style: GoogleFonts.outfit(fontSize: 13), maxLines: 3, decoration: InputDecoration(labelText: 'Keterangan Selesai', labelStyle: GoogleFonts.outfit(fontSize: 13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: [
                                _buildQuickMessageChip('Dibersihkan sepenuhnya'),
                                _buildQuickMessageChip('Sampah sudah steril'),
                                _buildQuickMessageChip('Sisa sedikit puing'),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), minimumSize: const Size(double.infinity, 50)),
                              onPressed: _isLoading ? null : _submitSelesai,
                              child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Selesaikan Tugas', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            )
                          ],
                        ),
                      )
                    : (isSelesai 
                        ? Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3))),
                              child: Column(
                                children: [
                                  const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 40),
                                  const SizedBox(height: 8),
                                  Text('Tugas Selesai', style: GoogleFonts.outfit(color: const Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('Terima kasih atas kerja keras Anda.', style: GoogleFonts.outfit(color: const Color(0xFF047857), fontSize: 12)),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink()),
                  isActive: _currentStep >= 2,
                  state: isSelesai ? StepState.complete : StepState.indexed,
                ),
              ],
            ),
          ),

          if (widget.tugas['ulasan'] != null) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withOpacity(0.3), // Amber soft
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 24),
                      const SizedBox(width: 8),
                      Text('Ulasan Pelapor', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: inkColor)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: List.generate(5, (index) => Icon(
                      index < (widget.tugas['ulasan']['nilai'] ?? 0) ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 20,
                    )),
                  ),
                  if (widget.tugas['ulasan']['komentar'] != null && widget.tugas['ulasan']['komentar'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      '"${widget.tugas['ulasan']['komentar']}"',
                      style: GoogleFonts.outfit(color: muteColor, fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ]
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildQuickMessageChip(String text) {
    return ActionChip(
      label: Text(text, style: GoogleFonts.outfit(fontSize: 11, color: primaryColor, fontWeight: FontWeight.w600)),
      backgroundColor: primaryColor.withOpacity(0.05),
      side: BorderSide(color: primaryColor.withOpacity(0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onPressed: () {
        setState(() {
          _keteranganController.text = text;
        });
      },
    );
  }
}