
import 'package:flutter/material.dart';

import '../../core/theme/fajr_theme.dart';
import '../adhkar/adhkar_screen.dart';
import '../prayer/city_presets.dart';
import '../prayer/prayer_times_screen.dart';

/// Main navigation hub shown after startup.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.isLocalMode,
  });

  final bool isLocalMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FajrTheme.navyDeep,
      appBar: AppBar(
        title: const Text('فَجْر'),
        actions: [
          if (isLocalMode)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Chip(
                backgroundColor: FajrTheme.gold,
                label: Text(
                  'الوضع المحلي',
                  style: TextStyle(
                    fontSize: 11,
                    color: FajrTheme.navyDeep,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            icon: Icons.access_time,
            title: 'أوقات الصلاة',
            subtitle: 'حساب محلي على جهازك — اختر مدينتك',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PrayerTimesScreen(
                    onCitySelected: _onCitySelected,
                  ),
                ),
              );
            },
          ),
          _SectionCard(
            icon: Icons.menu_book,
            title: 'أذكار الصباح',
            subtitle: 'أذكار تعمل بدون إنترنت',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AdhkarScreen(),
                ),
              );
            },
          ),
          _SectionCard(
            icon: Icons.groups,
            title: 'الفرق',
            subtitle: isLocalMode
                ? 'يتطلب ربط Firebase'
                : 'الميزة الاجتماعية قيد التطوير',
            enabled: false,
            onTap: () {},
          ),
          _SectionCard(
            icon: Icons.person_search,
            title: 'رفيق الفجر',
            subtitle: isLocalMode
                ? 'يتطلب ربط Firebase'
                : 'الميزة قيد التطوير',
            enabled: false,
            onTap: () {},
          ),
          const SizedBox(height: 24),
          Text(
            isLocalMode
                ? 'يعمل فَجْر حاليًا في الوضع المحلي. '
                    'أوقات الصلاة والأذكار متاحة، '
                    'أما الميزات الاجتماعية فتحتاج إلى إعداد Firebase.'
                : 'مرحبًا بك في فَجْر.',
            style: FajrTheme.label,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static void _onCitySelected(CityPreset city) {
    // The selected city is saved by PrayerTimesScreen.
    // The app shell can consume this callback in a later integration.
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color: enabled ? FajrTheme.gold : Colors.white30,
        ),
        title: Text(
          title,
          style: FajrTheme.headline.copyWith(
            fontSize: 18,
            color: enabled ? Colors.white : Colors.white38,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: FajrTheme.label,
        ),
        trailing: enabled
            ? const Icon(
                Icons.chevron_left,
                color: Colors.white54,
              )
            : null,
        onTap: enabled ? onTap : null,
      ),
    );
  }
}
