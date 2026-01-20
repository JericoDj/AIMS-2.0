enum ItemCategory {
  PGB,
  DSB,
  BMC,

}

extension ItemCategoryX on ItemCategory {
  String get label {
    switch (this) {
      case ItemCategory.PGB:
        return 'PGB Stocks';
      case ItemCategory.DSB:
        return 'DSB Stocks';
      case ItemCategory.BMC:
        return 'BMC Stocks';

    }
  }
}
