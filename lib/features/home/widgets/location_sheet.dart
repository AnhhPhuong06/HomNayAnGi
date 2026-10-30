import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/providers.dart';
import '../../../core/services/local_store.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/geo.dart';

Future<void> showLocationPicker(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const LocationSheet(),
    );

class LocationSheet extends ConsumerStatefulWidget {
  const LocationSheet({super.key});
  @override
  ConsumerState<LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends ConsumerState<LocationSheet> {
  bool _busy = false;
  LocationFailure? _failure;
  final _name = TextEditingController();
  final _lat = TextEditingController();
  final _lon = TextEditingController();
  final _form = GlobalKey<FormState>();
  String? _province;
  String _areaQuery = '';
  @override
  void dispose() {
    _name.dispose();
    _lat.dispose();
    _lon.dispose();
    super.dispose();
  }

  Future<void> _gps() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final point = await ref.read(locationServiceProvider).current();
      if (!mounted) return;
      await ref
          .read(settingsProvider.notifier)
          .setLocation(SavedLocation('Vị trí hiện tại', point, isGps: true));
      if (mounted) Navigator.pop(context);
    } on LocationFailure catch (e) {
      if (mounted) setState(() => _failure = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _select(String label, GeoPoint point) async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref
        .read(settingsProvider.notifier)
        .setLocation(SavedLocation(label, point));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(restaurantsProvider);
    final restaurants = data.asData?.value ?? [];
    final provinces = restaurants.map((r) => r.province).toSet().toList()
      ..sort();
    final areas =
        restaurants
            .where((r) => r.province == _province)
            .map((r) => r.area)
            .toSet()
            .toList()
          ..sort();
    final matchedAreas = areas
        .where(
          (area) => normalizeSearch(area).contains(normalizeSearch(_areaQuery)),
        )
        .toList();
    final visibleAreas = matchedAreas.take(50).toList();
    return FractionallySizedBox(
      heightFactor: .9,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Bạn muốn ăn ở đâu?',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng chọn khu vực',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Vị trí được dùng để tìm quán phù hợp gần bạn. Không theo dõi nền; GPS không được lưu sau khi đóng app.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _gps,
                icon: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(_busy ? 'Đang lấy vị trí…' : 'Dùng vị trí của tôi'),
              ),
            ),
            if (_failure != null) ...[
              const SizedBox(height: 12),
              Text(
                _failure!.message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              if (_failure!.issue == LocationIssue.deniedForever ||
                  _failure!.issue == LocationIssue.disabled)
                TextButton(
                  onPressed: () async {
                    final success = _failure!.issue == LocationIssue.disabled
                        ? await Geolocator.openLocationSettings()
                        : await Geolocator.openAppSettings();
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Không mở được cài đặt thiết bị.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Mở cài đặt thiết bị'),
                ),
            ],
            const SizedBox(height: 24),
            Text(
              'Chọn khu vực thủ công',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Việt Nam · Các khu vực có dữ liệu trong nguồn hiện tại. Khoảng cách tính từ tâm các địa điểm của khu vực.',
            ),
            const SizedBox(height: 12),
            if (data.isLoading) const LinearProgressIndicator(),
            if (data.hasError)
              TextButton(
                onPressed: () => ref.invalidate(restaurantsProvider),
                child: const Text('Tải lại danh sách khu vực'),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final p in provinces)
                  ChoiceChip(
                    label: Text(p),
                    selected: _province == p,
                    onSelected: _busy
                        ? null
                        : (_) => setState(() {
                            _province = p;
                            _areaQuery = '';
                          }),
                  ),
              ],
            ),
            if (areas.length > 20) ...[
              const SizedBox(height: 12),
              TextField(
                key: ValueKey(_province),
                decoration: const InputDecoration(
                  labelText: 'Tìm khu vực',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (query) => setState(() => _areaQuery = query),
              ),
              if (matchedAreas.length > visibleAreas.length)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Đang hiển thị ${visibleAreas.length}/${matchedAreas.length} khu vực. Nhập tên để tìm nhanh.',
                  ),
                ),
            ],
            for (final area in visibleAreas)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_outlined),
                title: Text(area),
                subtitle: Text(_province!),
                trailing: const Icon(Icons.chevron_right),
                onTap: _busy
                    ? null
                    : () {
                        final points = restaurants
                            .where(
                              (r) => r.area == area && r.province == _province,
                            )
                            .map((r) => r.location)
                            .toList();
                        _select(
                          '$area, $_province',
                          GeoPoint(
                            points.fold(0.0, (sum, p) => sum + p.latitude) /
                                points.length,
                            points.fold(0.0, (sum, p) => sum + p.longitude) /
                                points.length,
                          ),
                        );
                      },
              ),
            const Divider(height: 32),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Khu vực khác tại Việt Nam'),
              subtitle: const Text('Nhập tên và tọa độ tâm khu vực'),
              children: [
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Tên khu vực',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Nhập tên khu vực'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _lat,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Vĩ độ (latitude)',
                        ),
                        validator: (v) {
                          final n = double.tryParse(
                            v?.replaceAll(',', '.') ?? '',
                          );
                          return n == null || !n.isFinite || n < -90 || n > 90
                              ? 'Nhập vĩ độ trong khoảng -90–90'
                              : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _lon,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Kinh độ (longitude)',
                        ),
                        validator: (v) {
                          final n = double.tryParse(
                            v?.replaceAll(',', '.') ?? '',
                          );
                          return n == null || !n.isFinite || n < -180 || n > 180
                              ? 'Nhập kinh độ trong khoảng -180–180'
                              : null;
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () {
                                if (_form.currentState!.validate()) {
                                  _select(
                                    _name.text.trim(),
                                    GeoPoint(
                                      double.parse(
                                        _lat.text.replaceAll(',', '.'),
                                      ),
                                      double.parse(
                                        _lon.text.replaceAll(',', '.'),
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: const Text('Dùng khu vực này'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
