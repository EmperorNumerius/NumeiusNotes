import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/models/periodic_table_data.dart';

void main() {
  group('ChemElement.fromJson', () {
    test('returns correct element for valid atomic number (Hydrogen)', () {
      final json = {'atomicNumber': 1};
      final element = ChemElement.fromJson(json);

      expect(element.atomicNumber, 1);
      expect(element.symbol, 'H');
      expect(element.name, 'Hydrogen');
      expect(element.mass, 1.008);
      expect(element.category, ElementCategory.nonmetal);
    });

    test('returns correct element for valid atomic number (Oganesson)', () {
      final json = {'atomicNumber': 118};
      final element = ChemElement.fromJson(json);

      expect(element.atomicNumber, 118);
      expect(element.symbol, 'Og');
      expect(element.name, 'Oganesson');
    });

    test('throws StateError for invalid atomic number', () {
      final json = {'atomicNumber': 999};
      expect(() => ChemElement.fromJson(json), throwsStateError);
    });

    test('throws StateError for missing atomicNumber key', () {
      final json = <String, dynamic>{};
      expect(() => ChemElement.fromJson(json), throwsStateError);
    });

    test('throws StateError for null atomicNumber', () {
       final json = {'atomicNumber': null};
       expect(() => ChemElement.fromJson(json), throwsStateError);
    });
  });
}
