import 'package:flutter_test/flutter_test.dart';
import 'package:account_book/core/utils/date_util.dart';

void main() {
  group('formatDate', () {
    test('格式化为 yyyy-MM-dd', () {
      final date = DateTime(2026, 6, 2);
      expect(DateUtil.formatDate(date), '2026-06-02');
    });

    test('个位数补零', () {
      final date = DateTime(2026, 1, 5);
      expect(DateUtil.formatDate(date), '2026-01-05');
    });
  });

  group('isSameDay', () {
    test('同一天返回 true', () {
      expect(
        DateUtil.isSameDay(
          DateTime(2026, 6, 2, 10, 30),
          DateTime(2026, 6, 2, 22, 0),
        ),
        isTrue,
      );
    });

    test('不同天返回 false', () {
      expect(
        DateUtil.isSameDay(DateTime(2026, 6, 2), DateTime(2026, 6, 3)),
        isFalse,
      );
    });

    test('不同月返回 false', () {
      expect(
        DateUtil.isSameDay(DateTime(2026, 5, 2), DateTime(2026, 6, 2)),
        isFalse,
      );
    });
  });

  group('isSameMonth', () {
    test('同月返回 true', () {
      expect(
        DateUtil.isSameMonth(
          DateTime(2026, 6, 2),
          DateTime(2026, 6, 15),
        ),
        isTrue,
      );
    });

    test('不同月返回 false', () {
      expect(
        DateUtil.isSameMonth(DateTime(2026, 6, 1), DateTime(2026, 7, 1)),
        isFalse,
      );
    });
  });

  group('startOfDay / endOfDay', () {
    test('startOfDay 时间为 00:00:00', () {
      final result = DateUtil.startOfDay(DateTime(2026, 6, 2, 15, 30));
      expect(result.year, 2026);
      expect(result.month, 6);
      expect(result.day, 2);
      expect(result.hour, 0);
      expect(result.minute, 0);
      expect(result.second, 0);
    });

    test('endOfDay 时间为 23:59:59', () {
      final result = DateUtil.endOfDay(DateTime(2026, 6, 2));
      expect(result.year, 2026);
      expect(result.month, 6);
      expect(result.day, 2);
      expect(result.hour, 23);
      expect(result.minute, 59);
      expect(result.second, 59);
    });
  });

  group('startOfMonth / endOfMonth', () {
    test('startOfMonth', () {
      final result = DateUtil.startOfMonth(2026, 6);
      expect(result.year, 2026);
      expect(result.month, 6);
      expect(result.day, 1);
    });

    test('endOfMonth', () {
      final result = DateUtil.endOfMonth(2026, 6);
      expect(result.year, 2026);
      expect(result.month, 6);
      expect(result.day, 30);
    });
  });

  group('formatMonth', () {
    test('格式化为 yyyy-MM', () {
      expect(DateUtil.formatMonth(2026, 6), '2026-06');
      expect(DateUtil.formatMonth(2026, 12), '2026-12');
    });
  });
}
