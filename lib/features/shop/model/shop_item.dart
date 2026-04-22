enum ShopItemSlot {
  head,
  mouth,
}

class ShopItem {
  const ShopItem({
    required this.name,
    required this.imagePath,
    required this.price,
    this.slot = ShopItemSlot.head,
  });

  final String name;
  final String imagePath;
  final int price;
  final ShopItemSlot slot;
}
