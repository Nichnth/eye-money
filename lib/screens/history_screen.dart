import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../services/haptic_service.dart';
import '../state/pocket_store.dart';
import '../theme/app_theme.dart';
import '../utils/a11y.dart';
import '../utils/format.dart';
import '../utils/voice.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/circle_action_button.dart';
import '../widgets/notification_banner.dart';
import 'read_count_screen.dart';

/// "Nominal Record & History" — the pocket ("kantong saku"): a hidden
/// balance with an eye toggle, plus a date-grouped chat ledger. The mic
/// runs a mocked voice command that reduces the balance.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ScrollController _scroll = ScrollController();
  final Random _rng = Random();
  ({String title, String message})? _banner;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    PocketStore.instance.seedDemoIfEmpty();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  /// Shows the top banner and auto-hides it so it never permanently covers the
  /// balance header (and its eye toggle).
  void _showBanner(String title, String message) {
    _bannerTimer?.cancel();
    setState(() => _banner = (title: title, message: message));
    _bannerTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _banner = null);
    });
  }

  void _dismissBanner() {
    _bannerTimer?.cancel();
    if (_banner != null) setState(() => _banner = null);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _toggleVisibility() {
    HapticService.instance.selection();
    PocketStore.instance.toggleVisibility();
    final store = PocketStore.instance;
    voiceFeedback(
      context,
      store.balanceVisible
          ? 'Saldo kantong saku ${spokenRupiah(store.balance)}'
          : 'Saldo disembunyikan',
    );
  }

  Future<void> _onCamera() async {
    HapticService.instance.press();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ReadCountScreen()),
      );
    }
  }

  Future<void> _onMic() async {
    HapticService.instance.press();
    final store = PocketStore.instance;
    if (store.balance < 1000) {
      HapticService.instance.warning();
      await voiceFeedback(
          context, 'Kantong saku kosong. Tidak ada yang bisa dikurangi.');
      return;
    }
    // Mock a "reduce" voice command for a random round amount.
    final maxSteps = (store.balance.clamp(0, 5000)) ~/ 1000;
    final amount = (1 + _rng.nextInt(maxSteps)) * 1000;

    store.addUserMessage('Kurangin ${terbilang(amount)} rupiah dari kantong saku');
    _scrollToBottom();
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final spoken = store.subtractMoney(amount);
    _showBanner(
      'Nominal berhasil dikurangi',
      'Nominal sebesar ${formatRupiah(amount)} sudah dikurangi dari kantong saku.',
    );
    _scrollToBottom();
    HapticService.instance.success();
    await voiceFeedback(context, spoken);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: PocketStore.instance,
          builder: (context, _) {
            final store = PocketStore.instance;
            return Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildBalanceHeader(store),
                    const SizedBox(height: 16),
                    Expanded(child: _buildLedger(store)),
                    _buildControls(),
                  ],
                ),
                if (_banner != null)
                  Positioned(
                    top: 8,
                    left: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: _dismissBanner,
                      child: NotificationBanner(
                        title: _banner!.title,
                        message: _banner!.message,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBalanceHeader(PocketStore store) {
    final balanceText = store.balanceVisible ? formatRupiah(store.balance) : 'Rp******';
    return Column(
      children: [
        // Title + balance as a single screen-reader node. The raw texts are
        // excluded so they aren't read twice — but the eye toggle below is kept
        // OUTSIDE this ExcludeSemantics so the screen reader can still activate it.
        Semantics(
          header: true,
          liveRegion: true,
          attributedLabel: idLabel('Uang di kantong saku, '
              '${store.balanceVisible ? spokenRupiah(store.balance) : 'tersembunyi'}'),
          child: ExcludeSemantics(
            child: Text(
              'Uang di kantong saku',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.green.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ExcludeSemantics(
              child: Text(
                balanceText,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppColors.green,
                ),
              ),
            ),
            const SizedBox(width: 24),
            Semantics(
              button: true,
              attributedLabel: idLabel(
                  store.balanceVisible ? 'Sembunyikan saldo' : 'Tampilkan saldo'),
              child: IconButton(
                iconSize: 32,
                color: AppColors.green,
                onPressed: _toggleVisibility,
                icon: Icon(store.balanceVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLedger(PocketStore store) {
    final rows = <Widget>[];
    String? lastKey;
    for (final e in store.entries) {
      final key = dateKey(e.time);
      if (key != lastKey) {
        rows.add(_datePill(formatTanggal(e.time)));
        lastKey = key;
      }
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: e.kind == EntryKind.ai
            ? _aiBubble(e, live: e == store.entries.last)
            : _userBubble(e),
      ));
    }
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: rows,
    );
  }

  Widget _datePill(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 9),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.pill,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Semantics(
            attributedLabel: idLabel(text),
            child: ExcludeSemantics(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _aiBubble(PocketEntry e, {bool live = false}) {
    final visible = PocketStore.instance.balanceVisible;
    final subtitle = e.balanceAfter == null
        ? null
        : 'Saldo diperbarui menjadi '
            '${visible ? formatRupiah(e.balanceAfter!) : 'Rp*****'}';
    return ChatBubble(
      isAi: true,
      squareBottomRight: false,
      contentAlignEnd: false,
      fullWidth: true,
      liveRegion: live,
      sender: 'AI',
      time: formatJam(e.time),
      subtitle: subtitle,
      semanticsLabel: 'Pesan dari aplikasi: ${e.spoken}',
      body: Text(
        e.title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _userBubble(PocketEntry e) {
    return Align(
      alignment: Alignment.centerRight,
      child: ChatBubble(
        isAi: false,
        squareBottomRight: true,
        contentAlignEnd: true,
        sender: 'Anda',
        time: formatJam(e.time),
        semanticsLabel: 'Anda berkata: ${e.spoken}',
        body: Text(
          e.title,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CircleActionButton(
            icon: Icons.photo_camera_outlined,
            label: 'Pindai uang',
            hint: 'Buka kamera untuk memindai dan menghitung uang',
            onPressed: _onCamera,
          ),
          CircleActionButton(
            icon: Icons.mic,
            label: 'Perintah suara',
            hint: 'Ketuk lalu sebutkan perintah, misalnya mengurangi uang dari kantong saku',
            onPressed: _onMic,
          ),
        ],
      ),
    );
  }
}
