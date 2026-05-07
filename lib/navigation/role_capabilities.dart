class AppRoles {
  static const platformOwner = 'platformOwner';
  static const owner = 'owner';
  static const admin = 'admin';
  static const reception = 'reception';
  static const coach = 'coach';
  static const member = 'member';

  static const all = <String>{
    platformOwner,
    owner,
    admin,
    reception,
    coach,
    member,
  };
}

class RoleCapabilities {
  const RoleCapabilities._();

  static bool canAccessPlatformAdmin(String role) {
    return _normalized(role) == _normalized(AppRoles.platformOwner);
  }

  static bool canCreateMember(String role) {
    return _normalized(role) == AppRoles.owner ||
        _normalized(role) == AppRoles.admin ||
        _normalized(role) == AppRoles.reception;
  }

  static bool canEditMember(String role) {
    return _normalized(role) == AppRoles.owner ||
        _normalized(role) == AppRoles.admin ||
        _normalized(role) == AppRoles.reception;
  }

  static bool canArchiveMember(String role) {
    return _normalized(role) == AppRoles.owner ||
        _normalized(role) == AppRoles.admin;
  }

  static bool canManageMemberAccess(String role) {
    return _normalized(role) == AppRoles.owner ||
        _normalized(role) == AppRoles.admin ||
        _normalized(role) == AppRoles.reception;
  }

  static bool canCreateStaff(String role) {
    return _normalized(role) == AppRoles.owner ||
        _normalized(role) == AppRoles.admin;
  }

  static bool canManageStaff(String role) {
    return _normalized(role) == AppRoles.owner ||
        _normalized(role) == AppRoles.admin;
  }

  static bool canArchiveStaff(String role) {
    return canManageStaff(role);
  }

  static List<String> invitableStaffRoles(String role) {
    switch (_normalized(role)) {
      case AppRoles.owner:
        return const [
          AppRoles.admin,
          AppRoles.reception,
          AppRoles.coach,
        ];
      case AppRoles.admin:
        return const [
          AppRoles.reception,
          AppRoles.coach,
        ];
      default:
        return const [];
    }
  }

  static bool canInviteStaffRole(String actorRole, String targetRole) {
    return invitableStaffRoles(actorRole).contains(_normalized(targetRole));
  }

  static bool canCancelStaffInvite(String actorRole, String inviteRole) {
    return canInviteStaffRole(actorRole, inviteRole);
  }

  static bool canAssignRole(String actorRole, String targetRole) {
    final actor = _normalized(actorRole);
    final target = _normalized(targetRole);

    if (actor == AppRoles.owner) {
      return {
        AppRoles.admin,
        AppRoles.reception,
        AppRoles.coach,
        AppRoles.member,
      }.contains(target);
    }

    if (actor == AppRoles.admin) {
      return {
        AppRoles.reception,
        AppRoles.coach,
        AppRoles.member,
      }.contains(target);
    }

    if (actor == AppRoles.reception) {
      return target == AppRoles.member;
    }

    return false;
  }

  static bool canViewFinance(String role) {
    return _normalized(role) == AppRoles.owner ||
        _normalized(role) == AppRoles.admin;
  }

  static bool canManagePlans(String role) {
    return _normalized(role) == AppRoles.owner ||
        _normalized(role) == AppRoles.admin;
  }

  static bool canManageSettings(String role) {
    return _normalized(role) == AppRoles.owner ||
        _normalized(role) == AppRoles.admin;
  }

  static bool canCreateMemberInitialSubscription(String role) {
    return _normalized(role) == AppRoles.owner ||
        _normalized(role) == AppRoles.admin ||
        _normalized(role) == AppRoles.reception;
  }

  static bool canProcessPayments(String role) {
    return _normalized(role) == AppRoles.owner ||
        _normalized(role) == AppRoles.admin ||
        _normalized(role) == AppRoles.reception;
  }

  static String _normalized(String role) => role.trim().toLowerCase();
}
