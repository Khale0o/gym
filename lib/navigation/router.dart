import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/providers/auth_provider.dart';
import 'package:gymsaas/navigation/admin_shell.dart';
import 'package:gymsaas/screens/login/login_screen.dart';
import 'package:gymsaas/screens/dashboard/dashboard_screen.dart';
import 'package:gymsaas/screens/members/members_screen.dart';
import 'package:gymsaas/screens/members/member_detail_screen.dart';
import 'package:gymsaas/screens/checkin/checkin_screen.dart';
import 'package:gymsaas/screens/erp/erp_screen.dart';
import 'package:gymsaas/screens/member_app/member_app_screen.dart';
import 'package:gymsaas/screens/ai/ai_engine_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: auth.isLoggedIn ? '/' : '/login',
    redirect: (context, state) {
      final loggedIn = ref.read(authProvider).isLoggedIn;
      final isLogin = state.matchedLocation == '/login';
      if (!loggedIn && !isLogin) return '/login';
      if (loggedIn && isLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/members',
            builder: (_, __) => const MembersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    MemberDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/checkin',
            builder: (_, __) => const CheckInScreen(),
          ),
          GoRoute(
            path: '/erp',
            builder: (_, __) => const ErpScreen(),
          ),
          GoRoute(
            path: '/member-app',
            builder: (_, __) => const MemberAppScreen(),
          ),
          GoRoute(
            path: '/ai',
            builder: (_, __) => const AiEngineScreen(),
          ),
        ],
      ),
    ],
  );
});