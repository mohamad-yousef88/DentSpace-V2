import 'package:dentspace/features/tools/domain/entities/tool.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('Tool.fromJson', () {
    test('parses a full payload correctly', () {
      final json = TestData.toolJson();

      final tool = Tool.fromJson(json);

      expect(tool.id, 1);
      expect(tool.sellerId, 100);
      expect(tool.name, 'Dental Mirror');
      expect(tool.category, 'diagnostic');
      expect(tool.price, 25.0);
      expect(tool.status, ToolStatus.available);
      expect(tool.seller, isNotNull);
      expect(tool.seller!.fullName, 'Dr. Seller');
    });

    test('falls back on missing optional fields', () {
      final tool = Tool.fromJson(const {
        'id': 1,
        'seller_id': 100,
      });

      expect(tool.name, '');
      expect(tool.price, 0.0);
      expect(tool.imageUrls, isEmpty);
      expect(tool.status, ToolStatus.available);
    });

    test('parses all four statuses', () {
      for (final status in ToolStatus.values) {
        final tool = Tool.fromJson(TestData.toolJson(status: status.name));
        expect(tool.status, status);
      }
    });
  });

  group('Tool.toJson', () {
    test('round-trips through JSON', () {
      final original = TestData.tool(imageCount: 2);

      final restored = Tool.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.status, original.status);
      expect(restored.imageUrls.length, 2);
      expect(restored.seller?.id, original.seller?.id);
    });
  });

  group('ToolStatus helpers', () {
    test('isEditable is true only for available', () {
      expect(ToolStatus.available.isEditable, isTrue);
      expect(ToolStatus.reserved.isEditable, isFalse);
      expect(ToolStatus.sold.isEditable, isFalse);
      expect(ToolStatus.archived.isEditable, isFalse);
    });
  });
}