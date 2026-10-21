class AppRoutes {
  static const String login = '/login';
  static const String home = '/';
  static const String announcement = '/pengumuman/:id';

  static String announcementDetail(String id) => '/pengumuman/$id';
}

/// Pure function to extract and normalize destination route from notification data payload.
/// Designed for unit testing without Firebase dependency.
String routeFromMessage(Map<String, dynamic> data) {
  final dynamic rawRoute = data['route'];
  if (rawRoute == null || rawRoute is! String || rawRoute.trim().isEmpty) {
    return AppRoutes.home;
  }

  final trimmed = rawRoute.trim();
  if (trimmed.startsWith('/')) {
    return trimmed;
  }
  return '/$trimmed';
}
