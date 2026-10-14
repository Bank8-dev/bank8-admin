// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Bank8:Admin
// SPDX-License-Identifier: Apache-2.0

// Bank8:Admin Ledger pages — product catalog, accounts, postings, schedules, DLQ, balances, audit, settings.
//
// All API calls go through BffApiClient: {bff}/proxy/ledger/v1/*
// Uses AdminContext.instance!.services!.ledger for API access.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../../theme.dart';
import '../../app_context.dart';

// ── Overview ────────────────────────────────────────────────────────────

class LedgerOverviewPage extends StatelessWidget {
  const LedgerOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Ledger',
      subtitle: 'Double-entry ledger — product catalog, accounts, posting console, schedules, DLQ, reconciliation.',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _NavChip(label: 'Accounts', icon: Icons.account_balance, route: '/ledger/accounts'),
          _NavChip(label: 'Postings', icon: Icons.receipt_long, route: '/ledger/postings'),
          _NavChip(label: 'Products', icon: Icons.inventory_2, route: '/ledger/products'),
          _NavChip(label: 'Schedules', icon: Icons.schedule, route: '/ledger/schedules'),
          _NavChip(label: 'DLQ', icon: Icons.error_outline, route: '/ledger/dlq'),
          _NavChip(label: 'Reconcile', icon: Icons.balance, route: '/ledger/reconcile'),
          _NavChip(label: 'Balances', icon: Icons.bar_chart, route: '/ledger/balances'),
          _NavChip(label: 'Audit', icon: Icons.fact_check, route: '/ledger/audit'),
          _NavChip(label: 'Settings', icon: Icons.settings, route: '/ledger/settings'),
        ],
      ),
    );
  }
}

// ── Section Dispatch ────────────────────────────────────────────────────

class LedgerSectionPage extends StatelessWidget {
  final String section;
  const LedgerSectionPage({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return switch (section) {
      'accounts' => const LedgerAccountsPage(),
      'postings' => const LedgerPostingsPage(),
      'products' => const LedgerProductsPage(),
      'schedules' => const LedgerSchedulesPage(),
      'dlq' => const LedgerDlqPage(),
      'reconcile' => const _PlaceholderPage(title: 'Reconciliation', message: 'Reconciliation dashboard — match/mismatch summary.'),
      'balances' => const LedgerBalancesPage(),
      'customers' => const LedgerCustomersPage(),
      'audit' => const LedgerAuditPage(),
      'settings' => const _PlaceholderPage(title: 'Ledger Settings', message: 'Ledger configuration parameters.'),
      _ => _PlaceholderPage(title: 'Unknown', message: 'Unknown section: $section'),
    };
  }
}

// ── Products ────────────────────────────────────────────────────────────

class LedgerProductsPage extends StatefulWidget {
  const LedgerProductsPage({super.key});
  @override
  State<LedgerProductsPage> createState() => _LedgerProductsPageState();
}

class _LedgerProductsPageState extends State<LedgerProductsPage> {
  List<dynamic>? _products;
  String? _error;
  bool _showCreate = false;
  final _nameCtrl = TextEditingController();
  String _productType = 'current_account';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final svc = AdminContext.instance!.services!.ledger;
      final resp = await svc.get('/v1/products');
      final products = (resp.data?['products'] ?? resp.data?['data']) as List<dynamic>? ?? [];
      if (mounted) setState(() => _products = products);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _create() async {
    try {
      await AdminContext.instance!.services!.ledger.post('/v1/products', body: {
        'name': _nameCtrl.text,
        'product_type': _productType,
      });
      if (mounted) {
        setState(() => _showCreate = false);
        _nameCtrl.clear();
        _load();
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Error creating product: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Products',
      action: FilledButton.icon(onPressed: () => setState(() => _showCreate = !_showCreate), icon: const Icon(Icons.add), label: const Text('Create Product')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) _ErrorBanner(error: _error!),
          if (_showCreate) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Product Name')),
                    const SizedBox(height: 12),
                    DropdownButton<String>(
                      value: _productType,
                      items: const [
                        DropdownMenuItem(value: 'current_account', child: Text('Current Account')),
                        DropdownMenuItem(value: 'savings_account', child: Text('Savings Account')),
                        DropdownMenuItem(value: 'credit_card', child: Text('Credit Card')),
                        DropdownMenuItem(value: 'loan', child: Text('Loan')),
                        DropdownMenuItem(value: 'mortgage', child: Text('Mortgage')),
                      ],
                      onChanged: (v) => setState(() => _productType = v ?? 'current_account'),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [FilledButton(onPressed: _create, child: const Text('Create')), const SizedBox(width: 8), OutlinedButton(onPressed: () => setState(() => _showCreate = false), child: const Text('Cancel'))]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_products == null)
            const Center(child: CircularProgressIndicator(color: Sentin8Colors.primary))
          else if (_products!.isEmpty)
            const Text('No products yet.', style: Sentin8Text.bodyMedium)
          else
            Expanded(child: ListView.builder(itemCount: _products!.length, itemBuilder: (c, i) {
              final p = _products![i] as Map<String, dynamic>;
              return Card(child: ListTile(
                leading: const Icon(Icons.inventory_2, color: Sentin8Colors.primary),
                title: Text(p['name'] as String? ?? 'Unknown'),
                subtitle: Text('${p['product_type'] ?? '—'} • ${p['id'] ?? ''}'),
                trailing: Text(p['status'] as String? ?? 'active'),
              ));
            })),
        ],
      ),
    );
  }
}

