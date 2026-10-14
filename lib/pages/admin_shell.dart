// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Bank8:Admin
// SPDX-License-Identifier: Apache-2.0

// Bank8:Admin shell — main scaffold with sidebar navigation
//
// Hash-based routing: #/ledger/products, #/payments/rules, #/fdx/provider, etc.
// Sidebar shows: Overview, Ledger (expandable), Payments (expandable), FDX (expandable).

import 'package:flutter/material.dart';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import '../theme.dart';
import '../app_context.dart';
import '../rfw/rfw_page.dart';
import 'overview_page.dart';
import 'settings_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  String _route = '/';

  @override
  void initState() {
    super.initState();
    // Read initial route from hash (for deep linking).
    final hash = web.window.location.hash;
    final route = hash.replaceFirst('#', '');
    _route = route.isEmpty ? '/' : route;

    // Listen for hash changes (e.g. when tests or external code
    // set window.location.hash). Without this, hash navigation
    // only works on initial load.
    web.window.addEventListener('hashchange', (web.Event e) {
      final newHash = web.window.location.hash;
      final newRoute = newHash.replaceFirst('#', '');
      if (newRoute.isNotEmpty && newRoute != _route) {
        setState(() {
          _route = newRoute;
        });
      }
    }.toJS);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _navigate(String route) {
    final target = route.isEmpty ? '/' : route;
    debugPrint('[AdminShell] _navigate: $target (was $_route)');
    // Update the URL hash without triggering Flutter's Navigator.
    web.window.history.replaceState(null, '', '#$target');
    // Update state immediately.
    setState(() {
      _route = target;
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[AdminShell] build: route=$_route');
    final ctx = AdminContextProvider.of(context);
    final auth = ctx?.auth;
    final isSignedIn = auth?.state.isSignedIn ?? false;

    if (!isSignedIn) {
      return _SignInPage(auth: auth);
    }

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(route: _route, onNavigate: _navigate),
          const VerticalDivider(width: 1),
          Expanded(child: _PageContent(route: _route, onNavigate: _navigate)),
        ],
      ),
    );
  }
}

class _SignInPage extends StatelessWidget {
  final dynamic auth;
  const _SignInPage({this.auth});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings, size: 64, color: Sentin8Colors.primary),
            const SizedBox(height: 24),
            Text('Bank8:Admin', style: Sentin8Text.headlineLarge),
            const SizedBox(height: 8),
            const Text('Bank8 administration dashboard', style: Sentin8Text.bodyMedium),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => auth?.signInWithAuth(),
              icon: const Icon(Icons.login),
              label: const Text('Staff Sign In'),
            ),
            const SizedBox(height: 16),
            const Text('Staff access only — SSO with Sentin8:Dash', style: Sentin8Text.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  final List<_NavItem>? children;
  const _NavItem(this.label, this.icon, this.route, {this.children});
}

class _Sidebar extends StatelessWidget {
  final String route;
  final void Function(String) onNavigate;

  const _Sidebar({required this.route, required this.onNavigate});

