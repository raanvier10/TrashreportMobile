import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';

class CreateReportScreen extends StatefulWidget {
  @override
  _CreateReportScreenState createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final ApiClient _apiClient = ApiClient();
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  
  File? _image;
  XFile? _pickedImage;
  bool _isLoading = false;
  double _lat = 0;
  double _lng = 0;
  
  List<dynamic> _kategoriList = [];
  List<dynamic> _wilayahList = [];
  int? _selectedKategori;
  int? _selectedWilayah;
  
  int _deskripsiLength = 0;
  DateTime? _waktuPengambilan;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _fetchKategoriWilayah();
    _getLocation();
    
    _deskripsiController.addListener(() {
      setState(() {
        _deskripsiLength = _deskripsiController.text.length;
      });
    });
  }

  void _fetchKategoriWilayah() async {
    try {
      final resKat = await _apiClient.dio.get('/kategori');
      final resWil = await _apiClient.dio.get('/wilayah');
      setState(() {
        _kategoriList = resKat.data['data'] ?? [];
        _wilayahList = resWil.data['data'] ?? [];
      });
    } catch (e) {}
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _lat = position.latitude;
      _lng = position.longitude;
    });
    _mapController.move(LatLng(_lat, _lng), 15.0);
  }

  void _pickImage() async {
    final picker = ImagePicker();
    // Eco-Cam: Wajib ambil dari kamera langsung, tidak bisa dari galeri
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) {
      if (_lat == 0 && _lng == 0) {
        await _getLocation(); // pastikan GPS terambil
      }
      setState(() {
        _pickedImage = pickedFile;
        if (!kIsWeb) {
          _image = File(pickedFile.path);
        }
        _waktuPengambilan = DateTime.now();
      });
    }
  }

  void _submit() async {
    if (_pickedImage == null) {
      _showError('Silakan ambil foto bukti melalui Eco-Cam terlebih dahulu.');
      return;
    }
    if (_judulController.text.isEmpty || _selectedKategori == null || _selectedWilayah == null) {
      _showError('Judul, Kategori, dan Wilayah wajib diisi!');
      return;
    }
    if (_deskripsiLength < 20 || _deskripsiLength > 500) {
      _showError('Deskripsi Kondisi harus memiliki panjang antara 20 - 500 karakter.');
      return;
    }
    if (_lat == 0 || _lng == 0) {
      _showError('Lokasi GPS tidak ditemukan. Harap pastikan GPS perangkat Anda menyala.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      MultipartFile multipartFile;
      if (kIsWeb) {
        final bytes = await _pickedImage!.readAsBytes();
        multipartFile = MultipartFile.fromBytes(bytes, filename: _pickedImage!.name);
      } else {
        multipartFile = await MultipartFile.fromFile(_pickedImage!.path, filename: _pickedImage!.name);
      }

      FormData formData = FormData.fromMap({
        'judul': _judulController.text,
        'deskripsi': _deskripsiController.text,
        'kategori_id': _selectedKategori,
        'wilayah_id': _selectedWilayah,
        'alamat': 'Lat: $_lat, Lng: $_lng',
        'lintang': _lat,
        'bujur': _lng,
        'foto': multipartFile,
      });

      final response = await _apiClient.dio.post('/pelapor/laporan', data: formData);
      if (response.statusCode == 201 || response.statusCode == 200) {
        // ignore: use_build_context_synchronously
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 80),
                  const SizedBox(height: 16),
                  Text('Berhasil!', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A1A))),
                  const SizedBox(height: 8),
                  Text('Laporan Anda berhasil dikirim dan akan segera diproses oleh petugas.', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 14, color: const Color(0xFF666666))),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D530E), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: () {
                        Navigator.pop(context); // close dialog
                        Navigator.pop(context, true); // close screen and return true
                      },
                      child: Text('Kembali ke Dashboard', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    } on DioException catch (e) {
      String msg = 'Gagal mengirim laporan. Periksa koneksi Anda.';
      if (e.response != null && e.response?.statusCode == 422) {
        msg = 'Data tidak lengkap atau format salah.';
      }
      _showError(msg);
    } catch (e) {
      _showError('Terjadi kesalahan tidak terduga.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0D530E);
    const Color textPrimary = Color(0xFF1A1A1A);
    const Color textSecondary = Color(0xFF666666);
    const Color borderDefault = Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text('Buat Laporan Baru', style: GoogleFonts.outfit(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Eco-Cam Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderDefault),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Eco-Cam — Laporkan Sampah', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
                  const SizedBox(height: 4),
                  Text('Ambil foto sampah, pilih kategori, dan kirim laporan Anda.', style: GoogleFonts.outfit(fontSize: 12, color: textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Foto Section
            Text('Foto Sampah (Eco-Cam)', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 240, width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderDefault, style: BorderStyle.solid),
                ),
                child: _pickedImage == null 
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(color: Color(0xFFEAF5EA), shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: primaryColor, size: 32),
                        ),
                        const SizedBox(height: 12),
                        Text('Belum ada foto', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary)),
                        const SizedBox(height: 4),
                        Text('Ambil foto langsung di lokasi kejadian', style: GoogleFonts.outfit(fontSize: 12, color: textSecondary)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text('Buka Kamera Pintar', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        )
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          kIsWeb ? Image.network(_pickedImage!.path, fit: BoxFit.cover) : Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
                          // Geo-tagging Watermark Overlay
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                )
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.redAccent, size: 14),
                                      const SizedBox(width: 4),
                                      Expanded(child: Text('Lat: $_lat, Lng: $_lng', style: GoogleFonts.outfit(color: Colors.white, fontSize: 11))),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, color: Colors.white70, size: 14),
                                      const SizedBox(width: 4),
                                      Text(_waktuPengambilan != null ? DateFormat('dd MMM yyyy, HH:mm:ss').format(_waktuPengambilan!) : '', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Retake button
                          Positioned(
                            top: 8, right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                              child: const Icon(Icons.refresh, color: Colors.white, size: 20),
                            ),
                          )
                        ],
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.verified_user, color: Colors.green, size: 12),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Dilindungi dengan sistem anti-hoax (Watermark GPS & Waktu otomatis).', 
                    style: GoogleFonts.outfit(fontSize: 10, color: Colors.green.shade700)
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form Field: Judul
            Text('Judul Laporan', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _judulController,
              style: GoogleFonts.outfit(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Contoh: Tumpukan sampah di pinggir jalan',
                hintStyle: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderDefault)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderDefault)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Kategori & Wilayah Berdampingan
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kategori Sampah', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderDefault),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedKategori,
                            isExpanded: true,
                            hint: Text('Pilih', style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey)),
                            items: _kategoriList.map((k) => DropdownMenuItem<int>(value: k['id'], child: Text(k['nama'], style: GoogleFonts.outfit(fontSize: 14), overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (v) => setState(() => _selectedKategori = v),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Wilayah', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderDefault),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedWilayah,
                            isExpanded: true,
                            hint: Text('Pilih', style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey)),
                            items: _wilayahList.map((w) => DropdownMenuItem<int>(value: w['id'], child: Text(w['nama'], style: GoogleFonts.outfit(fontSize: 14), overflow: TextOverflow.ellipsis))).toList(),
                            onChanged: (v) => setState(() => _selectedWilayah = v),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Deskripsi
            Text('Deskripsi Kondisi', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _deskripsiController,
              maxLines: 4,
              maxLength: 500,
              style: GoogleFonts.outfit(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Jelaskan kondisi lokasi secara rinci...',
                hintStyle: GoogleFonts.outfit(fontSize: 13, color: Colors.grey),
                counterText: '', // Hide default counter to make custom one
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderDefault)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: borderDefault)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Minimal 20, maksimal 500 karakter.', style: GoogleFonts.outfit(fontSize: 11, color: textSecondary)),
                Text('$_deskripsiLength/500 Karakter', style: GoogleFonts.outfit(fontSize: 11, color: _deskripsiLength < 20 && _deskripsiLength > 0 ? Colors.red : textSecondary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),

            // Map GPS
            Text('Lokasi GPS', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
            const SizedBox(height: 8),
            Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderDefault),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(_lat == 0 ? -6.200 : _lat, _lng == 0 ? 106.816 : _lng),
                    initialZoom: 15.0,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none), // Static map feel for form
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.trashreport.app',
                    ),
                    if (_lat != 0 && _lng != 0)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(_lat, _lng),
                            child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
                          )
                        ],
                      )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: borderDefault), borderRadius: BorderRadius.circular(8)),
                    child: Text('$_lat', style: GoogleFonts.outfit(fontSize: 13, color: textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: borderDefault), borderRadius: BorderRadius.circular(8)),
                    child: Text('$_lng', style: GoogleFonts.outfit(fontSize: 13, color: textSecondary)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.my_location, size: 16),
              label: const Text('Ambil Lokasi Saat Ini'),
              style: OutlinedButton.styleFrom(
                foregroundColor: textPrimary,
                side: const BorderSide(color: borderDefault),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _getLocation,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: borderDefault),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Batal', style: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  icon: _isLoading ? const SizedBox() : const Icon(Icons.send, color: Colors.white, size: 18),
                  label: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Kirim Laporan', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isLoading ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}