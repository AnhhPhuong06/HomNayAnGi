import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/geo.dart';
import '../discover/widgets/restaurant_map.dart';

Future<GeoPoint?> pickPublicPlace(
  BuildContext context, {
  GeoPoint? selected,
  GeoPoint? center,
}) => showDialog<GeoPoint>(
  context: context,
  builder: (_) => _PlacePicker(selected: selected, center: center),
);

class _PlacePicker extends ConsumerStatefulWidget {
  const _PlacePicker({this.selected, this.center});
  final GeoPoint? selected, center;
  @override
  ConsumerState<_PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends ConsumerState<_PlacePicker> {
  late GeoPoint? _selected = widget.selected;
  final _controller = MapController();
  bool _failed = false;
  late final _tiles = NetworkTileProvider(
    cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
      maxCacheSize: 100000000,
    ),
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final network = ref.watch(mapNetworkEnabledProvider);
    final origin =
        widget.selected ?? widget.center ?? const GeoPoint(16.0544, 108.2022);
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: MediaQuery.sizeOf(context).height * .9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ghim địa điểm muốn chia sẻ',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Chạm đúng vị trí quán. Ghim này sẽ công khai với các thành viên khi bạn đăng bài.',
              ),
              if (!network || _failed)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Chưa tải được nền. Có thể đóng bản đồ và nhập tọa độ quán trực tiếp.',
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                height: math.min(
                  340,
                  math.max(180, MediaQuery.sizeOf(context).height * .4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _controller,
                        options: MapOptions(
                          initialCenter: LatLng(
                            origin.latitude,
                            origin.longitude,
                          ),
                          initialZoom: 15,
                          minZoom: 4,
                          maxZoom: 19,
                          onTap: (_, point) => setState(
                            () => _selected = GeoPoint(
                              point.latitude,
                              point.longitude,
                            ),
                          ),
                          interactionOptions: const InteractionOptions(
                            flags:
                                InteractiveFlag.all & ~InteractiveFlag.rotate,
                          ),
                        ),
                        children: [
                          if (network)
                            TileLayer(
                              urlTemplate: const String.fromEnvironment(
                                'MAP_TILE_URL',
                                defaultValue:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              ),
                              userAgentPackageName:
                                  'vn.homnayangi.hom_nay_an_gi',
                              panBuffer: 0,
                              tileProvider: _tiles,
                              errorTileCallback: (_, _, _) {
                                if (mounted && !_failed) {
                                  setState(() => _failed = true);
                                }
                              },
                            ),
                          if (_selected case final point?)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    point.latitude,
                                    point.longitude,
                                  ),
                                  width: 48,
                                  height: 48,
                                  child: Icon(
                                    Icons.location_pin,
                                    size: 46,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Column(
                          children: [
                            IconButton.filledTonal(
                              tooltip: 'Phóng to',
                              onPressed: () => _controller.move(
                                _controller.camera.center,
                                (_controller.camera.zoom + 1).clamp(4, 19),
                              ),
                              icon: const Icon(Icons.add),
                            ),
                            const SizedBox(height: 8),
                            IconButton.filledTonal(
                              tooltip: 'Thu nhỏ',
                              onPressed: () => _controller.move(
                                _controller.camera.center,
                                (_controller.camera.zoom - 1).clamp(4, 19),
                              ),
                              icon: const Icon(Icons.remove),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: Theme.of(context).colorScheme.surface,
                          child: InkWell(
                            onTap: () => launchUrl(
                              Uri.parse(
                                'https://www.openstreetmap.org/copyright',
                              ),
                              mode: LaunchMode.externalApplication,
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Text(
                                '© OpenStreetMap contributors',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _selected == null
                    ? 'Chưa chọn ghim.'
                    : '${_selected!.latitude.toStringAsFixed(6)}, ${_selected!.longitude.toStringAsFixed(6)}',
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),
                  FilledButton(
                    onPressed: _selected == null
                        ? null
                        : () => Navigator.pop(context, _selected),
                    child: const Text('Dùng vị trí quán này'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
