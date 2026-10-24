
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/errors.dart';
import '../../core/theme/fajr_theme.dart';
import 'city_presets.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({
    super.key,
    required this.onCitySelected,
  });

  final void Function(CityPreset city) onCitySelected;

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  CityPreset? _city;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadSavedCity();
  }

  Future<void> _loadSavedCity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('selected_city');

      if (!mounted) return;

      final savedCity = name == null
          ? null
          : kCities.where((city) => city.name == name).firstOrNull;

      setState(() {
        _city = savedCity;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'تعذّر تحميل المدينة المحفوظة. اختر مدينتك من جديد.';
      });
    }
  }

  Future<void> _pickCity() async {
    final picked = await showModalBottomSheet<CityPreset>(
      context: context,
      backgroundColor: FajrTheme.navyCard,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'اختر مدينتك',
                style: FajrTheme.headline,
                textAlign: TextAlign.center,
              ),
            ),
            for (final city in kCities)
              ListTile(
                title: Text(
                  city.name,
                  style: FajrTheme.body,
                ),
                onTap: () => Navigator.of(sheetContext).pop(city),
              ),
          ],
        ),
      ),
    );

    if (picked == null || !mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_city', picked.name);

      if (!mounted) return;

      setState(() {
        _city = picked;
        _loadError = null;
      });

      widget.onCitySelected(picked);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadError = 'تعذّر حفظ المدينة. حاول مرة أخرى.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FajrTheme.navyDeep,
      appBar: AppBar(
        title: const Text('أوقات الصلاة'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _city == null
              ? _buildCityPrompt()
              : _buildTimes(_city!),
    );
  }

  Widget _buildCityPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_city,
              size: 48,
              color: FajrTheme.gold,
            ),
            const SizedBox(height: 16),
            const Text(
              'اختر مدينتك لحساب أوقات الصلاة',
              style: FajrTheme.headline,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'الحساب يتم على جهازك بدون إنترنت، '
              'ولا نحتاج إلى جمع موقعك.',
              style: FajrTheme.label,
              textAlign: TextAlign.center,
            ),
            if (_loadError != null) ...[
              const SizedBox(height: 12),
              Text(
                _loadError!,
                style: FajrTheme.label,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _pickCity,
              child: const Text('اختيار المدينة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimes(CityPreset city) {
    final PrayerTimes times;

    try {
      final coordinates = Coordinates(
        city.latitude,
        city.longitude,
      );

      final parameters =
          CalculationMethod.muslim_world_league.getParameters();

      times = PrayerTimes.today(coordinates, parameters);
    } catch (_) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ErrorMapper.userMessage(
                  const AppError(ErrorCode.invalidPrayerTime),
                ),
                style: FajrTheme.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _pickCity,
                child: const Text('اختيار مدينة أخرى'),
              ),
            ],
          ),
        ),
      );
    }

    final rows = <(String, DateTime)>[
      ('الفجر', times.fajr),
      ('الشروق', times.sunrise),
      ('الظهر', times.dhuhr),
      ('العصر', times.asr),
      ('المغرب', times.maghrib),
      ('العشاء', times.isha),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    city.name,
                    style: FajrTheme.headline,
                  ),
                ),
                TextButton(
                  onPressed: _pickCity,
                  child: const Text('تغيير'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final (name, time) in rows)
          Card(
            child: ListTile(
              title: Text(
                name,
                style: FajrTheme.headline,
              ),
              trailing: Text(
                _format(time),
                style: TextStyle(
                  color: name == 'الفجر'
                      ? FajrTheme.gold
                      : Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          'طريقة الحساب: رابطة العالم الإسلامي. '
          'قد تختلف الأوقات قليلًا عن الجداول المحلية المعتمدة.',
          style: FajrTheme.label,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _format(DateTime time) {
    final hour = time.hour;
    final period = hour >= 12 ? 'م' : 'ص';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour12:$minute $period';
  }
}
