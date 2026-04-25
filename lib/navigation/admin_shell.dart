import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymsaas/core/theme.dart';
import 'package:gymsaas/providers/occupancy_provider.dart';
import 'package:gymsaas/widgets/apex_text.dart';

// نموذج عنصر القائمة
class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  const _NavItem(this.label, this.icon, this.route);
}

// عناصر القائمة الثابتة
const _navItems = [
  _NavItem('Dashboard', Icons.dashboard_rounded, '/'),
  _NavItem('Members', Icons.people_rounded, '/members'),
  _NavItem('Check-in', Icons.nfc_rounded, '/checkin'),
  _NavItem('Finance', Icons.account_balance_wallet_rounded, '/erp'),
  _NavItem('Member App', Icons.phone_android_rounded, '/member-app'),
  _NavItem('AI Engine', Icons.auto_awesome_rounded, '/ai'),
];

/// الغلاف الجانبي الدائم لكل شاشات الإدارة
class AdminShell extends ConsumerStatefulWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  bool _collapsed = false;

  bool _isActive(String route, String current) {
    if (route == '/') return current == '/';
    return current.startsWith(route);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final sidebarW = _collapsed ? 64.0 : 220.0;
    final isWide = MediaQuery.of(context).size.width > 900;

    // ─── الشريط الجانبي (مشترك) ────────────────────
    final sidebar = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: sidebarW,
      color: const Color(0xFF090909),
      child: Column(
        children: [
          // الشعار
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: borderDark)),
            ),
            child: Row(
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fitness_center,
                      color: Colors.black, size: 18),
                ),
                if (!_collapsed) ...[
                  const SizedBox(width: 10),
                  Text(
                    'APEX',
                    style: GoogleFonts.cinzel(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: gold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
                const Spacer(),
                if (isWide)
                  IconButton(
                    icon: Icon(
                      _collapsed
                          ? Icons.chevron_right_rounded
                          : Icons.chevron_left_rounded,
                      color: const Color(0xFF555555),
                      size: 18,
                    ),
                    onPressed: () =>
                        setState(() => _collapsed = !_collapsed),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // عناصر القائمة
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: _navItems.map((item) {
                final active = _isActive(item.route, location);
                return _NavTile(
                  item: item,
                  active: active,
                  collapsed: _collapsed,
                  onTap: () => context.go(item.route),
                );
              }).toList(),
            ),
          ),

          const Divider(color: borderDark, height: 1),

          // مؤشر الإشغال الحي
          ref.watch(occupancyStreamProvider).when(
                data: (count) => _OccupancyIndicator(
                    count: count.round(), collapsed: _collapsed),
                loading: () => const SizedBox(height: 56),
                error: (_, __) => const SizedBox(height: 56),
              ),
          const SizedBox(height: 8),
        ],
      ),
    );

    // ─── وضع الموبايل (Drawer) ─────────────────────
    if (!isWide) {
      return Scaffold(
        backgroundColor: bgDark,
        drawer: Drawer(
          backgroundColor: const Color(0xFF090909),
          child: SafeArea(child: sidebar),
        ),
        appBar: AppBar(
          backgroundColor: const Color(0xFF090909),
          foregroundColor: gold,
          title: Text('APEX',
              style: GoogleFonts.cinzel(
                  fontSize: 16, color: gold, fontWeight: FontWeight.w700)),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ),
        body: widget.child,
      );
    }

    // ─── وضع سطح المكتب ──────────────────────────
    return Scaffold(
      backgroundColor: bgDark,
      body: Row(
        children: [
          sidebar,
          const VerticalDivider(width: 1, color: borderDark),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

// ─── مربع القائمة ─────────────────────────────────
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
        ? gold.withOpacity(0.12)
        : _hovered
            ? const Color(0xFF111111)
            : Colors.transparent;
    final iconColor =
        widget.active ? gold : const Color(0xFF555555);
    final textColor =
        widget.active ? gold : const Color(0xFF666666);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? 14 : 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: widget.active
                ? Border.all(color: gold.withOpacity(0.2))
                : null,
          ),
          child: Row(
            mainAxisAlignment: widget.collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(widget.item.icon, color: iconColor, size: 18),
              if (!widget.collapsed) ...[
                const SizedBox(width: 10),
                ApexText(
                  widget.item.label,
                  fontSize: 13,
                  color: textColor,
                  fontWeight:
                      widget.active ? FontWeight.w600 : FontWeight.w400,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── مؤشر الإشغال ───────────────────────────────
class _OccupancyIndicator extends StatelessWidget {
  final int count;
  final bool collapsed;

  const _OccupancyIndicator({required this.count, required this.collapsed});

  @override
  Widget build(BuildContext context) {
    final pct = (count / gymCapacity * 100).clamp(0, 100).toDouble();
    final color = ocColor(pct);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                ApexText('$count / $gymCapacity live',
                    fontSize: 11, color: const Color(0xFF555555)),
              ],
            ),
    );
  }
}