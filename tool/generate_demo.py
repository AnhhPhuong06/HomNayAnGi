"""Regenerate explicitly fictional fixtures. No real venue data is represented."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
foods = [
    ('Phở bò', 'noodles', 35000, 55000, ['breakfast', 'lunch'], 'noodles'),
    ('Cơm tấm', 'rice', 30000, 50000, ['lunch', 'dinner'], 'rice'),
    ('Bún bò Huế', 'noodles', 40000, 60000, ['breakfast', 'lunch', 'dinner'], 'noodles'),
    ('Lẩu nấm', 'hotpot', 120000, 190000, ['dinner'], 'hotpot'),
    ('Thịt nướng', 'grill', 150000, 250000, ['dinner'], 'grill'),
    ('Bánh mì trứng', 'bread', 20000, 28000, ['breakfast', 'lunch'], 'bread'),
    ('Salad rau củ', 'healthy', 45000, 75000, ['lunch', 'dinner'], 'salad'),
    ('Gà giòn', 'snacks', 25000, 45000, ['lunch', 'dinner'], 'grill'),
    ('Cà phê sữa', 'cafe', 25000, 45000, ['breakfast', 'lunch', 'dinner'], 'cafe'),
    ('Chè đậu', 'dessert', 15000, 25000, ['lunch', 'dinner'], 'dessert'),
    ('Cháo sườn', 'late', 25000, 40000, ['breakfast', 'late'], 'rice'),
    ('Cơm chay', 'healthy', 30000, 50000, ['lunch', 'dinner'], 'salad'),
]
# Labels describe demo clusters, not an authoritative administrative directory.
clusters = [
    ('Bắc Ninh', 'Khu vực Bắc Ninh (demo)', 21.183, 106.072, 12),
    ('Hà Nội', 'Khu vực Hoàn Kiếm (demo)', 21.0285, 105.854, 4),
    ('Đà Nẵng', 'Khu vực Hải Châu (demo)', 16.060, 108.220, 4),
    ('TP. Hồ Chí Minh', 'Khu vực trung tâm (demo)', 10.776, 106.700, 4),
]
venues = []
for province, area, lat, lon, count in clusters:
    for i in range(count):
        food, category, low, high, meals, image = foods[(i + len(venues) // 12) % len(foods)]
        index = len(venues) + 1
        venues.append(dict(
            id=f'demo-{index:02}', name=f'{food} · Bếp Demo {index:02}', dishName=food,
            description=f'Không gian minh họa cho món {food.lower()}. Tên quán, giá, đánh giá và địa chỉ đều là dữ liệu giả lập để kiểm thử ứng dụng.',
            imageUrl=f'assets/images/{image}.jpg', country='VN',
            latitude=round(lat + ((i % 4) - 1.5) * .004, 6),
            longitude=round(lon + ((i // 4) - 1) * .004, 6),
            address=f'Địa chỉ minh họa số {index} · Không phải quán thật',
            province=province, area=area, categories=[category],
            tags=[food, 'Món Việt', 'Minh họa'],
            priceMin=low if index != 8 else None, priceMax=high if index != 8 else None,
            rating=round(3.8 + (index % 7) * .15, 1) if index != 5 else None,
            reviewCount=20 + index * 9 if index != 5 else None,
            openingHours='07:00–21:00 (giả lập)' if index % 3 == 0 else None,
            phone=None, mapUrl=None, mealTimes=meals,
            companions=['alone', 'partner'] if category in ['bread', 'rice', 'cafe'] else ['friends', 'family', 'partner'],
        ))
(root / 'assets/data').mkdir(parents=True, exist_ok=True)
(root / 'assets/data/restaurants.json').write_text(json.dumps(venues, ensure_ascii=False, indent=2), encoding='utf-8')
print(f'Wrote {len(venues)} DEMO restaurants')
