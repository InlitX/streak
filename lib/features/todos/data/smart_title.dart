import 'package:flutter/widgets.dart' show Locale;
import 'package:intl/intl.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/todos/data/todo_repeat.dart';
import 'package:streak/l10n/app_localizations.dart';

class SmartWords {
  const SmartWords({
    this.today = const [],
    this.tomorrow = const [],
    this.every = const [],
    this.at = const [],
    this.on = const [],
    this.of = const [],
    this.units = const {},
    this.adverbs = const {},
    this.weekdays = const {},
    this.months = const {},
    this.dayFirst = true,
  });

  final List<String> today;
  final List<String> tomorrow;
  final List<String> every;
  final List<String> at;
  final List<String> on;
  final List<String> of;
  final Map<String, RepeatUnit> units;
  final Map<String, RepeatUnit> adverbs;
  final Map<String, int> weekdays;
  final Map<String, int> months;
  final bool dayFirst;

  factory SmartWords.of(AppLocalizations local, String locale) {
    final english = lookupAppLocalizations(const Locale('en'));
    List<String> words(String Function(AppLocalizations l) pick) => {
          for (final l in [local, english])
            for (final word in pick(l).split(','))
              if (smartFold(word.trim().toLowerCase()) case final w
                  when w.isNotEmpty)
                w,
        }.toList();
    Map<String, RepeatUnit> byUnit(
      String Function(AppLocalizations l) days,
      String Function(AppLocalizations l) weeks,
      String Function(AppLocalizations l) months,
      String Function(AppLocalizations l) years,
    ) =>
        {
          for (final w in words(years)) w: RepeatUnit.years,
          for (final w in words(months)) w: RepeatUnit.months,
          for (final w in words(weeks)) w: RepeatUnit.weeks,
          for (final w in words(days)) w: RepeatUnit.days,
        };
    final weekdays = <String, int>{};
    final months = <String, int>{};
    for (final code in {locale, 'en'}) {
      final DateFormat format;
      try {
        format = DateFormat('EEEE', code);
      } catch (_) {
        continue;
      }
      final symbols = format.dateSymbols;
      for (final (i, name) in symbols.WEEKDAYS.indexed) {
        final key = _symbol(name);
        if (key.length > 1) weekdays.putIfAbsent(key, () => i == 0 ? 7 : i);
      }
      for (final list in [
        symbols.MONTHS,
        symbols.STANDALONEMONTHS,
        symbols.SHORTMONTHS,
        symbols.STANDALONESHORTMONTHS,
      ]) {
        for (final (i, name) in list.indexed) {
          final key = _symbol(name);
          if (key.length > 2) months.putIfAbsent(key, () => i + 1);
        }
      }
    }
    var pattern = 'dMy';
    try {
      pattern = DateFormat.yMd(locale).pattern ?? pattern;
    } catch (_) {}
    return SmartWords(
      today: words((l) => l.smart_today),
      tomorrow: words((l) => l.smart_tomorrow),
      every: words((l) => l.smart_every),
      at: words((l) => l.smart_at),
      on: words((l) => l.smart_on),
      of: words((l) => l.smart_of),
      units: byUnit((l) => l.smart_day, (l) => l.smart_week,
          (l) => l.smart_month, (l) => l.smart_year),
      adverbs: byUnit((l) => l.smart_daily, (l) => l.smart_weekly,
          (l) => l.smart_monthly, (l) => l.smart_yearly),
      weekdays: weekdays,
      months: months,
      dayFirst: pattern.indexOf('d') < pattern.indexOf('M'),
    );
  }

  static String _symbol(String name) =>
      smartFold(name.toLowerCase().replaceAll('.', '').trim());
}

class SmartTitle {
  const SmartTitle({
    required this.title,
    required this.date,
    this.minutes,
    this.repeat,
  });

  final String title;
  final DateTime date;
  final int? minutes;
  final TodoRepeat? repeat;
}

const _fold = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', 'ą': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'ę': 'e', 'ě': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ı': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ø': 'o', 'ő': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ů': 'u', 'ű': 'u',
  'ñ': 'n', 'ń': 'n', 'ň': 'n', 'ç': 'c', 'ć': 'c', 'č': 'c',
  'ś': 's', 'š': 's', 'ş': 's', 'ș': 's', 'ź': 'z', 'ż': 'z', 'ž': 'z',
  'ł': 'l', 'ř': 'r', 'ť': 't', 'ț': 't', 'ď': 'd', 'ğ': 'g', 'ý': 'y',
};

String smartFold(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    out.write(char.length == 1 ? (_fold[char] ?? char) : char);
  }
  return out.toString();
}

const _edge = r'(?<![\p{L}\p{N}])';
const _end = r'(?![\p{L}\p{N}])';

String _any(Iterable<String> words) {
  final list = words.where((w) => w.isNotEmpty).toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  if (list.isEmpty) return r'(?!)';
  return '(?:${list.map((w) => RegExp.escape(w).replaceAll(' ', r'\s+')).join('|')})';
}

