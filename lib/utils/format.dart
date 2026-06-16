/// Indonesian-language money formatting and number spelling helpers.
///
/// These power both the on-screen text (`Rp5.000,00`) and the spoken
/// text-to-speech output (`lima ribu rupiah`) used for accessibility.
library;

const _ones = [
  '', 'satu', 'dua', 'tiga', 'empat', 'lima',
  'enam', 'tujuh', 'delapan', 'sembilan', 'sepuluh', 'sebelas',
];

/// Spells an integer in Indonesian ("terbilang"), e.g. 5000 -> "lima ribu".
String terbilang(int n) {
  if (n < 0) return 'minus ${terbilang(-n)}';
  if (n < 12) return _ones[n];
  if (n < 20) return '${terbilang(n - 10)} belas';
  if (n < 100) {
    final r = n % 10;
    return '${terbilang(n ~/ 10)} puluh${r != 0 ? ' ${terbilang(r)}' : ''}';
  }
  if (n < 200) {
    final r = n - 100;
    return 'seratus${r != 0 ? ' ${terbilang(r)}' : ''}';
  }
  if (n < 1000) {
    final r = n % 100;
    return '${terbilang(n ~/ 100)} ratus${r != 0 ? ' ${terbilang(r)}' : ''}';
  }
  if (n < 2000) {
    final r = n - 1000;
    return 'seribu${r != 0 ? ' ${terbilang(r)}' : ''}';
  }
  if (n < 1000000) {
    final r = n % 1000;
    return '${terbilang(n ~/ 1000)} ribu${r != 0 ? ' ${terbilang(r)}' : ''}';
  }
  if (n < 1000000000) {
    final r = n % 1000000;
    return '${terbilang(n ~/ 1000000)} juta${r != 0 ? ' ${terbilang(r)}' : ''}';
  }
  final r = n % 1000000000;
  return '${terbilang(n ~/ 1000000000)} miliar${r != 0 ? ' ${terbilang(r)}' : ''}';
}

/// Spoken amount in Indonesian, e.g. 5000 -> "lima ribu rupiah".
String spokenRupiah(int amount) {
  if (amount == 0) return 'nol rupiah';
  return '${terbilang(amount)} rupiah';
}

/// On-screen amount, e.g. 5000 -> "Rp5.000,00".
String formatRupiah(int amount, {bool withCents = true}) {
  final neg = amount < 0;
  final digits = amount.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) b.write('.');
    b.write(digits[i]);
  }
  return 'Rp${neg ? '-' : ''}$b${withCents ? ',00' : ''}';
}

const _days = ['', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _months = [
  '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

/// e.g. "Kamis 4 Juni 2026".
String formatTanggal(DateTime d) =>
    '${_days[d.weekday]} ${d.day} ${_months[d.month]} ${d.year}';

/// e.g. "12:30".
String formatJam(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Stable per-day key used to group ledger entries by date.
String dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
