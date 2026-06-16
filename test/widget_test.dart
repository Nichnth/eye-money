import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eye_money/main.dart';
import 'package:eye_money/screens/history_screen.dart';
import 'package:eye_money/services/money_detector.dart';
import 'package:eye_money/utils/format.dart';

void main() {
  group('format', () {
    test('terbilang spells Indonesian numbers', () {
      expect(terbilang(1000), 'seribu');
      expect(terbilang(5000), 'lima ribu');
      expect(terbilang(21), 'dua puluh satu');
      expect(terbilang(100000), 'seratus ribu');
    });

    test('spokenRupiah', () {
      expect(spokenRupiah(5000), 'lima ribu rupiah');
      expect(spokenRupiah(0), 'nol rupiah');
    });

    test('formatRupiah', () {
      expect(formatRupiah(5000), 'Rp5.000,00');
      expect(formatRupiah(100000), 'Rp100.000,00');
    });
  });

  test('MockMoneyDetector returns a positive total and spoken summary', () async {
    final detector = MockMoneyDetector(random: Random(1), delay: Duration.zero);
    final result = await detector.detect();
    expect(result.items, isNotEmpty);
    expect(result.total, greaterThan(0));
    expect(result.spoken, contains('Totalnya'));
    expect(result.spoken, contains('rupiah'));
  });

  testWidgets('Read screen shows the scan prompt', (tester) async {
    await tester.pumpWidget(const EyeMoneyApp());
    await tester.pump();
    expect(find.textContaining('Arahkan kamera ke uang'), findsOneWidget);
  });

  testWidgets('History screen shows hidden balance and a ledger entry',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HistoryScreen()));
    await tester.pump();
    expect(find.text('Uang di kantong saku'), findsOneWidget);
    expect(find.text('Rp******'), findsOneWidget);
  });
}
