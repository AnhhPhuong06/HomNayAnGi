import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/geo.dart';
import '../../restaurants/models/restaurant.dart';
import '../../restaurants/widgets/restaurant_card.dart';

final mapNetworkEnabledProvider = Provider<bool>(
  (ref) => !const bool.fromEnvironment('DISABLE_MAP_NETWORK'),
);

class RestaurantMap extends ConsumerStatefulWidget {
  const RestaurantMap({
    super.key,
    required this.restaurants,
    required this.origin,
  });
  final List<Restaurant> restaurants;
  final GeoPoint origin;
  @override
  ConsumerState<RestaurantMap> createState() => _RestaurantMapState();
}

class _RestaurantMapState extends ConsumerState<RestaurantMap> {
  String? _selected;
  bool _tileError = false;
  final _controller = MapController();
  late final _tileProvider = NetworkTileProvider(
    cachingProvider: BuiltInMapCachingProvider.getOrCreateInstance(
      maxCacheSize: 100000000,
    ),
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTileError() {
    if (_tileError || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_tileError) setState(() => _tileError = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final venues = widget.restaurants.take(80).toList();
    final selected = venues.where((r) => r.id == _selected).firstOrNull;
    final network = ref.watch(mapNetworkEnabledProvider);
    final center = LatLng(widget.origin.latitude, widget.origin.longitude);
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${widget.restaurants.length} quán phù hợp · ${venues.length} điểm trên bản đồ',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Chạm ghim để xem quán. Bản đồ cần Internet; danh sách quán vẫn dùng được ngoại tuyến.',
        ),
        if (_tileError || !network)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Chưa tải được nền bản đồ. Bạn vẫn có thể chọn ghim hoặc chuyển về Danh sách.',
              style: TextStyle(color: colors.error),
            ),
          ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 380,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 13,
                    minZoom: 4,
                    maxZoom: 19,
                    backgroundColor: colors.surfaceContainerHighest,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
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
                        userAgentPackageName: 'vn.homnayangi.hom_nay_an_gi',
                        panBuffer: 0,
                        maxNativeZoom: 19,
                        tileProvider: _tileProvider,
                        errorTileCallback: (_, _, _) => _onTileError(),
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: center,
                          width: 32,
                          height: 32,
                          child: const Tooltip(
                            message: 'Tâm khu vực đã chọn',
                            child: Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                        ),
                        for (final r in venues)
                          Marker(
                            point: LatLng(r.latitude, r.longitude),
                            width: 44,
                            height: 44,
                            child: IconButton(
                              tooltip: r.name,
                              style: IconButton.styleFrom(
                                backgroundColor: selected?.id == r.id
                                    ? colors.primary
                                    : colors.surface,
                                foregroundColor: selected?.id == r.id
                                    ? colors.onPrimary
                                    : colors.primary,
                              ),
                              onPressed: () => setState(() => _selected = r.id),
                              icon: const Icon(
                                Icons.restaurant_rounded,
                                size: 21,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: null,
                        tooltip: 'Phóng to bản đồ',
                        onPressed: () => _controller.move(
                          _controller.camera.center,
                          (_controller.camera.zoom + 1).clamp(4, 19),
                        ),
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 6),
                      FloatingActionButton.small(
                        heroTag: null,
                        tooltip: 'Thu nhỏ bản đồ',
                        onPressed: () => _controller.move(
                          _controller.camera.center,
                          (_controller.camera.zoom - 1).clamp(4, 19),
                        ),
                        child: const Icon(Icons.remove),
                      ),
                      const SizedBox(height: 6),
                      FloatingActionButton.small(
                        heroTag: null,
                        tooltip: 'Về khu vực đã chọn',
                        onPressed: () => _controller.move(center, 13),
                        child: const Icon(Icons.center_focus_strong),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Material(
                    color: colors.surface,
                    child: InkWell(
                      onTap: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
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
        if (selected != null)
          RestaurantCard(restaurant: selected)
        else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Chọn biểu tượng quán trên bản đồ để xem chi tiết.'),
          ),
      ],
    );
  }
}
