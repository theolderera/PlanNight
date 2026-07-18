// Smoke tests for the "Daylight/Nocturne" design system: the theme resolves in
// both brightnesses, the brand tokens are present, and every reusable building
// block (including the two CustomPainters) renders without throwing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plannight/core/theme.dart';
import 'package:plannight/core/widgets/app_widgets.dart';

Future<void> pumpUnder(WidgetTester tester, ThemeData theme, Widget child) async {
  await tester.pumpWidget(MaterialApp(
    theme: theme,
    home: Scaffold(body: Center(child: child)),
  ));
  await tester.pump();
}

void main() {
  group('theme', () {
    test('light and dark carry the AppColors extension', () {
      expect(AppTheme.light().extension<AppColors>(), isNotNull);
      expect(AppTheme.dark().extension<AppColors>(), isNotNull);
    });

    test('primary is the cobalt accent in both modes', () {
      expect(AppTheme.light().colorScheme.primary, AppColors.light.accent);
      expect(AppTheme.dark().colorScheme.primary, AppColors.dark.accent);
    });

    test('modeFromString maps the stored preference', () {
      expect(AppTheme.modeFromString('light'), ThemeMode.light);
      expect(AppTheme.modeFromString('dark'), ThemeMode.dark);
      expect(AppTheme.modeFromString(null), ThemeMode.system);
    });
  });

  for (final entry in {'light': AppTheme.light(), 'dark': AppTheme.dark()}.entries) {
    group('reusable widgets render (${entry.key})', () {
      final theme = entry.value;

      testWidgets('AppLogo (crescent + check painter)', (tester) async {
        await pumpUnder(tester, theme, const AppLogo(size: 72));
        expect(tester.takeException(), isNull);
        expect(find.byType(AppLogo), findsOneWidget);
      });

      testWidgets('ProgressRing at several fractions', (tester) async {
        for (final p in [0.0, 0.38, 1.0]) {
          await pumpUnder(
            tester,
            theme,
            ProgressRing(
              progress: p,
              trackColor: const Color(0x33FFFFFF),
              fillColor: const Color(0xFF7AA2FF),
              child: Text('${(p * 100).round()}%'),
            ),
          );
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('SurfaceCard, PillSegment, FieldTile, labels', (tester) async {
        await pumpUnder(
          tester,
          theme,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SectionLabel('Section'),
              const FieldLabel('Field'),
              const SurfaceCard(child: Text('card')),
              PillSegment(options: const ['A', 'B', 'C'], selected: 1, onSelect: (_) {}),
              const FieldTile(child: Text('tile')),
            ],
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('card'), findsOneWidget);
      });

      testWidgets('themed inputs and buttons', (tester) async {
        await pumpUnder(
          tester,
          theme,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TextField(decoration: InputDecoration(labelText: 'Email')),
              FilledButton(onPressed: () {}, child: const Text('Save')),
              OutlinedButton(onPressed: () {}, child: const Text('Cancel')),
            ],
          ),
        );
        expect(tester.takeException(), isNull);
      });
    });
  }
}