  static const _navItems = [
    _NavItem('Overview', Icons.dashboard, '/'),
    _NavItem('Ledger', Icons.account_balance, '/ledger', children: [
      _NavItem('Accounts', Icons.account_balance_wallet, '/ledger/accounts'),
      _NavItem('Products', Icons.inventory_2, '/ledger/products'),
      _NavItem('Postings', Icons.receipt_long, '/ledger/postings'),
      _NavItem('Schedules', Icons.schedule, '/ledger/schedules'),
      _NavItem('DLQ', Icons.error_outline, '/ledger/dlq'),
      _NavItem('Reconcile', Icons.balance, '/ledger/reconcile'),
      _NavItem('Balances', Icons.bar_chart, '/ledger/balances'),
      _NavItem('Customers', Icons.people, '/ledger/customers'),
      _NavItem('Audit', Icons.fact_check, '/ledger/audit'),
      _NavItem('Settings', Icons.settings, '/ledger/settings'),
    ]),
    _NavItem('Payments', Icons.payments, '/payments', children: [
      _NavItem('Instructions', Icons.assignment, '/payments/instructions'),
      _NavItem('Rules', Icons.rule, '/payments/rules'),
      _NavItem('Cards', Icons.credit_card, '/payments/cards'),
      _NavItem('Files', Icons.folder, '/payments/files'),
      _NavItem('Integrations', Icons.integration_instructions, '/payments/integrations'),
      _NavItem('Decisions', Icons.gavel, '/payments/decisions'),
      _NavItem('Mandates', Icons.assignment_turned_in, '/payments/mandates'),
      _NavItem('Templates', Icons.copy, '/payments/templates'),
      _NavItem('Calendars', Icons.calendar_month, '/payments/calendars'),
      _NavItem('Dashboards', Icons.dashboard_customize, '/payments/dashboards'),
      _NavItem('Settings', Icons.settings, '/payments/settings'),
    ]),
    _NavItem('FDX', Icons.sync_alt, '/fdx', children: [
      _NavItem('Provider', Icons.cloud, '/fdx/provider'),
      _NavItem('Recipients', Icons.group, '/fdx/recipients'),
      _NavItem('Consents', Icons.lock, '/fdx/consents'),
      _NavItem('CSDF', Icons.data_object, '/fdx/csdf'),
      _NavItem('Settings', Icons.settings, '/fdx/settings'),
    ]),
    _NavItem('Reporting', Icons.description, '/reporting', children: [
      _NavItem('Calendar', Icons.calendar_month, '/reporting/calendar'),
      _NavItem('Runs', Icons.fact_check, '/reporting/runs'),
    ]),
    _NavItem('Risk', Icons.warning_amber, '/risk', children: [
      _NavItem('Limits', Icons.speed, '/risk/limits'),
      _NavItem('Stress', Icons.science, '/risk/stress'),
    ]),
    _NavItem('Compliance', Icons.shield, '/compliance', children: [
      _NavItem('Alerts', Icons.notifications_active, '/compliance/alerts'),
      _NavItem('Cases', Icons.folder_shared, '/compliance/cases'),
    ]),
    _NavItem('Settings', Icons.settings, '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: Sentin8Spacing.lg),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Sentin8Spacing.lg),
            child: Text('Bank8:Admin', style: Sentin8Text.headlineMedium),
          ),
          const SizedBox(height: Sentin8Spacing.lg),
          for (final item in _navItems) ...[
            if (item.children != null)
              _ExpansionNavItem(item: item, route: route, onNavigate: onNavigate)
            else
              _SimpleNavItem(item: item, route: route, onNavigate: onNavigate),
          ],
        ],
      ),
    );
  }
}

class _SimpleNavItem extends StatelessWidget {
  final _NavItem item;
  final String route;
  final void Function(String) onNavigate;
  const _SimpleNavItem({required this.item, required this.route, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final selected = route == item.route;
    return ListTile(
      leading: Icon(item.icon, size: 20, color: selected ? Sentin8Colors.primary : null),
      title: Text(item.label, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      selected: selected,
      onTap: () => onNavigate(item.route),
    );
  }
}

class _ExpansionNavItem extends StatefulWidget {
  final _NavItem item;
  final String route;
  final void Function(String) onNavigate;
  const _ExpansionNavItem({required this.item, required this.route, required this.onNavigate});

  @override
  State<_ExpansionNavItem> createState() => _ExpansionNavItemState();
}

class _ExpansionNavItemState extends State<_ExpansionNavItem> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.route.startsWith(widget.item.route);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header — uses InkWell for reliable CanvasKit click handling.
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(widget.item.icon, size: 20),
                const SizedBox(width: 12),
                Text(widget.item.label, style: Sentin8Text.bodyMedium),
                const Spacer(),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 20),
              ],
            ),
          ),
        ),
        // Children — shown when expanded.
        if (_expanded)
          for (final child in widget.item.children!)
            InkWell(
              onTap: () => widget.onNavigate(child.route),
              child: Padding(
                padding: const EdgeInsets.only(left: 56, right: 16, top: 8, bottom: 8),
                child: Row(
                  children: [
                    Icon(child.icon, size: 16),
                    const SizedBox(width: 8),
                    Text(child.label, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _PageContent extends StatelessWidget {
  final String route;
  final void Function(String) onNavigate;
  const _PageContent({required this.route, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    debugPrint('[PageContent] build: route=$route');
    if (route == '/' || route.isEmpty) {
      return const OverviewPage();
    }

    // Settings route — keep the hand-written settings page.
    if (route == '/settings') return const SettingsPage();

    // Bank8 service routes — render via RFW.
    for (final service in ['ledger', 'payments', 'fdx', 'reporting', 'risk', 'compliance']) {
      final prefix = '/$service';
      if (route == prefix) {
        return Bank8RfwPage(service: service, page: 'overview', onNavigate: onNavigate);
      }
      if (route.startsWith('$prefix/')) {
        final fullPage = route.replaceFirst('$prefix/', '');
        // Parse query params (e.g. "products/new?type=current_account")
        // and pass them as extraProps to the RFW page.
        Map<String, dynamic>? extraProps;
        String page = fullPage;
        if (fullPage.contains('?')) {
          final uri = Uri.parse(fullPage);
          page = uri.path;
          for (final entry in uri.queryParameters.entries) {
            extraProps ??= {};
            extraProps[entry.key] = entry.value;
          }
        }
        return Bank8RfwPage(service: service, page: page, onNavigate: onNavigate, extraProps: extraProps);
      }
    }

    return const Center(child: Text('Page not found'));
  }
}