// ── Accounts ────────────────────────────────────────────────────────────

class LedgerAccountsPage extends StatefulWidget {
  const LedgerAccountsPage({super.key});
  @override
  State<LedgerAccountsPage> createState() => _LedgerAccountsPageState();
}

class _LedgerAccountsPageState extends State<LedgerAccountsPage> {
  List<dynamic>? _accounts;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await AdminContext.instance!.services!.ledger.get('/v1/accounts');
      if (mounted) setState(() => _accounts = (resp.data?['accounts'] ?? resp.data?['data']) as List<dynamic>? ?? []);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Accounts',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) _ErrorBanner(error: _error!),
          if (_accounts == null)
            const Center(child: CircularProgressIndicator(color: Sentin8Colors.primary))
          else if (_accounts!.isEmpty)
            const Text('No accounts yet.', style: Sentin8Text.bodyMedium)
          else
            Expanded(child: ListView.builder(itemCount: _accounts!.length, itemBuilder: (c, i) {
              final a = _accounts![i] as Map<String, dynamic>;
              return Card(child: ListTile(
                leading: const Icon(Icons.account_balance, color: Sentin8Colors.primary),
                title: Text(a['id'] as String? ?? 'Unknown'),
                subtitle: Text('${a['account_type'] ?? '—'} • ${a['denomination'] ?? 'CAD'}'),
                trailing: Text(a['status'] as String? ?? 'active'),
              ));
            })),
        ],
      ),
    );
  }
}

// ── Postings ────────────────────────────────────────────────────────────

class LedgerPostingsPage extends StatefulWidget {
  const LedgerPostingsPage({super.key});
  @override
  State<LedgerPostingsPage> createState() => _LedgerPostingsPageState();
}

class _LedgerPostingsPageState extends State<LedgerPostingsPage> {
  List<dynamic>? _postings;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await AdminContext.instance!.services!.ledger.get('/v1/postings');
      if (mounted) setState(() => _postings = (resp.data?['postings'] ?? resp.data?['data']) as List<dynamic>? ?? []);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Postings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) _ErrorBanner(error: _error!),
          if (_postings == null)
            const Center(child: CircularProgressIndicator(color: Sentin8Colors.primary))
          else if (_postings!.isEmpty)
            const Text('No postings yet.', style: Sentin8Text.bodyMedium)
          else
            Expanded(child: ListView.builder(itemCount: _postings!.length, itemBuilder: (c, i) {
              final p = _postings![i] as Map<String, dynamic>;
              return Card(child: ListTile(
                leading: const Icon(Icons.receipt_long, color: Sentin8Colors.primary),
                title: Text(p['id'] as String? ?? 'Unknown'),
                subtitle: Text('${p['description'] ?? '—'} • ${p['amount'] ?? ''}'),
                trailing: Text(p['phase'] as String? ?? ''),
              ));
            })),
        ],
      ),
    );
  }
}

// ── Schedules ───────────────────────────────────────────────────────────

class LedgerSchedulesPage extends StatefulWidget {
  const LedgerSchedulesPage({super.key});
  @override
  State<LedgerSchedulesPage> createState() => _LedgerSchedulesPageState();
}

class _LedgerSchedulesPageState extends State<LedgerSchedulesPage> {
  List<dynamic>? _schedules;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await AdminContext.instance!.services!.ledger.get('/v1/schedules');
      if (mounted) setState(() => _schedules = (resp.data?['schedules'] ?? resp.data?['data']) as List<dynamic>? ?? []);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Schedules',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) _ErrorBanner(error: _error!),
          if (_schedules == null)
            const Center(child: CircularProgressIndicator(color: Sentin8Colors.primary))
          else if (_schedules!.isEmpty)
            const Text('No schedules yet.', style: Sentin8Text.bodyMedium)
          else
            Expanded(child: ListView.builder(itemCount: _schedules!.length, itemBuilder: (c, i) {
              final s = _schedules![i] as Map<String, dynamic>;
              return Card(child: ListTile(
                leading: const Icon(Icons.schedule, color: Sentin8Colors.primary),
                title: Text(s['name'] as String? ?? 'Unknown'),
                subtitle: Text(s['cron'] as String? ?? '—'),
              ));
            })),
        ],
      ),
    );
  }
}

// ── DLQ ──────────────────────────────────────────────────────────────────

class LedgerDlqPage extends StatefulWidget {
  const LedgerDlqPage({super.key});
  @override
  State<LedgerDlqPage> createState() => _LedgerDlqPageState();
}

