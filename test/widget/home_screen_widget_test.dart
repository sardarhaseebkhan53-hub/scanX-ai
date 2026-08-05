import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanx_ai/shared/widgets/custom_app_bar.dart';
import 'package:scanx_ai/shared/widgets/empty_state_widget.dart';
import 'package:scanx_ai/shared/widgets/premium_banner.dart';
import 'package:scanx_ai/widgets/ai_badge.dart';

void main() {
  group('ScanX AI Widget Component Tests', () {
    testWidgets('CustomAppBar displays title correctly and renders icons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: CustomAppBar(title: 'ScanX Studio'),
          ),
        ),
      );

      expect(find.text('ScanX Studio'), findsOneWidget);
    });

    testWidgets('EmptyStateWidget renders title, subtitle, and action button', (tester) async {
      bool buttonPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              title: 'No Documents',
              subtitle: 'Scan your first document',
              buttonText: 'Scan Now',
              onButtonPressed: () => buttonPressed = true,
            ),
          ),
        ),
      );

      expect(find.text('No Documents'), findsOneWidget);
      expect(find.text('Scan your first document'), findsOneWidget);
      expect(find.text('Scan Now'), findsOneWidget);

      await tester.tap(find.text('Scan Now'));
      expect(buttonPressed, isTrue);
    });

    testWidgets('AIBadge renders gradient label icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AIBadge(label: 'Executive Summary'),
          ),
        ),
      );

      expect(find.text('Executive Summary'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('PremiumBanner renders upgrade card and triggers callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PremiumBanner(onTap: () => tapped = true),
          ),
        ),
      );

      expect(find.text('ScanX AI Premium'), findsOneWidget);
      await tester.tap(find.text('ScanX AI Premium'));
      expect(tapped, isTrue);
    });
  });
}
