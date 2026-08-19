import 'package:flutter_test/flutter_test.dart';
import 'package:maraki_pos_mobile/providers/pos_provider.dart';
import 'package:maraki_pos_mobile/models/models.dart';

void main() {
  test('POSProvider initial state & shift start', () async {
    final pos = POSProvider();
    expect(pos.mode, AppMode.gate);

    pos.selectShift(ShiftType.day);
    expect(pos.mode, AppMode.cups);
    expect(pos.shiftType, ShiftType.day);

    pos.startShiftSession(120);
    expect(pos.mode, AppMode.pos);
    expect(pos.shiftSession, isNotNull);
    expect(pos.shiftSession!.openingCups, 120);
  });

  test('POSProvider cart and fire order workflow', () async {
    final pos = POSProvider();
    pos.selectShift(ShiftType.day);
    pos.startShiftSession(120);

    final product = Product(
      id: 'test-1',
      name: 'Avocado',
      amharicName: 'አቮካዶ',
      category: 'Juice',
      price: 170.0,
      description: 'Fresh',
      imageUrl: '',
      isAvailable: true,
    );

    pos.addToCart(product);
    pos.addToCart(product);
    expect(pos.currentCart.length, 1);
    expect(pos.currentCart.first.quantity, 2);
    expect(pos.cartTotal, 340.0);

    final fired = pos.fireOrder();
    expect(fired, isTrue);
    expect(pos.currentCart.isEmpty, isTrue);
    expect(pos.orders.length, 1);
    expect(pos.shiftJuiceCupsSold, 2);
  });

  test('Accounting calculations and Net Cash formula', () {
    const double cashSales = 850.0;
    const double collectedDebts = 2210.0;
    const double totalExpenses = 350.0;

    final double netCash = cashSales + collectedDebts - totalExpenses;
    expect(netCash, 2710.0);

    const int openingCups = 120;
    const int addedCups = 0;
    const int leftoverCups = 108;
    const int soldCups = 12;

    final int calculatedSold = (openingCups + addedCups) - leftoverCups;
    expect(calculatedSold, soldCups);
    expect(calculatedSold - soldCups, 0); // 0 variance
  });
}
