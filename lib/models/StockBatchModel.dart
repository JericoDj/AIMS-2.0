class StockBatch {
  final int quantity;
  final DateTime expiry;

  StockBatch({
    required this.quantity,
    required this.expiry,
  });

  factory StockBatch.fromMap(Map<String, dynamic> map) {
    return StockBatch(
      quantity: map['quantity'],
      expiry: DateTime.parse(map['expiry']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'quantity': quantity,
      'expiry': expiry.toIso8601String(),
    };
  }
}
