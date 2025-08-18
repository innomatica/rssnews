String yymmdd(DateTime? dt, {String fallback = ''}) {
  return dt?.toIso8601String().split('T').first ?? fallback;
}

const _month = [
  "inv", // 0
  "Jan", // 1
  "Feb", // 2
  "Mar",
  "Apr",
  "May",
  "Jun",
  "Jul",
  "Aug",
  "Sep",
  "Oct",
  "Nov",
  "Dec", // 12
];

String _twoDigit(int i) {
  return i.toString().padLeft(2, '0');
}

String mmddHHMM(DateTime? dt, {String fallback = ''}) {
  final lo = dt?.toLocal();
  return lo != null
      ? '${_month[lo.month]} ${_twoDigit(lo.day)} ${_twoDigit(lo.hour)}:${_twoDigit(lo.minute)}'
      : fallback;
}

String? googleFaviconUrl(String? url) {
  if (url != null) {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      return "https://www.google.com/s2/favicons?domain=${uri.host}&sz=128";
    }
  }
  return null;
  // String? domain = url
  //     ?.replaceFirst("https://", "")
  //     .replaceFirst("http://", "")
  //     .split("/")
  //     .first;

  // return domain != null
  //     ? "https://www.google.com/s2/favicons?domain=$domain&sz=128"
  //     : null;
}
