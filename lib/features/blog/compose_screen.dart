import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers.dart';
import '../../core/widgets/common.dart';
import '../../core/utils/geo.dart';
import '../auth/auth_repository.dart';
import '../auth/account_action_lock.dart';
import '../restaurants/models/food_category.dart';
import '../restaurants/models/restaurant.dart';
import '../restaurants/widgets/restaurant_card.dart';
import 'blog_repository.dart';
import 'place_picker.dart';

class ComposeScreen extends ConsumerStatefulWidget {
  const ComposeScreen({super.key, required this.kind, this.restaurantId});
  final PostKind kind;
  final String? restaurantId;
  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  final _title = TextEditingController(),
      _body = TextEditingController(),
      _venue = TextEditingController(),
      _area = TextEditingController(),
      _latitude = TextEditingController(),
      _longitude = TextEditingController();
  late PostKind _kind = widget.kind;
  String _category = 'noodles';
  Restaurant? _restaurant;
  bool _accepted = false, _busy = false, _seeded = false, _uncertain = false;
  String? _error;
  @override
  void dispose() {
    for (final c in [_title, _body, _venue, _area, _latitude, _longitude]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _publish() async {
    if (_busy || _uncertain) return;
    final author = ref.read(memberProvider).asData?.value;
    if (author == null) {
      context.go('/login');
      return;
    }
    final draft = PostDraft(
      kind: _kind,
      title: _title.text,
      body: _body.text,
      category: _category,
      restaurantId: _kind == PostKind.place ? '' : _restaurant?.id ?? '',
      restaurantName: _venue.text,
      area: _area.text,
      place: _kind == PostKind.place
          ? GeoPoint(
              double.tryParse(_latitude.text.trim()) ?? double.nan,
              double.tryParse(_longitude.text.trim()) ?? double.nan,
            )
          : null,
    );
    final error =
        draft.validationError ??
        (!_accepted ? 'Hãy đồng ý quy tắc chia sẻ trước khi đăng.' : null);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final lock = ref.read(accountActionLockProvider.notifier);
    if (!lock.begin()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(blogRepositoryProvider).publish(author, draft);
      if (mounted && ref.read(memberProvider).asData?.value?.id == author.id) {
        context.go('/blog');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã chia sẻ bài viết.')));
      }
    } on PendingPublication {
      if (mounted) {
        setState(() {
          _uncertain = true;
          _error =
              'Máy chủ chưa xác nhận. Bài có thể đang chờ đồng bộ; hãy kiểm tra blog trước khi viết lại để tránh đăng trùng.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Chưa đăng được bài. Hãy kiểm tra kết nối và thử lại.',
        );
      }
    } finally {
      lock.release();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(restaurantsProvider).asData?.value;
    if (!_seeded && catalog != null) {
      _seeded = true;
      _restaurant = catalog
          .where((r) => r.id == widget.restaurantId)
          .firstOrNull;
      if (_restaurant case final r?) {
        _venue.text = r.name;
        _area.text = '${r.area}, ${r.province}';
        _category = r.categories.firstOrNull ?? 'other';
        _title.text = _kind == PostKind.meal
            ? 'Hôm nay mình chọn ${r.dishName}'
            : 'Quán ngon: ${r.name}';
      }
    }
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Quay lại',
            icon: const Icon(Icons.arrow_back),
            onPressed: _busy
                ? null
                : () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/blog');
                    }
                  },
          ),
          title: Text(
            _kind == PostKind.place ? 'Thêm địa điểm mới' : 'Viết bài chia sẻ',
          ),
        ),
        body: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final kind in PostKind.values)
                    ChoiceChip(
                      label: Text(kind.label),
                      selected: _kind == kind,
                      onSelected: _busy
                          ? null
                          : (_) => setState(() => _kind = kind),
                    ),
                ],
              ),
              if (_kind == PostKind.place)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Giới thiệu địa điểm bạn đã biết. Tên quán, địa chỉ và ghim sẽ hiển thị trong Blog và mục Cộng đồng của Khám phá. Thông tin do thành viên cung cấp, chưa được xác minh.',
                  ),
                ),
              const SizedBox(height: 20),
              if (_kind != PostKind.place && _restaurant?.photo != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FoodImage(restaurant: _restaurant!, height: 170),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true,
                itemHeight: null,
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Kiểu món'),
                items: [
                  for (final c in foodCategories)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        '${c.icon} ${c.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _busy ? null : (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _title,
                enabled: !_busy,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Tiêu đề'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _body,
                enabled: !_busy,
                minLines: 5,
                maxLines: 12,
                maxLength: 3000,
                decoration: InputDecoration(
                  labelText: 'Câu chuyện của bạn',
                  hintText: _kind == PostKind.meal
                      ? 'Bạn ăn món gì? Điều gì làm bữa ăn này đáng nhớ?'
                      : 'Món nên thử, trải nghiệm, giá bạn đã trả và thời điểm ghé quán…',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _venue,
                enabled:
                    !_busy && (_restaurant == null || _kind == PostKind.place),
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: _kind != PostKind.meal
                      ? 'Tên quán *'
                      : 'Tên quán (tùy chọn)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _area,
                enabled:
                    !_busy && (_restaurant == null || _kind == PostKind.place),
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Khu vực / địa chỉ',
                ),
              ),
              if (_restaurant != null && _kind != PostKind.place)
                const Text('Quán được đính kèm từ danh mục trong ứng dụng.'),
              if (_kind == PostKind.place) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Chọn vị trí quán trên bản đồ'),
                  onPressed: _busy
                      ? null
                      : () async {
                          final latitude = double.tryParse(
                            _latitude.text.trim(),
                          );
                          final longitude = double.tryParse(
                            _longitude.text.trim(),
                          );
                          final candidate =
                              latitude != null && longitude != null
                              ? GeoPoint(latitude, longitude)
                              : null;
                          final point = await pickPublicPlace(
                            context,
                            selected: candidate?.isValid == true
                                ? candidate
                                : null,
                            center: ref.read(settingsProvider).location?.point,
                          );
                          if (!mounted || point == null) return;
                          setState(() {
                            _latitude.text = point.latitude.toStringAsFixed(6);
                            _longitude.text = point.longitude.toStringAsFixed(
                              6,
                            );
                          });
                        },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _latitude,
                  enabled: !_busy,
                  maxLength: 20,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Vĩ độ quán (công khai)',
                    hintText: 'Ví dụ: 10.777340',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _longitude,
                  enabled: !_busy,
                  maxLength: 20,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Kinh độ quán (công khai)',
                    hintText: 'Ví dụ: 106.700248',
                  ),
                ),
                const Text(
                  'Chỉ ghim vị trí địa điểm muốn giới thiệu. Ứng dụng không tự điền hay đăng GPS của bạn.',
                ),
              ],
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _accepted,
                onChanged: _busy ? null : (v) => setState(() => _accepted = v!),
                title: const Text(
                  'Tôi chia sẻ trải nghiệm trung thực, không đăng nội dung xúc phạm, quảng cáo rác hoặc thông tin riêng tư của người khác.',
                ),
                subtitle: const Text(
                  'Bài viết, tên hiển thị và ghim địa điểm (nếu có) được chia sẻ với các thành viên. Bạn có thể xóa bài của mình.',
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              FilledButton.icon(
                onPressed:
                    _busy || _uncertain || ref.watch(accountActionLockProvider)
                    ? null
                    : _publish,
                icon: const Icon(Icons.send_outlined),
                label: Text(
                  _busy
                      ? 'Đang gửi, hãy giữ kết nối…'
                      : _kind == PostKind.place
                      ? 'Chia sẻ địa điểm'
                      : 'Đăng bài lên blog',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
