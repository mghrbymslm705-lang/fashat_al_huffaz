import 'package:flutter/material.dart';

import '../enums/location_type.dart';
import '../enums/movement_level.dart';
import '../enums/suggest_type.dart';

/// يحوّل أسماء الأيقونات النصية (من ملفات JSON) إلى أيقونات Material فعلية.
///
/// أي اسم غير معروف يقع على أيقونة النجوم الافتراضية،
/// مما يسمح بإضافة أقسام جديدة دون تعديل الكود.
class IconResolver {
  IconResolver._();

  static const Map<String, IconData> _icons = {
    // أقسام رئيسية.
    'menu_book': Icons.menu_book_rounded,
    'mosque': Icons.mosque_rounded,
    'directions_run': Icons.directions_run_rounded,
    'psychology': Icons.psychology_rounded,
    'groups': Icons.groups_rounded,
    'emoji_events': Icons.emoji_events_rounded,
    'child_care': Icons.child_care_rounded,
    'school': Icons.school_rounded,
    'autorenew': Icons.autorenew_rounded,
    'bolt': Icons.bolt_rounded,
    // أدوات واجهة.
    'favorite': Icons.favorite_rounded,
    'favorite_border': Icons.favorite_border_rounded,
    'search': Icons.search_rounded,
    'settings': Icons.settings_rounded,
    'casino': Icons.casino_rounded,
    'filter': Icons.filter_list_rounded,
    'bookmark': Icons.bookmark_rounded,
    'movie': Icons.play_circle_rounded,
    'watch': Icons.timer_rounded,
    'people': Icons.people_rounded,
    'calendar': Icons.calendar_today_rounded,
    'place': Icons.place_rounded,
    'flag': Icons.flag_rounded,
    'celebration': Icons.celebration_rounded,
    'tune': Icons.tune_rounded,
    'meeting_room': Icons.meeting_room_rounded,
    'park': Icons.park_rounded,
    'public': Icons.public_rounded,
    'self_improvement': Icons.self_improvement_rounded,
    'shuffle': Icons.shuffle_rounded,
    'light_mode': Icons.light_mode_rounded,
    'dark_mode': Icons.dark_mode_rounded,
    'brightness_auto': Icons.brightness_auto_rounded,
    'privacy': Icons.privacy_tip_rounded,
    'info': Icons.info_rounded,
    'contact': Icons.mail_rounded,
    'download': Icons.download_rounded,
    'upload': Icons.upload_file_rounded,
    'folder': Icons.folder_rounded,
    'text': Icons.text_fields_rounded,
    'star': Icons.star_rounded,
    'home': Icons.home_rounded,
    'warning': Icons.warning_amber_rounded,
  };

  /// أيقونة افتراضية لأي اسم غير معروف.
  static const IconData fallback = Icons.star_rounded;

  static IconData resolve(String? name) {
    if (name == null || name.trim().isEmpty) return fallback;
    return _icons[name.trim()] ?? fallback;
  }

  static IconData forMovement(MovementLevel movement) =>
      resolve(movement.icon);

  static IconData forLocation(LocationType location) =>
      resolve(location.icon);

  static IconData forType(SuggestType type) => resolve(type.icon);
}
