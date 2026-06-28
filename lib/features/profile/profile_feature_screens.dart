import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/api_client.dart';

const Color primaryColor = Color(0xFF0D530E);
const Color bgColor = Color(0xFFF8F9FA);
const Color borderDefault = Color(0xFFE5E7EB);
const Color textPrimary = Color(0xFF1A1A1A);

// --- EDIT PROFILE SCREEN ---
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _teleponController = TextEditingController();
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  XFile? _pickedImage;
  String? _existingFoto;

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  void _loadCurrentData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _namaController.text = prefs.getString('user_name') ?? '';
      _emailController.text = prefs.getString('user_email') ?? '';
      _teleponController.text = prefs.getString('user_telepon') ?? '';
      _existingFoto = prefs.getString('user_foto');
    });
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _pickedImage = pickedFile);
    }
  }

  void _saveProfile() async {
    if (_namaController.text.isEmpty || _emailController.text.isEmpty || _teleponController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua bidang wajib diisi!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> data = {
        'nama': _namaController.text,
        'email': _emailController.text,
        'telepon': _teleponController.text,
      };

      if (_pickedImage != null) {
        if (kIsWeb) {
          final bytes = await _pickedImage!.readAsBytes();
          data['foto_profil'] = MultipartFile.fromBytes(bytes, filename: _pickedImage!.name);
        } else {
          data['foto_profil'] = await MultipartFile.fromFile(_pickedImage!.path, filename: _pickedImage!.name);
        }
      }

      final response = await _apiClient.dio.post('/profil/update', data: FormData.fromMap(data));

      if (response.statusCode == 200) {
        final userData = response.data['data'];
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', userData['name']);
        await prefs.setString('user_email', userData['email']);
        await prefs.setString('user_telepon', userData['telepon']);
        if (userData['foto_profil'] != null) {
          await prefs.setString('user_foto', userData['foto_profil']);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui'), backgroundColor: Colors.green));
          Navigator.pop(context, true); // return true to trigger refresh
        }
      }
    } on DioException catch (e) {
      String msg = 'Gagal menyimpan profil.';
      if (e.response?.statusCode == 422) msg = 'Email sudah digunakan atau format salah.';
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Edit Profil', style: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        image: _pickedImage != null 
                          ? (kIsWeb ? DecorationImage(image: NetworkImage(_pickedImage!.path), fit: BoxFit.cover) : DecorationImage(image: FileImage(File(_pickedImage!.path)), fit: BoxFit.cover))
                          : (_existingFoto != null ? DecorationImage(image: NetworkImage('https://trashreport.web.id/storage/$_existingFoto'), fit: BoxFit.cover) : null),
                      ),
                      child: (_pickedImage == null && _existingFoto == null) ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField('Nama Lengkap', _namaController, Icons.person_outline),
            const SizedBox(height: 16),
            _buildTextField('Email', _emailController, Icons.email_outlined, isEmail: true),
            const SizedBox(height: 16),
            _buildTextField('Nomor Telepon', _teleponController, Icons.phone_outlined, isNumber: true),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Simpan Perubahan', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isEmail = false, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isEmail ? TextInputType.emailAddress : (isNumber ? TextInputType.phone : TextInputType.text),
          style: GoogleFonts.outfit(fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderDefault)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderDefault)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

// --- CHANGE PASSWORD SCREEN ---
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  void _savePassword() async {
    if (_oldPasswordController.text.isEmpty || _newPasswordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua bidang wajib diisi!'), backgroundColor: Colors.red));
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konfirmasi password tidak cocok!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.dio.post('/profil/password', data: {
        'password_lama': _oldPasswordController.text,
        'password_baru': _newPasswordController.text,
        'password_baru_confirmation': _confirmPasswordController.text,
      });

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } on DioException catch (e) {
      String msg = 'Gagal mengubah password.';
      if (e.response?.statusCode == 400) msg = 'Password lama salah.';
      if (e.response?.statusCode == 422) msg = 'Password minimal 8 karakter.';
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Ubah Password', style: GoogleFonts.outfit(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPasswordField('Password Lama', _oldPasswordController, _obscureOld, () => setState(() => _obscureOld = !_obscureOld)),
            const SizedBox(height: 16),
            _buildPasswordField('Password Baru', _newPasswordController, _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
            const SizedBox(height: 16),
            _buildPasswordField('Konfirmasi Password Baru', _confirmPasswordController, _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _savePassword,
                child: _isLoading 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Perbarui Password', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool obscureText, VoidCallback onToggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: GoogleFonts.outfit(fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade500, size: 20),
            suffixIcon: IconButton(
              icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade400, size: 20),
              onPressed: onToggle,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderDefault)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: borderDefault)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}