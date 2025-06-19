import 'package:aromex/util.dart';

abstract class BillItem {
  String _title;
  double _unitPrice;
  int _quantity;
  String? _note;

  BillItem({
    required String title,
    required double unitPrice,
    required int quantity,
    String? note,
  }) : _title = title,
       _unitPrice = unitPrice,
       _quantity = quantity,
       _note = note;

  String get title => _title;

  String get unitPrice =>
      formatCurrency(_unitPrice, decimals: 2, showTrail: true);

  double get unitPriceValue => _unitPrice;

  String get totalPrice =>
      formatCurrency(_unitPrice * _quantity, decimals: 2, showTrail: true);

  double get totalPriceValue => _unitPrice * _quantity;

  int get quantity => _quantity;

  String? get note => _note;
}

class BillItemImpl extends BillItem {
  BillItemImpl({
    required super.title,
    required super.unitPrice,
    required super.quantity,
    super.note,
  });

  @override
  String toString() {
    return 'BillItem(title: $title, unitPrice: $unitPrice, quantity: $quantity, note: $note)';
  }
}
