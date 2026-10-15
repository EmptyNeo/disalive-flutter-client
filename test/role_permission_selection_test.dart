import 'package:disalive/domain/enums/entity_type.dart';
import 'package:disalive/presentation/features/role_members/role_permission_meta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final type in [EntityType.chat, EntityType.server]) {
    group('$type role permissions', () {
      final otherKeys = rolePermissionsFor(
        type,
      ).map((meta) => meta.key).where((key) => key != 'administrator').toList();

      test('administrator enables and disables every permission', () {
        final enabled = changeRolePermission(type, {}, 'administrator', true);
        expect(enabled.values.every((value) => value), isTrue);

        final disabled = changeRolePermission(
          type,
          enabled,
          'administrator',
          false,
        );
        expect(disabled.values.every((value) => !value), isTrue);
      });

      test('disabling one permission clears administrator', () {
        final enabled = changeRolePermission(type, {}, 'administrator', true);
        final changed = changeRolePermission(
          type,
          enabled,
          otherKeys.first,
          false,
        );
        expect(changed['administrator'], isFalse);
        expect(changed[otherKeys.first], isFalse);
        expect(changed[otherKeys.last], isTrue);
      });

      test('enabling the final permission enables administrator', () {
        final almostAll = {for (final key in otherKeys) key: true}
          ..[otherKeys.last] = false;
        final changed = changeRolePermission(
          type,
          almostAll,
          otherKeys.last,
          true,
        );
        expect(changed['administrator'], isTrue);
      });

      test('loaded permissions are synchronized', () {
        final administrator = normalizeRolePermissions(type, {
          'administrator': true,
        });
        expect(administrator.values.every((value) => value), isTrue);

        final allIndividual = normalizeRolePermissions(type, {
          for (final key in otherKeys) key: true,
        });
        expect(allIndividual['administrator'], isTrue);
      });
    });
  }
}
