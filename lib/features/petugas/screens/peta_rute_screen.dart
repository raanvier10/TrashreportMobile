import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'task_detail_screen.dart';

class PetaRuteScreen extends StatefulWidget {
  final dynamic tugas;

  const PetaRuteScreen({Key? key, required this.tugas}) : super(key: key);

  @override
  _PetaRuteScreenState createState() => _PetaRuteScreenState();
}

class _PetaRuteScreenState extends State<PetaRuteScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  dynamic _selectedTugas;
  double _currentZoom = 13.0;

  String _searchQuery = '';
  String _selectedFilter = 'Semua Tugas';
  final List<String> _filters = ['Semua Tugas', 'Baru Ditugaskan', 'Sedang Dieksekusi'];

  final Color primaryColor = const Color(0xFF0D530E);
  final Color infoColor = const Color(0xFF2563eb);
  final Color errorColor = const Color(0xFFdc2626);
  final Color warningColor = const Color(0xFFd97706);

  @override
  void initState() {
    super.initState();
    _getUserLocation();
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
        _mapController.move(_currentLocation!, _currentZoom);
      });
    }
  }

  Color _getMarkerColor(String status) {
    status = status.toLowerCase();
    if (status == 'selesai') return primaryColor;
    if (status == 'sedang dibersihkan' || status == 'dalam perjalanan') return warningColor;
    return errorColor; // menunggu / ditugaskan
  }

  void _zoomIn() {
    setState(() {
      _currentZoom = (_currentZoom + 1).clamp(1.0, 18.0);
      _mapController.move(_mapController.camera.center, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom = (_currentZoom - 1).clamp(1.0, 18.0);
      _mapController.move(_mapController.camera.center, _currentZoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> taskList = widget.tugas is List ? widget.tugas : [];
    
    // Filter logic
    List<dynamic> activeTasks = taskList.where((t) {
      final laporan = t;
      String status = (laporan['status'] ?? '').toString().toLowerCase();
      String judul = (laporan['judul'] ?? '').toString().toLowerCase();
      
      // Exclude finished tasks on map to keep it clean (unless requested)
      if (status == 'selesai' || status == 'ditutup') return false;

      // Filter by Search Query
      if (_searchQuery.isNotEmpty && !judul.contains(_searchQuery.toLowerCase())) {
        return false;
      }

      // Filter by Dropdown
      if (_selectedFilter == 'Baru Ditugaskan' && !status.contains('ditugaskan')) return false;
      if (_selectedFilter == 'Sedang Dieksekusi' && !(status.contains('jalan') || status.contains('bersih'))) return false;

      return true;
    }).toList();

    List<Marker> markers = [];
    
    // Add current location marker
    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 24, height: 24,
          child: Container(
            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.3), shape: BoxShape.circle),
            child: const Center(
              child: Icon(Icons.my_location, color: Colors.blue, size: 16),
            ),
          ),
        )
      );
    }

    // Add tasks markers
    for (var t in activeTasks) {
      final laporan = t;
      double lat = double.tryParse(laporan['lintang'].toString()) ?? 0;
      double lng = double.tryParse(laporan['bujur'].toString()) ?? 0;
      if (lat != 0 && lng != 0) {
        String status = (laporan['status'] ?? '').toString();
        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 32, height: 32,
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTugas = t);
                _mapController.move(LatLng(lat, lng), _currentZoom);
              },
              child: Icon(
                Icons.location_on, 
                color: _getMarkerColor(status), 
                size: _selectedTugas == t ? 36 : 28 // Diperkecil dari 48/36
              ),
            ),
          )
        );
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Peta Rute', style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_currentLocation != null) {
                _mapController.move(_currentLocation!, _currentZoom);
              }
            },
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? const LatLng(-6.200000, 106.816666),
              initialZoom: _currentZoom,
              onTap: (_, __) => setState(() => _selectedTugas = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.trashreport.app',
              ),
              MarkerLayer(markers: markers),
            ],
          ),
          
          // Search & Filter Overlay
          Positioned(
            top: 16, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Cari tugas...',
                            hintStyle: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: GoogleFonts.outfit(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
                      items: _filters.map((f) => DropdownMenuItem(value: f, child: Text(f, style: GoogleFonts.outfit(fontSize: 14)))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedFilter = val);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Zoom Controls
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: 16,
            bottom: _selectedTugas != null ? 180 : 32, // Move up if card is showing
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Colors.black87),
                  onPressed: _zoomIn,
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.remove, color: Colors.black87),
                  onPressed: _zoomOut,
                ),
              ],
            ),
          ),

          // Legend
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: 16,
            bottom: _selectedTugas != null ? 180 : 32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [Icon(Icons.location_on, color: errorColor, size: 14), const SizedBox(width: 6), Text('Baru Ditugaskan', style: GoogleFonts.outfit(fontSize: 11))]),
                  const SizedBox(height: 4),
                  Row(children: [Icon(Icons.location_on, color: warningColor, size: 14), const SizedBox(width: 6), Text('Sedang Dieksekusi', style: GoogleFonts.outfit(fontSize: 11))]),
                ],
              ),
            ),
          ),

          // Task Card
          if (_selectedTugas != null)
            Positioned(
              left: 16, right: 16, bottom: 16,
              child: _buildTaskCard(_selectedTugas),
            ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(dynamic tugas) {
    final laporan = tugas;
    final wilayah = laporan['wilayah'] ?? {};
    String status = (laporan['status'] ?? 'MENUNGGU').toString().toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  laporan['judul'] ?? 'Tugas Pembersihan',
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: warningColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status.length > 10 ? status.substring(0,10)+'...' : status, style: GoogleFonts.outfit(color: warningColor, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Expanded(child: Text(wilayah['nama'] ?? 'Wilayah Tidak Diketahui', style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 12))),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(tugas: tugas)));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('Lihat Detail Tugas', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}