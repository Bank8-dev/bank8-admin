// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Bank8:Admin
// SPDX-License-Identifier: Apache-2.0

// Bank8:Admin main entry point
//
// Bootstrap flow:
// 1. App starts, calls GET /v1/app/runtime/context (routed through TLS)
// 2. TLS injects X-Sentin8-App-Id, X-Sentin8-Env-Id headers
// 3. Receives AppRuntimeContext { authDomain, bffDomain, org, env, authMode }
// 4. Initializes AuthProvider with BFF base URL
// 5. Checks BFF /auth/session for existing session (SSO with Dash)
// 6. Renders signed-in admin dashboard or sign-in page

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:web/web.dart' as web;
import 'theme.dart';
import 'app_context.dart';
import 'bootstrap.dart';
import 'pages/pages.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  runApp(const AdminApp());
}

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  AppRuntimeContext? _runtimeContext;
  String? _bootstrapError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      // Use the app's own origin (the URL the browser loaded it from) so
      // the TLS proxy injects the correct X-Sentin8-Hostname header.
      final appBaseUrl = web.window.location.origin;
      final ctx = await fetchRuntimeContext(appBaseUrl: appBaseUrl);
      setState(() {
        _runtimeContext = ctx;
      });
    } catch (e) {
      setState(() {
        _bootstrapError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _runtimeContext?.themeMode == 'dark';
    return MaterialApp(
      title: _runtimeContext?.displayName ?? 'Bank8:Admin',
      theme: isDark
          ? sentin8DarkThemeForContext(_runtimeContext!)
          : (_runtimeContext != null
              ? sentin8ThemeForContext(_runtimeContext!)
              : sentin8Theme()),
      debugShowCheckedModeBanner: false,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_bootstrapError != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Bootstrap error', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(_bootstrapError!, textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      );
    }

    if (_runtimeContext == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return AdminContextProvider(
      runtimeContext: _runtimeContext!,
      child: const AdminShell(),
    );
  }
}