import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymsaas/navigation/admin_shell.dart';
import 'package:gymsaas/navigation/role_access.dart';
import 'package:gymsaas/providers/auth_provider.dart';
import 'package:gymsaas/providers/tenant_access_provider.dart';
import 'package:gymsaas/screens/access/access_error_screen.dart';
import 'package:gymsaas/screens/ai/ai_engine_screen.dart';
import 'package:gymsaas/screens/checkin/checkin_screen.dart';
import 'package:gymsaas/screens/dashboard/dashboard_screen.dart';
import 'package:gymsaas/screens/erp/erp_screen.dart';
import 'package:gymsaas/screens/login/login_screen.dart';
import 'package:gymsaas/screens/member_app/member_app_screen.dart';
import 'package:gymsaas/screens/members/member_detail_screen.dart';
import 'package:gymsaas/screens/members/members_screen.dart';
import 'package:gymsaas/screens/payments/payments_screen.dart';
import 'package:gymsaas/screens/plans/plans_screen.dart';
import 'package:gymsaas/screens/platform/platform_admin_screen.dart';
import 'package:gymsaas/screens/settings/gym_settings_screen.dart';
import 'package:gymsaas/screens/staff/staff_management_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(authStateProvider);
  ref.watch(currentUserProfileProvider);
  ref.watch(currentGymTenantAccessProvider);
  final user = ref.watch(firebaseAuthProvider).currentUser;

  return GoRouter(
    initialLocation: user != null ? '/' : '/login',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final loggedIn = authState.valueOrNull != null ||
          ref.read(firebaseAuthProvider).currentUser != null;
      final isLogin = state.matchedLocation == '/login';
      final isAccessError = state.matchedLocation == accessErrorRoute;

      if (!loggedIn && !isLogin) return '/login';
      if (!loggedIn) return null;

      final profileAsync = ref.read(currentUserProfileProvider);

      if (isLogin) {
        if (profileAsync.isLoading) return null;
        final profile = profileAsync.valueOrNull;
        if (profile == null) return accessErrorRoute;
        final issue = accessIssueForProfile(profile);
        if (issue != null) return accessErrorRoute;
        return firstAllowedRouteForRole(profile.role);
      }

      if (profileAsync.isLoading) {
        return null;
      }

      if (profileAsync.hasError) {
        if (!isAccessError) return accessErrorRoute;
        return null;
      }

      final profile = profileAsync.valueOrNull;
      final issue = accessIssueForProfile(profile);
      final tenantAccessAsync = ref.read(currentGymTenantAccessProvider);
      final tenantIssue = tenantAccessAsync.valueOrNull?.blockedMessage;

      if (issue != null) {
        if (!isAccessError) return accessErrorRoute;
        return null;
      }

      if (!isPlatformOwnerRole(profile?.role)) {
        if (tenantAccessAsync.isLoading) return null;
        if (tenantAccessAsync.hasError) {
          if (!isAccessError) return accessErrorRoute;
          return null;
        }
        if (tenantIssue != null) {
          if (!isAccessError) return accessErrorRoute;
          return null;
        }
      }

      if (isAccessError) {
        if (profile == null) return null;
        return firstAllowedRouteForRole(profile.role);
      }

      if (profile == null) {
        return accessErrorRoute;
      }

      final role = profile.role;
      final route = state.matchedLocation;
      if (!canAccessRoute(role: role, route: route)) {
        return firstAllowedRouteForRole(role);
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: accessErrorRoute,
        builder: (_, __) => Consumer(
          builder: (context, ref, child) {
            final profileAsync = ref.watch(currentUserProfileProvider);
            final profile = profileAsync.valueOrNull;
            final issue = accessIssueForProfile(profile);
            final tenantAccessAsync = ref.watch(currentGymTenantAccessProvider);
            final tenantIssue = tenantAccessAsync.valueOrNull?.blockedMessage;
            return AccessErrorScreen(
              title: 'Access Unavailable',
              message: profileAsync.hasError
                  ? 'Your profile could not be loaded. Please sign out and try again.'
                  : issue ??
                  (tenantAccessAsync.hasError
                      ? 'Your gym access could not be checked. Please sign out and try again.'
                      : null) ??
                  tenantIssue ??
                  'Your account does not currently have access to this part of the app.',
            );
          },
        ),
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
            path: paymentsRoute,
            builder: (_, __) => const PaymentsScreen(),
          ),
          GoRoute(
            path: staffManagementRoute,
            builder: (_, __) => const StaffManagementScreen(),
          ),
          GoRoute(
            path: plansRoute,
            builder: (_, __) => const PlansScreen(),
          ),
          GoRoute(
            path: settingsRoute,
            builder: (_, __) => const GymSettingsScreen(),
          ),
          GoRoute(
            path: '/member-app',
            builder: (_, __) => const MemberAppScreen(),
          ),
          GoRoute(
            path: '/ai',
            builder: (_, __) => const AiEngineScreen(),
          ),
          GoRoute(
            path: platformRoute,
            builder: (_, __) => const PlatformAdminScreen(),
          ),
        ],
      ),
    ],
  );
});
