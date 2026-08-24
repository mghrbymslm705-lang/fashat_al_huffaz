import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import 'pages/favorites/favorites_page.dart';
import 'pages/home/home_page.dart';
import 'pages/search/search_page.dart';
import 'pages/settings/settings_page.dart';
import 'pages/suggest/suggest_page.dart';
import 'providers/activity_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/settings_provider.dart';
import 'widgets/app_drawer.dart';

/// الجذر الرئيسي للتطبيق: المزودات + الإعدادات + الصفحة الأساسية.
class FashatApp extends StatelessWidget {
  const FashatApp({
    super.key,
    required this.settings,
    required this.activityProvider,
    required this.audioProvider,
  });

  final SettingsProvider settings;
  final ActivityProvider activityProvider;
  final AudioProvider audioProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<ActivityProvider>.value(value: activityProvider),
        ChangeNotifierProvider<AudioProvider>.value(value: audioProvider),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: settings.themeMode,
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localeResolutionCallback: (locale, supportedLocales) {
              return const Locale('ar');
            },
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(settings.fontScale),
                  ),
                  child: child!,
                ),
              );
            },
            home: const RootShell(),
          );
        },
      ),
    );
  }
}

/// الهيكل الأساسي: شريط تنقل سفلي أنيق مع 5 صفحات.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const int _suggestTab = 3;

  final _pages = <Widget?>[null, null, null, null];

  Widget _getPage(int index) {
    if (_pages[index] != null) return _pages[index]!;
    switch (index) {
      case 0:
        _pages[0] = HomePage(
          onOpenSuggest: () => setState(() => _index = _suggestTab),
        );
      case 1:
        _pages[1] = const SearchPage();
      case 2:
        _pages[2] = FavoritesPage(onExplore: () => setState(() => _index = 0));
      case 3:
        _pages[3] = const SuggestPage();
    }
    return _pages[index]!;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        onOpenSettings: () {
          Navigator.pop(context);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SettingsPage(
                  onOpenLibrary: () => setState(() => _index = 0)),
            ),
          );
        },
      ),
      body: Stack(
        children: [
          _getPage(_index),
          // زر القائمة الجانبية
          if (_index == 0)
            Positioned(
              top: 12,
              right: 16,
              child: SafeArea(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark.withValues(alpha: 0.95)
                        : AppColors.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppColors.divider.withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () =>
                          _scaffoldKey.currentState!.openDrawer(),
                      child: const Icon(
                        Icons.menu_rounded,
                        size: 22,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceDark.withValues(alpha: 0.95)
              : AppColors.navBackground.withValues(alpha: 0.95),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.divider.withValues(alpha: 0.5),
              width: 0.8,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  activeIcon: Icons.home_rounded,
                  label: 'الرئيسية',
                  isSelected: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
                _NavItem(
                  icon: Icons.search_rounded,
                  label: 'البحث',
                  isSelected: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),
                _NavItem(
                  icon: Icons.favorite_border_rounded,
                  activeIcon: Icons.favorite_rounded,
                  label: 'المفضلة',
                  isSelected: _index == 2,
                  onTap: () => setState(() => _index = 2),
                ),
                _NavItem(
                  icon: Icons.casino_rounded,
                  label: 'اقترح',
                  isSelected: _index == 3,
                  onTap: () => setState(() => _index = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// عنصر تنقل فردي بتصميم أنيق مع مؤشر نشط واضح.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeIcon,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppColors.primary
        : AppColors.textSecondary.withValues(alpha: 0.7);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // المؤشر العلوي
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: isSelected ? 24 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            // الأيقونة مع خلفية نشطة
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 14 : 0,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSelected ? (activeIcon ?? icon) : icon,
                size: 24,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            // التسمية
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                color: color,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}
