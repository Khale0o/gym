import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/l10n/app_localizations.dart';
import 'package:gymsaas/navigation/role_access.dart';
import 'package:gymsaas/providers/auth_provider.dart';
import 'package:gymsaas/providers/occupancy_provider.dart';
import 'package:gymsaas/screens/access/access_error_screen.dart';
import 'package:gymsaas/widgets/apex_text.dart';

class _NavItem {
  final String labelKey;
  final IconData icon;
  final String route;
  const _NavItem(this.labelKey, this.icon, this.route);
}

const _navItems = [
  _NavItem(L10nKeys.dashboard, Icons.dashboard_rounded, dashboardRoute),
  _NavItem(L10nKeys.members, Icons.people_rounded, membersRoute),
  _NavItem(L10nKeys.checkIn, Icons.nfc_rounded, checkinRoute),
  _NavItem(L10nKeys.staff, Icons.manage_accounts_rounded, staffManagementRoute),
  _NavItem(L10nKeys.plans, Icons.workspace_premium_rounded, plansRoute),
  _NavItem(L10nKeys.payments, Icons.point_of_sale_rounded, paymentsRoute),
  _NavItem(L10nKeys.settings, Icons.settings_rounded, settingsRoute),
  _NavItem(L10nKeys.finance, Icons.account_balance_wallet_rounded, financeRoute),
  _NavItem(L10nKeys.memberApp, Icons.phone_android_rounded, memberAppRoute),
  _NavItem(L10nKeys.aiEngine, Icons.auto_awesome_rounded, aiRoute),
  _NavItem(
    L10nKeys.platformAdmin,
    Icons.admin_panel_settings_rounded,
    platformRoute,
  ),
];

class AdminShell extends ConsumerStatefulWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  bool _isActive(String route, String current) {
    if (route == dashboardRoute) return current == dashboardRoute;
    return current.startsWith(route);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    const sidebarW = 248.0;
    final isWide = MediaQuery.of(context).size.width > 900;
    final profileAsync = ref.watch(currentUserProfileProvider);
    if (profileAsync.isLoading) {
      return const Scaffold(
        backgroundColor: bgDark,
        body: Center(child: CircularProgressIndicator(color: gold)),
      );
    }

    if (profileAsync.hasError || profileAsync.valueOrNull == null) {
      return AccessErrorScreen(
        title: 'Access Unavailable',
        message: profileAsync.hasError
            ? 'Your profile could not be loaded. Please sign out and try again.'
            : 'No user profile was found for this account. Please sign out and contact support.',
      );
    }

    final profile = profileAsync.valueOrNull;
    final role = normalizeRole(profile?.role);
    final visibleNavItems = _navItems
        .where((item) => canAccessRoute(role: role, route: item.route))
        .toList();

    final sidebar = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: sidebarW,
      color: ApexColors.surface,
      child: Column(
        children: [
          Container(
            height: 78,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: ApexColors.border)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showRole = constraints.maxWidth >= 270;
                return Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [gold, goldDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(ApexRadius.sm),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: Colors.black,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'APEX',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cinzel(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: gold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          if (showRole) ...[
                            const SizedBox(width: 8),
                            const ApexText(
                              'Admin',
                              fontSize: 11,
                              color: ApexColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isWide)
                      _ShellHeaderIconButton(
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: ApexColors.textMuted,
                          size: 18,
                        ),
                        onPressed: () =>
                            ref.read(authControllerProvider).signOut(),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: [
                _NavSectionLabel(context.t(L10nKeys.workspace)),
                ...visibleNavItems
                    .where((item) => item.route != settingsRoute)
                    .map((item) {
                  final active = _isActive(item.route, location);
                  return _NavTile(
                    item: item,
                    active: active,
                    collapsed: false,
                    onTap: () => context.go(item.route),
                  );
                }),
                const SizedBox(height: 14),
                _NavSectionLabel(context.t(L10nKeys.system)),
                ...visibleNavItems
                    .where((item) => item.route == settingsRoute)
                    .map((item) {
                  final active = _isActive(item.route, location);
                  return _NavTile(
                    item: item,
                    active: active,
                    collapsed: false,
                    onTap: () => context.go(item.route),
                  );
                }),
              ],
            ),
          ),
          const Divider(color: ApexColors.border, height: 1),
          if (!isPlatformOwnerRole(role))
            ref.watch(occupancyStreamProvider).when(
                  data: (count) => _OccupancyIndicator(
                    count: count.round(),
                    collapsed: false,
                  ),
                  loading: () => const SizedBox(height: 56),
                  error: (_, __) => const SizedBox(height: 56),
                ),
          const SizedBox(height: 8),
        ],
      ),
    );

    if (!isWide) {
      return Scaffold(
        backgroundColor: bgDark,
        drawer: Drawer(
          backgroundColor: ApexColors.surface,
          child: SafeArea(child: sidebar),
        ),
        appBar: AppBar(
          backgroundColor: ApexColors.surface,
          foregroundColor: gold,
          title: Text(
            'APEX',
            style: GoogleFonts.cinzel(
              fontSize: 16,
              color: gold,
              fontWeight: FontWeight.w700,
            ),
          ),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => ref.read(authControllerProvider).signOut(),
            ),
          ],
        ),
        body: widget.child,
      );
    }

    return Scaffold(
      backgroundColor: bgDark,
      body: Row(
        children: [
          sidebar,
          const VerticalDivider(width: 1, color: ApexColors.border),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

class _ShellHeaderIconButton extends StatelessWidget {
  const _ShellHeaderIconButton({
    required this.icon,
    required this.onPressed,
  });

  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 36,
      child: IconButton(
        icon: icon,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
        splashRadius: 18,
      ),
    );
  }
}

class _NavSectionLabel extends StatelessWidget {
  const _NavSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: ApexText(
        label.toUpperCase(),
        fontSize: 10,
        color: ApexColors.textMuted,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  final _NavItem item;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.active,
    required this.collapsed,
    required this.onTap,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.active
        ? gold.withValues(alpha: 0.14)
        : _hovered
            ? ApexColors.surfaceAlt
            : Colors.transparent;
    final iconColor = widget.active ? gold : ApexColors.textMuted;
    final textColor =
        widget.active ? ApexColors.textPrimary : ApexColors.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: EdgeInsets.symmetric(
            horizontal: widget.collapsed ? 14 : 13,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(ApexRadius.md),
            border: widget.active
                ? Border.all(color: gold.withValues(alpha: 0.35))
                : null,
          ),
          child: Row(
            mainAxisAlignment: widget.collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(widget.item.icon, color: iconColor, size: 19),
              if (!widget.collapsed) ...[
                const SizedBox(width: 11),
                ApexText(
                  context.t(widget.item.labelKey),
                  fontSize: 13,
                  color: textColor,
                  fontWeight:
                      widget.active ? FontWeight.w800 : FontWeight.w500,
                ),
                const Spacer(),
                if (widget.active)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: gold,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OccupancyIndicator extends StatelessWidget {
  final int count;
  final bool collapsed;

  const _OccupancyIndicator({required this.count, required this.collapsed});

  @override
  Widget build(BuildContext context) {
    final pct = (count / gymCapacity * 100).clamp(0, 100).toDouble();
    final color = ocColor(pct);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: collapsed
          ? Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            )
          : Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                ApexText(
                  '$count / $gymCapacity live',
                  fontSize: 12,
                  color: ApexColors.textMuted,
                ),
              ],
            ),
    );
  }
}
