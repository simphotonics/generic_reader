import 'package:generic_reader/generic_reader.dart';
import 'package:test/test.dart';

void main() async {
  group('numDecoder:', () {
    test('canDecode<int>()', () {
      expect(numDecoder.canDecode<int>(), true);
    });
    test('canDecode<double>()', () {
      expect(numDecoder.canDecode<double>(), true);
    });
  });
}
