import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/providers/auth_provider.dart';
import 'package:gymsaas/providers/staff_invite_signup_provider.dart';
import 'package:gymsaas/widgets/apex_text.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _loading = false;
  bool _signupMode = false;
  bool _claimingInvite = false;
  String? _error;
  String? _success;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _typeCtrl;
  late Animation<double> _typeAnim;

  static const String _brandName = 'APEX';

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _typeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _typeAnim = CurvedAnimation(parent: _typeCtrl, curve: Curves.easeOut);

    _fadeCtrl.forward();
    _typeCtrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _confirmPassCtrl.dispose();
    _fadeCtrl.dispose();
    _typeCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    final error = await ref.read(authControllerProvider).signIn(
          email: _emailCtrl.text,
          password: _passCtrl.text,
        );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  Future<void> _signupFromInvite() async {
    final validationError = _validateSignup();
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _loading = true;
      _claimingInvite = true;
      _error = null;
      _success = null;
    });

    final error = await ref
        .read(staffInviteSignupControllerProvider)
        .signUpAndClaimStaffInvite(
          fullName: _fullNameCtrl.text,
          email: _emailCtrl.text,
          password: _passCtrl.text,
          phone: _phoneCtrl.text,
        );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _claimingInvite = false;
      _error = error;
    });

    if (error == null) {
      _passCtrl.clear();
      _confirmPassCtrl.clear();
      setState(() {
        _signupMode = false;
        _success = 'Account created successfully. Please sign in.';
      });
    }
  }

  Future<void> _enterSignupMode() async {
    setState(() {
      _loading = true;
      _error = null;
      _success = null;
    });

    final currentUser = ref.read(firebaseAuthProvider).currentUser;
    if (currentUser != null) {
      await ref.read(firebaseAuthProvider).signOut();
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _signupMode = true;
    });
  }

  String? _validateSignup() {
    final fullName = _fullNameCtrl.text.trim();
    final email = _emailCtrl.text.trim().toLowerCase();
    final password = _passCtrl.text;
    final confirmPassword = _confirmPassCtrl.text;

    if (fullName.isEmpty) return 'Full name is required.';
    if (email.isEmpty) return 'Email is required.';
    final validEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    if (!validEmail) return 'Enter a valid email address.';
    if (password.length < 8) return 'Password must be at least 8 characters.';
    if (confirmPassword != password) return 'Passwords do not match.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<User?>>(authStateProvider, (prev, next) {
      if (next.valueOrNull != null && !_claimingInvite) {
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
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 48,
                      ),
                      child: Center(
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: Container(
                            width: 420,
                            padding: EdgeInsets.all(
                              constraints.maxHeight < 720 ? 24 : 36,
                            ),
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderDark),
                  boxShadow: [
                    BoxShadow(
                      color: gold.withValues(alpha: 0.06),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                            color: gold.withValues(alpha: 0.3),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: Colors.black,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 28),
                    if (_signupMode) ...[
                      _ApexInput(
                        controller: _fullNameCtrl,
                        label: 'Full name',
                        icon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _ApexInput(
                      controller: _emailCtrl,
                      label: 'Email',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 12),
                    _ApexInput(
                      controller: _passCtrl,
                      label: 'Password',
                      icon: Icons.lock_outline_rounded,
                      obscure: true,
                    ),
                    if (_signupMode) ...[
                      const SizedBox(height: 12),
                      _ApexInput(
                        controller: _confirmPassCtrl,
                        label: 'Confirm password',
                        icon: Icons.lock_reset_rounded,
                        obscure: true,
                      ),
                      const SizedBox(height: 12),
                      _ApexInput(
                        controller: _phoneCtrl,
                        label: 'Phone',
                        icon: Icons.phone_outlined,
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (_error != null) ...[
                      const SizedBox(height: 4),
                      ApexText(
                        _error!,
                        fontSize: 12,
                        color: redAlert,
                        fontWeight: FontWeight.w500,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_success != null) ...[
                      const SizedBox(height: 4),
                      ApexText(
                        _success!,
                        fontSize: 12,
                        color: greenSuccess,
                        fontWeight: FontWeight.w600,
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading
                            ? null
                            : (_signupMode ? _signupFromInvite : _login),
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
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _signupMode ? 'CREATE ACCOUNT' : 'SIGN IN',
                                style: GoogleFonts.cinzel(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              if (_signupMode) {
                                setState(() {
                                  _signupMode = false;
                                  _error = null;
                                  _success = null;
                                });
                              } else {
                                _enterSignupMode();
                              }
                            },
                      child: ApexText(
                        _signupMode
                            ? 'Already have an account? Sign in'
                            : 'Have an invite? Create account',
                        fontSize: 11,
                        color: gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    ApexText(
                      _signupMode
                          ? 'Create account from a staff invite'
                          : 'Sign in with your gym account',
                      fontSize: 10,
                      color: const Color(0xFF3A3A3A),
                    ),
                  ],
                ),
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
    );
  }
}

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
        final visibleCount =
            (progress * chars.length).ceil().clamp(0, chars.length);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(chars.length, (index) {
            if (index >= visibleCount) {
              return Opacity(
                opacity: 0.0,
                child: Text(chars[index], style: style),
              );
            } else if (index == visibleCount - 1 && progress < 1.0) {
              final charProgress = (progress * chars.length) - index;
              return Opacity(
                opacity: charProgress.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, (1 - charProgress) * 10),
                  child: Text(chars[index], style: style),
                ),
              );
            } else {
              return Text(chars[index], style: style);
            }
          }),
        );
      },
    );
  }
}

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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
