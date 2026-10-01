import 'package:dental_managment_system/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('arabic index list is initialized', () {
    expect(arabicIndex, isNotEmpty);
    expect(arabicIndex.first, 'ا');
  });
}
