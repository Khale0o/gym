import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/providers/auth_provider.dart';
import 'package:gymsaas/widgets/apex_text.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController(text: 'admin@apex.gym');
  final _passCtrl = TextEditingController(text: 'apex2024');
  bool _loading = false;
  String? _error;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _typeCtrl;
  late Animation<double> _typeAnim;

  static const String _brandName = 'APEX';

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _typeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _typeAnim = CurvedAnimation(parent: _typeCtrl, curve: Curves.easeOut);

    _fadeCtrl.forward();
    _typeCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _fadeCtrl.dispose();
    _typeCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await ref.read(authProvider.notifier).login(_emailCtrl.text, _passCtrl.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // مراقبة المصادقة والتوجيه التلقائي
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isLoggedIn) {
        context.go('/');
      }
    });

    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.6, -0.6),
                  radius: 1.2,
                  colors: [Color(0xFF1A1200), bgDark],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, gold, Colors.transparent],
                ),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderDark),
                  boxShadow: [
                    BoxShadow(
                      color: gold.withOpacity(0.06),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // الشعار الذهبي
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [gold, goldDark],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: gold.withOpacity(0.3),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.fitness_center,
                          color: Colors.black, size: 28),
                    ),
                    const SizedBox(height: 16),
                    // كتابة APEX حرف حرف
                    _BuildTypewriterText(
                      text: _brandName,
                      animation: _typeAnim,
                      style: GoogleFonts.cinzel(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: gold,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // النص الفرعي يظهر بعد انتهاء معظم الكتابة
                    AnimatedBuilder(
                      animation: _typeAnim,
                      builder: (context, child) {
                        final appear = _typeAnim.value > 0.7;
                        return Opacity(
                          opacity: appear ? 1.0 : 0.0,
                          child: Transform.translate(
                            offset: Offset(0, appear ? 0 : 10),
                            child: child,
                          ),
                        );
                      },
                      child: const ApexText(
                        'Gym Management System',
                        fontSize: 12,
                        color: Color(0xFF555555),
                      ),
                    ),
                    const SizedBox(height: 36),
                    // حقل البريد الإلكتروني
                    _ApexInput(
                      controller: _emailCtrl,
                      label: 'Email',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 12),
                    // حقل كلمة المرور
                    _ApexInput(
                      controller: _passCtrl,
                      label: 'Password',
                      icon: Icons.lock_outline_rounded,
                      obscure: true,
                    ),
                    const SizedBox(height: 8),
                    if (_error != null) ...[
                      const SizedBox(height: 4),
                      ApexText(_error!,
                          fontSize: 12,
                          color: redAlert,
                          fontWeight: FontWeight.w500),
                    ],
                    const SizedBox(height: 24),
                    // زر الدخول
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.black, strokeWidth: 2),
                              )
                            : Text(
                                'SIGN IN',
                                style: GoogleFonts.cinzel(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const ApexText(
                      'Pre-filled for demo — tap Sign In',
                      fontSize: 10,
                      color: Color(0xFF3A3A3A),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// ويدجت الكتابة الحرفية (Typewriter)
// ────────────────────────────────────────────────────────────────────────
class _BuildTypewriterText extends StatelessWidget {
  final String text;
  final Animation<double> animation;
  final TextStyle style;

  const _BuildTypewriterText({
    required this.text,
    required this.animation,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final chars = text.split('');
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = animation.value;
        final visibleCount = (progress * chars.length).ceil().clamp(0, chars.length);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(chars.length, (index) {
            if (index >= visibleCount) {
              // لم يظهر بعد
              return Opacity(opacity: 0.0, child: Text(chars[index], style: style));
            } else if (index == visibleCount - 1 && progress < 1.0) {
              // الحرف الحالي: يظهر بتأثير fade + slide
              final charProgress = (progress * chars.length) - index;
              return Opacity(
                opacity: charProgress.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, (1 - charProgress) * 10),
                  child: Text(chars[index], style: style),
                ),
              );
            } else {
              // ظهر بالكامل
              return Text(chars[index], style: style);
            }
          }),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// حقل إدخال مخصص
// ────────────────────────────────────────────────────────────────────────
class _ApexInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;

  const _ApexInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF555555), fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFF444444), size: 18),
        filled: true,
        fillColor: const Color(0xFF0A0A0A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: gold),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}