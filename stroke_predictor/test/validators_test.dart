import 'package:flutter_test/flutter_test.dart';
import 'package:stroke_predictor/utils/validators.dart';

void main() {
  test('BMI Field Boundary: -1 returns validation error', () {
    final result = validateNonNegativeNumber('BMI', '-1');
    expect(result, 'BMI cannot be negative');
  });

  test('BMI valid value returns null', () {
    final result = validateNonNegativeNumber('BMI', '27.5');
    expect(result, isNull);
  });
}
