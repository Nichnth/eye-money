import 'package:flutter/foundation.dart';

import '../utils/format.dart';

enum EntryKind { ai, user }

/// A single line in the "kantong saku" (pocket) ledger.
class PocketEntry {
  final EntryKind kind;
  final String title;

  /// Running balance after this entry (null for user messages). Rendered
  /// masked or revealed by the eye toggle; never baked into a string.
  final int? balanceAfter;

  /// Screen-reader friendly version (spells amounts as words).
  final String spoken;
  final DateTime time;
  const PocketEntry({
    required this.kind,
    required this.title,
    this.balanceAfter,
    required this.spoken,
    required this.time,
  });
}

/// Shared in-memory pocket: balance + chat-style ledger.
///
/// Both the Read/Count screen (adds money) and the History screen
/// (shows + voice-edits the ledger) observe this single store.
class PocketStore extends ChangeNotifier {
  PocketStore._();
  static final PocketStore instance = PocketStore._();

  int _balance = 0;
  int get balance => _balance;

  bool balanceVisible = false;
  final List<PocketEntry> entries = [];

  bool _seeded = false;

  /// Seeds the ledger so History looks populated on first open (matches Figma).
  void seedDemoIfEmpty() {
    if (_seeded) return;
    _seeded = true;
    _applyAdd(5000, at: DateTime(2026, 6, 4, 12, 30));
    _applyAdd(9000, at: DateTime(2026, 6, 4, 17, 30));
    _applyAdd(5000, at: DateTime(2026, 6, 5, 12, 30));
    _applyAdd(9000, at: DateTime(2026, 6, 5, 17, 30));
    notifyListeners();
  }

  void _applyAdd(int amount, {required DateTime at}) {
    _balance += amount;
    entries.add(PocketEntry(
      kind: EntryKind.ai,
      title: 'Menambahkan ${formatRupiah(amount)}',
      balanceAfter: _balance,
      spoken: 'Menambahkan ${spokenRupiah(amount)}. '
          'Saldo diperbarui menjadi ${spokenRupiah(_balance)}',
      time: at,
    ));
  }

  /// Adds money and returns a spoken confirmation.
  String addMoney(int amount) {
    _applyAdd(amount, at: DateTime.now());
    notifyListeners();
    return 'Berhasil menambahkan ${spokenRupiah(amount)}. '
        'Saldo sekarang ${spokenRupiah(_balance)}';
  }

  /// Subtracts money (clamped to the balance) and returns a spoken confirmation.
  String subtractMoney(int amount) {
    final applied = amount.clamp(0, _balance);
    _balance -= applied;
    entries.add(PocketEntry(
      kind: EntryKind.ai,
      title: 'Mengurangi ${formatRupiah(applied)}',
      balanceAfter: _balance,
      spoken: 'Mengurangi ${spokenRupiah(applied)}. '
          'Saldo diperbarui menjadi ${spokenRupiah(_balance)}',
      time: DateTime.now(),
    ));
    notifyListeners();
    return 'Berhasil mengurangi ${spokenRupiah(applied)}. '
        'Saldo sekarang ${spokenRupiah(_balance)}';
  }

  void addUserMessage(String text) {
    entries.add(PocketEntry(
      kind: EntryKind.user,
      title: text,
      spoken: text,
      time: DateTime.now(),
    ));
    notifyListeners();
  }

  void toggleVisibility() {
    balanceVisible = !balanceVisible;
    notifyListeners();
  }
}
