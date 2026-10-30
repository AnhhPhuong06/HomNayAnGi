class FoodCategory {
  const FoodCategory(this.id, this.name, this.icon, this.keywords);
  final String id;
  final String name;
  final String icon;
  final List<String> keywords;
}

const foodCategories = [
  FoodCategory('noodles', 'Bún / Phở', '🍜', [
    'bún',
    'phở',
    'mì',
    'bun bo hue',
  ]),
  FoodCategory('rice', 'Cơm', '🍚', ['cơm', 'gạo', 'com tam']),
  FoodCategory('hotpot', 'Lẩu', '🥘', ['lẩu', 'hotpot']),
  FoodCategory('grill', 'Nướng', '🔥', ['nướng', 'bbq']),
  FoodCategory('snacks', 'Ăn vặt', '🍗', ['ăn vặt', 'gà', 'nem']),
  FoodCategory('bread', 'Bánh mì', '🥖', ['bánh mì', 'banh mi']),
  FoodCategory('healthy', 'Healthy', '🥗', ['salad', 'chay', 'rau']),
  FoodCategory('cafe', 'Cafe', '☕', ['cafe', 'cà phê', 'trà']),
  FoodCategory('dessert', 'Đồ ngọt', '🍰', ['bánh', 'chè', 'kem']),
  FoodCategory('late', 'Ăn đêm', '🌙', ['đêm', 'cháo']),
  FoodCategory('other', 'Món khác', '🍽️', ['quán ăn', 'nhà hàng']),
];

FoodCategory categoryById(String id) => foodCategories.firstWhere(
  (c) => c.id == id,
  orElse: () => FoodCategory(id, id, '🍽️', const []),
);
