// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Bank8:Admin
// SPDX-License-Identifier: Apache-2.0

// Bank8:Admin app context - central runtime state
//
// Holds the AppRuntimeContext, AuthProvider, and AdminServices.
// Provides them to the widget tree via InheritedWidget.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'bootstrap.dart';
import 'auth_provider.dart';
import 'services.dart';

/// Central app context that ties together runtime context, auth, and services.
class AdminContext extends ChangeNotifier {
  /// Singleton instance - accessible from anywhere (like Dash's AuthProvider.instance).
  static AdminContext? instance;

  final AppRuntimeContext runtimeContext;
  final AuthProvider auth;
  final String correlationId;

  AdminContext._({
    required this.runtimeContext,
    required this.auth,
    required this.correlationId,
  }) {
    AdminContext.instance = this;
    auth.addListener(_onAuthChanged);
    _updateServices();
  }

  /// Create the app context after bootstrap.
  static Future<AdminContext> create(AppRuntimeContext runtimeContext) async {
    final corrId = generateCorrelationId();
    final auth = AuthProvider(
      bffBaseUrl: runtimeContext.bffBaseUrl,
      authDomain: runtimeContext.authDomain,
    );
    auth.onRedirect = (String url) {
      web.window.location.href = url;
    };
    await auth.init();
    return AdminContext._(
      runtimeContext: runtimeContext,
      auth: auth,
      correlationId: corrId,
    );
  }

  /// Convenience accessor for the services, available after init.
  AdminServices? _services;
  AdminServices? get services => _services;

  void _onAuthChanged() {
    _updateServices();
    notifyListeners();
  }

  void _updateServices() {
    _services = AdminServices(
      bffBaseUrl: runtimeContext.bffBaseUrl,
      csrfToken: auth.csrfToken,
      correlationId: correlationId,
    );
  }

  @override
  void dispose() {
    auth.removeListener(_onAuthChanged);
    auth.dispose();
    AdminContext.instance = null;
    super.dispose();
  }
}

/// StatefulWidget providing AdminContext to the widget tree.
class AdminContextProvider extends StatefulWidget {
  final AppRuntimeContext runtimeContext;
  final Widget child;

  const AdminContextProvider({
    super.key,
    required this.runtimeContext,
    required this.child,
  });

  @override
  State<AdminContextProvider> createState() => _AdminContextProviderState();

  static AdminContext? of(BuildContext context) {
    final inh = context.dependOnInheritedWidgetOfExactType<_AdminContextInherited>();
    return inh?.adminContext;
  }
}

class _AdminContextProviderState extends State<AdminContextProvider> {
  AdminContext? _context;

  @override
  void initState() {
    super.initState();
    _initContext();
  }

  Future<void> _initContext() async {
    final ctx = await AdminContext.create(widget.runtimeContext);
    if (mounted) {
      setState(() {
        _context = ctx;
      });
    }
  }

  @override
  void dispose() {
    _context?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_context == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _AdminContextInherited(
      adminContext: _context!,
      child: widget.child,
    );
  }
}

class _AdminContextInherited extends InheritedWidget {
  final AdminContext adminContext;

  const _AdminContextInherited({required this.adminContext, required super.child});

  @override
  bool updateShouldNotify(_AdminContextInherited old) =>
      adminContext != old.adminContext;
}