// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Bank8:Admin
// SPDX-License-Identifier: Apache-2.0

// Bank8:Admin overview page — dashboard with service health cards
import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../app_context.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});
  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  Map<String, dynamic>? _healthStatus;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHealth();
  }

  Future<void> _loadHealth() async {
    final ctx = AdminContextProvider.of(context);
    if (ctx?.services == null) return;
    final results = <String, dynamic>{};
    for (final entry in {
      'ledger': ctx!.services!.ledger,
      'payments': ctx.services!.payments,
      'fdx': ctx.services!.fdx,
      'reporting': ctx.services!.reporting,
      'risk': ctx.services!.risk,
      'compliance': ctx.services!.compliance,
    }.entries) {
      try {
        final resp = await entry.value.get('/v1/health');
        results[entry.key] = resp.statusCode == 200 ? 'healthy' : 'degraded';
      } catch (_) {
        results[entry.key] = 'offline';
      }
    }
    if (mounted) setState(() => _healthStatus = results);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Sentin8Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overview', style: Sentin8Text.headlineLarge),
          const SizedBox(height: Sentin8Spacing.lg),
          if (_healthStatus == null)
            const Center(child: CircularProgressIndicator(color: Sentin8Colors.primary))
          else
            Wrap(
              spacing: Sentin8Spacing.lg,
              runSpacing: Sentin8Spacing.lg,
              children: _healthStatus!.entries.map((e) => _HealthCard(name: e.key, status: e.value)).toList(),
            ),
        ],
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  final String name;
  final String status;
  const _HealthCard({required this.name, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'healthy' ? Colors.green : (status == 'degraded' ? Colors.orange : Colors.red);
    return Card(
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(Sentin8Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.circle, color: color, size: 12), const SizedBox(width: 8), Text(name, style: Sentin8Text.headlineMedium)]),
            const SizedBox(height: 8),
            Text(status, style: Sentin8Text.bodyMedium),
          ],
        ),
      ),
    );
  }
}