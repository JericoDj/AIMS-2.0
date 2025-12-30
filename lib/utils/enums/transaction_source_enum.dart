enum TransactionSource {
  online,
  offline,
}

extension TransactionSourceX on TransactionSource {
  String get value {
    switch (this) {
      case TransactionSource.online:
        return 'ONLINE';
      case TransactionSource.offline:
        return 'OFFLINE';
    }
  }

  static TransactionSource fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'OFFLINE':
        return TransactionSource.offline;
      case 'ONLINE':
      default:
        return TransactionSource.online;
    }
  }
}
