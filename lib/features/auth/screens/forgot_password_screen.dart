import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

// ── Colors ──
const Color primary500 = Color(0xFF0D530E);
const Color primary400 = Color(0xFF1B6A1C);
const Color primary50 = Color(0xFFEAF5EA);
const Color textPrimary = Color(0xFF1A1A1A);
const Color textSecondary = Color(0xFF666666);
const Color textTertiary = Color(0xFF999999);
const Color neutral50 = Color(0xFFF8F9FA);
const Color borderDefault = Color(0xFFE5E7EB);
const Color danger50 = Color(0xFFFEF2F2);
const Color danger500 = Color(0xFFEF4444);
const Color danger700 = Color(0xFFB91C1C);

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final ApiClient _apiClient = ApiClient();
  
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMsg;

  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscurePassConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    if (_emailCtrl.text.isEmpty) {
      setState(() => _errorMsg = 'Email wajib diisi');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final response = await _apiClient.dio.post('/forgot-password', data: {
        'email': _emailCtrl.text.trim(),
      });
      
      if (response.statusCode == 200 && response.data['success']) {
        setState(() => _currentStep = 1);
      } else {
        setState(() => _errorMsg = response.data['message']);
      }
    } on DioException catch (e) {
      setState(() {
        _errorMsg = e.response?.data['message'] ?? 'Gagal mengirim OTP.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _verifyOtp() async {
    if (_otpCtrl.text.length != 6) {
      setState(() => _errorMsg = 'Kode OTP harus 6 digit');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final response = await _apiClient.dio.post('/verify-otp', data: {
        'email': _emailCtrl.text.trim(),
        'token': _otpCtrl.text.trim(),
      });
      
      if (response.statusCode == 200 && response.data['success']) {
        setState(() => _currentStep = 2);
      } else {
        setState(() => _errorMsg = response.data['message']);
      }
    } on DioException catch (e) {
      setState(() {
        _errorMsg = e.response?.data['message'] ?? 'OTP tidak valid.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetPassword() async {
    if (_passCtrl.text.length < 8) {
      setState(() => _errorMsg = 'Password minimal 8 karakter');
      return;
    }
    if (_passCtrl.text != _passConfirmCtrl.text) {
      setState(() => _errorMsg = 'Konfirmasi password tidak cocok');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final response = await _apiClient.dio.post('/reset-password', data: {
        'email': _emailCtrl.text.trim(),
        'token': _otpCtrl.text.trim(),
        'password': _passCtrl.text,
        'password_confirmation': _passConfirmCtrl.text,
      });
      
      if (response.statusCode == 200 && response.data['success']) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password berhasil diubah. Silakan login.')),
        );
        Navigator.pop(context); // Kembali ke login
      } else {
        setState(() => _errorMsg = response.data['message']);
      }
    } on DioException catch (e) {
      setState(() {
        _errorMsg = e.response?.data['message'] ?? 'Gagal mereset password.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 20),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        _currentStep == 0 ? 'Lupa Password' : (_currentStep == 1 ? 'Verifikasi OTP' : 'Buat Password Baru'),
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentStep == 0 
                          ? 'Masukkan email Anda yang terdaftar untuk menerima kode OTP.' 
                          : (_currentStep == 1 ? 'Masukkan 6 digit kode OTP yang kami kirimkan ke email ${_emailCtrl.text}.' : 'Silakan masukkan password baru Anda yang kuat dan aman.'),
                        style: GoogleFonts.outfit(fontSize: 14, color: textSecondary, height: 1.5),
                      ),
                      const SizedBox(height: 36),

                      if (_errorMsg != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: danger50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: danger500.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: danger500, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorMsg!,
                                  style: GoogleFonts.outfit(color: danger700, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      if (_currentStep == 0) _buildStep0(),
                      if (_currentStep == 1) _buildStep1(),
                      if (_currentStep == 2) _buildStep2(),

                      const Spacer(),
                      const SizedBox(height: 20),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary500,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: _isLoading ? null : () {
                          if (_currentStep == 0) _sendOtp();
                          else if (_currentStep == 1) _verifyOtp();
                          else _resetPassword();
                        },
                        child: _isLoading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _currentStep == 0 ? 'Kirim OTP' : (_currentStep == 1 ? 'Verifikasi' : 'Simpan Password'),
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStep0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Email Address', style: GoogleFonts.outfit(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.outfit(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'masukkan@email.com',
            hintStyle: GoogleFonts.outfit(color: textTertiary, fontSize: 15),
            prefixIcon: const Icon(Icons.email_outlined, color: textTertiary),
            filled: true,
            fillColor: neutral50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderDefault, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primary500, width: 1.8)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kode OTP (6 Angka)', style: GoogleFonts.outfit(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: GoogleFonts.outfit(color: textPrimary, fontSize: 18, letterSpacing: 8, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            counterText: '',
            hintText: '000000',
            hintStyle: GoogleFonts.outfit(color: textTertiary, fontSize: 18, letterSpacing: 8),
            filled: true,
            fillColor: neutral50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderDefault, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primary500, width: 1.8)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Password Baru', style: GoogleFonts.outfit(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passCtrl,
          obscureText: _obscurePass,
          style: GoogleFonts.outfit(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Minimal 8 karakter',
            hintStyle: GoogleFonts.outfit(color: textTertiary, fontSize: 15),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: textTertiary),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePass = !_obscurePass),
              child: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: textTertiary),
            ),
            filled: true,
            fillColor: neutral50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderDefault, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primary500, width: 1.8)),
          ),
        ),
        const SizedBox(height: 20),
        Text('Konfirmasi Password', style: GoogleFonts.outfit(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passConfirmCtrl,
          obscureText: _obscurePassConfirm,
          style: GoogleFonts.outfit(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Ulangi password baru',
            hintStyle: GoogleFonts.outfit(color: textTertiary, fontSize: 15),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: textTertiary),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePassConfirm = !_obscurePassConfirm),
              child: Icon(_obscurePassConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: textTertiary),
            ),
            filled: true,
            fillColor: neutral50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderDefault, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primary500, width: 1.8)),
          ),
        ),
      ],
    );
  }
}
