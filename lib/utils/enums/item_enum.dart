enum ItemCategory {
  pgb,
  dsbpgb,
  bmcpgb,

}

extension ItemCategoryX on ItemCategory {
  String get label {
    switch (this) {
      case ItemCategory.pgb:
        return 'PGB Stocks';
      case ItemCategory.dsbpgb:
        return 'DSB-PGB Stocks';
      case ItemCategory.bmcpgb:
        return 'BMC-PGB Stocks';

    }
  }
}
