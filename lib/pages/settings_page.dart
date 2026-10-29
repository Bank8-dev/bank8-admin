// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Bank8:Admin
// SPDX-License-Identifier: Apache-2.0

// Bank8:Admin Settings page - service enablement toggles.
//
// Enables/disables ledger, payments, and fdx services via the Sentin8:Sys
// API (PUT /v1/env/{env_id}/services). Uses the admin app's
// BffApiClient which routes through the BFF proxy.

import 'package:flutter/material.dart';
import '../theme.dart';
import '../app_context.dart';
import '../services.dart';
import 'package:sentin8/sentin8.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _loading = true;
  String? _error;
  final _services = <String, bool>{};
  final _serviceLabels = <String, String>{
    'ledger': 'Ledger',
    'payments': 'Payments',
    'fdx': 'FDX',
  };

  @override
  void initState() {
    super.initState();
    _loadServiceStates();
  }

  Future<void> _loadServiceStates() async {
    try {
      final ctx = AdminContextProvider.of(context);
      if (ctx == null || ctx.services == null) return;
      final runtimeCtx = ctx.runtimeContext;
      final orgId = runtimeCtx.organizationId;
      final envId = runtimeCtx.environmentId;
      if (orgId.isEmpty || envId.isEmpty) return;

      // Fetch service states from the sys module services endpoint.
      final sysClient = BffApiClient(
        bffBaseUrl: ctx.services!.ledger.bffBaseUrl,
        serviceName: 'sys',
        csrfToken: ctx.services!.ledger.csrfToken,
        correlationId: ctx.services!.ledger.correlationId,
      );
      final resp = await sysClient.get(
        '/v1/modules/services?org_id=$orgId&env_id=$envId',
      );
      if (resp.isSuccess && resp.data != null) {
        final modules = resp.data!['data'] as List<dynamic>? ?? resp.data! as List<dynamic>? ?? [];
        for (final m in modules) {
          final flag = m['feature_flag'] as String? ?? '';
          final enabled = m['enabled'] as bool? ?? false;
          if (_serviceLabels.containsKey(flag)) {
            _services[flag] = enabled;
          }
        }
      }
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleService(String service, bool enabled) async {
    try {
      final ctx = AdminContextProvider.of(context);
      if (ctx == null || ctx.services == null) return;
      final runtimeCtx = ctx.runtimeContext;
      final orgId = runtimeCtx.organizationId;
      final envId = runtimeCtx.environmentId;
      if (orgId.isEmpty || envId.isEmpty) return;

      final sysClient = BffApiClient(
        bffBaseUrl: ctx.services!.ledger.bffBaseUrl,
        serviceName: 'sys',
        csrfToken: ctx.services!.ledger.csrfToken,
        correlationId: ctx.services!.ledger.correlationId,
      );
      await sysClient.put(
        '/v1/env/$envId/services',
        body: {
          'service': service,
          'enabled': enabled,
        },
      );
      setState(() {
        _services[service] = enabled;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.all(Sentin8Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: Sentin8Text.headlineLarge),
          const SizedBox(height: 16),
          Text('Enable or disable Bank8 services for this environment.', style: Sentin8Text.bodyMedium),
          const SizedBox(height: 24),
          for (final entry in _serviceLabels.entries) ...[
            _ServiceToggle(
              label: entry.value,
              enabled: _services[entry.key] ?? false,
              onChanged: (v) => _toggleService(entry.key, v),
            ),
            const SizedBox(height: 12),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }
}

class _ServiceToggle extends StatelessWidget {
  final String label;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ServiceToggle({
    required this.label,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(label, style: Sentin8Text.headlineMedium),
        subtitle: Text(enabled ? 'Enabled' : 'Disabled'),
        trailing: FilledButton.tonal(
          onPressed: () => onChanged(!enabled),
          style: FilledButton.styleFrom(
            backgroundColor: enabled
                ? Sentin8Colors.royalGold
                : const Color(0xFF2A2A2A),
            foregroundColor: enabled
                ? Sentin8Colors.carbonBlack
                : Sentin8Colors.textSecondary,
          ),
          child: Text(enabled ? 'Enabled' : 'Enable $label'),
        ),
      ),
    );
  }
}
