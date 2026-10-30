import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/common.dart';
import '../../home/widgets/filter_sheet.dart';
import '../../restaurants/services/restaurant_queries.dart';
import '../../restaurants/widgets/restaurant_card.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});
  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(restaurantsProvider);
    final p = ref.watch(settingsProvider.select((s) => s.preference));
    final location = ref.watch(settingsProvider.select((s) => s.location));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khám phá'),
        actions: [
          IconButton(
            tooltip: 'Bộ lọc',
            onPressed: () => showFilters(context),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: ContentWidth(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Tìm món hoặc quán...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 12),
                  const DataSourceNotice(),
                ],
              ),
            ),
            Expanded(
              child: data.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, stack) => EmptyMessage(
                  title: 'Không thể tải danh sách quán.',
                  message: 'Vui lòng thử lại.',
                  action: 'Thử lại',
                  onAction: () => ref.invalidate(restaurantsProvider),
                ),
                data: (restaurants) {
                  final visible = queryRestaurants(
                    restaurants,
                    query: _query,
                    preference: p,
                    origin: location?.point,
                  );
                  if (visible.isEmpty) {
                    return EmptyMessage(
                      title: 'Chưa tìm thấy quán phù hợp.',
                      message: 'Thử từ khóa khác hoặc nới bộ lọc.',
                      action: 'Chỉnh bộ lọc',
                      onAction: () => showFilters(context),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: visible.length + 1,
                    itemBuilder: (_, i) => i == 0
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text('${visible.length} quán phù hợp'),
                          )
                        : RestaurantCard(restaurant: visible[i - 1]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
