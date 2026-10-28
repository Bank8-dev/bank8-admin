// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Bank8:Admin
// SPDX-License-Identifier: Apache-2.0

// Bank8:Admin services — BFF proxy access layer
//
// All API calls go through the BFF proxy: {bff}/proxy/{serviceName}{path}
// The BffApiClient uses credentials: 'include' so the HttpOnly bff-session
// cookie is sent automatically (SSO with Dash via shared cookie domain).

export 'package:sentin8/sentin8.dart'
    show BffApiClient, ApiResponse, generateCorrelationId;

import 'package:sentin8/sentin8.dart';

/// Centralized service registry for Bank8:Admin.
///
/// Provides typed API clients for each backend service, all routed through BFF.
class AdminServices {
  final BffApiClient ledger;
  final BffApiClient payments;
  final BffApiClient fdx;
  final BffApiClient reporting;
  final BffApiClient risk;
  final BffApiClient compliance;
  final BffApiClient db;
  final BffApiClient storage;
  final BffApiClient post;

  AdminServices._({
    required this.ledger,
    required this.payments,
    required this.fdx,
    required this.reporting,
    required this.risk,
    required this.compliance,
    required this.db,
    required this.storage,
    required this.post,
  });

  /// Create AdminServices from runtime context + auth state.
  factory AdminServices({
    required String bffBaseUrl,
    String? csrfToken,
    String? correlationId,
  }) {
    final base = bffBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return AdminServices._(
      ledger: BffApiClient(bffBaseUrl: base, serviceName: 'bank8-ledger', csrfToken: csrfToken, correlationId: correlationId),
      payments: BffApiClient(bffBaseUrl: base, serviceName: 'bank8-payments', csrfToken: csrfToken, correlationId: correlationId),
      fdx: BffApiClient(bffBaseUrl: base, serviceName: 'openfin8-ca', csrfToken: csrfToken, correlationId: correlationId),
      reporting: BffApiClient(bffBaseUrl: base, serviceName: 'bank8-reporting', csrfToken: csrfToken, correlationId: correlationId),
      risk: BffApiClient(bffBaseUrl: base, serviceName: 'bank8-risk', csrfToken: csrfToken, correlationId: correlationId),
      compliance: BffApiClient(bffBaseUrl: base, serviceName: 'bank8-compliance', csrfToken: csrfToken, correlationId: correlationId),
      db: BffApiClient(bffBaseUrl: base, serviceName: 'db', csrfToken: csrfToken, correlationId: correlationId),
      storage: BffApiClient(bffBaseUrl: base, serviceName: 'storage', csrfToken: csrfToken, correlationId: correlationId),
      post: BffApiClient(bffBaseUrl: base, serviceName: 'post', csrfToken: csrfToken, correlationId: correlationId),
    );
  }
}