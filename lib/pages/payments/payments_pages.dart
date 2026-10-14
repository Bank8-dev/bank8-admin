// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Bank8:Admin
// SPDX-License-Identifier: Apache-2.0

// Bank8:Admin Payments pages — instructions, rules, cards, files, integrations, decisions, etc.
//
// All API calls go through BffApiClient: {bff}/proxy/payments/v1/*
// Uses AdminContext.instance!.services!.payments for API access.

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../../theme.dart';
import '../../app_context.dart';

// ── Overview ────────────────────────────────────────────────────────────

class PaymentsOverviewPage extends StatelessWidget {
  const PaymentsOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Payments',
      subtitle: 'Payment orchestration — instructions, rules, cards, files, integrations, decisions.',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _NavChip(label: 'Instructions', icon: Icons.assignment, route: '/payments/instructions'),
          _NavChip(label: 'Rules', icon: Icons.rule, route: '/payments/rules'),
          _NavChip(label: 'Cards', icon: Icons.credit_card, route: '/payments/cards'),
          _NavChip(label: 'Files', icon: Icons.folder, route: '/payments/files'),
          _NavChip(label: 'Integrations', icon: Icons.integration_instructions, route: '/payments/integrations'),
          _NavChip(label: 'Decisions', icon: Icons.gavel, route: '/payments/decisions'),
          _NavChip(label: 'Mandates', icon: Icons.assignment_turned_in, route: '/payments/mandates'),
          _NavChip(label: 'Templates', icon: Icons.copy, route: '/payments/templates'),
          _NavChip(label: 'Calendars', icon: Icons.calendar_month, route: '/payments/calendars'),
          _NavChip(label: 'Dashboards', icon: Icons.dashboard_customize, route: '/payments/dashboards'),
          _NavChip(label: 'Settings', icon: Icons.settings, route: '/payments/settings'),
        ],
      ),
    );
  }
}

// ── Section Dispatch ────────────────────────────────────────────────────

class PaymentsSectionPage extends StatelessWidget {
  final String section;
  const PaymentsSectionPage({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return switch (section) {
      'instructions' => const _PaymentsListPage(title: 'Instructions', path: '/v1/instructions', icon: Icons.assignment),
      'rules' => const _PaymentsListPage(title: 'Rules', path: '/v1/rules', icon: Icons.rule),
      'cards' => const _PaymentsListPage(title: 'Cards', path: '/v1/cards', icon: Icons.credit_card),
      'files' => const _PaymentsListPage(title: 'Files', path: '/v1/files', icon: Icons.folder),
      'integrations' => const _PaymentsListPage(title: 'Integrations', path: '/v1/integrations', icon: Icons.integration_instructions),
      'decisions' => const _PaymentsListPage(title: 'Manual Decisions', path: '/v1/manual-decisions', icon: Icons.gavel),
      'mandates' => const _PaymentsListPage(title: 'Mandates', path: '/v1/mandates', icon: Icons.assignment_turned_in),
      'templates' => const _PaymentsListPage(title: 'Templates', path: '/v1/templates', icon: Icons.copy),
      'calendars' => const _PaymentsListPage(title: 'Calendars', path: '/v1/calendars', icon: Icons.calendar_month),
      'dashboards' => const _PaymentsListPage(title: 'Dashboards', path: '/v1/dashboards', icon: Icons.dashboard_customize),
      'settings' => const _PlaceholderPage(title: 'Payments Settings', message: 'Payments configuration parameters.'),
      _ => _PlaceholderPage(title: 'Unknown', message: 'Unknown section: $section'),
    };
  }
}

// ── Generic list page ──────────────────────────────────────────────────

class _PaymentsListPage extends StatefulWidget {
  final String title;
  final String path;
  final IconData icon;
  const _PaymentsListPage({required this.title, required this.path, required this.icon});

  @override
  State<_PaymentsListPage> createState() => _PaymentsListPageState();
}

class _PaymentsListPageState extends State<_PaymentsListPage> {
  List<dynamic>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await AdminContext.instance!.services!.payments.get(widget.path);
      final items = (resp.data?['data'] ?? resp.data?['items']) as List<dynamic>? ?? [];
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) _ErrorBanner(error: _error!),
          if (_items == null)
            const Center(child: CircularProgressIndicator(color: Sentin8Colors.primary))
          else if (_items!.isEmpty)
            Text('No ${widget.title.toLowerCase()} yet.', style: Sentin8Text.bodyMedium)
          else
            Expanded(child: ListView.builder(itemCount: _items!.length, itemBuilder: (c, i) {
              final item = _items![i] as Map<String, dynamic>;
              final id = item['id'] as String? ?? item['name'] as String? ?? 'Unknown';
              final subtitle = item.entries.take(3).where((e) => e.key != 'id').map((e) => '${e.key}: ${e.value}').join(' • ');
              return Card(child: ListTile(
                leading: Icon(widget.icon, color: Sentin8Colors.primary),
                title: Text(id),
                subtitle: Text(subtitle.isEmpty ? '—' : subtitle),
              ));
            })),
        ],
      ),
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────

class _PageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget child;
  const _PageScaffold({required this.title, this.subtitle, this.action, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Sentin8Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Text(title, style: Sentin8Text.headlineLarge), const Spacer(), if (action != null) action!]),
          if (subtitle != null) ...[const SizedBox(height: 8), Text(subtitle!, style: Sentin8Text.bodyMedium)],
          const SizedBox(height: Sentin8Spacing.lg),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  final String message;
  const _PlaceholderPage({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(title: title, child: Center(child: Text(message, style: Sentin8Text.bodyMedium)));
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  const _ErrorBanner({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [const Icon(Icons.error, color: Colors.red), const SizedBox(width: 8), Expanded(child: Text(error, style: const TextStyle(color: Colors.red)))]),
    );
  }
}

class _NavChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String route;
  const _NavChip({required this.label, required this.icon, required this.route});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: () => web.window.location.hash = route,
    );
  }
}