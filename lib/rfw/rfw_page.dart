// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Bank8:Admin
// SPDX-License-Identifier: Apache-2.0

// Bank8:Admin RFW page — thin wrapper around the shared Sentin8RfwPage.
//
// Delegates to sentin8's Sentin8RfwPage which handles fetching, rendering,
// and form submission for remote admin UI pages. The only app-specific
// logic is resolving the BFF client for the service and hash-based
// navigation.

import 'package:flutter/material.dart';
import 'package:sentin8/sentin8.dart';

import '../app_context.dart';
import '../services.dart';

/// Bank8:Admin RFW page — renders a remote admin UI page for a bank8 service.
class Bank8RfwPage extends StatelessWidget {
  final String service;
  final String page;
  final void Function(String route) onNavigate;
  final Map<String, dynamic>? extraProps;

  const Bank8RfwPage({
    super.key,
    required this.service,
    required this.page,
    required this.onNavigate,
    this.extraProps,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final ctx = AdminContextProvider.of(context);
      debugPrint('[Bank8RfwPage] build: service=$service, page=$page, ctx=${ctx != null}, services=${ctx?.services != null}');
      if (ctx == null || ctx.services == null) {
        return const Center(child: Text('Not initialized'));
      }

      final bffClient = _getBffClient(ctx.services!);
      debugPrint('[Bank8RfwPage] bffClient=${bffClient != null}');
      if (bffClient == null) {
        return Center(child: Text('Unknown service: $service'));
      }

      return Sentin8RfwPage(
        key: ValueKey('$service/$page/${extraProps?['type'] ?? ''}'),
        service: service,
        page: page,
        bffClient: bffClient,
        onNavigate: (route) {
          // Navigate within this service via the parent's navigation callback.
          onNavigate('/$service/$route');
        },
        extraProps: extraProps,
      );
    } catch (e) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
      );
    }
  }

  BffApiClient? _getBffClient(AdminServices services) {
    switch (service) {
      case 'ledger':
        return services.ledger;
      case 'payments':
        return services.payments;
      case 'fdx':
        return services.fdx;
      case 'reporting':
        return services.reporting;
      case 'risk':
        return services.risk;
      case 'compliance':
        return services.compliance;
      default:
        return null;
    }
  }
}

/// Simple error boundary — catches render errors and shows a message.
class ErrorBoundary extends StatelessWidget {
  final Widget child;
  const ErrorBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (e) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error rendering page: $e',
                      style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
