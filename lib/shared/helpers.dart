String yymmdd(DateTime? dt, {String fallback = ''}) {
  return dt?.toIso8601String().split('T').first ?? fallback;
}
