// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Bank8:Admin
// SPDX-License-Identifier: Apache-2.0

// Bank8:Admin open-banking pages - provider settings, recipients, consents, CSDF, settings.
//
// All API calls go through BffApiClient: {bff}/proxy/openfin8-ca/v1/*
// (OpenFin8:CA - the open-banking vertical serving the FDX v6.5 wire).
// Uses AdminContext.instance!.services!.openBanking for API access.

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../../theme.dart';
import '../../app_context.dart';

// ── Overview ────────────────────────────────────────────────────────────

class OpenBankingOverviewPage extends StatelessWidget {
  const OpenBankingOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Open Banking',
      subtitle: 'Open banking (OpenFin8, FDX v6.5 wire) - provider settings, recipients, consents, CSDF.',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _NavChip(label: 'Provider', icon: Icons.cloud, route: '/open-banking/provider'),
          _NavChip(label: 'Recipients', icon: Icons.group, route: '/open-banking/recipients'),
          _NavChip(label: 'Consents', icon: Icons.lock, route: '/open-banking/consents'),
          _NavChip(label: 'CSDF', icon: Icons.data_object, route: '/open-banking/csdf'),
          _NavChip(label: 'Settings', icon: Icons.settings, route: '/open-banking/settings'),
        ],
      ),
    );
  }
}

// ── Section Dispatch ────────────────────────────────────────────────────

class OpenBankingSectionPage extends StatelessWidget {
  final String section;
  const OpenBankingSectionPage({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return switch (section) {
      'provider' => const _OpenBankingProviderPage(),
      'recipients' => const _OpenBankingRecipientsPage(),
      'consents' => const _OpenBankingConsentsPage(),
      'csdf' => const _PlaceholderPage(title: 'CSDF', message: 'Consent Synchronization Data Format settings.'),
      'settings' => const _PlaceholderPage(title: 'Open Banking Settings', message: 'Open-banking configuration parameters.'),
      _ => _PlaceholderPage(title: 'Unknown', message: 'Unknown section: $section'),
    };
  }
}

// ── Provider ────────────────────────────────────────────────────────────

class _OpenBankingProviderPage extends StatefulWidget {
  const _OpenBankingProviderPage();

  @override
  State<_OpenBankingProviderPage> createState() => _OpenBankingProviderPageState();
}

class _OpenBankingProviderPageState extends State<_OpenBankingProviderPage> {
  Map<String, dynamic>? _profile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await AdminContext.instance!.services!.openBanking.get('/v1/provider/profile');
      if (mounted) setState(() => _profile = resp.data);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Open Banking Provider',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) _ErrorBanner(error: _error!),
          if (_profile == null)
            const Center(child: CircularProgressIndicator(color: Sentin8Colors.primary))
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _profile!.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [Text('${e.key}: ', style: const TextStyle(fontWeight: FontWeight.bold)), Expanded(child: Text('${e.value}'))]),
                  )).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Recipients ──────────────────────────────────────────────────────────

class _OpenBankingRecipientsPage extends StatefulWidget {
  const _OpenBankingRecipientsPage();

  @override
  State<_OpenBankingRecipientsPage> createState() => _OpenBankingRecipientsPageState();
}

class _OpenBankingRecipientsPageState extends State<_OpenBankingRecipientsPage> {
  List<dynamic>? _recipients;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await AdminContext.instance!.services!.openBanking.get('/v1/recipient/providers');
      if (mounted) setState(() => _recipients = (resp.data?['providers'] ?? resp.data?['data']) as List<dynamic>? ?? []);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Open Banking Recipients',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) _ErrorBanner(error: _error!),
          if (_recipients == null)
            const Center(child: CircularProgressIndicator(color: Sentin8Colors.primary))
          else if (_recipients!.isEmpty)
            const Text('No recipients yet.', style: Sentin8Text.bodyMedium)
          else
            Expanded(child: ListView.builder(itemCount: _recipients!.length, itemBuilder: (c, i) {
              final r = _recipients![i] as Map<String, dynamic>;
              return Card(child: ListTile(
                leading: const Icon(Icons.group, color: Sentin8Colors.primary),
                title: Text(r['name'] as String? ?? 'Unknown'),
                subtitle: Text(r['client_id'] as String? ?? ' - '),
              ));
            })),
        ],
      ),
    );
  }
}

// ── Consents ─────────────────────────────────────────────────────────────

class _OpenBankingConsentsPage extends StatefulWidget {
  const _OpenBankingConsentsPage();

  @override
  State<_OpenBankingConsentsPage> createState() => _OpenBankingConsentsPageState();
}

class _OpenBankingConsentsPageState extends State<_OpenBankingConsentsPage> {
  List<dynamic>? _consents;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await AdminContext.instance!.services!.openBanking.get('/v1/admin/consents');
      if (mounted) setState(() => _consents = (resp.data?['consents'] ?? resp.data?['data']) as List<dynamic>? ?? []);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: 'Open Banking Consents',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error != null) _ErrorBanner(error: _error!),
          if (_consents == null)
            const Center(child: CircularProgressIndicator(color: Sentin8Colors.primary))
          else if (_consents!.isEmpty)
            const Text('No consents yet.', style: Sentin8Text.bodyMedium)
          else
            Expanded(child: ListView.builder(itemCount: _consents!.length, itemBuilder: (c, i) {
              final co = _consents![i] as Map<String, dynamic>;
              return Card(child: ListTile(
                leading: const Icon(Icons.lock, color: Sentin8Colors.primary),
                title: Text(co['id'] as String? ?? 'Unknown'),
                subtitle: Text('${co['recipient_id'] ?? ' - '} • ${co['status'] ?? ''}'),
                trailing: Text(co['scope'] as String? ?? ''),
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