import 'dart:math';

import '../utils/format.dart';

/// Indonesian Rupiah banknote denominations.
const List<int> kRupiahDenominations = [
  1000, 2000, 5000, 10000, 20000, 50000, 100000,
];

/// A count of identical banknotes detected, e.g. two Rp2.000 notes.
class DetectionItem {
  final int denom;
  final int count;
  const DetectionItem(this.denom, this.count);
  int get value => denom * count;
}

/// The outcome of a (mocked) money scan.
class DetectionResult {
  final List<DetectionItem> items;
  const DetectionResult(this.items);

  int get total => items.fold(0, (s, it) => s + it.value);

  /// Human-spoken summary, matching the Figma copy, e.g.
  /// "satu lembar seribu rupiah dan dua lembar dua ribu rupiah.
  ///  Totalnya lima ribu rupiah".
  String get spoken {
    final parts = items
        .map((it) => '${terbilang(it.count)} lembar ${terbilang(it.denom)} rupiah')
        .toList();
    return '${_joinDan(parts)}. Totalnya ${spokenRupiah(total)}';
  }
}

String _joinDan(List<String> parts) {
  if (parts.isEmpty) return '';
  if (parts.length == 1) return parts.first;
  return '${parts.sublist(0, parts.length - 1).join(', ')} dan ${parts.last}';
}

/// Seam for a real camera + ML detector to drop in later.
abstract class MoneyDetector {
  Future<DetectionResult> detect();
}

/// Stand-in detector: returns a random plausible mix of notes after a delay.
class MockMoneyDetector implements MoneyDetector {
  MockMoneyDetector({Random? random, this.delay = const Duration(milliseconds: 1500)})
      : _rng = random ?? Random();

  final Random _rng;
  final Duration delay;

  @override
  Future<DetectionResult> detect() async {
    await Future.delayed(delay);
    final kinds = 1 + _rng.nextInt(2); // 1-2 distinct denominations
    final chosen = <int>{};
    while (chosen.length < kinds) {
      chosen.add(kRupiahDenominations[_rng.nextInt(kRupiahDenominations.length)]);
    }
    final items = chosen.map((d) => DetectionItem(d, 1 + _rng.nextInt(3))).toList()
      ..sort((a, b) => a.denom.compareTo(b.denom));
    return DetectionResult(items);
  }
}
