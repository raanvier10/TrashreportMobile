import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../../pelapor/dashboard/pelapor_dashboard.dart';

// ── Colors ──
const Color primary500 = Color(0xFF0D530E);
const Color primary400 = Color(0xFF1B6A1C);
const Color primary50 = Color(0xFFEAF5EA);
const Color primary200 = Color(0xFFA8DDAA);
const Color primary600 = Color(0xFF0A400A);
const Color primary700 = Color(0xFF072B07);

const Color textPrimary = Color(0xFF1A1A1A);
const Color textSecondary = Color(0xFF666666);
const Color textTertiary = Color(0xFF999999);

const Color neutral50 = Color(0xFFF8F9FA);
const Color borderDefault = Color(0xFFE5E7EB);

const Color danger50 = Color(0xFFFEF2F2);
const Color danger500 = Color(0xFFEF4444);
const Color danger700 = Color(0xFFB91C1C);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMsg;

  final AuthService _authService = AuthService();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _errorMsg = 'Password dan Ulangi Password tidak cocok!');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final result = await _authService.register(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _phoneCtrl.text.trim(),
      _passCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => PelaporDashboard()),
        (route) => false,
      );
    } else {
      setState(() => _errorMsg = result['message'] ?? 'Gagal mendaftar. Silakan coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // ── Content ────────────────────────────────────────
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 24,
                        ),
                        child: IntrinsicHeight(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 8),

                        // ── Back button ─────────────────────
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 22,
                                color: textPrimary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Heading ─────────────────────────
                        Text(
                          'Buat Akun Baru',
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Mari bergabung menjadi pahlawan kebersihan untuk lingkungan yang lebih baik!',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: textSecondary,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Error banner ───────────────────
                        if (_errorMsg != null) ...[
                          _ErrorBanner(message: _errorMsg!),
                          const SizedBox(height: 16),
                        ],

                        // ── Nama Lengkap ───────────────────
                        const _AuthLabel('Nama Lengkap'),
                        const SizedBox(height: 8),
                        _AuthField(
                          controller: _nameCtrl,
                          hint: 'Budi Santoso',
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (v) =>
                              (v?.isEmpty ?? true) ? 'Nama wajib diisi' : null,
                        ),

                        const SizedBox(height: 16),

                        // ── Email ──────────────────────────
                        const _AuthLabel('Email Address'),
                        const SizedBox(height: 8),
                        _AuthField(
                          controller: _emailCtrl,
                          hint: 'nama@email.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v?.isEmpty ?? true) return 'Email wajib diisi';
                            if (!v!.contains('@')) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // ── No HP ──────────────────────────
                        const _AuthLabel('Nomor Telepon'),
                        const SizedBox(height: 8),
                        _AuthField(
                          controller: _phoneCtrl,
                          hint: '081234567890',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) => (v?.length ?? 0) < 10
                              ? 'Nomor telepon tidak valid'
                              : null,
                        ),

                        const SizedBox(height: 16),

                        // ── Password ───────────────────────
                        const _AuthLabel('Password'),
                        const SizedBox(height: 8),
                        _AuthField(
                          controller: _passCtrl,
                          hint: 'Minimal 6 karakter',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscurePass,
                          suffixIcon: GestureDetector(
                            onTap: () =>
                                setState(() => _obscurePass = !_obscurePass),
                            child: Icon(
                              _obscurePass
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: textTertiary,
                            ),
                          ),
                          validator: (v) => (v?.length ?? 0) < 6
                              ? 'Password minimal 6 karakter'
                              : null,
                        ),

                        const SizedBox(height: 16),

                        // ── Konfirmasi Password ────────────
                        const _AuthLabel('Ulangi Password'),
                        const SizedBox(height: 8),
                        _AuthField(
                          controller: _confirmCtrl,
                          hint: 'Ulangi password',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscureConfirm,
                          suffixIcon: GestureDetector(
                            onTap: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                            child: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: textTertiary,
                            ),
                          ),
                          validator: (v) =>
                              v != _passCtrl.text ? 'Password tidak cocok' : null,
                        ),

                        const SizedBox(height: 32),

                        // ── CTA Button ─────────────────────
                        _GradientButton(
                          label: 'Daftar Sekarang',
                          isLoading: _isLoading,
                          onPressed: _register,
                        ),

                        const SizedBox(height: 24),

                        // ── Sign in link ───────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sudah punya akun? ',
                              style: GoogleFonts.outfit(
                                color: textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                'Masuk di sini',
                                style: GoogleFonts.outfit(
                                  color: primary500,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                  decorationColor: primary500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Shared Auth Widgets
// ─────────────────────────────────────────────────────────────────

class _AuthLabel extends StatelessWidget {
  final String text;
  const _AuthLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _AuthField({
    super.key,
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.outfit(
        color: textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: textTertiary, fontSize: 15),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Icon(prefixIcon, size: 22, color: textTertiary),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 16),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: neutral50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderDefault, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary500, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: danger500, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: danger500, width: 1.8),
        ),
        errorStyle: GoogleFonts.outfit(color: danger500, fontSize: 13),
      ),
    );
  }
}

class _GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const _GradientButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isLoading) _scaleCtrl.reverse();
      },
      onTapUp: (_) {
        if (!widget.isLoading) {
          _scaleCtrl.forward();
          widget.onPressed();
        }
      },
      onTapCancel: () => _scaleCtrl.forward(),
      child: AnimatedBuilder(
        animation: _scaleCtrl,
        builder: (_, child) =>
            Transform.scale(scale: _scaleCtrl.value, child: child),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primary500, primary400],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primary500.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          alignment: Alignment.center,
          child: widget.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.label,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 22),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: danger50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: danger500.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: danger500, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.outfit(
                color: danger700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}