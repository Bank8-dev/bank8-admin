// SPDX-FileCopyrightText: Copyright Logically Magic Inc. <hello@logicallymagic.com>
// SPDX-FileCopyrightText: Copyright Hamid Jahanzad <Hamid@Jahanzad.com>
// SPDX-FileCopyrightText: Copyright Contributors to the Bank8:Admin
// SPDX-License-Identifier: Apache-2.0

// Admin widget test — app root smoke test.
//
// AdminApp bootstraps via `fetchRuntimeContext` (a network call on
// web.window.location.origin), so pumping the full app in a test would
// either hang on the spinner or hit the network. Instead, assert the
// theme layer directly: `sentin8Theme()` is what the app applies when no
// runtime context is present (MaterialApp.theme in main.dart).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentin8/sentin8.dart' show sentin8Theme;

void main() {
  testWidgets('sentin8Theme produces a light Material 3 scheme', (tester) async {
    final theme = sentin8Theme();
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.brightness, Brightness.light);
    expect(theme.colorScheme.primary, isNot(Colors.transparent));

    // The theme must render a standard Scaffold without errors.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(body: Text('Admin')),
      ),
    );
    expect(find.text('Admin'), findsOneWidget);
  });
}
