class AppStrings {
  static const appName = 'Library+';
  static const portalName = 'SLIIT QUICK BOOK';
  static const searchBooksHint = 'Search by title, author, ISBN…';
  static const seatSearchHint = 'Filter by floor or section…';
}

@Deprecated('Use AppSpacing from app_theme.dart')
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
}

/// Minimum tap target per accessibility guidance.
class AppTouchTarget {
  static const minSize = 48.0;
}

/// Extra bottom inset so scroll content clears the navigation bar.
class AppNavInset {
  static const bottom = 96.0;
}

/// Library policy numbers shared by countdowns and reminders. The server
/// enforces the real values; these only drive on-screen timers.
class AppPolicy {
  static const checkInGraceMinutes = 15;
  static const seatReminderLeadMinutes = 30;
  static const pickupReminderLeadHours = 2;
  static const loanReminderLeadDays = 2;
}