class _LedgerDlqPageState extends State<LedgerDlqPage> {
  List<dynamic>? _entries;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await AdminContext.instance!.services!.ledger.get('/v1/dlq');
      if (mounted) setState(() => _entries = (resp.data?['entries'] ?? resp.data?['data']) as List<dynamic>? ?? []);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Dead-Letter Queue',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) _ErrorBanner(error: _error!),
          if (_entries == null)
            const Center(child: CircularProgressIndicator(color: Sentin8Colors.primary))
          else if (_entries!.isEmpty)
            const Text('No dead-letter entries.', style: Sentin8Text.bodyMedium)
          else
            Expanded(child: ListView.builder(itemCount: _entries!.length, itemBuilder: (c, i) {
              final e = _entries![i] as Map<String, dynamic>;
              return Card(child: ListTile(
                leading: const Icon(Icons.error_outline, color: Colors.red),
                title: Text(e['id'] as String? ?? 'Unknown'),
                subtitle: Text(e['error'] as String? ?? '—'),
                trailing: Text(e['status'] as String? ?? ''),
              ));
            })),
        ],
      ),
    );
  }
}

// ── Balances ────────────────────────────────────────────────────────────

class LedgerBalancesPage extends StatefulWidget {
  const LedgerBalancesPage({super.key});
  @override
  State<LedgerBalancesPage> createState() => _LedgerBalancesPageState();
}

class _LedgerBalancesPageState extends State<LedgerBalancesPage> {
  List<dynamic>? _balances;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await AdminContext.instance!.services!.ledger.get('/v1/balances');
      if (mounted) setState(() => _balances = (resp.data?['balances'] ?? resp.data?['data']) as List<dynamic>? ?? []);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Balances',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) _ErrorBanner(error: _error!),
          if (_balances == null)
            const Center(child: CircularProgressIndicator(color: Sentin8Colors.primary))
          else if (_balances!.isEmpty)
            const Text('No balances yet.', style: Sentin8Text.bodyMedium)
          else
            Expanded(child: ListView.builder(itemCount: _balances!.length, itemBuilder: (c, i) {
              final b = _balances![i] as Map<String, dynamic>;
              return Card(child: ListTile(
                leading: const Icon(Icons.bar_chart, color: Sentin8Colors.primary),
                title: Text('${b['account_id'] ?? '—'}'),
                subtitle: Text('${b['amount'] ?? '—'} ${b['denomination'] ?? ''}'),
                trailing: Text(b['phase'] as String? ?? ''),
              ));
            })),
        ],
      ),
    );
  }
}

// ── Customers ───────────────────────────────────────────────────────────

class LedgerCustomersPage extends StatefulWidget {
  const LedgerCustomersPage({super.key});
  @override
  State<LedgerCustomersPage> createState() => _LedgerCustomersPageState();
}

class _LedgerCustomersPageState extends State<LedgerCustomersPage> {
  List<dynamic>? _customers;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await AdminContext.instance!.services!.ledger.get('/v1/customers');
      if (mounted) setState(() => _customers = (resp.data?['customers'] ?? resp.data?['data']) as List<dynamic>? ?? []);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Customers',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) _ErrorBanner(error: _error!),
          if (_customers == null)
            const Center(child: CircularProgressIndicator(color: Sentin8Colors.primary))
          else if (_customers!.isEmpty)
            const Text('No customers yet.', style: Sentin8Text.bodyMedium)
          else
            Expanded(child: ListView.builder(itemCount: _customers!.length, itemBuilder: (c, i) {
              final cu = _customers![i] as Map<String, dynamic>;
              return Card(child: ListTile(
                leading: const Icon(Icons.people, color: Sentin8Colors.primary),
                title: Text(cu['display_name'] as String? ?? 'Unknown'),
                subtitle: Text(cu['email'] as String? ?? '—'),
                trailing: Text(cu['id'] as String? ?? ''),
              ));
            })),
        ],
      ),
    );
  }
}

// ── Audit ────────────────────────────────────────────────────────────────

class LedgerAuditPage extends StatefulWidget {
  const LedgerAuditPage({super.key});
  @override
  State<LedgerAuditPage> createState() => _LedgerAuditPageState();
}

class _LedgerAuditPageState extends State<LedgerAuditPage> {
  List<dynamic>? _events;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await AdminContext.instance!.services!.ledger.get('/v1/audit');
      if (mounted) setState(() => _events = (resp.data?['events'] ?? resp.data?['data']) as List<dynamic>? ?? []);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Audit Trail',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) _ErrorBanner(error: _error!),
          if (_events == null)
            const Center(child: CircularProgressIndicator(color: Sentin8Colors.primary))
          else if (_events!.isEmpty)
            const Text('No audit events.', style: Sentin8Text.bodyMedium)
          else
            Expanded(child: ListView.builder(itemCount: _events!.length, itemBuilder: (c, i) {
              final e = _events![i] as Map<String, dynamic>;
              return Card(child: ListTile(
                leading: const Icon(Icons.fact_check, color: Sentin8Colors.primary),
                title: Text(e['action'] as String? ?? '—'),
                subtitle: Text('${e['actor_user_id'] ?? ''} • ${e['timestamp'] ?? ''}'),
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
      onPressed: () {
        web.window.location.hash = route;
      },
    );
  }
}