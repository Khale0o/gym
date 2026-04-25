import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final bool isLoggedIn;
  const AuthState({required this.isLoggedIn});

  AuthState copyWith({bool? isLoggedIn}) =>
      AuthState(isLoggedIn: isLoggedIn ?? this.isLoggedIn);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(isLoggedIn: false));

  Future<bool> login(String email, String password) async {
    // محاكاة تسجيل الدخول
    await Future.delayed(const Duration(milliseconds: 800));
    if (email == 'admin@apex.gym' && password == 'apex2024') {
      state = state.copyWith(isLoggedIn: true);
      return true;
    }
    return false;
  }

  void logout() {
    state = state.copyWith(isLoggedIn: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});