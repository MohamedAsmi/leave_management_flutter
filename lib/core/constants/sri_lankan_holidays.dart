// Sri Lankan Mercantile Holidays 2026
// Source: Based on typical Sri Lankan public and mercantile holidays

class SriLankanHolidays {
  static final Map<DateTime, String> holidays2026 = {
    // January
    DateTime(2026, 1, 1): "New Year's Day",
    DateTime(2026, 1, 15): "Thai Pongal",
    
    // February
    DateTime(2026, 2, 4): "Independence Day",
    DateTime(2026, 2, 16): "Maha Shivarathri Day",
    
    // March
    DateTime(2026, 3, 12): "Meelad-un-Nabi (Holy Prophet's Birthday)",
    
    // April
    DateTime(2026, 4, 2): "Ramadan Festival Day",
    DateTime(2026, 4, 13): "Day prior to Sinhala & Tamil New Year",
    DateTime(2026, 4, 14): "Sinhala & Tamil New Year Day",
    DateTime(2026, 4, 15): "Day following Sinhala & Tamil New Year",
    
    // May
    DateTime(2026, 5, 1): "May Day",
    DateTime(2026, 5, 5): "Vesak Full Moon Poya Day",
    DateTime(2026, 5, 6): "Day following Vesak Full Moon Poya Day",
    
    // June
    DateTime(2026, 6, 3): "Poson Full Moon Poya Day",
    DateTime(2026, 6, 9): "Hadj Festival Day",
    
    // July
    DateTime(2026, 7, 3): "Esala Full Moon Poya Day",
    
    // August
    DateTime(2026, 8, 1): "Nikini Full Moon Poya Day",
    
    // September
    
    // October
    DateTime(2026, 10, 20): "Deepavali Festival Day",
    DateTime(2026, 10, 29): "Ill Full Moon Poya Day",
    
    // November
    
    // December
    DateTime(2026, 12, 25): "Christmas Day",
    DateTime(2026, 12, 28): "Unduvap Full Moon Poya Day",
  };

  static final Map<DateTime, String> holidays2025 = {
    // January
    DateTime(2025, 1, 1): "New Year's Day",
    DateTime(2025, 1, 14): "Thai Pongal",
    DateTime(2025, 1, 13): "Duruthu Full Moon Poya Day",
    
    // February
    DateTime(2025, 2, 4): "Independence Day",
    DateTime(2025, 2, 12): "Navam Full Moon Poya Day",
    DateTime(2025, 2, 26): "Maha Shivarathri Day",
    
    // March
    DateTime(2025, 3, 1): "Meelad-un-Nabi (Holy Prophet's Birthday)",
    DateTime(2025, 3, 14): "Madin Full Moon Poya Day",
    DateTime(2025, 3, 31): "Ramadan Festival Day",
    
    // April
    DateTime(2025, 4, 13): "Day prior to Sinhala & Tamil New Year",
    DateTime(2025, 4, 14): "Sinhala & Tamil New Year Day",
    DateTime(2025, 4, 12): "Bak Full Moon Poya Day",
    
    // May
    DateTime(2025, 5, 1): "May Day",
    DateTime(2025, 5, 12): "Vesak Full Moon Poya Day",
    DateTime(2025, 5, 13): "Day following Vesak Full Moon Poya Day",
    
    // June
    DateTime(2025, 6, 7): "Hadj Festival Day",
    DateTime(2025, 6, 10): "Poson Full Moon Poya Day",
    
    // July
    DateTime(2025, 7, 10): "Esala Full Moon Poya Day",
    
    // August
    DateTime(2025, 8, 8): "Nikini Full Moon Poya Day",
    
    // September
    DateTime(2025, 9, 7): "Binara Full Moon Poya Day",
    
    // October
    DateTime(2025, 10, 6): "Vap Full Moon Poya Day",
    DateTime(2025, 10, 21): "Deepavali Festival Day",
    
    // November
    DateTime(2025, 11, 5): "Ill Full Moon Poya Day",
    
    // December
    DateTime(2025, 12, 4): "Unduvap Full Moon Poya Day",
    DateTime(2025, 12, 25): "Christmas Day",
  };

  static bool isHoliday(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    if (date.year == 2025) {
      return holidays2025.containsKey(normalizedDate);
    } else if (date.year == 2026) {
      return holidays2026.containsKey(normalizedDate);
    }
    
    return false;
  }

  static String? getHolidayName(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    if (date.year == 2025) {
      return holidays2025[normalizedDate];
    } else if (date.year == 2026) {
      return holidays2026[normalizedDate];
    }
    
    return null;
  }

  static bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }
}