SmartTitle? parseSmartTitle(String text, DateTime now, SmartWords words) {
  if (text.trim().isEmpty) return null;
  final source = smartFold(text.toLowerCase());
  if (source.length != text.length) return null;
  final today = now.atMidnight;
  final taken = <(int, int)>[];

  RegExpMatch? take(String pattern) {
    for (final match in RegExp('$_edge$pattern$_end', unicode: true)
        .allMatches(source)) {
      if (taken.any((t) => match.start < t.$2 && t.$1 < match.end)) continue;
      taken.add((match.start, match.end));
      return match;
    }
    return null;
  }

  DateTime nextWeekday(int weekday) =>
      today.addDays((weekday - today.weekday + 7) % 7);

  DateTime? valid(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1) return null;
    if (day > DateTime(year, month + 1, 0).day) return null;
    return DateTime(year, month, day);
  }

  DateTime? ahead(int month, int day) {
    final date = valid(today.year, month, day);
    if (date == null) return null;
    return date.isBefore(today) ? valid(today.year + 1, month, day) : date;
  }

  final on = words.on.isEmpty ? '' : '(?:${_any(words.on)}\\s+)?';
  final weekday = '(${_any(words.weekdays.keys)})';
  final month = '(${_any(words.months.keys)})';

  TodoRepeat? repeat;
  DateTime? date;
  int? minutes;

  final every = _any(words.every);
  if (take('$every\\s+(?:(\\d{1,3})\\s+)?(${_any(words.units.keys)})')
      case final m?) {
    final count = int.tryParse(m.group(1) ?? '') ?? 1;
    if (count > 0) {
      repeat = TodoRepeat(unit: words.units[m.group(2)]!, every: count);
    }
  } else if (take('$every\\s+$weekday') case final m?) {
    final day = words.weekdays[m.group(1)]!;
    repeat = TodoRepeat(unit: RepeatUnit.weeks, weekdays: [day]);
    date = nextWeekday(day);
  } else if (take('(?:$every\\s+)?(${_any(words.adverbs.keys)})')
      case final m?) {
    repeat = TodoRepeat(unit: words.adverbs[m.group(1)]!);
  }

  if (take('$on(${_any(words.tomorrow)})') != null) {
    date = today.addDays(1);
  } else if (take('$on(${_any(words.today)})') != null) {
    date = today;
  } else if (take('$on(\\d{1,2})/(\\d{1,2})(?:/(\\d{2,4}))?') case final m?) {
    final a = int.parse(m.group(1)!);
    final b = int.parse(m.group(2)!);
    final (d, mo) = words.dayFirst ? (a, b) : (b, a);
    final y = int.tryParse(m.group(3) ?? '');
    final found = y == null ? ahead(mo, d) : valid(y < 100 ? 2000 + y : y, mo, d);
    if (found == null) {
      taken.removeLast();
    } else {
      date = found;
    }
  } else if (take('$on(\\d{1,2})\\s+(?:${_any(words.of)}\\s+)?$month')
      case final m?) {
    final found = ahead(words.months[m.group(2)]!, int.parse(m.group(1)!));
    if (found == null) {
      taken.removeLast();
    } else {
      date = found;
    }
  } else if (take('$on$month\\s+(\\d{1,2})') case final m?) {
    final found = ahead(words.months[m.group(1)]!, int.parse(m.group(2)!));
    if (found == null) {
      taken.removeLast();
    } else {
      date = found;
    }
  } else if (repeat == null) {
    if (take('$on$weekday') case final m?) {
      date = nextWeekday(words.weekdays[m.group(1)]!);
    }
  }

  final at = words.at.isEmpty ? '' : '(?:${_any(words.at)}\\s+)?';
  const half = r'(?:\s?([ap])\.?m\.?)';
  int? clock(int hour, int minute, String? half) {
    if (minute > 59) return null;
    if (half != null) {
      if (hour < 1 || hour > 12) return null;
      hour = hour % 12 + (half == 'p' ? 12 : 0);
    }
    if (hour > 23) return null;
    return hour * 60 + minute;
  }

  if (take('$at(\\d{1,2})[:h](\\d{2})$half?') case final m?) {
    minutes = clock(int.parse(m.group(1)!), int.parse(m.group(2)!), m.group(3));
    if (minutes == null) taken.removeLast();
  } else if (take('$at(\\d{1,2})$half') case final m?) {
    minutes = clock(int.parse(m.group(1)!), 0, m.group(2));
    if (minutes == null) taken.removeLast();
  } else if (take('${_any(words.at)}\\s+(\\d{1,2})') case final m?) {
    minutes = clock(int.parse(m.group(1)!), 0, null);
    if (minutes == null) taken.removeLast();
  }

  if (taken.isEmpty) return null;
  if (date == null) {
    final late = minutes != null &&
        minutes <= now.hour * 60 + now.minute;
    date = late && repeat == null ? today.addDays(1) : today;
  }
  taken.sort((a, b) => b.$1.compareTo(a.$1));
  var title = text;
  for (final (start, end) in taken) {
    title = title.replaceRange(start, end, ' ');
  }
  title = title
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^[\s,;:\-]+|[\s,;:\-]+$'), '');
  if (title.isEmpty) return null;
  return SmartTitle(
    title: title,
    date: date,
    minutes: minutes,
    repeat: repeat?.anchoredTo(date),
  );
}
