import 'package:expense_manager_app/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formatters.money', () {
    test('formatea un monto positivo', () {
      expect(Formatters.money(3000), r'$ 3.000');
    });

    test('pone el signo negativo antes del símbolo', () {
      expect(Formatters.money(-3000), r'-$ 3.000');
    });

    test('formatea el cero', () {
      expect(Formatters.money(0), r'$ 0');
    });

    test('separa los miles de un monto de millones', () {
      expect(Formatters.money(1234567), r'$ 1.234.567');
    });
  });
}
