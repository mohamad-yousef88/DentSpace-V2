import 'package:dentspace/core/utils/helpers/debouncer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Debouncer', () {
    test('runs the callback once after the delay', () async {
      final d = Debouncer(delay: const Duration(milliseconds: 50));
      addTearDown(d.dispose);

      var calls = 0;
      d.run(() => calls++);

      expect(calls, 0);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(calls, 1);
    });

    test('rapid consecutive calls cancel previous ones', () async {
      final d = Debouncer(delay: const Duration(milliseconds: 50));
      addTearDown(d.dispose);

      var calls = 0;
      d.run(() => calls++);
      d.run(() => calls++);
      d.run(() => calls++);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(calls, 1, reason: 'only the last run should fire');
    });

    test('non-consecutive calls fire independently', () async {
      final d = Debouncer(delay: const Duration(milliseconds: 30));
      addTearDown(d.dispose);

      var calls = 0;

      d.run(() => calls++);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(calls, 1);

      d.run(() => calls++);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(calls, 2);
    });

    test('dispose cancels a pending callback', () async {
      final d = Debouncer(delay: const Duration(milliseconds: 50));
      var calls = 0;

      d.run(() => calls++);
      d.dispose();

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(calls, 0);
    });
  });
}