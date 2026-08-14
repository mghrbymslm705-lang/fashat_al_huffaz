import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import 'pages/favorites/favorites_page.dart';
import 'pages/home/home_page.dart';
import 'pages/search/search_page.dart';
import 'pages/settings/settings_page.dart';
import 'pages/suggest/suggest_page.dart';
import 'providers/activity_provider.dart';
import 'providers/settings_provider.dart';

/// الجذر الرئيسي للتطبيق: المزودات + الإعدادات + الصفحة الأساسية.
class FashatApp extends StatelessWidget {
  const FashatApp({
    super.key,
    required this.settings,
    required this.activityProvider,
  });

  final SettingsProvider settings;
  final ActivityProvider activityProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<ActivityProvider>.value(value: activityProvider),
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
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // تكبير/تصغير الخط وفق الإعدادات.
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(settings.fontScale),
                ),
                child: child!,
              );
            },
            home: const RootShell(),
          );
        },
      ),
    );
  }
}

/// الهيكل الأساسي: شريط تنقل سفلي مع 5 صفحات.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const int _suggestTab = 3;

  @override
  void initState() {
    super.initState();
    // تحميل المحتوى مرة واحدة عند الإقلاع.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(
        onOpenSuggest: () => setState(() => _index = _suggestTab),
      ),
      const SearchPage(),
      FavoritesPage(onExplore: () => setState(() => _index = 0)),
      const SuggestPage(),
      SettingsPage(onOpenLibrary: () => setState(() => _index = 0)),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: 'البحث',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'المفضلة',
          ),
          NavigationDestination(
            icon: Icon(Icons.casino_rounded),
            label: 'اقترح نشاطًا',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}
