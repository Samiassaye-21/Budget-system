import 'package:flutter/material.dart';

class AppColors {
  // 1. Primary Main Color: Golden Sunset Amber (Day Shift)
  static const Color primary = Color(0xFFD97706);
  static const Color primaryDark = Color(0xFFB45309);
  static const Color primaryLight = Color(0xFFFEF3C7);
  static const Color primarySoft = Color(0xFFFFFBEB);

  // Night Shift Palette
  static const Color nightPrimary = Color(0xFF6B46C1);
  static const Color nightDark = Color(0xFF4C1D95);
  static const Color nightLight = Color(0xFFEDE9FE);
  static const Color nightSoft = Color(0xFFF5F3FF);

  // 2. Obsidian Black & Grays
  static const Color obsidian = Color(0xFF0F172A);
  static const Color obsidianCard = Color(0xFF1E293B);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // 3. Crisp White & Clean Background
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);

  // 4. Single Accent: Slate Gray
  static const Color slate = Color(0xFF64748B);
  static const Color slateLight = Color(0xFFF1F5F9);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: AppColors.surface,
          onSurface: AppColors.obsidian,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.obsidian,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.obsidian,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
}

class DateHelper {
  static const List<String> amharicWeekdays = [
    'ሰኞ', 'ማክሰኞ', 'ረቡዕ', 'ሐሙስ', 'አርብ', 'ቅዳሜ', 'እሁድ'
  ];

  static const List<String> engWeekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  static const List<String> ethiopianMonths = [
    'መስከረም', 'ጥቅምት', 'ኅዳር', 'ታኅሣሥ', 'ጥር', 'የካቲት',
    'መጋቢት', 'ሚያዝያ', 'ግንቦት', 'ሰኔ', 'ሐምሌ', 'ነሐሴ', 'ጳጉሜ'
  ];

  static const List<String> amharicMonths = [
    'ጃንዋሪ', 'ፌብሩወሪ', 'ማርች', 'ኤፕሪል', 'ሜይ', 'ጁን',
    'ጁላይ', 'ኦገስት', 'ሴፕቴምበር', 'ኦክቶበር', 'ኖቬምበር', 'ዲሴምበር'
  ];

  static const List<String> engMonths = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  /// Convert Gregorian DateTime to Ethiopian Year, Month, Day
  static Map<String, int> toEthiopianDate(DateTime dt) {
    int a = ((14 - dt.month) / 12).floor();
    int y = dt.year + 4800 - a;
    int m = dt.month + 12 * a - 3;
    int jdn = dt.day + ((153 * m + 2) / 5).floor() + 365 * y + (y / 4).floor() - (y / 100).floor() + (y / 400).floor() - 32045;

    int r = (jdn - 1723856) % 1461;
    int n = (r % 365) + 365 * (r ~/ 1460);
    int ethYear = 4 * ((jdn - 1723856) ~/ 1461) + (r ~/ 365) - (r ~/ 1460);
    int ethMonth = (n ~/ 30) + 1;
    int ethDay = (n % 30) + 1;
    return {'year': ethYear, 'month': ethMonth, 'day': ethDay};
  }

  /// Returns Ethiopian date formatted: e.g. "ነሐሴ 15, 2018 ዓ.ም"
  static String ethiopianDateFormatted([DateTime? date]) {
    final dt = date ?? DateTime.now();
    final eth = toEthiopianDate(dt);
    final monthName = ethiopianMonths[eth['month']! - 1];
    return '$monthName ${eth['day']}, ${eth['year']} ዓ.ም';
  }

  /// Returns full localized date string with Ethiopian Date + Gregorian Date:
  /// e.g. "ዓርብ፣ ነሐሴ 15, 2018 ዓ.ም (Fri, Aug 21, 2026)"
  static String todayFormatted([DateTime? date]) {
    final dt = date ?? DateTime.now();
    final amWeekday = amharicWeekdays[dt.weekday - 1];
    final engWeekday = engWeekdays[dt.weekday - 1].substring(0, 3);
    final eth = toEthiopianDate(dt);
    final ethMonthName = ethiopianMonths[eth['month']! - 1];
    final engMonth = engMonths[dt.month - 1];
    return '$amWeekday፣ $ethMonthName ${eth['day']}, ${eth['year']} ዓ.ም ($engWeekday, $engMonth ${dt.day})';
  }

  /// Returns short localized date string with Ethiopian date: e.g. "ነሐሴ 15, 2018 ዓ.ም (Aug 21)"
  static String shortDate([DateTime? date]) {
    final dt = date ?? DateTime.now();
    final eth = toEthiopianDate(dt);
    final ethMonthName = ethiopianMonths[eth['month']! - 1];
    final engMonth = engMonths[dt.month - 1];
    return '$ethMonthName ${eth['day']}, ${eth['year']} ዓ.ም ($engMonth ${dt.day})';
  }

  /// Returns date and time string
  static String formatDateTime([DateTime? date]) {
    final dt = date ?? DateTime.now();
    final eth = toEthiopianDate(dt);
    final ethMonthName = ethiopianMonths[eth['month']! - 1];
    final engMonth = engMonths[dt.month - 1];
    final hour = dt.hour;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$ethMonthName ${eth['day']}, ${eth['year']} ዓ.ም ($engMonth ${dt.day}) • $h12:$min $period';
  }

  /// Returns shift working hours
  /// Day: 2:00 in morning to 2:00 evening (08:00 AM - 08:00 PM)
  /// Night: 2:00 evening to 2:00 morning (08:00 PM - 08:00 AM)
  static String shiftOperatingHours(String shiftType) {
    final isDay = shiftType.toLowerCase().contains('day') || shiftType.contains('ቀን');
    if (isDay) {
      return '2:00 ጠዋት – 2:00 ማታ (08:00 AM – 08:00 PM)';
    } else {
      return '2:00 ማታ – 2:00 ጠዋት (08:00 PM – 08:00 AM)';
    }
  }

  static String dayShiftHours = '2:00 ጠዋት – 2:00 ማታ (08:00 AM – 08:00 PM)';
  static String nightShiftHours = '2:00 ማታ – 2:00 ጠዋት (08:00 PM – 08:00 AM)';
}

