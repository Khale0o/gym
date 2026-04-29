import 'package:gymsaas/models/user_profile.dart';

const String ownerRole = 'owner';
const String adminRole = 'admin';
const String receptionRole = 'reception';
const String coachRole = 'coach';
const String memberRole = 'member';

const String dashboardRoute = '/';
const String membersRoute = '/members';
const String checkinRoute = '/checkin';
const String financeRoute = '/erp';
const String staffManagementRoute = '/staff';
const String plansRoute = '/plans';
const String memberAppRoute = '/member-app';
const String aiRoute = '/ai';
const String accessErrorRoute = '/access-error';

const Set<String> _knownRoles = {
  ownerRole,
  adminRole,
  receptionRole,
  coachRole,
  memberRole,
};

const Map<String, Set<String>> _roleRoutes = {
  ownerRole: {
    dashboardRoute,
    membersRoute,
    checkinRoute,
    financeRoute,
    staffManagementRoute,
    plansRoute,
    memberAppRoute,
    aiRoute,
  },
  adminRole: {
    dashboardRoute,
    membersRoute,
    checkinRoute,
    financeRoute,
    staffManagementRoute,
    plansRoute,
    memberAppRoute,
    aiRoute,
  },
  receptionRole: {
    membersRoute,
    checkinRoute,
  },
  coachRole: {
    membersRoute,
    aiRoute,
  },
  memberRole: {
    memberAppRoute,
  },
};

String normalizeRole(String? role) {
  return (role ?? '').trim().toLowerCase();
}

bool isKnownRole(String? role) {
  return _knownRoles.contains(normalizeRole(role));
}

bool isActiveStatus(String? status) {
  return (status ?? '').trim().toLowerCase() == 'active';
}

bool canAccessRoute({
  required String role,
  required String route,
}) {
  final normalizedRole = normalizeRole(role);
  final allowedRoutes = _roleRoutes[normalizedRole];
  if (allowedRoutes == null) return false;

  if (route == dashboardRoute) {
    return allowedRoutes.contains(dashboardRoute);
  }

  if (route.startsWith('$membersRoute/')) {
    return allowedRoutes.contains(membersRoute);
  }

  return allowedRoutes.contains(route);
}

List<String> allowedRoutesForRole(String role) {
  final normalizedRole = normalizeRole(role);
  return (_roleRoutes[normalizedRole] ?? const <String>{}).toList();
}

String firstAllowedRouteForRole(String role) {
  final normalizedRole = normalizeRole(role);
  switch (normalizedRole) {
    case ownerRole:
    case adminRole:
      return dashboardRoute;
    case receptionRole:
    case coachRole:
      return membersRoute;
    case memberRole:
      return memberAppRoute;
    default:
      return accessErrorRoute;
  }
}

String? accessIssueForProfile(UserProfile? profile) {
  if (profile == null) {
    return null;
  }

  if (!isActiveStatus(profile.status)) {
    return 'Your account is not active right now.';
  }

  if (!isKnownRole(profile.role)) {
    return 'Your account role is missing or unsupported.';
  }

  return null;
}
