import 'package:craie/core/utils/maps.dart';
import 'package:craie/core/utils/time_slot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses coordinates from Maps links', () {
    expect(parseCoordinates('https://www.google.com/maps/@6.4167,2.3333,17z')?.lat, 6.4167);
    expect(parseCoordinates('https://maps.google.com/?q=6.45,2.35')?.lng, 2.35);
    expect(parseCoordinates('x!3d6.41!4d2.33')?.lat, 6.41);
    expect(parseCoordinates('6.41, 2.33')?.lng, 2.33);
    expect(parseCoordinates('https://maps.app.goo.gl/abc'), isNull);
  });

  test('slot validation', () {
    final d = DateTime(2026, 1, 1);
    DateTime at(int h, int m) => DateTime(d.year, d.month, d.day, h, m);
    expect(validateSlot(at(8, 0), at(13, 0)), isNull);
    expect(validateSlot(at(8, 0), at(8, 30)), isNull);
    expect(validateSlot(at(8, 0), at(8, 29)), contains('au moins 30'));
    expect(validateSlot(at(13, 0), at(8, 0)), contains('antérieure'));
    expect(validateSlot(at(8, 0), at(8, 0)), contains('antérieure'));
  });
}
